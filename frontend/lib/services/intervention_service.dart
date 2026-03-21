import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:easyconnect/services/http_interceptor.dart';
import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/Models/intervention_model.dart';
import 'package:easyconnect/Models/pagination_response.dart';
import 'package:easyconnect/utils/constant.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/services/api_service.dart';
import 'package:easyconnect/utils/auth_error_handler.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/retry_helper.dart';
import 'package:easyconnect/utils/pagination_helper.dart';
import 'package:easyconnect/services/storage_service.dart';

class InterventionService {
  final storage = GetStorage();

  /// Récupérer les interventions avec pagination côté serveur
  Future<PaginationResponse<Intervention>> getInterventionsPaginated({
    String? status,
    String? type,
    String? priority,
    String? search,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final token = storage.read('token');
      final userRole = storage.read('userRole');
      final userId = storage.read('userId');

      String url = '${AppConfig.baseUrl}/interventions';
      List<String> params = [];

      if (status != null && status.isNotEmpty) {
        params.add('status=$status');
      }
      if (type != null && type.isNotEmpty) {
        params.add('type=$type');
      }
      if (priority != null && priority.isNotEmpty) {
        params.add('priority=$priority');
      }
      if (search != null && search.isNotEmpty) {
        params.add('search=$search');
      }
      // Filtrer par userId uniquement pour les techniciens (role 5)
      if (userRole == 5 && userId != null) {
        params.add('user_id=$userId');
      }
      // Ajouter la pagination
      params.add('page=$page');
      params.add('per_page=$perPage');

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      AppLogger.httpRequest('GET', url, tag: 'INTERVENTION_SERVICE');

      final response = await RetryHelper.retryNetwork(
        operation:
            () => HttpInterceptor.get(
              Uri.parse(url),
              headers: {
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
              },
            ),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(
        response.statusCode,
        url,
        tag: 'INTERVENTION_SERVICE',
      );
      await AuthErrorHandler.handleHttpResponse(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final result = PaginationHelper.parseResponse<Intervention>(
          json: data,
          fromJsonT: (json) => Intervention.fromJson(json),
        );
        if (page == 1 && result.data.isNotEmpty) {
          _saveInterventionsToHive(result.data);
        }
        return result;
      } else {
        throw Exception(
          'Erreur lors de la récupération paginée des interventions: ${response.statusCode}',
        );
      }
    } catch (e) {
      AppLogger.error(
        'Erreur dans getInterventionsPaginated: $e',
        tag: 'INTERVENTION_SERVICE',
      );
      rethrow;
    }
  }

  // Récupérer toutes les interventions
  Future<List<Intervention>> getInterventions({
    String? status,
    String? type,
    String? priority,
    String? search,
  }) async {
    try {
      final token = storage.read('token');
      final userRole = storage.read('userRole');
      final userId = storage.read('userId');

      var queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (type != null) queryParams['type'] = type;
      if (priority != null) queryParams['priority'] = priority;
      if (search != null) queryParams['search'] = search;
      // Filtrer par userId uniquement pour les techniciens (role 5)
      // Les admins (role 1) et patrons (role 6) doivent voir toutes les interventions
      if (userRole == 5 && userId != null) {
        queryParams['user_id'] = userId.toString();
      }

      final queryString =
          queryParams.isEmpty
              ? ''
              : '?${Uri(queryParameters: queryParams).query}';

      final url = '$baseUrl/interventions-list$queryString';

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(
            AppConfig.extraLongTimeout,
            onTimeout: () {
              throw Exception(
                'Timeout: le serveur ne répond pas',
              );
            },
          );

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        final responseData = result['data'];

        // Gérer différents formats de réponse
        List<dynamic> data;
        if (responseData is List) {
          data = responseData;
        } else if (responseData is Map<String, dynamic>) {
          if (responseData['data'] is List) {
            data = responseData['data'];
          } else if (responseData['data'] is Map &&
              responseData['data']['data'] is List) {
            data = responseData['data']['data'];
          } else {
            data = [responseData['data']];
          }
        } else {
          data = [];
        }

        print('✅ [INTERVENTION] ${data.length} interventions trouvées');
        final list = data.map((json) => Intervention.fromJson(json)).toList();
        _saveInterventionsToHive(list);
        return list;
      }

      throw Exception(
        result['message'] ?? 'Erreur lors de la récupération des interventions',
      );
    } catch (e) {
      throw Exception('Erreur lors de la récupération des interventions: $e');
    }
  }

  // Récupérer une intervention par ID
  Future<Intervention> getInterventionById(int id) async {
    try {
      final token = storage.read('token');

      final response = await HttpInterceptor.get(
        Uri.parse('$baseUrl/interventions-show/$id'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        return Intervention.fromJson(result['data']);
      }

      throw Exception(
        result['message'] ??
            'Erreur lors de la récupération de l\'intervention',
      );
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'intervention: $e');
    }
  }

  // Créer une intervention
  Future<Intervention> createIntervention(Intervention intervention) async {
    try {
      final token = storage.read('token');

      final response = await http
          .post(
            Uri.parse('$baseUrl/interventions-create'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(intervention.toJson()),
          )
          .timeout(
            AppConfig.defaultTimeout,
            onTimeout: () =>
                throw Exception('Timeout: le serveur ne répond pas'),
          );
      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        return Intervention.fromJson(result['data']);
      } else if (result['statusCode'] == 500) {
        // En cas d'erreur 500, simuler une création locale
        return Intervention(
          id: DateTime.now().millisecondsSinceEpoch,
          title: intervention.title,
          description: intervention.description,
          type: intervention.type,
          priority: intervention.priority,
          status: 'pending',
          scheduledDate: intervention.scheduledDate,
          location: intervention.location,
          clientId: intervention.clientId,
          clientName: intervention.clientName,
          clientPhone: intervention.clientPhone,
          clientEmail: intervention.clientEmail,
          equipment: intervention.equipment,
          problemDescription: intervention.problemDescription,
          notes: intervention.notes,
          estimatedDuration: intervention.estimatedDuration,
          cost: intervention.cost,
          attachments: intervention.attachments,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      throw Exception(
        'Erreur lors de la création de l\'intervention: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      // En cas d'erreur de connexion, simuler une création locale
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Timeout') ||
          e.toString().contains('Connection')) {
        return Intervention(
          id: DateTime.now().millisecondsSinceEpoch,
          title: intervention.title,
          description: intervention.description,
          type: intervention.type,
          priority: intervention.priority,
          status: 'pending',
          scheduledDate: intervention.scheduledDate,
          location: intervention.location,
          clientId: intervention.clientId,
          clientName: intervention.clientName,
          clientPhone: intervention.clientPhone,
          clientEmail: intervention.clientEmail,
          equipment: intervention.equipment,
          problemDescription: intervention.problemDescription,
          notes: intervention.notes,
          estimatedDuration: intervention.estimatedDuration,
          cost: intervention.cost,
          attachments: intervention.attachments,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      throw Exception('Erreur lors de la création de l\'intervention: $e');
    }
  }

  // Mettre à jour une intervention
  Future<Intervention> updateIntervention(Intervention intervention) async {
    try {
      final token = storage.read('token');

      final response = await http
          .put(
            Uri.parse('$baseUrl/interventions-update/${intervention.id}'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(intervention.toJson()),
          )
          .timeout(
            AppConfig.defaultTimeout,
            onTimeout: () =>
                throw Exception('Timeout: le serveur ne répond pas'),
          );

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        return Intervention.fromJson(result['data']);
      }

      throw Exception(
        result['message'] ?? 'Erreur lors de la mise à jour de l\'intervention',
      );
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'intervention: $e');
    }
  }

  // Approuver une intervention
  Future<bool> approveIntervention(int interventionId, {String? notes}) async {
    try {
      final token = storage.read('token');

      final response = await HttpInterceptor.post(
        Uri.parse('$baseUrl/interventions-approve/$interventionId'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'notes': notes}),
      );

      // Si le status code est 200 ou 201, considérer comme succès
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }

      final result = ApiService.parseResponse(response);
      return result['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // Rejeter une intervention
  Future<bool> rejectIntervention(
    int interventionId, {
    required String reason,
  }) async {
    try {
      final token = storage.read('token');

      final response = await HttpInterceptor.post(
        Uri.parse('$baseUrl/interventions-reject/$interventionId'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'reason': reason}),
      );

      final result = ApiService.parseResponse(response);
      return result['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // Démarrer une intervention
  Future<bool> startIntervention(int interventionId, {String? notes}) async {
    try {
      final token = storage.read('token');

      final response = await HttpInterceptor.post(
        Uri.parse('$baseUrl/interventions-start/$interventionId'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'notes': notes}),
      );

      final result = ApiService.parseResponse(response);
      return result['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // Terminer une intervention
  Future<bool> completeIntervention(
    int interventionId, {
    required String solution,
    String? completionNotes,
    double? actualDuration,
    double? cost,
  }) async {
    try {
      final token = storage.read('token');

      final response = await HttpInterceptor.post(
        Uri.parse('$baseUrl/interventions-complete/$interventionId'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'solution': solution,
          'completion_notes': completionNotes,
          'actual_duration': actualDuration,
          'cost': cost,
        }),
      );

      final result = ApiService.parseResponse(response);
      return result['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // Supprimer une intervention
  Future<bool> deleteIntervention(int interventionId) async {
    try {
      final token = storage.read('token');

      final response = await HttpInterceptor.delete(
        Uri.parse('$baseUrl/interventions-delete/$interventionId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final result = ApiService.parseResponse(response);
      return result['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // Récupérer les statistiques des interventions
  Future<InterventionStats> getInterventionStats() async {
    try {
      final token = storage.read('token');

      final response = await HttpInterceptor.get(
        Uri.parse('$baseUrl/interventions-stats'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        return InterventionStats.fromJson(result['data']);
      } else if (result['statusCode'] == 404) {
        // En cas d'erreur 404, retourner des statistiques vides
        return InterventionStats(
          totalInterventions: 0,
          pendingInterventions: 0,
          approvedInterventions: 0,
          inProgressInterventions: 0,
          completedInterventions: 0,
          rejectedInterventions: 0,
          externalInterventions: 0,
          onSiteInterventions: 0,
          averageDuration: 0.0,
          totalCost: 0.0,
          interventionsByMonth: {},
          interventionsByPriority: {},
        );
      }
      throw Exception(
        'Erreur lors de la récupération des statistiques: ${response.statusCode}',
      );
    } catch (e) {
      // Retourner des données de test en cas d'erreur
      return InterventionStats(
        totalInterventions: 0,
        pendingInterventions: 0,
        approvedInterventions: 0,
        inProgressInterventions: 0,
        completedInterventions: 0,
        rejectedInterventions: 0,
        externalInterventions: 0,
        onSiteInterventions: 0,
        averageDuration: 0.0,
        totalCost: 0.0,
        interventionsByMonth: {},
        interventionsByPriority: {},
      );
    }
  }

  // Récupérer les interventions en attente
  Future<List<Intervention>> getPendingInterventions() async {
    try {
      final token = storage.read('token');
      final userRole = storage.read('userRole');
      final userId = storage.read('userId');

      var queryParams = <String, String>{};
      // Filtrer par userId uniquement pour les techniciens (role 5)
      // Les admins (role 1) et patrons (role 6) doivent voir toutes les interventions
      if (userRole == 5 && userId != null) {
        queryParams['user_id'] = userId.toString();
      }

      final queryString =
          queryParams.isEmpty
              ? ''
              : '?${Uri(queryParameters: queryParams).query}';

      final response = await HttpInterceptor.get(
        Uri.parse('$baseUrl/interventions/pending$queryString'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        final data = result['data'];
        if (data is List) {
          return data.map((json) => Intervention.fromJson(json)).toList();
        }
        return [];
      }

      throw Exception(
        result['message'] ??
            'Erreur lors de la récupération des interventions en attente',
      );
    } catch (e) {
      throw Exception(
        'Erreur lors de la récupération des interventions en attente: $e',
      );
    }
  }

  // Récupérer les interventions du technicien
  Future<List<Intervention>> getTechnicianInterventions(
    int technicianId,
  ) async {
    try {
      final token = storage.read('token');

      final response = await HttpInterceptor.get(
        Uri.parse('$baseUrl/interventions/technician/$technicianId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        final data = result['data'];
        if (data is List) {
          return data.map((json) => Intervention.fromJson(json)).toList();
        }
        return [];
      }

      throw Exception(
        result['message'] ??
            'Erreur lors de la récupération des interventions du technicien',
      );
    } catch (e) {
      throw Exception(
        'Erreur lors de la récupération des interventions du technicien: $e',
      );
    }
  }

  // Ajouter une pièce jointe
  Future<bool> addAttachment(int interventionId, String filePath) async {
    try {
      final token = storage.read('token');

      final response = await HttpInterceptor.post(
        Uri.parse('$baseUrl/interventions/$interventionId/attachments'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'file_path': filePath}),
      );

      final result = ApiService.parseResponse(response);
      return result['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // Supprimer une pièce jointe
  Future<bool> removeAttachment(int interventionId, String filePath) async {
    try {
      final token = storage.read('token');

      final response = await HttpInterceptor.delete(
        Uri.parse('$baseUrl/interventions/$interventionId/attachments'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'file_path': filePath}),
      );

      final result = ApiService.parseResponse(response);
      return result['success'] == true;
    } catch (e) {
      return false;
    }
  }

  static void _saveInterventionsToHive(List<Intervention> list) {
    try {
      HiveStorageService.saveEntityList(
        HiveStorageService.keyInterventions,
        list.map((e) => e.toJson()).toList(),
      );
    } catch (_) {}
  }

  /// Cache Hive : liste des interventions pour affichage instantané.
  static List<Intervention> getCachedInterventions() {
    try {
      final raw = HiveStorageService.getEntityList(HiveStorageService.keyInterventions);
      return raw.map((e) => Intervention.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }
}

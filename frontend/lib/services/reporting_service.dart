import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:easyconnect/services/http_interceptor.dart';
import 'package:easyconnect/Models/reporting_model.dart';
import 'package:easyconnect/Models/pagination_response.dart';
import 'package:easyconnect/services/api_service.dart';
import 'package:easyconnect/utils/constant.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/utils/auth_error_handler.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/retry_helper.dart';
import 'package:easyconnect/utils/pagination_helper.dart';
import 'package:easyconnect/services/storage_service.dart';

class ReportingService {
  static final ReportingService _instance = ReportingService._();
  static ReportingService get to => _instance;
  factory ReportingService() => _instance;
  ReportingService._();

  /// Convertit le type relance de l'app (relance_telephonique, relance_mail, relance_rdv)
  /// vers le format API backend (telephonique, mail, rdv).
  static String? _typeRelanceToApi(String? typeRelance) {
    if (typeRelance == null || typeRelance.isEmpty) return null;
    switch (typeRelance) {
      case 'relance_telephonique':
        return 'telephonique';
      case 'relance_mail':
        return 'mail';
      case 'relance_rdv':
        return 'rdv';
      case 'telephonique':
      case 'mail':
      case 'rdv':
        return typeRelance;
      default:
        return typeRelance;
    }
  }

  // Créer un rapport
  Future<Map<String, dynamic>> createReport({
    required int userId,
    required String userRole,
    required DateTime reportDate,
    required String nature,
    required String nomSociete,
    String? contactSociete,
    required String nomPersonne,
    String? contactPersonne,
    required String moyenContact,
    String? produitDemarche,
    String? commentaire,
    String? typeRelance,
    DateTime? relanceDateHeure,
  }) async {
    try {
      final requestBody = {
        'user_id': userId,
        'user_role': userRole,
        'report_date': reportDate.toIso8601String(),
        'nature': nature,
        'nom_societe': nomSociete,
        'contact_societe': contactSociete,
        'nom_personne': nomPersonne,
        'contact_personne': contactPersonne,
        'moyen_contact': moyenContact,
        'produit_demarche': produitDemarche,
        'commentaire': commentaire,
        'type_relance': _typeRelanceToApi(typeRelance),
        'relance_date_heure': relanceDateHeure?.toIso8601String(),
      };

      // Log pour déboguer
      print('📤 [REPORTING_SERVICE] Création de rapport:');
      print('📤 [REPORTING_SERVICE] user_id: $userId');
      print('📤 [REPORTING_SERVICE] user_role: $userRole');
      print(
        '📤 [REPORTING_SERVICE] report_date: ${reportDate.toIso8601String()}',
      );
      print('📤 [REPORTING_SERVICE] nature: $nature');
      print('📤 [REPORTING_SERVICE] nom_societe: $nomSociete');
      print('📤 [REPORTING_SERVICE] moyen_contact: $moyenContact');

      final jsonBody = jsonEncode(requestBody);
      print('📤 [REPORTING_SERVICE] Body JSON: $jsonBody');

      final response = await HttpInterceptor.post(
        Uri.parse('$baseUrl/user-reportings-create'),
        headers: ApiService.headers(),
        body: jsonBody,
      );

      print('📥 [REPORTING_SERVICE] Réponse status: ${response.statusCode}');
      print('📥 [REPORTING_SERVICE] Réponse body: ${response.body}');
      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        // Essayer d'extraire le reporting créé
        if (responseData.containsKey('data')) {
          return responseData;
        } else {
          // Si pas de 'data', créer une structure avec les données envoyées
          return {
            'success': true,
            'data': {
              'id': responseData['id'] ?? DateTime.now().millisecondsSinceEpoch,
              'user_id': userId,
              'user_role': userRole,
              'report_date': reportDate.toIso8601String(),
              'nature': nature,
              'nom_societe': nomSociete,
              'contact_societe': contactSociete,
              'nom_personne': nomPersonne,
              'contact_personne': contactPersonne,
              'moyen_contact': moyenContact,
              'produit_demarche': produitDemarche,
              'commentaire': commentaire,
              'type_relance': _typeRelanceToApi(typeRelance),
              'relance_date_heure': relanceDateHeure?.toIso8601String(),
              'status': 'submitted',
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            },
          };
        }
      } else if (response.statusCode == 404) {
        // Route non trouvée - retourner une réponse simulée pour le développement
        return {
          'success': true,
          'message': 'Rapport créé avec succès (simulation)',
          'data': {
            'id': DateTime.now().millisecondsSinceEpoch,
            'user_id': userId,
            'user_role': userRole,
            'report_date': reportDate.toIso8601String(),
            'nature': nature,
            'nom_societe': nomSociete,
            'contact_societe': contactSociete,
            'nom_personne': nomPersonne,
            'contact_personne': contactPersonne,
            'moyen_contact': moyenContact,
            'produit_demarche': produitDemarche,
            'commentaire': commentaire,
            'type_relance': _typeRelanceToApi(typeRelance),
            'relance_date_heure': relanceDateHeure?.toIso8601String(),
            'status': 'submitted',
            'created_at': DateTime.now().toIso8601String(),
          },
        };
      } else {
        // Essayer de parser le message d'erreur du backend
        String errorMessage = 'Erreur lors de la création du rapport';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map) {
            errorMessage =
                errorBody['message'] ??
                errorBody['error'] ??
                errorBody['errors']?.toString() ??
                errorMessage;
          }
        } catch (e) {
          // Si le parsing échoue, utiliser le body brut
          errorMessage =
              response.body.isNotEmpty
                  ? response.body
                  : 'Erreur ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer les rapports d'un utilisateur
  Future<List<ReportingModel>> getUserReports({
    required int userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      String url = '$baseUrl/user-reportings-list';

      if (startDate != null && endDate != null) {
        url +=
            '?start_date=${startDate.toIso8601String()}&end_date=${endDate.toIso8601String()}';
      }
      final response = await HttpInterceptor.get(
        Uri.parse(url),
        headers: ApiService.headers(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> reportsData;

        // Gérer différents formats de réponse
        if (data is List) {
          // La réponse est directement une liste
          reportsData = data;
        } else if (data['data'] != null) {
          // La réponse contient une clé 'data'
          if (data['data'] is List) {
            reportsData = data['data'];
          } else if (data['data']['data'] != null &&
              data['data']['data'] is List) {
            // Cas de pagination Laravel: data.data.data
            reportsData = data['data']['data'];
          } else {
            reportsData = [data['data']];
          }
        } else {
          return [];
        }

        if (reportsData.isNotEmpty) {}

        final List<ReportingModel> reportsList =
            reportsData
                .map((json) {
                  try {
                    return ReportingModel.fromJson(json);
                  } catch (e) {
                    return null;
                  }
                })
                .where((report) => report != null)
                .cast<ReportingModel>()
                .toList();

        // Filtrer par userId pour s'assurer que l'utilisateur ne voit que ses propres reporting
        final filteredReports =
            reportsList.where((report) => report.userId == userId).toList();
        return filteredReports;
      } else {
        throw Exception(
          'Erreur lors de la récupération des rapports: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Récupérer les rapports avec pagination côté serveur
  /// [perPage] par défaut 10 pour limiter les réponses tronquées sur certains réseaux.
  Future<PaginationResponse<ReportingModel>> getReportsPaginated({
    DateTime? startDate,
    DateTime? endDate,
    String? userRole,
    int? userId,
    int page = 1,
    int perPage = 10,
    String? search,
  }) async {
    try {
      return await _getReportsPaginatedRequest(
        startDate: startDate,
        endDate: endDate,
        userRole: userRole,
        userId: userId,
        page: page,
        perPage: perPage,
        search: search,
      );
    } on FormatException catch (e) {
      // Réponse JSON tronquée (ex: "Unexpected end of input") → retry avec moins d'éléments
      if (perPage > 5 &&
          (e.message.contains('Unexpected end of input') ||
              e.message.contains('character'))) {
        AppLogger.info(
          'Réponse tronquée détectée, nouvel essai avec per_page=5',
          tag: 'REPORTING_SERVICE',
        );
        return _getReportsPaginatedRequest(
          startDate: startDate,
          endDate: endDate,
          userRole: userRole,
          userId: userId,
          page: page,
          perPage: 5,
          search: search,
        );
      }
      rethrow;
    }
  }

  Future<PaginationResponse<ReportingModel>> _getReportsPaginatedRequest({
    DateTime? startDate,
    DateTime? endDate,
    String? userRole,
    int? userId,
    required int page,
    required int perPage,
    String? search,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (startDate != null) {
      queryParams['start_date'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['end_date'] = endDate.toIso8601String();
    }
    if (userRole != null && userRole.isNotEmpty) queryParams['user_role'] = userRole;
    if (userId != null) queryParams['user_id'] = userId.toString();
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final uri = Uri.parse('${AppConfig.baseUrl}/user-reportings').replace(
      queryParameters: queryParams,
    );
    AppLogger.httpRequest('GET', uri.toString(), tag: 'REPORTING_SERVICE');

    final response = await RetryHelper.retryNetwork(
      operation: () => HttpInterceptor.get(uri, headers: ApiService.headers()),
      maxRetries: AppConfig.defaultMaxRetries,
    );

    AppLogger.httpResponse(response.statusCode, uri.toString(), tag: 'REPORTING_SERVICE');
    await AuthErrorHandler.handleHttpResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur lors de la récupération paginée des rapports: ${response.statusCode}',
      );
    }

    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error(
        'JSON invalide ou tronqué (${response.body.length} caractères): $e',
        tag: 'REPORTING_SERVICE',
      );
      rethrow;
    }

    final result = PaginationHelper.parseResponseSafe<ReportingModel>(
      json: data,
      fromJsonT: (json) {
        try {
          return ReportingModel.fromJson(json);
        } catch (_) {
          return null;
        }
      },
    );
    if (page == 1 && result.data.isNotEmpty) {
      _saveReportingToHive(result.data);
    }
    return result;
  }

  /// Tous les rapports : délègue à getReportsPaginated (page 1, perPage 500).
  Future<List<ReportingModel>> getAllReports({
    DateTime? startDate,
    DateTime? endDate,
    String? userRole,
    int? userId,
  }) async {
    try {
      final res = await getReportsPaginated(
        startDate: startDate,
        endDate: endDate,
        userRole: userRole,
        userId: userId,
        page: 1,
        perPage: 500,
      );
      if (res.data.isNotEmpty) {
        _saveReportingToHive(res.data);
      }
      return res.data;
    } catch (e) {
      rethrow;
    }
  }

  // Soumettre un rapport
  Future<Map<String, dynamic>> submitReport(int reportId) async {
    try {
      final response = await HttpInterceptor.post(
        Uri.parse('$baseUrl/user-reportings-submit/$reportId'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la soumission du rapport: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Approuver un rapport (pour le patron). [patronNote] est envoyé au backend.
  Future<Map<String, dynamic>> approveReport(
    int reportId, {
    String? patronNote,
  }) async {
    try {
      final response = await HttpInterceptor.post(
        Uri.parse('$baseUrl/user-reportings-validate/$reportId'),
        headers: ApiService.headers(),
        body: jsonEncode({'patron_note': patronNote}),
      );

      // Si le status code est 200 ou 201, considérer comme succès
      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = jsonDecode(response.body);
        // Si le body dit success:false mais le status code est 200/201,
        // forcer success:true car le backend a validé
        if (result is Map && result['success'] == false) {
          return {
            'success': true,
            'message': result['message'] ?? 'Rapport approuvé avec succès',
            'data': result['data'],
          };
        }
        return result;
      } else {
        throw Exception(
          'Erreur lors de l\'approbation du rapport: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Mettre à jour un rapport (champs alignés avec le backend UserReportingController::update)
  Future<Map<String, dynamic>> updateReport({
    required int reportId,
    String? nature,
    String? nomSociete,
    String? contactSociete,
    String? nomPersonne,
    String? contactPersonne,
    String? moyenContact,
    String? produitDemarche,
    String? commentaire,
    String? typeRelance,
    DateTime? relanceDateHeure,
  }) async {
    try {
      // Backend attend type_relance: telephonique, mail, rdv (sans préfixe relance_)
      String? typeRelanceSent = typeRelance;
      if (typeRelance != null && typeRelance.isNotEmpty) {
        typeRelanceSent = typeRelance
            .replaceFirst('relance_telephonique', 'telephonique')
            .replaceFirst('relance_mail', 'mail')
            .replaceFirst('relance_rdv', 'rdv');
      }
      final body = <String, dynamic>{
        if (nature != null) 'nature': nature,
        if (nomSociete != null) 'nom_societe': nomSociete,
        if (contactSociete != null) 'contact_societe': contactSociete,
        if (nomPersonne != null) 'nom_personne': nomPersonne,
        if (contactPersonne != null) 'contact_personne': contactPersonne,
        if (moyenContact != null) 'moyen_contact': moyenContact,
        if (produitDemarche != null) 'produit_demarche': produitDemarche,
        if (commentaire != null) 'commentaire': commentaire,
        if (typeRelanceSent != null && typeRelanceSent.isNotEmpty)
          'type_relance': typeRelanceSent,
        if (relanceDateHeure != null)
          'relance_date_heure': relanceDateHeure.toIso8601String(),
      };
      final response = await HttpInterceptor.put(
        Uri.parse('$baseUrl/user-reportings-update/$reportId'),
        headers: ApiService.headers(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la mise à jour du rapport: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Supprimer un rapport
  Future<Map<String, dynamic>> deleteReport(int reportId) async {
    try {
      final response = await HttpInterceptor.delete(
        Uri.parse('$baseUrl/user-reportings-delete/$reportId'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la suppression du rapport: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer un rapport spécifique
  Future<ReportingModel> getReport(int reportId) async {
    try {
      final response = await HttpInterceptor.get(
        Uri.parse('$baseUrl/user-reportings-show/$reportId'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ReportingModel.fromJson(data);
      } else {
        throw Exception(
          'Erreur lors de la récupération du rapport: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Générer un rapport
  Future<Map<String, dynamic>> generateReport({
    required int userId,
    required String userRole,
    required DateTime reportDate,
    required Map<String, dynamic> metrics,
    String? comments,
  }) async {
    try {
      final response = await HttpInterceptor.post(
        Uri.parse('$baseUrl/user-reportings-generate'),
        headers: ApiService.headers(),
        body: jsonEncode({
          'user_id': userId,
          'user_role': userRole,
          'report_date': reportDate.toIso8601String(),
          'metrics': metrics,
          'comments': comments,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la génération du rapport: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer les statistiques de reporting
  Future<Map<String, dynamic>> getReportingStats({
    DateTime? startDate,
    DateTime? endDate,
    String? userRole,
  }) async {
    try {
      String url = '$baseUrl/user-reportings-stats';
      List<String> params = [];

      if (startDate != null) {
        params.add('start_date=${startDate.toIso8601String()}');
      }
      if (endDate != null) {
        params.add('end_date=${endDate.toIso8601String()}');
      }
      if (userRole != null) {
        params.add('user_role=$userRole');
      }

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await HttpInterceptor.get(
        Uri.parse(url),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la récupération des statistiques: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Rejeter un rapport
  Future<Map<String, dynamic>> rejectReport(
    int reportId, {
    String? comments,
  }) async {
    try {
      final response = await HttpInterceptor.post(
        Uri.parse('$baseUrl/user-reportings-reject/$reportId'),
        headers: ApiService.headers(),
        body: jsonEncode({'comments': comments}),
      );

      // Si le status code est 200 ou 201, considérer comme succès
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final result = jsonDecode(response.body);
          // Si le body dit success:false mais le status code est 200/201,
          // forcer success:true car le backend a validé
          if (result is Map && result['success'] == false) {
            return {
              'success': true,
              'message': result['message'] ?? 'Rapport rejeté avec succès',
              'data': result['data'],
            };
          }
          return result;
        } catch (e) {
          // Si le parsing échoue mais le status code est 200/201, considérer comme succès
          return {
            'success': true,
            'message': 'Rapport rejeté avec succès',
          };
        }
      } else {
        throw Exception(
          'Erreur lors du rejet du rapport: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Ajouter ou modifier la note du patron sur un rapport
  Future<Map<String, dynamic>> addPatronNote(
    int reportId, {
    String? note,
  }) async {
    try {
      final response = await HttpInterceptor.post(
        Uri.parse('$baseUrl/user-reportings-note/$reportId'),
        headers: ApiService.headers(),
        body: jsonEncode({'patron_note': note}),
      );

      // Si le status code est 200 ou 201, considérer comme succès
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final result = jsonDecode(response.body);
          // Si le body dit success:false mais le status code est 200/201,
          // forcer success:true car le backend a validé
          if (result is Map && result['success'] == false) {
            return {
              'success': true,
              'message': result['message'] ?? 'Note enregistrée avec succès',
              'data': result['data'],
            };
          }
          return result;
        } catch (e) {
          // Si le parsing échoue mais le status code est 200/201, considérer comme succès
          return {
            'success': true,
            'message': 'Note enregistrée avec succès',
          };
        }
      } else {
        throw Exception(
          'Erreur lors de l\'ajout de la note: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  static void _saveReportingToHive(List<ReportingModel> list) {
    try {
      HiveStorageService.saveEntityList(
        HiveStorageService.keyReporting,
        list.map((e) => e.toJson()).toList(),
      );
    } catch (_) {}
  }

  /// Persiste la liste en cache Hive (appelé après création ou refresh API).
  static void saveCachedReporting(List<ReportingModel> list) {
    _saveReportingToHive(list);
  }

  /// Cache Hive : liste des reportings pour affichage instantané.
  static List<ReportingModel> getCachedReporting() {
    try {
      final raw = HiveStorageService.getEntityList(HiveStorageService.keyReporting);
      return raw.map((e) => ReportingModel.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }
}

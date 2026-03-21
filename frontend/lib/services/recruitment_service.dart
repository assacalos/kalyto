import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:easyconnect/services/http_interceptor.dart';
import 'package:easyconnect/Models/recruitment_model.dart';
import 'package:easyconnect/services/api_service.dart';
import 'package:easyconnect/services/storage_service.dart';
import 'package:easyconnect/utils/constant.dart';

class RecruitmentService {
  static final RecruitmentService _instance = RecruitmentService._();
  static RecruitmentService get to => _instance;
  factory RecruitmentService() => _instance;
  RecruitmentService._();

  // Créer une demande de recrutement
  Future<Map<String, dynamic>> createRecruitmentRequest({
    required String title,
    required String department,
    required String position,
    required String description,
    required String requirements,
    required String responsibilities,
    required int numberOfPositions,
    required String employmentType,
    required String experienceLevel,
    required String salaryRange,
    required String location,
    required DateTime applicationDeadline,
  }) async {
    try {
      final response = await HttpInterceptor.post(
        Uri.parse('$baseUrl/recruitment-requests'),
        headers: ApiService.headers(),
        body: jsonEncode({
          'title': title,
          'department': department,
          'position': position,
          'description': description,
          'requirements': requirements,
          'responsibilities': responsibilities,
          'number_of_positions': numberOfPositions,
          'employment_type': employmentType,
          'experience_level': experienceLevel,
          'salary_range': salaryRange,
          'location': location,
          'application_deadline': applicationDeadline.toIso8601String(),
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la création de la demande: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer toutes les demandes de recrutement
  Future<List<RecruitmentRequest>> getAllRecruitmentRequests({
    String? status,
    String? department,
    String? position,
  }) async {
    try {
      String url = '$baseUrl/recruitment-requests';
      List<String> params = [];

      if (status != null) {
        params.add('status=$status');
      }
      if (department != null) {
        params.add('department=$department');
      }
      if (position != null) {
        params.add('position=$position');
      }

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await HttpInterceptor.get(
        Uri.parse(url),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['data'] != null) {
          // Le backend peut retourner soit une liste directe, soit un objet paginé
          List<dynamic> dataList;

          if (data['data'] is List) {
            // Format simple : {"success": true, "data": [...]}
            dataList = data['data'] as List;
          } else if (data['data'] is Map && data['data']['data'] != null) {
            // Format paginé : {"success": true, "data": {"current_page": 1, "data": [...]}}
            dataList = data['data']['data'] as List;
          } else {
            return [];
          }

          try {
            final requests =
                dataList
                    .map((json) => RecruitmentRequest.fromJson(json))
                    .toList();
            _saveRecruitmentsToHive(requests);
            return requests;
          } catch (e) {
            rethrow;
          }
        } else {
          return [];
        }
      } else {
        throw Exception(
          'Erreur lors de la récupération des demandes: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer une demande de recrutement par ID
  Future<RecruitmentRequest> getRecruitmentRequest(int id) async {
    try {
      final response = await HttpInterceptor.get(
        Uri.parse('$baseUrl/recruitment-requests/$id'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return RecruitmentRequest.fromJson(data['data']);
      } else {
        throw Exception(
          'Erreur lors de la récupération de la demande: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Publier une demande de recrutement
  Future<Map<String, dynamic>> publishRecruitmentRequest(int id) async {
    try {
      final response = await HttpInterceptor.post(
        Uri.parse('$baseUrl/recruitment-requests/$id/publish'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la publication: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Approuver une demande de recrutement
  Future<Map<String, dynamic>> approveRecruitmentRequest(int id) async {
    try {
      final response = await HttpInterceptor.post(
        Uri.parse('$baseUrl/recruitment-requests/$id/approve'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de l\'approbation: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Rejeter une demande de recrutement
  Future<Map<String, dynamic>> rejectRecruitmentRequest(
    int id, {
    required String rejectionReason,
  }) async {
    try {
      final response = await HttpInterceptor.put(
        Uri.parse('$baseUrl/recruitment-requests/$id/reject'),
        headers: ApiService.headers(),
        body: jsonEncode({'rejection_reason': rejectionReason}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur lors du rejet: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Fermer une demande de recrutement
  Future<Map<String, dynamic>> closeRecruitmentRequest(int id) async {
    try {
      final response = await HttpInterceptor.post(
        Uri.parse('$baseUrl/recruitment-requests/$id/close'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur lors de la fermeture: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Annuler une demande de recrutement
  Future<Map<String, dynamic>> cancelRecruitmentRequest(int id) async {
    try {
      final response = await HttpInterceptor.post(
        Uri.parse('$baseUrl/recruitment-requests/$id/cancel'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur lors de l\'annulation: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Mettre à jour une demande de recrutement
  Future<Map<String, dynamic>> updateRecruitmentRequest({
    required int id,
    String? title,
    String? department,
    String? position,
    String? description,
    String? requirements,
    String? responsibilities,
    int? numberOfPositions,
    String? employmentType,
    String? experienceLevel,
    String? salaryRange,
    String? location,
    DateTime? applicationDeadline,
  }) async {
    try {
      Map<String, dynamic> body = {};

      if (title != null) body['title'] = title;
      if (department != null) body['department'] = department;
      if (position != null) body['position'] = position;
      if (description != null) body['description'] = description;
      if (requirements != null) body['requirements'] = requirements;
      if (responsibilities != null) body['responsibilities'] = responsibilities;
      if (numberOfPositions != null)
        body['number_of_positions'] = numberOfPositions;
      if (employmentType != null) body['employment_type'] = employmentType;
      if (experienceLevel != null) body['experience_level'] = experienceLevel;
      if (salaryRange != null) body['salary_range'] = salaryRange;
      if (location != null) body['location'] = location;
      if (applicationDeadline != null)
        body['application_deadline'] = applicationDeadline.toIso8601String();

      final response = await HttpInterceptor.put(
        Uri.parse('$baseUrl/recruitment-requests/$id'),
        headers: ApiService.headers(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la mise à jour: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Supprimer une demande de recrutement
  Future<Map<String, dynamic>> deleteRecruitmentRequest(int id) async {
    try {
      final response = await HttpInterceptor.delete(
        Uri.parse('$baseUrl/recruitment-requests/$id'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la suppression: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer les candidatures d'une demande
  Future<List<RecruitmentApplication>> getApplications({
    required int recruitmentRequestId,
    String? status,
  }) async {
    try {
      String url =
          '$baseUrl/recruitment-requests/$recruitmentRequestId/applications';

      if (status != null) {
        url += '?status=$status';
      }

      final response = await HttpInterceptor.get(
        Uri.parse(url),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as List)
            .map((json) => RecruitmentApplication.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'Erreur lors de la récupération des candidatures: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer une candidature par ID
  Future<RecruitmentApplication> getApplication(int id) async {
    try {
      final response = await HttpInterceptor.get(
        Uri.parse('$baseUrl/recruitment-applications/$id'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return RecruitmentApplication.fromJson(data['data']);
      } else {
        throw Exception(
          'Erreur lors de la récupération de la candidature: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Mettre à jour le statut d'une candidature
  Future<Map<String, dynamic>> updateApplicationStatus({
    required int id,
    required String status,
    String? notes,
    String? rejectionReason,
  }) async {
    try {
      final response = await HttpInterceptor.put(
        Uri.parse('$baseUrl/recruitment-applications/$id/status'),
        headers: ApiService.headers(),
        body: jsonEncode({
          'status': status,
          'notes': notes,
          'rejection_reason': rejectionReason,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la mise à jour du statut: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Programmer un entretien
  Future<Map<String, dynamic>> scheduleInterview({
    required int applicationId,
    required DateTime scheduledAt,
    required String location,
    required String type,
    String? meetingLink,
    String? notes,
    int? interviewerId,
  }) async {
    try {
      final response = await HttpInterceptor.post(
        Uri.parse('$baseUrl/recruitment-interviews'),
        headers: ApiService.headers(),
        body: jsonEncode({
          'application_id': applicationId,
          'scheduled_at': scheduledAt.toIso8601String(),
          'location': location,
          'type': type,
          'meeting_link': meetingLink,
          'notes': notes,
          'interviewer_id': interviewerId,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la programmation de l\'entretien: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer les entretiens
  Future<List<RecruitmentInterview>> getInterviews({
    int? applicationId,
    String? status,
  }) async {
    try {
      String url = '$baseUrl/recruitment-interviews';
      List<String> params = [];

      if (applicationId != null) {
        params.add('application_id=$applicationId');
      }
      if (status != null) {
        params.add('status=$status');
      }

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await HttpInterceptor.get(
        Uri.parse(url),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as List)
            .map((json) => RecruitmentInterview.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'Erreur lors de la récupération des entretiens: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer les statistiques de recrutement
  Future<RecruitmentStats> getRecruitmentStats({
    DateTime? startDate,
    DateTime? endDate,
    String? department,
  }) async {
    try {
      String url = '$baseUrl/recruitment-statistics';
      List<String> params = [];

      if (startDate != null) {
        params.add('start_date=${startDate.toIso8601String()}');
      }
      if (endDate != null) {
        params.add('end_date=${endDate.toIso8601String()}');
      }
      if (department != null) {
        params.add('department=$department');
      }

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await HttpInterceptor.get(
        Uri.parse(url),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return RecruitmentStats.fromJson(data['data']);
      } else {
        throw Exception(
          'Erreur lors de la récupération des statistiques: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer les départements disponibles
  Future<List<String>> getDepartments() async {
    try {
      final response = await HttpInterceptor.get(
        Uri.parse('$baseUrl/recruitment-departments'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final apiDepartments = List<String>.from(data['data'] ?? []);

        // Liste des départements par défaut
        final defaultDepartments = [
          'Ressources Humaines',
          'Commercial',
          'Comptabilité',
          'Informatique',
          'Technique',
          'Technicien',
          'Support',
          'Direction',
          'Administration',
        ];

        // Fusionner les départements de l'API avec les départements par défaut
        final allDepartments = <String>{};
        allDepartments.addAll(apiDepartments);
        allDepartments.addAll(defaultDepartments);

        // Retourner une liste triée et sans doublons
        return allDepartments.toList()..sort();
      }
      // Retourner des départements par défaut si le backend ne retourne rien
      return [
        'Ressources Humaines',
        'Commercial',
        'Comptabilité',
        'Informatique',
        'Technique',
        'Technicien',
        'Support',
        'Direction',
        'Administration',
      ];
    } catch (e) {
      // Retourner des départements par défaut en cas d'erreur
      return [
        'Ressources Humaines',
        'Commercial',
        'Comptabilité',
        'Informatique',
        'Technique',
        'Technicien',
        'Support',
        'Direction',
        'Administration',
      ];
    }
  }

  // Récupérer les postes disponibles
  Future<List<String>> getPositions() async {
    try {
      final response = await HttpInterceptor.get(
        Uri.parse('$baseUrl/recruitment-positions'),
        headers: ApiService.headers(),
      );

      // Liste des postes par défaut
      final defaultPositions = [
        'Développeur',
        'Développeur Web',
        'Développeur Mobile',
        'Chef de projet',
        'Chef de projet IT',
        'Comptable',
        'Comptable Général',
        'Commercial',
        'Commercial B2B',
        'Technicien',
        'Technicien Informatique',
        'Technicien Réseau',
        'Technicien Maintenance',
        'Informaticien',
        'Administrateur Système',
        'Assistant RH',
        'Manager',
        'Manager Commercial',
        'Manager Technique',
        'Responsable Comptabilité',
      ];

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final apiPositions = List<String>.from(data['data'] ?? []);

        // Fusionner les postes de l'API avec les postes par défaut
        final allPositions = <String>{};
        allPositions.addAll(apiPositions);
        allPositions.addAll(defaultPositions);

        // Retourner une liste triée et sans doublons
        return allPositions.toList()..sort();
      } else {
        // Retourner des postes par défaut en cas d'erreur
        return [
          'Développeur',
          'Développeur Web',
          'Développeur Mobile',
          'Chef de projet',
          'Chef de projet IT',
          'Comptable',
          'Comptable Général',
          'Commercial',
          'Commercial B2B',
          'Technicien',
          'Technicien Informatique',
          'Technicien Réseau',
          'Technicien Maintenance',
          'Informaticien',
          'Administrateur Système',
          'Assistant RH',
          'Manager',
          'Manager Commercial',
          'Manager Technique',
          'Responsable Comptabilité',
        ];
      }
    } catch (e) {
      return [
        'Développeur',
        'Développeur Web',
        'Développeur Mobile',
        'Chef de projet',
        'Chef de projet IT',
        'Comptable',
        'Comptable Général',
        'Commercial',
        'Commercial B2B',
        'Technicien',
        'Technicien Informatique',
        'Technicien Réseau',
        'Technicien Maintenance',
        'Informaticien',
        'Administrateur Système',
        'Assistant RH',
        'Manager',
        'Manager Commercial',
        'Manager Technique',
        'Responsable Comptabilité',
      ];
    }
  }

  static void _saveRecruitmentsToHive(List<RecruitmentRequest> list) {
    try {
      HiveStorageService.saveEntityList(
        HiveStorageService.keyRecruitments,
        list.map((e) => e.toJson()).toList(),
      );
    } catch (_) {}
  }

  /// Cache Hive : liste des demandes de recrutement pour affichage instantané.
  static List<RecruitmentRequest> getCachedRecruitments() {
    try {
      final raw = HiveStorageService.getEntityList(HiveStorageService.keyRecruitments);
      return raw.map((e) => RecruitmentRequest.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }
}

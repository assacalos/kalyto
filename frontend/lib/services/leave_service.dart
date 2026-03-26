import 'dart:convert';
import 'package:easyconnect/services/http_interceptor.dart';
import 'package:easyconnect/Models/leave_model.dart';
import 'package:easyconnect/Models/pagination_response.dart';
import 'package:easyconnect/services/api_service.dart';
import 'package:easyconnect/utils/constant.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/utils/auth_error_handler.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/retry_helper.dart';
import 'package:easyconnect/utils/pagination_helper.dart';
import 'package:easyconnect/services/storage_service.dart';

class LeaveService {
  static final LeaveService _instance = LeaveService._();
  static LeaveService get to => _instance;
  factory LeaveService() => _instance;
  LeaveService._();

  // Créer une demande de congé
  Future<Map<String, dynamic>> createLeaveRequest({
    required int employeeId,
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    String? comments,
    List<String>? attachmentPaths,
  }) async {
    try {
      final response = await HttpInterceptor.post(
        HttpInterceptor.apiUri('leave-requests'),
        headers: ApiService.headers(),
        body: jsonEncode({
          'employee_id': employeeId,
          'leave_type': leaveType,
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
          'reason': reason,
          'comments': comments,
          'attachment_paths': attachmentPaths ?? [],
        }),
      ).timeout(
        AppConfig.defaultTimeout,
        onTimeout: () =>
            throw Exception('Timeout: le serveur ne répond pas'),
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

  // Récupérer les demandes de congé d'un employé
  Future<List<LeaveRequest>> getEmployeeLeaveRequests({
    required int employeeId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    try {
      String url = '$baseUrl/leave-requests/employee/$employeeId';
      List<String> params = [];

      if (startDate != null) {
        params.add('start_date=${startDate.toIso8601String()}');
      }
      if (endDate != null) {
        params.add('end_date=${endDate.toIso8601String()}');
      }
      if (status != null) {
        params.add('status=$status');
      }

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await HttpInterceptor.get(Uri.parse(url)).timeout(
        AppConfig.defaultTimeout,
        onTimeout: () =>
            throw Exception('Timeout: le serveur ne répond pas'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as List)
            .map((json) => LeaveRequest.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'Erreur lors de la récupération des demandes: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Récupérer les demandes de congé avec pagination côté serveur
  Future<PaginationResponse<LeaveRequest>> getLeaveRequestsPaginated({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? leaveType,
    int? employeeId,
    int page = 1,
    int perPage = 15,
    String? search,
  }) async {
    try {
      String url = '${AppConfig.baseUrl}/leave-requests';
      List<String> params = [];

      if (startDate != null) {
        params.add('start_date=${startDate.toIso8601String()}');
      }
      if (endDate != null) {
        params.add('end_date=${endDate.toIso8601String()}');
      }
      if (status != null) {
        params.add('status=$status');
      }
      if (leaveType != null) {
        params.add('leave_type=$leaveType');
      }
      if (employeeId != null) {
        params.add('employee_id=$employeeId');
      }
      if (search != null && search.isNotEmpty) {
        params.add('search=$search');
      }
      // Ajouter la pagination
      params.add('page=$page');
      params.add('per_page=$perPage');

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      AppLogger.httpRequest('GET', url, tag: 'LEAVE_SERVICE');

      final response = await RetryHelper.retryNetwork(
        operation: () => HttpInterceptor.get(Uri.parse(url)),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(response.statusCode, url, tag: 'LEAVE_SERVICE');
      await AuthErrorHandler.handleHttpResponse(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final result = PaginationHelper.parseResponse<LeaveRequest>(
          json: data,
          fromJsonT: (json) => LeaveRequest.fromJson(json),
        );
        if (page == 1 && result.data.isNotEmpty) {
          _saveLeavesToHive(result.data);
        }
        return result;
      } else {
        throw Exception(
          'Erreur lors de la récupération paginée des demandes de congé: ${response.statusCode}',
        );
      }
    } catch (e) {
      AppLogger.error(
        'Erreur dans getLeaveRequestsPaginated: $e',
        tag: 'LEAVE_SERVICE',
      );
      rethrow;
    }
  }

  // Récupérer toutes les demandes de congé (pour RH et Patron)
  Future<List<LeaveRequest>> getAllLeaveRequests({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? leaveType,
    int? employeeId,
  }) async {
    try {
      String url = '$baseUrl/leave-requests';
      List<String> params = [];

      if (startDate != null) {
        params.add('start_date=${startDate.toIso8601String()}');
      }
      if (endDate != null) {
        params.add('end_date=${endDate.toIso8601String()}');
      }
      if (status != null) {
        params.add('status=$status');
      }
      if (leaveType != null) {
        params.add('leave_type=$leaveType');
      }
      if (employeeId != null) {
        params.add('employee_id=$employeeId');
      }

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await HttpInterceptor.get(Uri.parse(url)).timeout(
        AppConfig.defaultTimeout,
        onTimeout: () =>
            throw Exception('Timeout: le serveur ne répond pas'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['data'] as List)
            .map((json) => LeaveRequest.fromJson(json))
            .toList();
        _saveLeavesToHive(list);
        return list;
      } else {
        throw Exception(
          'Erreur lors de la récupération des demandes: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer une demande de congé par ID
  Future<LeaveRequest> getLeaveRequest(int id) async {
    try {
      final response = await HttpInterceptor.get(
        HttpInterceptor.apiUri('leave-requests/$id'),
      ).timeout(
        AppConfig.defaultTimeout,
        onTimeout: () =>
            throw Exception('Timeout: le serveur ne répond pas'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return LeaveRequest.fromJson(data['data']);
      } else {
        throw Exception(
          'Erreur lors de la récupération de la demande: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Approuver une demande de congé
  Future<Map<String, dynamic>> approveLeaveRequest(
    int id, {
    String? comments,
  }) async {
    try {
      final response = await HttpInterceptor.put(
        Uri.parse('$baseUrl/leave-requests/$id/approve'),
        headers: ApiService.headers(),
        body: jsonEncode({'comments': comments}),
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

  // Rejeter une demande de congé
  Future<Map<String, dynamic>> rejectLeaveRequest(
    int id, {
    required String rejectionReason,
  }) async {
    try {
      final response = await HttpInterceptor.put(
        Uri.parse('$baseUrl/leave-requests/$id/reject'),
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

  // Annuler une demande de congé
  Future<Map<String, dynamic>> cancelLeaveRequest(int id) async {
    try {
      final response = await HttpInterceptor.put(
        Uri.parse('$baseUrl/leave-requests/$id/cancel'),
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

  // Mettre à jour une demande de congé
  Future<Map<String, dynamic>> updateLeaveRequest({
    required int id,
    String? leaveType,
    DateTime? startDate,
    DateTime? endDate,
    String? reason,
    String? comments,
  }) async {
    try {
      Map<String, dynamic> body = {};

      if (leaveType != null) body['leave_type'] = leaveType;
      if (startDate != null) body['start_date'] = startDate.toIso8601String();
      if (endDate != null) body['end_date'] = endDate.toIso8601String();
      if (reason != null) body['reason'] = reason;
      if (comments != null) body['comments'] = comments;

      final response = await HttpInterceptor.put(
        Uri.parse('$baseUrl/leave-requests/$id'),
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

  // Supprimer une demande de congé
  Future<Map<String, dynamic>> deleteLeaveRequest(int id) async {
    try {
      final response = await HttpInterceptor.delete(
        Uri.parse('$baseUrl/leave-requests/$id'),
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

  // Récupérer le solde de congés d'un employé
  Future<LeaveBalance> getEmployeeLeaveBalance(int employeeId) async {
    try {
      final response = await HttpInterceptor.get(
        Uri.parse('$baseUrl/leave-balance/$employeeId'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return LeaveBalance.fromJson(data['data']);
      } else {
        throw Exception(
          'Erreur lors de la récupération du solde: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer les statistiques des congés
  Future<LeaveStats> getLeaveStats({
    DateTime? startDate,
    DateTime? endDate,
    int? employeeId,
  }) async {
    try {
      String url = '$baseUrl/leave-stats';
      List<String> params = [];

      if (startDate != null) {
        params.add('start_date=${startDate.toIso8601String()}');
      }
      if (endDate != null) {
        params.add('end_date=${endDate.toIso8601String()}');
      }
      if (employeeId != null) {
        params.add('employee_id=$employeeId');
      }

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await HttpInterceptor.get(Uri.parse(url)).timeout(
        AppConfig.defaultTimeout,
        onTimeout: () =>
            throw Exception('Timeout: le serveur ne répond pas'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return LeaveStats.fromJson(data['data']);
      } else {
        throw Exception(
          'Erreur lors de la récupération des statistiques: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer les types de congés disponibles
  Future<List<LeaveType>> getLeaveTypes() async {
    try {
      final response = await HttpInterceptor.get(
        HttpInterceptor.apiUri('leave-types'),
      ).timeout(
        AppConfig.defaultTimeout,
        onTimeout: () =>
            throw Exception('Timeout: le serveur ne répond pas'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as List)
            .map(
              (json) => LeaveType(
                value: json['value'],
                label: json['label'],
                description: json['description'],
                requiresApproval: json['requires_approval'],
                maxDays: json['max_days'],
                isPaid: json['is_paid'],
              ),
            )
            .toList();
      } else {
        // Retourner les types par défaut en cas d'erreur
        return LeaveType.leaveTypes;
      }
    } catch (e) {
      return LeaveType.leaveTypes;
    }
  }

  // Vérifier les conflits de congés
  Future<Map<String, dynamic>> checkLeaveConflicts({
    required int employeeId,
    required DateTime startDate,
    required DateTime endDate,
    int? excludeRequestId,
  }) async {
    try {
      final response = await HttpInterceptor.post(
        Uri.parse('$baseUrl/leave-requests/check-conflicts'),
        headers: ApiService.headers(),
        body: jsonEncode({
          'employee_id': employeeId,
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
          'exclude_request_id': excludeRequestId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la vérification des conflits: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Télécharger un justificatif
  Future<String> downloadAttachment(int attachmentId) async {
    try {
      final response = await HttpInterceptor.get(
        Uri.parse('$baseUrl/leave-attachments/$attachmentId/download'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['download_url'];
      } else {
        throw Exception(
          'Erreur lors du téléchargement: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  static void _saveLeavesToHive(List<LeaveRequest> list) {
    try {
      HiveStorageService.saveEntityList(
        HiveStorageService.keyLeaves,
        list.map((e) => e.toJson()).toList(),
      );
    } catch (_) {}
  }

  /// Cache Hive : liste des demandes de congé pour affichage instantané.
  static List<LeaveRequest> getCachedLeaves() {
    try {
      final raw = HiveStorageService.getEntityList(HiveStorageService.keyLeaves);
      return raw.map((e) => LeaveRequest.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }
}

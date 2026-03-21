import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:easyconnect/services/http_interceptor.dart';
import 'package:easyconnect/Models/employee_model.dart';
import 'package:easyconnect/Models/pagination_response.dart';
import 'package:easyconnect/services/api_service.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/utils/auth_error_handler.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/retry_helper.dart';
import 'package:easyconnect/services/storage_service.dart';
import 'package:easyconnect/utils/pagination_helper.dart';

class EmployeeService {
  static final EmployeeService _instance = EmployeeService._();
  static EmployeeService get to => _instance;
  factory EmployeeService() => _instance;
  EmployeeService._();

  /// Récupérer les employés avec pagination côté serveur
  ///
  /// Le backend Laravel doit retourner une réponse paginée au format :
  /// {
  ///   "success": true,
  ///   "data": {
  ///     "data": [...],
  ///     "current_page": 1,
  ///     "last_page": 5,
  ///     "per_page": 15,
  ///     "total": 100,
  ///     ...
  ///   }
  /// }
  Future<PaginationResponse<Employee>> getEmployeesPaginated({
    String? search,
    String? department,
    String? position,
    String? status,
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (department != null && department.isNotEmpty) queryParams['department'] = department;
      if (position != null && position.isNotEmpty) queryParams['position'] = position;
      if (status != null && status.isNotEmpty) queryParams['status'] = status;

      final uri = Uri.parse('${AppConfig.baseUrl}/employees').replace(
        queryParameters: queryParams,
      );
      AppLogger.httpRequest('GET', uri.toString(), tag: 'EMPLOYEE_SERVICE');

      final response = await RetryHelper.retryNetwork(
        operation: () => http
            .get(uri, headers: ApiService.headers())
            .timeout(
              AppConfig.extraLongTimeout,
              onTimeout: () =>
                  throw Exception('Timeout: le serveur ne répond pas'),
            ),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(response.statusCode, uri.toString(), tag: 'EMPLOYEE_SERVICE');
      await AuthErrorHandler.handleHttpResponse(response);

      if (response.statusCode == 200) {
        Map<String, dynamic> data;
        try {
          data = jsonDecode(response.body) as Map<String, dynamic>;
        } on FormatException catch (e) {
          if (perPage > 5) {
            AppLogger.warning(
              'Réponse JSON tronquée, nouvel essai avec per_page=5: $e',
              tag: 'EMPLOYEE_SERVICE',
            );
            return getEmployeesPaginated(
              search: search,
              department: department,
              position: position,
              status: status,
              page: page,
              perPage: 5,
            );
          }
          rethrow;
        }

        final result = PaginationHelper.parseResponseSafe<Employee>(
          json: data,
          fromJsonT: (json) {
            try {
              return Employee.fromJson(json);
            } catch (_) {
              return null;
            }
          },
        );
        if (page == 1 && result.data.isNotEmpty) {
          _saveEmployeesToHive(result.data);
        }
        return result;
      } else {
        throw Exception(
          'Erreur lors de la récupération des employés: ${response.statusCode}',
        );
      }
    } catch (e) {
      AppLogger.error(
        'Erreur lors de la récupération paginée des employés: $e',
        tag: 'EMPLOYEE_SERVICE',
        error: e,
      );
      rethrow;
    }
  }

  /// Récupère la première page (délégation vers getEmployeesPaginated pour compatibilité).
  Future<List<Employee>> getEmployees({
    String? search,
    String? department,
    String? position,
    String? status,
    int? page,
    int? limit,
  }) async {
    final effectiveLimit = limit ?? 500;
    final effectivePage = page ?? 1;
    final res = await getEmployeesPaginated(
      search: search,
      department: department,
      position: position,
      status: status,
      page: effectivePage,
      perPage: effectiveLimit,
    );
    if (res.data.isNotEmpty && (search == null || search.isEmpty)) {
      _saveEmployeesToHive(res.data);
    }
    return res.data;
  }

  // Récupérer un employé par ID
  Future<Employee> getEmployee(int id) async {
    try {
      final response = await HttpInterceptor.get(
        Uri.parse('${AppConfig.baseUrl}/employees/$id'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Employee.fromJson(data['data']);
      } else {
        throw Exception(
          'Erreur lors de la récupération de l\'employé: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Créer un nouvel employé
  Future<Map<String, dynamic>> createEmployee({
    required String firstName,
    required String lastName,
    required String email,
    String? phone,
    String? address,
    DateTime? birthDate,
    String? gender,
    String? maritalStatus,
    String? nationality,
    String? idNumber,
    String? socialSecurityNumber,
    String? position,
    String? department,
    String? manager,
    DateTime? hireDate,
    DateTime? contractStartDate,
    DateTime? contractEndDate,
    String? contractType,
    double? salary,
    String? currency,
    String? workSchedule,
    String? profilePicture,
    String? notes,
  }) async {
    try {
      final url = '${AppConfig.baseUrl}/employees';
      AppLogger.httpRequest('POST', url, tag: 'EMPLOYEE_SERVICE');

      // Préparer les données en filtrant les valeurs null
      final employeeData = <String, dynamic>{
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
      };

      // Ajouter les champs optionnels seulement s'ils ne sont pas null
      if (phone != null && phone.isNotEmpty) employeeData['phone'] = phone;
      if (address != null && address.isNotEmpty)
        employeeData['address'] = address;
      if (birthDate != null) {
        employeeData['birth_date'] =
            birthDate.toIso8601String().split('T')[0]; // Format YYYY-MM-DD
      }
      if (gender != null && gender.isNotEmpty) employeeData['gender'] = gender;
      if (maritalStatus != null && maritalStatus.isNotEmpty) {
        employeeData['marital_status'] = maritalStatus;
      }
      if (nationality != null && nationality.isNotEmpty) {
        employeeData['nationality'] = nationality;
      }
      if (idNumber != null && idNumber.isNotEmpty) {
        employeeData['id_number'] = idNumber;
      }
      if (socialSecurityNumber != null && socialSecurityNumber.isNotEmpty) {
        employeeData['social_security_number'] = socialSecurityNumber;
      }
      if (position != null && position.isNotEmpty)
        employeeData['position'] = position;
      if (department != null && department.isNotEmpty) {
        employeeData['department'] = department;
      }
      if (manager != null && manager.isNotEmpty)
        employeeData['manager'] = manager;
      if (hireDate != null) {
        employeeData['hire_date'] =
            hireDate.toIso8601String().split('T')[0]; // Format YYYY-MM-DD
      }
      if (contractStartDate != null) {
        employeeData['contract_start_date'] =
            contractStartDate.toIso8601String().split('T')[0];
      }
      if (contractEndDate != null) {
        employeeData['contract_end_date'] =
            contractEndDate.toIso8601String().split('T')[0];
      }
      if (contractType != null && contractType.isNotEmpty) {
        employeeData['contract_type'] = contractType;
      }
      if (salary != null && salary > 0) employeeData['salary'] = salary;
      if (currency != null && currency.isNotEmpty)
        employeeData['currency'] = currency;
      if (workSchedule != null && workSchedule.isNotEmpty) {
        employeeData['work_schedule'] = workSchedule;
      }
      if (profilePicture != null && profilePicture.isNotEmpty) {
        employeeData['profile_picture'] = profilePicture;
      }
      if (notes != null && notes.isNotEmpty) employeeData['notes'] = notes;

      AppLogger.debug(
        'Données envoyées: ${jsonEncode(employeeData)}',
        tag: 'EMPLOYEE_SERVICE',
      );

      final response = await RetryHelper.retryNetwork(
        operation:
            () => HttpInterceptor.post(
              Uri.parse(url),
              headers: ApiService.headers(),
              body: jsonEncode(employeeData),
            ),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(response.statusCode, url, tag: 'EMPLOYEE_SERVICE');

      // Logger le body de la réponse pour le débogage
      AppLogger.debug(
        'Réponse du backend (${response.statusCode}): ${response.body}',
        tag: 'EMPLOYEE_SERVICE',
      );

      await AuthErrorHandler.handleHttpResponse(response);

      if (response.statusCode == 201 || response.statusCode == 200) {
        AppLogger.info('Employé créé avec succès', tag: 'EMPLOYEE_SERVICE');
        return jsonDecode(response.body);
      } else {
        // Extraire le message d'erreur détaillé du backend
        String errorMessage =
            'Erreur lors de la création de l\'employé: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          } else if (errorData['errors'] != null) {
            // Si c'est une erreur de validation Laravel
            final errors = errorData['errors'] as Map<String, dynamic>;
            final errorList = errors.values.expand((e) => e as List).join(', ');
            errorMessage = 'Erreurs de validation: $errorList';
          } else {
            // Si pas de message structuré, utiliser le body complet
            errorMessage = 'Erreur ${response.statusCode}: ${response.body}';
          }
          AppLogger.error(
            'Erreur backend: $errorMessage',
            tag: 'EMPLOYEE_SERVICE',
          );
        } catch (e) {
          AppLogger.error(
            'Erreur lors du parsing de la réponse: ${response.body}',
            tag: 'EMPLOYEE_SERVICE',
            error: e,
          );
          // Si le parsing échoue, utiliser le body brut
          errorMessage = 'Erreur ${response.statusCode}: ${response.body}';
        }
        throw Exception(errorMessage);
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erreur lors de la création de l\'employé: $e',
        tag: 'EMPLOYEE_SERVICE',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Mettre à jour un employé
  Future<Map<String, dynamic>> updateEmployee({
    required int id,
    required String firstName,
    required String lastName,
    required String email,
    String? phone,
    String? address,
    DateTime? birthDate,
    String? gender,
    String? maritalStatus,
    String? nationality,
    String? idNumber,
    String? socialSecurityNumber,
    String? position,
    String? department,
    String? manager,
    DateTime? hireDate,
    DateTime? contractStartDate,
    DateTime? contractEndDate,
    String? contractType,
    double? salary,
    String? currency,
    String? workSchedule,
    String? status,
    String? profilePicture,
    String? notes,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('${AppConfig.baseUrl}/employees/$id'),
            headers: ApiService.headers(),
            body: jsonEncode({
              'first_name': firstName,
              'last_name': lastName,
              'email': email,
              'phone': phone,
              'address': address,
              'birth_date': birthDate?.toIso8601String(),
              'gender': gender,
              'marital_status': maritalStatus,
              'nationality': nationality,
              'id_number': idNumber,
              'social_security_number': socialSecurityNumber,
              'position': position,
              'department': department,
              'manager': manager,
              'hire_date': hireDate?.toIso8601String(),
              'contract_start_date': contractStartDate?.toIso8601String(),
              'contract_end_date': contractEndDate?.toIso8601String(),
              'contract_type': contractType,
              'salary': salary,
              'currency': currency,
              'work_schedule': workSchedule,
              'status': status,
              'profile_picture': profilePicture,
              'notes': notes,
            }),
          )
          .timeout(
            AppConfig.defaultTimeout,
            onTimeout: () =>
                throw Exception('Timeout: le serveur ne répond pas'),
          );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la mise à jour de l\'employé: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Supprimer un employé
  Future<Map<String, dynamic>> deleteEmployee(int id) async {
    try {
      final response = await HttpInterceptor.delete(
        Uri.parse('${AppConfig.baseUrl}/employees/$id'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la suppression de l\'employé: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Soumettre un employé pour approbation
  Future<Map<String, dynamic>> submitEmployeeForApproval(int id) async {
    try {
      final response = await HttpInterceptor.post(
        Uri.parse('${AppConfig.baseUrl}/employees/$id/submit'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur lors de la soumission: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Approuver un employé (pour le patron)
  Future<Map<String, dynamic>> approveEmployee(
    int id, {
    String? comments,
  }) async {
    try {
      final response = await HttpInterceptor.post(
        Uri.parse('${AppConfig.baseUrl}/employees/$id/approve'),
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

  // Rejeter un employé (pour le patron)
  Future<Map<String, dynamic>> rejectEmployee(
    int id, {
    required String reason,
  }) async {
    try {
      final response = await HttpInterceptor.post(
        Uri.parse('${AppConfig.baseUrl}/employees/$id/reject'),
        headers: ApiService.headers(),
        body: jsonEncode({'reason': reason}),
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

  // Récupérer les statistiques des employés
  Future<EmployeeStats> getEmployeeStats() async {
    try {
      final response = await HttpInterceptor.get(
        Uri.parse('${AppConfig.baseUrl}/employees/stats'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return EmployeeStats.fromJson(data['data']);
      } else {
        throw Exception(
          'Erreur lors de la récupération des statistiques: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer les départements
  Future<List<String>> getDepartments() async {
    try {
      final response = await HttpInterceptor.get(
        Uri.parse('${AppConfig.baseUrl}/employees/departments'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final departments = List<String>.from(data['data'] ?? []);
        // S'assurer que "Ressources Humaines" est toujours dans la liste
        if (departments.isNotEmpty) {
          if (!departments.contains('Ressources Humaines')) {
            departments.add('Ressources Humaines');
          }
          return departments;
        }
      }
      // Retourner des départements par défaut si le backend ne retourne rien
      return [
        'Ressources Humaines',
        'Commercial',
        'Comptabilité',
        'Technique',
        'Support',
        'Direction',
      ];
    } catch (e) {
      // Retourner des départements par défaut en cas d'erreur
      return [
        'Ressources Humaines',
        'Commercial',
        'Comptabilité',
        'Technique',
        'Support',
        'Direction',
      ];
    }
  }

  // Récupérer les postes
  Future<List<String>> getPositions() async {
    try {
      final response = await HttpInterceptor.get(
        Uri.parse('${AppConfig.baseUrl}/employees/positions'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['data']);
      } else {
        throw Exception(
          'Erreur lors de la récupération des postes: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Gestion des documents d'employé
  Future<Map<String, dynamic>> addEmployeeDocument({
    required int employeeId,
    required String name,
    required String type,
    String? description,
    String? filePath,
    DateTime? expiryDate,
    bool isRequired = false,
  }) async {
    try {
      final response = await HttpInterceptor.post(
        Uri.parse('${AppConfig.baseUrl}/employees/$employeeId/documents'),
        headers: ApiService.headers(),
        body: jsonEncode({
          'name': name,
          'type': type,
          'description': description,
          'file_path': filePath,
          'expiry_date': expiryDate?.toIso8601String(),
          'is_required': isRequired,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de l\'ajout du document: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Gestion des congés d'employé
  Future<Map<String, dynamic>> addEmployeeLeave({
    required int employeeId,
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
  }) async {
    try {
      final response = await HttpInterceptor.post(
        Uri.parse('${AppConfig.baseUrl}/employees/$employeeId/leaves'),
        headers: ApiService.headers(),
        body: jsonEncode({
          'type': type,
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
          'reason': reason,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de l\'ajout du congé: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Approuver un congé
  Future<Map<String, dynamic>> approveLeave(
    int leaveId, {
    String? comments,
  }) async {
    try {
      final response = await HttpInterceptor.post(
        Uri.parse('${AppConfig.baseUrl}/leaves/$leaveId/approve'),
        headers: ApiService.headers(),
        body: jsonEncode({'comments': comments}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de l\'approbation du congé: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Rejeter un congé
  Future<Map<String, dynamic>> rejectLeave(
    int leaveId, {
    required String reason,
  }) async {
    try {
      final response = await HttpInterceptor.post(
        Uri.parse('${AppConfig.baseUrl}/leaves/$leaveId/reject'),
        headers: ApiService.headers(),
        body: jsonEncode({'reason': reason}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors du rejet du congé: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Gestion des performances
  Future<Map<String, dynamic>> addEmployeePerformance({
    required int employeeId,
    required String period,
    required double rating,
    String? comments,
    String? goals,
    String? achievements,
    String? areasForImprovement,
  }) async {
    try {
      final response = await HttpInterceptor.post(
        Uri.parse('${AppConfig.baseUrl}/employees/$employeeId/performances'),
        headers: ApiService.headers(),
        body: jsonEncode({
          'period': period,
          'rating': rating,
          'comments': comments,
          'goals': goals,
          'achievements': achievements,
          'areas_for_improvement': areasForImprovement,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de l\'ajout de la performance: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Rechercher des employés
  Future<List<Employee>> searchEmployees(String query) async {
    try {
      final response = await HttpInterceptor.get(
        Uri.parse('${AppConfig.baseUrl}/employees/search?q=$query'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as List)
            .map((json) => Employee.fromJson(json))
            .toList();
      } else {
        throw Exception('Erreur lors de la recherche: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  static void _saveEmployeesToHive(List<Employee> list) {
    try {
      HiveStorageService.saveEntityList(
        HiveStorageService.keyEmployees,
        list.map((e) => e.toJson()).toList(),
      );
    } catch (_) {}
  }

  /// Persiste la liste en cache Hive (appelé après création ou refresh API).
  static void saveCachedEmployees(List<Employee> list) {
    _saveEmployeesToHive(list);
  }

  /// Cache Hive : liste des employés pour affichage instantané.
  static List<Employee> getCachedEmployees() {
    try {
      final raw = HiveStorageService.getEntityList(HiveStorageService.keyEmployees);
      return raw.map((e) => Employee.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }
}

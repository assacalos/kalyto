import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:easyconnect/services/http_interceptor.dart';
import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/Models/salary_model.dart';
import 'package:easyconnect/Models/pagination_response.dart';
import 'package:easyconnect/utils/constant.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/services/api_service.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/retry_helper.dart';
import 'package:easyconnect/utils/auth_error_handler.dart';
import 'package:easyconnect/utils/pagination_helper.dart';
import 'package:easyconnect/services/storage_service.dart';
import 'package:easyconnect/services/company_service.dart';

class SalaryService {
  final storage = GetStorage();

  // Tester la connectivité à l'API pour les salaires
  Future<bool> testSalaryConnection() async {
    try {
      final token = storage.read('token');

      final response = await http
          .get(
            Uri.parse('$baseUrl/salaries-list'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(AppConfig.extraLongTimeout);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Récupérer les salaires avec pagination côté serveur
  Future<PaginationResponse<Salary>> getSalariesPaginated({
    String? status,
    String? month,
    int? year,
    String? search,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final token = storage.read('token');
      final userRole = storage.read('userRole');
      final userId = storage.read('userId');

      String url = '${AppConfig.baseUrl}/salaries';
      List<String> params = [];

      if (status != null && status.isNotEmpty) {
        params.add('status=$status');
      }
      if (month != null && month.isNotEmpty) {
        params.add('month=$month');
      }
      if (year != null) {
        params.add('year=$year');
      }
      if (search != null && search.isNotEmpty) {
        params.add('search=$search');
      }
      // Filtrer par userId pour les comptables (role 3)
      if (userRole == 3 && userId != null) {
        params.add('user_id=$userId');
      }
      // Ajouter la pagination
      params.add('page=$page');
      params.add('per_page=$perPage');

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      AppLogger.httpRequest('GET', url, tag: 'SALARY_SERVICE');

      final response = await RetryHelper.retryNetwork(
        operation: () => HttpInterceptor.get(
          Uri.parse(url),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(response.statusCode, url, tag: 'SALARY_SERVICE');
      await AuthErrorHandler.handleHttpResponse(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final result = PaginationHelper.parseResponse<Salary>(
          json: data,
          fromJsonT: (json) => Salary.fromJson(json),
        );
        if (page == 1 && result.data.isNotEmpty) {
          _saveSalairesToHive(result.data);
        }
        return result;
      } else {
        throw Exception(
          'Erreur lors de la récupération paginée des salaires: ${response.statusCode}',
        );
      }
    } catch (e) {
      AppLogger.error(
        'Erreur dans getSalariesPaginated: $e',
        tag: 'SALARY_SERVICE',
      );
      rethrow;
    }
  }

  // Récupérer tous les salaires
  Future<List<Salary>> getSalaries({
    String? status,
    String? month,
    int? year,
    String? search,
  }) async {
    try {
      final token = storage.read('token');
      final userRole = storage.read('userRole');
      final userId = storage.read('userId');

      var queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (month != null) queryParams['month'] = month;
      if (year != null) queryParams['year'] = year.toString();
      if (search != null) queryParams['search'] = search;
      // Filtrer par userId pour les comptables (role 3) - seulement leurs propres salaires
      if (userRole == 3 && userId != null) {
        queryParams['user_id'] = userId.toString();
      }
      queryParams.addAll(CompanyService.companyQueryParam());

      final queryString =
          queryParams.isEmpty
              ? ''
              : '?${Uri(queryParameters: queryParams).query}';

      final url = '$baseUrl/salaries-list$queryString';

      final response = await HttpInterceptor.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Si le status code est 200 ou 201, considérer comme succès même si parseResponse dit false
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = jsonDecode(response.body);
          List<dynamic> data = [];

          // Gérer différents formats de réponse de l'API Laravel
          if (responseData is List) {
            data = responseData;
          } else if (responseData is Map) {
            // Essayer d'abord le format standard Laravel
            if (responseData['data'] != null) {
              if (responseData['data'] is List) {
                data = responseData['data'];
              } else if (responseData['data'] is Map && responseData['data']['data'] != null) {
                data = responseData['data']['data'];
              }
            }
            // Essayer le format spécifique aux salaires
            else if (responseData['salaries'] != null) {
              if (responseData['salaries'] is List) {
                data = responseData['salaries'];
              }
            }
          }
          
          if (data.isEmpty) {
            return [];
          }

          try {
            final list = data.map((json) => Salary.fromJson(json)).toList();
            _saveSalairesToHive(list);
            return list;
          } catch (e) {
            throw Exception('Erreur de format des données: $e');
          }
        } catch (e) {
          throw Exception('Erreur de format des données: $e');
        }
      }
      
      // Si le status code n'est pas 200/201, utiliser parseResponse
      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        try {
          final responseData = result['data'];

          // Gérer différents formats de réponse de l'API Laravel
          List<dynamic> data = [];

          // Essayer d'abord le format standard Laravel
          if (responseData is List) {
            data = responseData;
          } else if (responseData is Map) {
            if (responseData['data'] != null) {
              if (responseData['data'] is List) {
                data = responseData['data'];
              } else if (responseData['data']['data'] != null) {
                data = responseData['data']['data'];
              }
            }
            // Essayer le format spécifique aux salaires
            else if (responseData['salaries'] != null) {
              if (responseData['salaries'] is List) {
                data = responseData['salaries'];
              }
            }
          }
          
          if (data.isEmpty) {
            return [];
          }

          try {
            final list = data.map((json) => Salary.fromJson(json)).toList();
            _saveSalairesToHive(list);
            return list;
          } catch (e) {
            rethrow;
          }
        } catch (e) {
          throw Exception('Erreur de format des données: $e');
        }
      } else {
        throw Exception(
          'Erreur lors de la récupération des salaires: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer un salaire par ID
  Future<Salary> getSalaryById(int id) async {
    try {
      final token = storage.read('token');

      final response = await HttpInterceptor.get(
        Uri.parse('$baseUrl/salaries-show/$id'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        return Salary.fromJson(result['data']);
      }

      throw Exception(
        result['message'] ?? 'Erreur lors de la récupération du salaire',
      );
    } catch (e) {
      throw Exception('Erreur lors de la récupération du salaire: $e');
    }
  }

  // Créer un salaire
  Future<Salary> createSalary(Salary salary) async {
    try {
      final token = storage.read('token');

      // Validation des champs requis
      if (salary.employeeId == 0) {
        throw Exception('employeeId est requis');
      }
      if (salary.baseSalary <= 0) {
        throw Exception('baseSalary doit être supérieur à 0');
      }
      if (salary.month == null || salary.month!.isEmpty) {
        throw Exception('month est requis');
      }
      if (salary.year == null || salary.year! < 2000 || salary.year! > 2100) {
        throw Exception('year est requis et doit être entre 2000 et 2100');
      }

      // Formatage du mois selon la documentation API
      // La documentation accepte un entier (1-12) ou une string
      // On envoie un entier pour plus de simplicité
      int monthInt = int.tryParse(salary.month!) ?? 0;
      if (monthInt < 1 || monthInt > 12) {
        throw Exception('Le mois doit être entre 1 et 12');
      }

      // Préparer les données selon la documentation API
      // Le backend génère automatiquement : period, period_start, period_end, salary_date
      // Format snake_case comme recommandé dans la documentation
      final salaryData = {
        'employee_id':
            salary
                .employeeId, // ID de l'employé depuis la table employees (obligatoire)
        'base_salary': salary.baseSalary, // Salaire de base (obligatoire)
        'month': monthInt, // Mois (1-12) - format entier comme recommandé
        'year': salary.year!, // Année (obligatoire)
        // Champs optionnels
        if (salary.netSalary > 0) 'net_salary': salary.netSalary,
        if (salary.bonus > 0) 'bonus': salary.bonus,
        if (salary.deductions > 0) 'deductions': salary.deductions,
        if (salary.notes != null && salary.notes!.isNotEmpty)
          'notes': salary.notes,
        if (salary.justificatifs.isNotEmpty)
          'justificatif':
              salary
                  .justificatifs, // Note: le backend attend 'justificatif' (singulier) comme array
      };
      CompanyService.addCompanyIdToBody(salaryData);
      final response = await HttpInterceptor.post(
        Uri.parse('$baseUrl/salaries-create'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(salaryData),
      );
      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        return Salary.fromJson(result['data']);
      }

      throw Exception(
        result['message'] ?? 'Erreur lors de la création du salaire',
      );
    } catch (e) {
      throw Exception('Erreur lors de la création du salaire: $e');
    }
  }

  // Mettre à jour un salaire
  Future<Salary> updateSalary(Salary salary) async {
    try {
      final token = storage.read('token');

      // Validation des champs requis
      if (salary.id == null) {
        throw Exception('salary.id est requis pour la mise à jour');
      }
      if (salary.employeeId == 0) {
        throw Exception('employeeId est requis');
      }
      if (salary.baseSalary <= 0) {
        throw Exception('baseSalary doit être supérieur à 0');
      }
      if (salary.month == null || salary.month!.isEmpty) {
        throw Exception('month est requis');
      }
      if (salary.year == null || salary.year! < 2000 || salary.year! > 2100) {
        throw Exception('year est requis et doit être entre 2000 et 2100');
      }

      // Formatage du mois selon la documentation API
      // La documentation accepte un entier (1-12) ou une string
      // On envoie un entier pour plus de simplicité
      int monthInt = int.tryParse(salary.month!) ?? 0;
      if (monthInt < 1 || monthInt > 12) {
        throw Exception('Le mois doit être entre 1 et 12');
      }

      // Préparer les données selon la documentation API
      // Le backend génère automatiquement : period, period_start, period_end, salary_date
      // Format snake_case comme recommandé dans la documentation
      final salaryData = {
        'employee_id':
            salary.employeeId, // ID de l'employé depuis la table employees
        'base_salary': salary.baseSalary, // Salaire de base
        'month': monthInt, // Mois (1-12) - format entier comme recommandé
        'year': salary.year!, // Année
        // Champs optionnels
        if (salary.netSalary > 0) 'net_salary': salary.netSalary,
        if (salary.bonus > 0) 'bonus': salary.bonus,
        if (salary.deductions > 0) 'deductions': salary.deductions,
        if (salary.status != null) 'status': salary.status,
        if (salary.notes != null && salary.notes!.isNotEmpty)
          'notes': salary.notes,
        if (salary.justificatifs.isNotEmpty)
          'justificatif':
              salary
                  .justificatifs, // Note: le backend attend 'justificatif' (singulier) comme array
      };
      final response = await HttpInterceptor.put(
        Uri.parse('$baseUrl/salaries-update/${salary.id}'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(salaryData),
      );
      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        return Salary.fromJson(result['data']);
      }

      throw Exception(
        result['message'] ?? 'Erreur lors de la mise à jour du salaire',
      );
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du salaire: $e');
    }
  }

  // Approuver un salaire
  Future<bool> approveSalary(int salaryId, {String? notes}) async {
    try {
      final token = storage.read('token');
      final url = '$baseUrl/salaries-validate/$salaryId';

      final response = await HttpInterceptor.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'notes': notes}),
      );

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        return true;
      }

      throw Exception(
        result['message'] ?? 'Ce salaire ne peut pas être approuvé',
      );
    } catch (e) {
      rethrow; // Propager l'exception au lieu de retourner false
    }
  }

  // Rejeter un salaire
  Future<bool> rejectSalary(int salaryId, {required String reason}) async {
    try {
      final token = storage.read('token');
      final url = '$baseUrl/salaries-reject/$salaryId';

      final response = await HttpInterceptor.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'reason': reason}),
      );

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        return true;
      }

      throw Exception(
        result['message'] ?? 'Ce salaire ne peut pas être rejeté',
      );
    } catch (e) {
      rethrow; // Propager l'exception au lieu de retourner false
    }
  }

  // Marquer comme payé
  Future<bool> markSalaryAsPaid(int salaryId, {String? notes}) async {
    try {
      final token = storage.read('token');

      final response = await HttpInterceptor.post(
        Uri.parse('$baseUrl/salaries/$salaryId/pay'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'notes': notes}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Supprimer un salaire
  Future<bool> deleteSalary(int salaryId) async {
    try {
      final token = storage.read('token');

      final response = await HttpInterceptor.delete(
        Uri.parse('$baseUrl/salaries-delete/$salaryId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Récupérer les statistiques des salaires
  Future<SalaryStats> getSalaryStats() async {
    try {
      final token = storage.read('token');

      final response = await HttpInterceptor.get(
        Uri.parse('$baseUrl/salaries/stats'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        return SalaryStats.fromJson(result['data']);
      }
      throw Exception(
        'Erreur lors de la récupération des statistiques: ${response.statusCode}',
      );
    } catch (e) {
      // Retourner des données de test en cas d'erreur
      return SalaryStats(
        totalSalaries: 0.0,
        pendingSalaries: 0.0,
        approvedSalaries: 0.0,
        paidSalaries: 0.0,
        totalEmployees: 0,
        pendingCount: 0,
        approvedCount: 0,
        paidCount: 0,
        salariesByMonth: {},
        countByMonth: {},
      );
    }
  }

  // Récupérer les salaires en attente
  Future<List<Salary>> getPendingSalaries() async {
    try {
      final token = storage.read('token');
      final response = await HttpInterceptor.get(
        Uri.parse('$baseUrl/salaries-pending'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        final data = result['data'];

        // Gérer le cas où data est une liste ou un objet
        if (data is List) {
          return data.map((json) => Salary.fromJson(json)).toList();
        } else if (data is Map<String, dynamic>) {
          return [Salary.fromJson(data)];
        } else {
          return [];
        }
      }

      // Si l'endpoint n'existe pas (404), utiliser les salaires généraux et filtrer
      if (result['statusCode'] == 404) {
        final allSalaries = await getSalaries();
        final pendingSalaries =
            allSalaries.where((salary) => salary.status == 'pending').toList();
        return pendingSalaries;
      }

      throw Exception(
        'Erreur lors de la récupération des salaires en attente: ${response.statusCode}',
      );
    } catch (e) {
      // En cas d'erreur, retourner une liste vide au lieu de lever une exception
      return [];
    }
  }

  // Récupérer les employés
  Future<List<Map<String, dynamic>>> getEmployees() async {
    try {
      final url = '${AppConfig.baseUrl}/employees-list';
      AppLogger.httpRequest('GET', url, tag: 'SALARY_SERVICE');

      final response = await RetryHelper.retryNetwork(
        operation:
            () => HttpInterceptor.get(Uri.parse(url), headers: ApiService.headers()),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(response.statusCode, url, tag: 'SALARY_SERVICE');
      
      // Parser directement le body au lieu d'utiliser ApiService.parseResponse
      // car parseResponse peut retourner success:false même avec status 200
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final body = json.decode(response.body);
          
          // Gérer les erreurs d'authentification seulement si ce n'est pas un succès
          await AuthErrorHandler.handleHttpResponse(response);
          
          // Extraire les données selon le format de la réponse
          dynamic data;
          if (body is Map) {
            if (body['success'] == true && body['data'] != null) {
              data = body['data'];
            } else if (body['data'] != null) {
              data = body['data'];
            } else {
              // Le body peut être directement la liste
              data = body;
            }
          } else if (body is List) {
            data = body;
          } else {
            return [];
          }

          // Gérer différents formats de réponse
          List<dynamic> dataList = [];

          if (data is List) {
            // Format direct : {"success": true, "data": [...]}
            dataList = data;
          } else if (data != null && data is Map) {
            // Le backend peut retourner soit une liste directe, soit un objet paginé
            if (data['data'] is List) {
              // Format simple : {"success": true, "data": {"data": [...]}}
              dataList = data['data'] as List;
            } else if (data['data'] is Map && data['data']['data'] != null) {
              // Format paginé : {"success": true, "data": {"current_page": 1, "data": [...]}}
              dataList = data['data']['data'] as List;
            } else if (data['employees'] is List) {
              // Format alternatif : {"success": true, "data": {"employees": [...]}}
              dataList = data['employees'] as List;
            } else {
              AppLogger.warning(
                'Format de données inattendu dans la réponse',
                tag: 'SALARY_SERVICE',
              );
              return [];
            }
          } else {
            AppLogger.warning(
              'Aucune donnée dans la réponse',
              tag: 'SALARY_SERVICE',
            );
            return [];
          }

        if (dataList.isEmpty) {
          return [];
        }

        // Transformer les données pour inclure toutes les informations de l'employé
        final employees =
            dataList.map((json) {
              final employee = Map<String, dynamic>.from(json);
              // Construire le nom complet depuis first_name et last_name
              final firstName = employee['first_name'] ?? '';
              final lastName = employee['last_name'] ?? '';
              employee['name'] = '$firstName $lastName'.trim();
              // S'assurer que le salaire est correctement formaté
              if (employee['salary'] != null) {
                final salary = employee['salary'];
                if (salary is String) {
                  employee['salary'] = double.tryParse(salary);
                } else if (salary is num) {
                  employee['salary'] = salary.toDouble();
                }
              }
              return employee;
            }).toList();

          AppLogger.info(
            '${employees.length} employé(s) récupéré(s)',
            tag: 'SALARY_SERVICE',
          );
          return employees;
        } catch (e) {
          // Fallback: essayer avec ApiService.parseResponse
          try {
            final result = ApiService.parseResponse(response);
            if (result['success'] == true && result['data'] != null) {
              final fallbackData = result['data'];
              if (fallbackData is List) {
                final employees = fallbackData.map((json) {
                  final employee = Map<String, dynamic>.from(json);
                  final firstName = employee['first_name'] ?? '';
                  final lastName = employee['last_name'] ?? '';
                  employee['name'] = '$firstName $lastName'.trim();
                  if (employee['salary'] != null) {
                    final salary = employee['salary'];
                    if (salary is String) {
                      employee['salary'] = double.tryParse(salary);
                    } else if (salary is num) {
                      employee['salary'] = salary.toDouble();
                    }
                  }
                  return employee;
                }).toList();
                return employees;
              }
            }
          } catch (e2) {
            // Erreur silencieuse lors du fallback
          }
          rethrow;
        }
      } else {
        // Gérer les erreurs d'authentification pour les status non-200
        await AuthErrorHandler.handleHttpResponse(response);
        final errorMessage =
            'Erreur lors de la récupération des employés: ${response.statusCode}';
        AppLogger.error(errorMessage, tag: 'SALARY_SERVICE');
        throw Exception(errorMessage);
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erreur lors de la récupération des employés: $e',
        tag: 'SALARY_SERVICE',
        error: e,
        stackTrace: stackTrace,
      );
      // Ne jamais retourner de données fictives - propager l'erreur
      rethrow;
    }
  }

  // Récupérer les composants de salaire
  Future<List<SalaryComponent>> getSalaryComponents() async {
    try {
      final token = storage.read('token');
      final response = await HttpInterceptor.get(
        Uri.parse('$baseUrl/salary-components'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        final data = result['data'];
        if (data is List) {
          return data.map((json) => SalaryComponent.fromJson(json)).toList();
        }
        return [];
      }

      // Si l'endpoint n'existe pas ou a une erreur serveur, retourner des composants par défaut
      if (result['statusCode'] == 404 || result['statusCode'] == 500) {
        return [
          SalaryComponent(
            id: 1,
            name: 'Salaire de base',
            type: 'base',
            amount: 0.0,
            description: 'Salaire de base mensuel',
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          SalaryComponent(
            id: 2,
            name: 'Prime de performance',
            type: 'bonus',
            amount: 0.0,
            description: 'Prime basée sur les performances',
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          SalaryComponent(
            id: 3,
            name: 'Retenue sécurité sociale',
            type: 'deduction',
            amount: 0.0,
            description: 'Retenue pour la sécurité sociale',
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];
      }

      throw Exception(
        'Erreur lors de la récupération des composants: ${response.statusCode}',
      );
    } catch (e) {
      // En cas d'erreur, retourner des composants par défaut
      return [
        SalaryComponent(
          id: 1,
          name: 'Salaire de base',
          type: 'base',
          amount: 0.0,
          description: 'Salaire de base mensuel',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        SalaryComponent(
          id: 2,
          name: 'Prime de performance',
          type: 'bonus',
          amount: 0.0,
          description: 'Prime basée sur les performances',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
    }
  }

  // Créer un composant de salaire
  Future<SalaryComponent> createSalaryComponent(
    SalaryComponent component,
  ) async {
    try {
      final token = storage.read('token');

      final response = await HttpInterceptor.post(
        Uri.parse('$baseUrl/salary-components'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(component.toJson()),
      );

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        return SalaryComponent.fromJson(result['data']);
      }

      throw Exception(
        result['message'] ?? 'Erreur lors de la création du composant',
      );
    } catch (e) {
      throw Exception('Erreur lors de la création du composant: $e');
    }
  }

  // Mettre à jour un composant de salaire
  Future<SalaryComponent> updateSalaryComponent(
    SalaryComponent component,
  ) async {
    try {
      final token = storage.read('token');

      final response = await HttpInterceptor.put(
        Uri.parse('$baseUrl/salary-components/${component.id}'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(component.toJson()),
      );

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        return SalaryComponent.fromJson(result['data']);
      }

      throw Exception(
        result['message'] ?? 'Erreur lors de la mise à jour du composant',
      );
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du composant: $e');
    }
  }

  // Supprimer un composant de salaire
  Future<bool> deleteSalaryComponent(int componentId) async {
    try {
      final token = storage.read('token');

      final response = await HttpInterceptor.delete(
        Uri.parse('$baseUrl/salary-components/$componentId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static void _saveSalairesToHive(List<Salary> list) {
    try {
      HiveStorageService.saveEntityList(
        HiveStorageService.keySalaires,
        list.map((e) => e.toJson()).toList(),
      );
    } catch (_) {}
  }

  /// Cache Hive : liste des salaires pour affichage instantané.
  static List<Salary> getCachedSalaires() {
    try {
      final raw = HiveStorageService.getEntityList(HiveStorageService.keySalaires);
      return raw.map((e) => Salary.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }
}

import 'dart:convert';
import 'package:easyconnect/services/http_interceptor.dart';
import 'package:easyconnect/services/api_service.dart';
import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/Models/expense_model.dart';
import 'package:easyconnect/Models/pagination_response.dart';
import 'package:easyconnect/utils/constant.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/utils/auth_error_handler.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/retry_helper.dart';
import 'package:easyconnect/utils/pagination_helper.dart';
import 'package:easyconnect/services/storage_service.dart';
import 'package:easyconnect/services/company_service.dart';

class ExpenseService {
  final storage = GetStorage();

  /// Récupérer les dépenses avec pagination côté serveur
  Future<PaginationResponse<Expense>> getExpensesPaginated({
    String? status,
    String? category,
    String? search,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final token = storage.read('token');
      final userRole = storage.read('userRole');
      final userId = storage.read('userId');

      String url = '${AppConfig.baseUrl}/expenses';
      List<String> params = [];

      if (status != null && status.isNotEmpty) {
        params.add('status=$status');
      }
      if (category != null && category.isNotEmpty) {
        params.add('category=$category');
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

      AppLogger.httpRequest('GET', url, tag: 'EXPENSE_SERVICE');

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

      AppLogger.httpResponse(response.statusCode, url, tag: 'EXPENSE_SERVICE');
      await AuthErrorHandler.handleHttpResponse(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final result = PaginationHelper.parseResponse<Expense>(
          json: data,
          fromJsonT: (json) => Expense.fromJson(json),
        );
        if (page == 1) _saveDepensesToHive(result.data, status, category);
        return result;
      } else {
        throw Exception(
          'Erreur lors de la récupération paginée des dépenses: ${response.statusCode}',
        );
      }
    } catch (e) {
      AppLogger.error(
        'Erreur dans getExpensesPaginated: $e',
        tag: 'EXPENSE_SERVICE',
      );
      rethrow;
    }
  }

  // Récupérer toutes les dépenses
  Future<List<Expense>> getExpenses({
    String? status,
    String? category,
    String? search,
  }) async {
    try {
      final token = storage.read('token');
      final userRole = storage.read('userRole');
      final userId = storage.read('userId');

      var queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (category != null) queryParams['category'] = category;
      if (search != null) queryParams['search'] = search;
      // Filtrer par userId pour les comptables (role 3) - le patron (role 6) voit toutes les dépenses
      if (userRole == 3 && userId != null) {
        queryParams['user_id'] = userId.toString();
      }
      queryParams.addAll(CompanyService.companyQueryParam());

      final queryString =
          queryParams.isEmpty
              ? ''
              : '?${Uri(queryParameters: queryParams).query}';

      final response = await HttpInterceptor.get(
        Uri.parse('$baseUrl/expenses-list$queryString'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        try {
          final responseBody = json.decode(response.body);
          // Gérer différents formats de réponse
          List<dynamic> data;
          if (responseBody is List) {
            data = responseBody;
          } else if (responseBody['data'] != null) {
            data =
                responseBody['data'] is List
                    ? responseBody['data']
                    : [responseBody['data']];
          } else {
            data = [];
          }

          if (data.isEmpty) {
            return [];
          }

          final List<Expense> parsedExpenses = [];
          for (var jsonItem in data) {
            try {
              final expense = Expense.fromJson(
                jsonItem is Map<String, dynamic>
                    ? jsonItem
                    : Map<String, dynamic>.from(jsonItem),
              );
              parsedExpenses.add(expense);
            } catch (e) {
              // Logger l'erreur mais continuer avec les autres dépenses
              print(
                '⚠️ [EXPENSE_SERVICE] Erreur lors du parsing d\'une dépense: $e',
              );
              print('⚠️ [EXPENSE_SERVICE] JSON problématique: $jsonItem');
              // Continuer avec les autres dépenses
            }
          }
          _saveDepensesToHive(parsedExpenses, status, category);
          return parsedExpenses;
        } catch (e) {
          throw Exception(
            'Erreur lors du parsing de la réponse: $e. Réponse: ${response.body}',
          );
        }
      }
      throw Exception(
        'Erreur lors de la récupération des dépenses: ${response.statusCode}',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer une dépense par ID
  Future<Expense> getExpenseById(int id) async {
    try {
      final token = storage.read('token');

      final response = await HttpInterceptor.get(
        Uri.parse('$baseUrl/expenses-show/$id'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        return Expense.fromJson(responseBody['data'] ?? responseBody);
      }
      throw Exception(
        'Erreur lors de la récupération de la dépense: ${response.statusCode}',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Créer une dépense
  Future<Expense> createExpense(Map<String, dynamic> expenseData) async {
    try {
      CompanyService.addCompanyIdToBody(expenseData);
      final jsonBody = json.encode(expenseData);

      final response = await HttpInterceptor.post(
        HttpInterceptor.apiUri('expenses-create'),
        headers: ApiService.headers(),
        body: jsonBody,
      ).timeout(
        AppConfig.defaultTimeout,
        onTimeout: () =>
            throw Exception('Timeout: le serveur ne répond pas'),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = json.decode(response.body);
        return Expense.fromJson(responseBody['data'] ?? responseBody);
      }
      throw Exception(
        'Erreur lors de la création de la dépense: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Mettre à jour une dépense
  Future<Expense> updateExpense(
    int id,
    Map<String, dynamic> expenseData,
  ) async {
    try {
      final response = await HttpInterceptor.put(
        HttpInterceptor.apiUri('expenses-update/$id'),
        headers: ApiService.headers(),
        body: json.encode(expenseData),
      ).timeout(
        AppConfig.defaultTimeout,
        onTimeout: () =>
            throw Exception('Timeout: le serveur ne répond pas'),
      );
      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        return Expense.fromJson(responseBody['data'] ?? responseBody);
      }
      throw Exception(
        'Erreur lors de la mise à jour de la dépense: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Supprimer une dépense
  Future<bool> deleteExpense(int expenseId) async {
    try {
      final token = storage.read('token');

      final response = await HttpInterceptor.delete(
        Uri.parse('$baseUrl/expenses-destroy/$expenseId'),
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

  // Soumettre une dépense au patron
  Future<bool> submitExpense(int expenseId) async {
    try {
      final token = storage.read('token');

      final response = await HttpInterceptor.post(
        Uri.parse('$baseUrl/expenses-submit/$expenseId'),
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

  // Approuver une dépense
  Future<bool> approveExpense(int expenseId, {String? notes}) async {
    try {
      final token = storage.read('token');
      final url = '$baseUrl/expenses-validate/$expenseId';

      final response = await HttpInterceptor.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'notes': notes}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        // Vérifier si la réponse contient success == true
        if (responseData is Map && responseData['success'] == true) {
          return true;
        }
        // Si pas de champ success, considérer 200 comme succès
        return true;
      } else if (response.statusCode == 400) {
        // Erreur 400 : message explicite du backend
        final responseData = json.decode(response.body);
        final message =
            responseData['message'] ??
            'Cette dépense ne peut pas être approuvée';
        throw Exception(message);
      } else if (response.statusCode == 500) {
        // Erreur 500 : problème serveur
        final responseData = json.decode(response.body);
        final message =
            responseData['message'] ?? 'Erreur serveur lors de l\'approbation';
        throw Exception('Erreur serveur: $message');
      }
      return false;
    } catch (e) {
      rethrow; // Propager l'exception au lieu de retourner false
    }
  }

  // Rejeter une dépense
  Future<bool> rejectExpense(int expenseId, {required String reason}) async {
    try {
      final token = storage.read('token');
      final url = '$baseUrl/expenses-reject/$expenseId';

      final response = await HttpInterceptor.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'reason': reason}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        // Vérifier si la réponse contient success == true
        if (responseData is Map && responseData['success'] == true) {
          return true;
        }
        // Si pas de champ success, considérer 200 comme succès
        return true;
      } else if (response.statusCode == 400) {
        // Erreur 400 : message explicite du backend
        final responseData = json.decode(response.body);
        final message =
            responseData['message'] ?? 'Cette dépense ne peut pas être rejetée';
        throw Exception(message);
      } else if (response.statusCode == 500) {
        // Erreur 500 : problème serveur
        final responseData = json.decode(response.body);
        final message =
            responseData['message'] ?? 'Erreur serveur lors du rejet';
        throw Exception('Erreur serveur: $message');
      }
      return false;
    } catch (e) {
      rethrow; // Propager l'exception au lieu de retourner false
    }
  }

  // Récupérer les statistiques des dépenses
  Future<ExpenseStats> getExpenseStats() async {
    try {
      final token = storage.read('token');

      final response = await HttpInterceptor.get(
        Uri.parse('$baseUrl/expenses-statistics'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        return ExpenseStats.fromJson(responseBody['data'] ?? responseBody);
      }
      throw Exception(
        'Erreur lors de la récupération des statistiques: ${response.statusCode}',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer les dépenses en attente
  Future<List<Expense>> getPendingExpenses() async {
    try {
      return await getExpenses(status: 'pending');
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer les catégories de dépenses
  Future<List<ExpenseCategory>> getExpenseCategories() async {
    try {
      final token = storage.read('token');

      final response = await HttpInterceptor.get(
        Uri.parse('$baseUrl/expense-categories'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        final List<dynamic> data = responseBody['data'] ?? responseBody;
        if (data.isEmpty) {
          return [];
        }
        return data.map((json) => ExpenseCategory.fromJson(json)).toList();
      }
      throw Exception(
        'Erreur lors de la récupération des catégories: ${response.statusCode}',
      );
    } catch (e) {
      rethrow;
    }
  }

  static void _saveDepensesToHive(List<Expense> list, [String? status, String? category]) {
    try {
      final key = '${HiveStorageService.keyDepenses}_${status ?? 'all'}_${category ?? 'all'}';
      HiveStorageService.saveEntityList(
        key,
        list.map((e) => e.toJson()).toList(),
      );
    } catch (_) {}
  }

  /// Cache Hive (sync) : affichage instantané Cache-First.
  static List<Expense> getCachedDepenses([String? status, String? category]) {
    try {
      final key = '${HiveStorageService.keyDepenses}_${status ?? 'all'}_${category ?? 'all'}';
      final raw = HiveStorageService.getEntityList(key);
      if (raw.isNotEmpty) {
        return raw.map((e) => Expense.fromJson(Map<String, dynamic>.from(e))).toList();
      }
      if (status != null || category != null) return [];
      final fallback = HiveStorageService.getEntityList(HiveStorageService.keyDepenses);
      return fallback.map((e) => Expense.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }
}

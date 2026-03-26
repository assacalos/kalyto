import 'dart:convert';
import 'package:easyconnect/services/http_interceptor.dart';
import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/Models/tax_model.dart';
import 'package:easyconnect/Models/pagination_response.dart';
import 'package:easyconnect/utils/constant.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/services/api_service.dart';
import 'package:easyconnect/utils/auth_error_handler.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/retry_helper.dart';
import 'package:easyconnect/utils/pagination_helper.dart';
import 'package:easyconnect/services/storage_service.dart';

class TaxService {
  final storage = GetStorage();

  // Tester la connectivité à l'API pour les impôts
  Future<bool> testTaxConnection() async {
    try {
      final response = await HttpInterceptor.get(
        HttpInterceptor.apiUri('taxes-list'),
      ).timeout(AppConfig.extraLongTimeout);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Récupérer les taxes avec pagination côté serveur
  Future<PaginationResponse<Tax>> getTaxesPaginated({
    String? status,
    String? type,
    String? search,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      String url = '${AppConfig.baseUrl}/taxes';
      List<String> params = [];

      if (status != null && status.isNotEmpty) {
        params.add('status=$status');
      }
      if (type != null && type.isNotEmpty) {
        params.add('type=$type');
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

      AppLogger.httpRequest('GET', url, tag: 'TAX_SERVICE');

      final response = await RetryHelper.retryNetwork(
        operation: () => HttpInterceptor.get(Uri.parse(url)),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(response.statusCode, url, tag: 'TAX_SERVICE');
      await AuthErrorHandler.handleHttpResponse(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        try {
          final result = PaginationHelper.parseResponse<Tax>(
            json: data,
            fromJsonT: (json) => Tax.fromJson(json),
          );
          if (page == 1 && result.data.isNotEmpty) {
            _saveTaxesToHive(result.data);
          }
          return result;
        } catch (e) {
          // Fallback si PaginationHelper échoue
          AppLogger.warning(
            'PaginationHelper a échoué, tentative de parsing manuel: $e',
            tag: 'TAX_SERVICE',
          );

          // Essayer de parser manuellement
          List<Tax> taxes = [];
          if (data['data'] != null) {
            if (data['data'] is List) {
              taxes =
                  (data['data'] as List)
                      .map((json) => Tax.fromJson(json as Map<String, dynamic>))
                      .toList();
            } else if (data['data'] is Map &&
                (data['data'] as Map)['data'] != null) {
              final nestedData = (data['data'] as Map)['data'];
              if (nestedData is List) {
                taxes =
                    nestedData
                        .map(
                          (json) => Tax.fromJson(json as Map<String, dynamic>),
                        )
                        .toList();
              }
            }
          }

          if (page == 1 && taxes.isNotEmpty) {
            _saveTaxesToHive(taxes);
          }
          return PaginationResponse<Tax>(
            data: taxes,
            meta: PaginationMeta.fromJson({
              'current_page': data['current_page'] ?? 1,
              'last_page': data['last_page'] ?? 1,
              'per_page': data['per_page'] ?? perPage,
              'total': data['total'] ?? taxes.length,
            }),
          );
        }
      } else {
        throw Exception(
          'Erreur lors de la récupération paginée des taxes: ${response.statusCode}',
        );
      }
    } catch (e) {
      AppLogger.error('Erreur dans getTaxesPaginated: $e', tag: 'TAX_SERVICE');
      rethrow;
    }
  }

  // Récupérer tous les impôts et taxes
  Future<List<Tax>> getTaxes({
    String? status,
    String? type,
    String? search,
  }) async {
    try {
      var queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (type != null) queryParams['type'] = type;
      if (search != null) queryParams['search'] = search;

      final queryString =
          queryParams.isEmpty
              ? ''
              : '?${Uri(queryParameters: queryParams).query}';

      final url = '$baseUrl/taxes-list$queryString';
      final response = await HttpInterceptor.get(Uri.parse(url));

      // Si le status code est 200 ou 201, traiter directement
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = jsonDecode(response.body);
          List<dynamic> data = [];

          // Gérer différents formats de réponse de l'API Laravel
          if (responseData is List) {
            data = responseData;
          } else if (responseData is Map) {
            if (responseData['data'] != null) {
              if (responseData['data'] is List) {
                data = responseData['data'];
              } else if (responseData['data'] is Map &&
                  responseData['data']['data'] != null) {
                data = responseData['data']['data'];
              }
            }
            // Essayer le format spécifique aux impôts
            else if (responseData['taxes'] != null) {
              if (responseData['taxes'] is List) {
                data = responseData['taxes'];
              }
            }
          }

          if (data.isEmpty) {
            return [];
          }

          try {
            final list = data.map((json) => Tax.fromJson(json)).toList();
            _saveTaxesToHive(list);
            return list;
          } catch (e) {
            throw Exception('Erreur de format des données: $e');
          }
        } catch (e) {
          throw Exception('Erreur de format des données: $e');
        }
      }

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
            // Essayer le format spécifique aux impôts
            else if (responseData['taxes'] != null) {
              if (responseData['taxes'] is List) {
                data = responseData['taxes'];
              }
            }
          }

          if (data.isEmpty) {
            return [];
          }

          try {
            final list = data.map((json) => Tax.fromJson(json)).toList();
            _saveTaxesToHive(list);
            return list;
          } catch (e) {
            rethrow;
          }
        } catch (e) {
          throw Exception('Erreur de format des données: $e');
        }
      } else {
        throw Exception(
          result['message'] ?? 'Erreur lors de la récupération des impôts',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer un impôt par ID
  Future<Tax> getTaxById(int id) async {
    try {
      final token = storage.read('token');

      final response = await HttpInterceptor.get(
        Uri.parse('$baseUrl/taxes-show/$id'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        return Tax.fromJson(result['data']);
      }

      throw Exception(
        result['message'] ?? 'Erreur lors de la récupération de l\'impôt',
      );
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'impôt: $e');
    }
  }

  // Créer un impôt
  Future<Tax> createTax(Tax tax) async {
    try {
      final token = storage.read('token');

      // Validation des champs requis
      if (tax.category == null || tax.category!.isEmpty) {
        throw Exception('category est requis');
      }
      if (tax.baseAmount <= 0) {
        throw Exception('baseAmount doit être supérieur à 0');
      }
      if (tax.period == null || tax.period!.isEmpty) {
        throw Exception('period est requis (format: YYYY-MM)');
      }
      if (tax.periodStart == null || tax.periodStart!.isEmpty) {
        throw Exception('periodStart est requis (format: YYYY-MM-DD)');
      }
      if (tax.periodEnd == null || tax.periodEnd!.isEmpty) {
        throw Exception('periodEnd est requis (format: YYYY-MM-DD)');
      }
      if (tax.dueDate == null || tax.dueDate!.isEmpty) {
        throw Exception('dueDate est requis (format: YYYY-MM-DD)');
      }

      // Préparer les données selon la documentation API (camelCase)
      final taxData = tax.toJson();
      final response = await HttpInterceptor.post(
        Uri.parse('$baseUrl/taxes-create'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(taxData),
      );
      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        return Tax.fromJson(result['data']);
      }

      throw Exception(
        result['message'] ?? 'Erreur lors de la création de la taxe',
      );
    } catch (e) {
      throw Exception('Erreur lors de la création de la taxe: $e');
    }
  }

  // Mettre à jour un impôt
  Future<Tax> updateTax(Tax tax) async {
    try {
      final token = storage.read('token');

      final response = await HttpInterceptor.put(
        Uri.parse('$baseUrl/taxes-update/${tax.id}'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(tax.toJson()),
      );

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        return Tax.fromJson(result['data']);
      }

      throw Exception(
        result['message'] ?? 'Erreur lors de la mise à jour de l\'impôt',
      );
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'impôt: $e');
    }
  }

  // Marquer un impôt comme payé
  Future<bool> markTaxAsPaid(
    int taxId, {
    required String paymentMethod,
    String? reference,
    String? notes,
  }) async {
    try {
      final token = storage.read('token');

      final response = await HttpInterceptor.post(
        Uri.parse('$baseUrl/taxes/$taxId/mark-paid'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          if (paymentMethod.isNotEmpty) 'payment_method': paymentMethod,
          if (reference != null && reference.isNotEmpty) 'reference': reference,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Supprimer un impôt
  Future<bool> deleteTax(int taxId) async {
    try {
      final token = storage.read('token');

      final response = await HttpInterceptor.delete(
        Uri.parse('$baseUrl/taxes-delete/$taxId'),
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

  // Récupérer les statistiques des impôts
  Future<TaxStats> getTaxStats() async {
    try {
      final token = storage.read('token');

      final response = await HttpInterceptor.get(
        Uri.parse('$baseUrl/taxes-stats'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        return TaxStats.fromJson(result['data']);
      }

      throw Exception(
        result['message'] ?? 'Erreur lors de la récupération des statistiques',
      );
    } catch (e) {
      // Retourner des données de test en cas d'erreur
      return TaxStats(
        totalAmount: 0.0,
        pendingAmount: 0.0,
        validatedAmount: 0.0,
        rejectedAmount: 0.0,
        total: 0,
        pending: 0,
        validated: 0,
        rejected: 0,
      );
    }
  }

  // Récupérer les impôts en retard
  Future<List<Tax>> getOverdueTaxes() async {
    try {
      final token = storage.read('token');

      final response = await HttpInterceptor.get(
        Uri.parse('$baseUrl/taxes-overdue'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> data = responseData['data'] ?? [];
        return data.map((json) => Tax.fromJson(json)).toList();
      }
      throw Exception(
        'Erreur lors de la récupération des impôts en retard: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception(
        'Erreur lors de la récupération des impôts en retard: $e',
      );
    }
  }

  // Récupérer les impôts à échéance proche
  Future<List<Tax>> getUpcomingTaxes() async {
    try {
      final token = storage.read('token');

      final response = await HttpInterceptor.get(
        Uri.parse('$baseUrl/taxes-upcoming'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> data = responseData['data'] ?? [];
        return data.map((json) => Tax.fromJson(json)).toList();
      }
      throw Exception(
        'Erreur lors de la récupération des impôts à échéance: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception(
        'Erreur lors de la récupération des impôts à échéance: $e',
      );
    }
  }

  // Récupérer les catégories d'impôts
  Future<List<TaxCategory>> getTaxCategories() async {
    try {
      // Essayer plusieurs endpoints possibles
      final endpoints = [
        '/tax-categories',
        '/tax_categories',
        '/taxCategories',
        '/tax-categories-list',
      ];

      Exception? lastException;

      for (final endpoint in endpoints) {
        try {
          final response = await HttpInterceptor.get(
            Uri.parse('${AppConfig.baseUrl}$endpoint'),
          ).timeout(AppConfig.extraLongTimeout);
          if (response.statusCode == 200) {
            final responseBody = json.decode(response.body);
            if (responseBody is Map) {}

            List<dynamic> data = [];

            // Gérer différents formats de réponse
            if (responseBody is Map) {
              if (responseBody['data'] != null) {
                if (responseBody['data'] is List) {
                  data = responseBody['data'];
                } else if (responseBody['data'] is Map &&
                    responseBody['data']['data'] != null) {
                  data = responseBody['data']['data'];
                }
              } else if (responseBody['categories'] != null) {
                if (responseBody['categories'] is List) {
                  data = responseBody['categories'];
                }
              } else if (responseBody['tax_categories'] != null) {
                if (responseBody['tax_categories'] is List) {
                  data = responseBody['tax_categories'];
                }
              }
            } else if (responseBody is List) {
              // Si la réponse est directement une liste
              data = responseBody;
            }
            if (data.isEmpty) {
              continue; // Essayer l'endpoint suivant
            }

            try {
              final categories =
                  data.map((json) {
                    return TaxCategory.fromJson(json);
                  }).toList();
              return categories;
            } catch (parseError) {
              lastException = Exception('Erreur de parsing: $parseError');
              continue; // Essayer l'endpoint suivant
            }
          } else {
            lastException = Exception(
              'Erreur ${response.statusCode}: ${response.body}',
            );
          }
        } catch (endpointError) {
          lastException = Exception('Erreur avec $endpoint: $endpointError');
          continue; // Essayer l'endpoint suivant
        }
      }

      // Si aucun endpoint n'a fonctionné
      if (lastException != null) {
        throw lastException;
      }
      return [];
    } catch (e) {
      // Retourner une liste vide au lieu de lever une exception pour éviter de bloquer l'UI
      return [];
    }
  }

  // Créer une catégorie d'impôt
  Future<Tax> createTaxCategory(Tax category) async {
    try {
      final token = storage.read('token');

      final response = await HttpInterceptor.post(
        Uri.parse('$baseUrl/tax-categories-create'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(category.toJson()),
      );

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        return Tax.fromJson(result['data']);
      }

      throw Exception(
        result['message'] ?? 'Erreur lors de la création de la catégorie',
      );
    } catch (e) {
      throw Exception('Erreur lors de la création de la catégorie: $e');
    }
  }

  // Mettre à jour une catégorie d'impôt
  Future<Tax> updateTaxCategory(Tax category) async {
    try {
      final token = storage.read('token');

      final response = await HttpInterceptor.put(
        Uri.parse('$baseUrl/tax-categories-update/${category.id}'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(category.toJson()),
      );

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        return Tax.fromJson(result['data']);
      }

      throw Exception(
        result['message'] ?? 'Erreur lors de la mise à jour de la catégorie',
      );
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la catégorie: $e');
    }
  }

  // Supprimer une catégorie d'impôt
  Future<bool> deleteTaxCategory(int categoryId) async {
    try {
      final token = storage.read('token');

      final response = await HttpInterceptor.delete(
        Uri.parse('$baseUrl/tax-categories-delete/$categoryId'),
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

  // Approuver/Valider une taxe
  Future<bool> approveTax(int taxId, {String? notes}) async {
    try {
      final token = storage.read('token');
      final response = await HttpInterceptor.post(
        Uri.parse('$baseUrl/taxes-validate/$taxId'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          if (notes != null && notes.isNotEmpty) 'validation_comment': notes,
        }),
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Rejeter une taxe
  Future<bool> rejectTax(
    int taxId, {
    required String reason,
    String? notes,
  }) async {
    try {
      final token = storage.read('token');
      final response = await HttpInterceptor.post(
        Uri.parse('$baseUrl/taxes-reject/$taxId'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'rejection_reason': reason,
          if (notes != null && notes.isNotEmpty) 'rejection_comment': notes,
        }),
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Récupérer les taxes en attente d'approbation
  Future<List<Tax>> getPendingTaxes() async {
    try {
      final token = storage.read('token');
      final response = await HttpInterceptor.get(
        Uri.parse('$baseUrl/taxes-pending'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        List<dynamic> data = [];

        // Gérer différents formats de réponse
        if (responseData['data'] != null) {
          data =
              responseData['data'] is List
                  ? responseData['data']
                  : responseData['data']['data'] ?? [];
        } else if (responseData['taxes'] != null) {
          data = responseData['taxes'] is List ? responseData['taxes'] : [];
        }
        return data.map((json) => Tax.fromJson(json)).toList();
      } else {
        throw Exception(
          'Erreur lors de la récupération des taxes en attente: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception(
        'Erreur lors de la récupération des taxes en attente: $e',
      );
    }
  }

  // Récupérer l'historique des approbations/rejets
  Future<List<Map<String, dynamic>>> getTaxApprovalHistory(int taxId) async {
    try {
      final token = storage.read('token');
      final response = await HttpInterceptor.get(
        Uri.parse('$baseUrl/taxes-history/$taxId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        List<dynamic> data = responseData['data'] ?? [];
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception(
          'Erreur lors de la récupération de l\'historique: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'historique: $e');
    }
  }

  static void _saveTaxesToHive(List<Tax> list) {
    try {
      HiveStorageService.saveEntityList(
        HiveStorageService.keyTaxes,
        list.map((e) => e.toJson()).toList(),
      );
    } catch (_) {}
  }

  /// Cache Hive : liste des taxes pour affichage instantané.
  static List<Tax> getCachedTaxes() {
    try {
      final raw = HiveStorageService.getEntityList(HiveStorageService.keyTaxes);
      return raw.map((e) => Tax.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }
}

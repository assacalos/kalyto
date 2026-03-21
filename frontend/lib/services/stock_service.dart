import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:easyconnect/services/http_interceptor.dart';
import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/Models/stock_model.dart';
import 'package:easyconnect/Models/pagination_response.dart';
import 'package:easyconnect/services/api_service.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/utils/auth_error_handler.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/retry_helper.dart';
import 'package:easyconnect/utils/pagination_helper.dart';
import 'package:easyconnect/services/storage_service.dart';

class StockService {
  static final StockService _instance = StockService._();
  static StockService get to => _instance;
  factory StockService() => _instance;
  StockService._();
  final storage = GetStorage();

  // Tester la connectivité à l'API
  Future<bool> testConnection() async {
    try {
      final token = storage.read('token');
      final url = '${AppConfig.baseUrl}/stocks';
      AppLogger.httpRequest('GET', url, tag: 'STOCK_SERVICE');

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
      ).timeout(AppConfig.shortTimeout);

      AppLogger.httpResponse(response.statusCode, url, tag: 'STOCK_SERVICE');
      return response.statusCode == 200;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erreur lors du test de connexion: $e',
        tag: 'STOCK_SERVICE',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Récupérer les stocks avec pagination côté serveur
  Future<PaginationResponse<Stock>> getStocksPaginated({
    String? search,
    String? category,
    String? status,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final token = storage.read('token');
      String url = '${AppConfig.baseUrl}/stocks';
      List<String> params = [];

      if (search != null && search.isNotEmpty) {
        params.add('search=$search');
      }
      if (category != null && category.isNotEmpty) {
        params.add('category=$category');
      }
      if (status != null && status.isNotEmpty) {
        params.add('status=$status');
      }
      // Ajouter la pagination
      params.add('page=$page');
      params.add('per_page=$perPage');

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      AppLogger.httpRequest('GET', url, tag: 'STOCK_SERVICE');

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

      AppLogger.httpResponse(response.statusCode, url, tag: 'STOCK_SERVICE');
      await AuthErrorHandler.handleHttpResponse(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final result = PaginationHelper.parseResponse<Stock>(
          json: data,
          fromJsonT: (json) => Stock.fromJson(json),
        );
        if (page == 1 && result.data.isNotEmpty) {
          _saveStocksToHive(result.data);
        }
        return result;
      } else {
        throw Exception(
          'Erreur lors de la récupération paginée des stocks: ${response.statusCode}',
        );
      }
    } catch (e) {
      AppLogger.error(
        'Erreur dans getStocksPaginated: $e',
        tag: 'STOCK_SERVICE',
      );
      rethrow;
    }
  }

  // Récupérer tous les stocks
  Future<List<Stock>> getStocks({
    String? search,
    String? category,
    String? status,
    int? page,
    int? limit,
  }) async {
    try {
      final token = storage.read('token');
      String url = '${AppConfig.baseUrl}/stocks';
      List<String> params = [];

      if (search != null && search.isNotEmpty) {
        params.add('search=$search');
      }
      if (category != null && category.isNotEmpty) {
        params.add('category=$category');
      }
      if (status != null && status.isNotEmpty) {
        params.add('status=$status');
      }
      if (page != null) {
        params.add('page=$page');
      }
      if (limit != null) {
        params.add('limit=$limit');
      }

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }
      AppLogger.httpRequest('GET', url, tag: 'STOCK_SERVICE');

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

      AppLogger.httpResponse(response.statusCode, url, tag: 'STOCK_SERVICE');

      // Gérer les erreurs d'authentification
      await AuthErrorHandler.handleHttpResponse(response);

      // Gérer les réponses avec différents codes de statut
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
            // Essayer le format spécifique aux stocks
            else if (responseData['stocks'] != null) {
              if (responseData['stocks'] is List) {
                data = responseData['stocks'];
              }
            }
          }

          if (data.isEmpty) {
            return [];
          }

          try {
            final list = data.map((json) => Stock.fromJson(json)).toList();
            _saveStocksToHive(list);
            return list;
          } catch (e) {
            rethrow;
          }
        } catch (e) {
          throw Exception('Erreur de format des données: $e');
        }
      } else {
        // Si c'est une erreur 401, elle a déjà été gérée
        if (result['statusCode'] == 401) {
          throw Exception('Session expirée');
        }

        // Pour les erreurs 500, retourner une liste vide plutôt que de planter
        // Cela permet à l'application de continuer à fonctionner
        if (response.statusCode == 500) {
          return [];
        }

        throw Exception(
          'Erreur lors de la récupération des stocks: ${response.statusCode}',
        );
      }
    } catch (e) {
      // Gérer les erreurs d'authentification dans les exceptions
      final isAuthError = await AuthErrorHandler.handleError(e);
      if (isAuthError) {
        throw Exception('Session expirée');
      }
      rethrow;
    }
  }

  // Récupérer un stock par ID
  Future<Stock> getStock(int id) async {
    try {
      final token = storage.read('token');

      final response = await HttpInterceptor.get(
        Uri.parse('${AppConfig.baseUrl}/stocks/$id'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        return Stock.fromJson(result['data']);
      } else {
        throw Exception(
          result['message'] ?? 'Erreur lors de la récupération du stock',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Créer un nouveau stock
  Future<Stock> createStock(Stock stock) async {
    try {
      // Validation des champs requis
      if (stock.name.isEmpty) {
        throw Exception('Le nom du produit est requis');
      }
      if (stock.category.isEmpty) {
        throw Exception('La catégorie est requise');
      }
      if (stock.sku.isEmpty) {
        throw Exception('Le SKU est requis');
      }
      // Note: 'unit' n'est pas requis car il n'existe pas dans le backend
      if (stock.quantity < 0) {
        throw Exception('La quantité doit être >= 0');
      }
      if (stock.minQuantity < 0) {
        throw Exception('La quantité minimale doit être >= 0');
      }
      if (stock.maxQuantity < 0) {
        throw Exception('La quantité maximale doit être >= 0');
      }
      if (stock.unitPrice < 0) {
        throw Exception('Le prix unitaire doit être >= 0');
      }

      final stockData = stock.toJson();

      // Essayer d'abord la route stocks-create, puis stocks en fallback
      String url = '${AppConfig.baseUrl}/stocks-create';
      AppLogger.httpRequest('POST', url, tag: 'STOCK_SERVICE');

      http.Response response;
      try {
        response = await RetryHelper.retryNetwork(
          operation:
              () => HttpInterceptor.post(
                Uri.parse(url),
                headers: ApiService.headers(),
                body: jsonEncode(stockData),
              ),
          maxRetries: AppConfig.defaultMaxRetries,
        );
        AppLogger.httpResponse(response.statusCode, url, tag: 'STOCK_SERVICE');
      } catch (e) {
        // Si la première route échoue, essayer la route standard
        url = '${AppConfig.baseUrl}/stocks';
        AppLogger.warning(
          'Tentative avec route alternative: $url',
          tag: 'STOCK_SERVICE',
        );
        response = await RetryHelper.retryNetwork(
          operation:
              () => HttpInterceptor.post(
                Uri.parse(url),
                headers: ApiService.headers(),
                body: jsonEncode(stockData),
              ),
          maxRetries: AppConfig.defaultMaxRetries,
        );
        AppLogger.httpResponse(response.statusCode, url, tag: 'STOCK_SERVICE');
      }

      await AuthErrorHandler.handleHttpResponse(response);

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        AppLogger.info('Stock créé avec succès', tag: 'STOCK_SERVICE');
        return Stock.fromJson(result['data']);
      }

      throw Exception(
        result['message'] ?? 'Erreur lors de la création du stock',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erreur lors de la création du stock: $e',
        tag: 'STOCK_SERVICE',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Mettre à jour un stock
  Future<Stock> updateStock(Stock stock) async {
    try {
      if (stock.id == null) {
        throw Exception('L\'ID du stock est requis pour la mise à jour');
      }

      final stockData = stock.toJson();
      final url = '${AppConfig.baseUrl}/stocks-update/${stock.id}';
      AppLogger.httpRequest('PUT', url, tag: 'STOCK_SERVICE');

      final response = await RetryHelper.retryNetwork(
        operation:
            () => HttpInterceptor.put(
              Uri.parse(url),
              headers: ApiService.headers(),
              body: jsonEncode(stockData),
            ),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(response.statusCode, url, tag: 'STOCK_SERVICE');
      await AuthErrorHandler.handleHttpResponse(response);

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        AppLogger.info('Stock mis à jour avec succès', tag: 'STOCK_SERVICE');
        return Stock.fromJson(result['data']);
      }

      throw Exception(
        result['message'] ?? 'Erreur lors de la mise à jour du stock',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Supprimer un stock
  Future<Map<String, dynamic>> deleteStock(int id) async {
    try {
      final response = await HttpInterceptor.delete(
        Uri.parse('${AppConfig.baseUrl}/stocks-destroy/$id'),
        headers: ApiService.headers(),
      );

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        return result['data'] ?? {};
      } else {
        throw Exception(
          result['message'] ?? 'Erreur lors de la suppression du stock',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Ajouter du stock (entrée)
  Future<Stock> addStock({
    required int stockId,
    required double quantity,
    double? unitCost,
    String reason = 'purchase',
    String? reference,
    String? notes,
  }) async {
    try {
      final response = await HttpInterceptor.post(
        Uri.parse('${AppConfig.baseUrl}/stocks-add-stock/$stockId'),
        headers: ApiService.headers(),
        body: jsonEncode({
          'quantity': quantity,
          if (unitCost != null) 'unit_cost': unitCost,
          'reason': reason,
          if (reference != null && reference.isNotEmpty) 'reference': reference,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        }),
      );
      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        return Stock.fromJson(result['data']);
      }

      throw Exception(
        'Erreur lors de l\'ajout du stock: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Retirer du stock (sortie)
  Future<Stock> removeStock({
    required int stockId,
    required double quantity,
    String reason = 'sale',
    String? reference,
    String? notes,
  }) async {
    try {
      final response = await HttpInterceptor.post(
        Uri.parse('${AppConfig.baseUrl}/stocks-remove-stock/$stockId'),
        headers: ApiService.headers(),
        body: jsonEncode({
          'quantity': quantity,
          'reason': reason,
          if (reference != null && reference.isNotEmpty) 'reference': reference,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        }),
      );
      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        return Stock.fromJson(result['data']);
      }

      throw Exception(
        'Erreur lors du retrait du stock: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Ajuster le stock (inventaire)
  Future<Stock> adjustStock({
    required int stockId,
    required double newQuantity,
    String reason = 'adjustment',
    String? notes,
  }) async {
    try {
      final response = await HttpInterceptor.post(
        Uri.parse('${AppConfig.baseUrl}/stocks-adjust-stock/$stockId'),
        headers: ApiService.headers(),
        body: jsonEncode({
          'new_quantity': newQuantity,
          'reason': reason,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        }),
      );
      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        return Stock.fromJson(result['data']);
      }

      throw Exception(
        'Erreur lors de l\'ajustement du stock: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Transférer du stock
  Future<Stock> transferStock({
    required int stockId,
    required double quantity,
    required String locationTo,
    String? notes,
  }) async {
    try {
      final response = await HttpInterceptor.post(
        Uri.parse('${AppConfig.baseUrl}/stocks-transfer-stock/$stockId'),
        headers: ApiService.headers(),
        body: jsonEncode({
          'quantity': quantity,
          'location_to': locationTo,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        }),
      );
      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        return Stock.fromJson(result['data']);
      }

      throw Exception(
        'Erreur lors du transfert du stock: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Ajouter un mouvement de stock (ancienne méthode pour compatibilité)
  @Deprecated('Utilisez addStock, removeStock, adjustStock ou transferStock')
  Future<Map<String, dynamic>> addStockMovement({
    required int stockId,
    required String type,
    required double quantity,
    String? reason,
    String? reference,
    String? notes,
  }) async {
    try {
      final response = await HttpInterceptor.post(
        Uri.parse('${AppConfig.baseUrl}/stocks-movements/$stockId'),
        headers: ApiService.headers(),
        body: jsonEncode({
          'type': type,
          'quantity': quantity,
          'reason': reason,
          'reference': reference,
          'notes': notes,
        }),
      );

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        return result['data'] ?? {};
      } else {
        throw Exception(
          result['message'] ?? 'Erreur lors de l\'ajout du mouvement',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer les mouvements d'un stock
  Future<List<StockMovement>> getStockMovements({
    required int stockId,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    int? page,
    int? limit,
  }) async {
    try {
      String url = '${AppConfig.baseUrl}/stocks-movements/$stockId';
      List<String> params = [];

      if (type != null && type.isNotEmpty) {
        params.add('type=$type');
      }
      if (startDate != null) {
        params.add('start_date=${startDate.toIso8601String()}');
      }
      if (endDate != null) {
        params.add('end_date=${endDate.toIso8601String()}');
      }
      if (page != null) {
        params.add('page=$page');
      }
      if (limit != null) {
        params.add('limit=$limit');
      }

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await HttpInterceptor.get(
        Uri.parse(url),
        headers: ApiService.headers(),
      );

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        final data = result['data'];
        if (data is List) {
          return data.map((json) => StockMovement.fromJson(json)).toList();
        }
        return [];
      } else {
        throw Exception(
          'Erreur lors de la récupération des mouvements: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer les statistiques de stock
  Future<StockStats> getStockStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      String url = '${AppConfig.baseUrl}/stocks-statistics';
      List<String> params = [];

      if (startDate != null) {
        params.add('start_date=${startDate.toIso8601String()}');
      }
      if (endDate != null) {
        params.add('end_date=${endDate.toIso8601String()}');
      }

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await HttpInterceptor.get(
        Uri.parse(url),
        headers: ApiService.headers(),
      );

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        return StockStats.fromJson(result['data']);
      } else {
        throw Exception(
          result['message'] ??
              'Erreur lors de la récupération des statistiques',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer les catégories de stock
  Future<List<StockCategory>> getStockCategories() async {
    try {
      final response = await HttpInterceptor.get(
        Uri.parse('${AppConfig.baseUrl}/stocks-categories'),
        headers: ApiService.headers(),
      );
      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        final data = result['data'];
        if (data is List) {
          return data.map((json) => StockCategory.fromJson(json)).toList();
        }
        return [];
      } else {
        throw Exception(
          result['message'] ?? 'Erreur lors de la récupération des catégories',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Créer une catégorie de stock
  Future<Map<String, dynamic>> createStockCategory({
    required String name,
    required String description,
    String? parentCategory,
  }) async {
    try {
      final response = await HttpInterceptor.post(
        Uri.parse(
          '${AppConfig.baseUrl}/stock-categories',
        ), // Correction: conforme à Laravel
        headers: ApiService.headers(),
        body: jsonEncode({
          'name': name,
          'description': description,
          'parent_category': parentCategory,
        }),
      );

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        return result['data'] ?? {};
      } else {
        throw Exception(
          result['message'] ?? 'Erreur lors de la création de la catégorie',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer les alertes de stock
  Future<List<StockAlert>> getStockAlerts({
    bool? unreadOnly,
    String? type,
  }) async {
    try {
      String url = '${AppConfig.baseUrl}/stocks/alerts';
      List<String> params = [];

      if (unreadOnly == true) {
        params.add('unread_only=true');
      }
      if (type != null && type.isNotEmpty) {
        params.add('type=$type');
      }

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await HttpInterceptor.get(
        Uri.parse(url),
        headers: ApiService.headers(),
      );

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        final data = result['data'];
        if (data is List) {
          return data.map((json) => StockAlert.fromJson(json)).toList();
        }
        return [];
      } else {
        throw Exception(
          result['message'] ?? 'Erreur lors de la récupération des alertes',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Marquer une alerte comme lue
  Future<Map<String, dynamic>> markAlertAsRead(int alertId) async {
    try {
      final response = await HttpInterceptor.put(
        Uri.parse('${AppConfig.baseUrl}/stocks/alerts/$alertId/read'),
        headers: ApiService.headers(),
      );

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        return result['data'] ?? {};
      } else {
        throw Exception(
          result['message'] ?? 'Erreur lors du marquage de l\'alerte',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Rechercher des stocks par code-barres
  Future<Stock?> searchStockByBarcode(String barcode) async {
    try {
      final response = await HttpInterceptor.get(
        Uri.parse('${AppConfig.baseUrl}/stocks/search/barcode/$barcode'),
        headers: ApiService.headers(),
      );

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        return Stock.fromJson(result['data']);
      } else if (result['statusCode'] == 404) {
        return null;
      } else {
        throw Exception(
          'Erreur lors de la recherche par code-barres: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Rejeter un stock (endpoint selon la doc: POST /api/stocks/{id}/rejeter)
  // Approuver/Valider un stock
  Future<Stock> approveStock({
    required int stockId,
    String? validationComment,
  }) async {
    try {
      final response = await HttpInterceptor.post(
        Uri.parse('${AppConfig.baseUrl}/stocks/$stockId/valider'),
        headers: ApiService.headers(),
        body: jsonEncode({
          if (validationComment != null && validationComment.isNotEmpty)
            'validation_comment': validationComment,
        }),
      );
      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        return Stock.fromJson(result['data']);
      }

      throw Exception(
        'Erreur lors de l\'approbation du stock: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Stock> rejectStock({
    required int stockId,
    required String commentaire,
  }) async {
    try {
      final response = await HttpInterceptor.post(
        Uri.parse('${AppConfig.baseUrl}/stocks/$stockId/rejeter'),
        headers: ApiService.headers(),
        body: jsonEncode({'commentaire': commentaire}),
      );
      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        return Stock.fromJson(result['data']);
      }

      throw Exception(
        'Erreur lors du rejet du stock: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      rethrow;
    }
  }

  static void _saveStocksToHive(List<Stock> list) {
    try {
      HiveStorageService.saveEntityList(
        HiveStorageService.keyStocks,
        list.map((e) => e.toJson()).toList(),
      );
    } catch (_) {}
  }

  /// Cache Hive : liste des stocks pour affichage instantané.
  static List<Stock> getCachedStocks() {
    try {
      final raw = HiveStorageService.getEntityList(HiveStorageService.keyStocks);
      return raw.map((e) => Stock.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }
}

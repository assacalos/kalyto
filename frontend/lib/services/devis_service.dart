import 'package:easyconnect/services/http_interceptor.dart';
import 'package:easyconnect/services/api_service.dart';
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/Models/devis_model.dart';
import 'package:easyconnect/Models/pagination_response.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/utils/auth_error_handler.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/retry_helper.dart';
import 'package:easyconnect/services/storage_service.dart';
import 'package:easyconnect/services/company_service.dart';
import 'package:easyconnect/utils/pagination_helper.dart';

class DevisService {
  final storage = GetStorage();

  /// Récupérer les devis avec pagination côté serveur
  Future<PaginationResponse<Devis>> getDevisPaginated({
    int? status,
    int? clientId,
    int page = 1,
    int perPage = 15,
    String? search,
  }) async {
    try {
      final userRole = storage.read('userRole');
      final userId = storage.read('userId');

      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      if (status != null) {
        final apiStatus = status == 1 ? 0 : status;
        queryParams['status'] = apiStatus.toString();
      }
      if (clientId != null) queryParams['client_id'] = clientId.toString();
      if (userRole == 2 && userId != null) queryParams['user_id'] = userId.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      queryParams.addAll(CompanyService.companyQueryParam());

      final uri = HttpInterceptor.apiUri('devis').replace(
        queryParameters: queryParams,
      );
      AppLogger.httpRequest('GET', uri.toString(), tag: 'DEVIS_SERVICE');

      final response = await RetryHelper.retryNetwork(
        operation:
            () => HttpInterceptor.get(uri).timeout(
                  AppConfig.defaultTimeout,
                  onTimeout:
                      () =>
                          throw Exception('Timeout: le serveur ne répond pas'),
                ),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(response.statusCode, uri.toString(), tag: 'DEVIS_SERVICE');
      await AuthErrorHandler.handleHttpResponse(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final paginatedResponse = PaginationHelper.parseResponseSafe<Devis>(
          json: data,
          fromJsonT: (json) {
            try {
              return Devis.fromJson(json);
            } catch (_) {
              return null;
            }
          },
        );
        if (page == 1 && clientId == null) _saveDevisToHive(paginatedResponse.data, status);

        if (paginatedResponse.data.isEmpty) {
          AppLogger.warning(
            'Aucun devis retourné malgré un statut 200. Vérifier les filtres et les données en base.',
            tag: 'DEVIS_SERVICE',
          );
        }

        return paginatedResponse;
      } else {
        AppLogger.error(
          'Erreur HTTP ${response.statusCode}: ${response.body}',
          tag: 'DEVIS_SERVICE',
        );
        throw Exception(
          'Erreur lors de la récupération paginée des devis: ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erreur dans getDevisPaginated: $e',
        tag: 'DEVIS_SERVICE',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Récupère la première page (délégation vers getDevisPaginated pour compatibilité).
  /// [clientId] : si fourni, ne retourne que les devis de ce client (utilisé par le formulaire bordereau).
  Future<List<Devis>> getDevis({int? status, int? clientId, bool forceRefresh = false}) async {
    final res = await getDevisPaginated(
      status: status,
      clientId: clientId,
      page: 1,
      perPage: 500,
      search: null,
    );
    return res.data;
  }

  Future<Devis> createDevis(Devis devis) async {
    try {
      final devisData = devis.toJson();
      CompanyService.addCompanyIdToBody(devisData);
      final uri = HttpInterceptor.apiUri('devis-create');

      AppLogger.httpRequest('POST', uri.toString(), tag: 'DEVIS_SERVICE');
      AppLogger.debug(
        'Données: ${json.encode(devisData)}',
        tag: 'DEVIS_SERVICE',
      );

      final response = await RetryHelper.retryNetwork(
        operation:
            () => HttpInterceptor.post(
                  uri,
                  headers: ApiService.headers(),
                  body: json.encode(devisData),
                )
                .timeout(
                  AppConfig.defaultTimeout,
                  onTimeout: () =>
                      throw Exception('Timeout: le serveur ne répond pas'),
                ),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(response.statusCode, uri.toString(), tag: 'DEVIS_SERVICE');

      // Gérer les erreurs d'authentification
      await AuthErrorHandler.handleHttpResponse(response);

      if (response.statusCode == 201) {
        try {
          final responseData = json.decode(response.body);
          AppLogger.info('Réponse décodée avec succès', tag: 'DEVIS_SERVICE');

          if (responseData['data'] != null) {
            final createdDevis = Devis.fromJson(responseData['data']);
            AppLogger.info(
              'Devis créé avec ID: ${createdDevis.id}',
              tag: 'DEVIS_SERVICE',
            );
            return createdDevis;
          } else {
            AppLogger.error(
              'Pas de champ "data" dans la réponse',
              tag: 'DEVIS_SERVICE',
            );
            throw Exception('Réponse invalide: pas de champ "data"');
          }
        } catch (e) {
          AppLogger.error(
            'Erreur lors du décodage: $e',
            tag: 'DEVIS_SERVICE',
            error: e,
          );
          throw Exception('Erreur lors du décodage de la réponse: $e');
        }
      } else {
        AppLogger.error(
          'Erreur HTTP ${response.statusCode}: ${response.body}',
          tag: 'DEVIS_SERVICE',
        );
        throw Exception('Erreur HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erreur lors de la création du devis: $e',
        tag: 'DEVIS_SERVICE',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Erreur lors de la création du devis: $e');
    }
  }

  Future<Devis> updateDevis(Devis devis) async {
    try {
      final uri = HttpInterceptor.apiUri('devis-update/${devis.id}');
      AppLogger.httpRequest('PUT', uri.toString(), tag: 'DEVIS_SERVICE');

      final response = await RetryHelper.retryNetwork(
        operation:
            () => HttpInterceptor.put(
                  uri,
                  headers: ApiService.headers(),
                  body: json.encode(devis.toJson()),
                )
                .timeout(
                  AppConfig.defaultTimeout,
                  onTimeout: () =>
                      throw Exception('Timeout: le serveur ne répond pas'),
                ),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(response.statusCode, uri.toString(), tag: 'DEVIS_SERVICE');
      await AuthErrorHandler.handleHttpResponse(response);

      if (response.statusCode == 200) {
        return Devis.fromJson(json.decode(response.body)['data']);
      }
      throw Exception('Erreur lors de la mise à jour du devis');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erreur lors de la mise à jour du devis: $e',
        tag: 'DEVIS_SERVICE',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Erreur lors de la mise à jour du devis: $e');
    }
  }

  Future<bool> deleteDevis(int devisId) async {
    try {
      final token = storage.read('token');
      final url = '${AppConfig.baseUrl}/devis-delete/$devisId';
      AppLogger.httpRequest('DELETE', url, tag: 'DEVIS_SERVICE');

      final response = await RetryHelper.retryNetwork(
        operation:
            () => HttpInterceptor.delete(
              Uri.parse(url),
              headers: {
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
              },
            ),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(response.statusCode, url, tag: 'DEVIS_SERVICE');
      await AuthErrorHandler.handleHttpResponse(response);

      return response.statusCode == 200;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erreur lors de la suppression du devis: $e',
        tag: 'DEVIS_SERVICE',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<bool> sendDevis(int devisId) async {
    try {
      final uri = HttpInterceptor.apiUri('devis/$devisId/send');
      AppLogger.httpRequest('POST', uri.toString(), tag: 'DEVIS_SERVICE');

      final response = await RetryHelper.retryNetwork(
        operation: () => HttpInterceptor.post(uri),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(response.statusCode, uri.toString(), tag: 'DEVIS_SERVICE');
      await AuthErrorHandler.handleHttpResponse(response);

      return response.statusCode == 200;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erreur lors de l\'envoi du devis: $e',
        tag: 'DEVIS_SERVICE',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  // Soumettre un devis au patron pour validation
  Future<bool> submitDevis(int devisId) async {
    try {
      final response = await HttpInterceptor.post(
        HttpInterceptor.apiUri('devis-submit/$devisId'),
      ).timeout(
        AppConfig.defaultTimeout,
        onTimeout: () =>
            throw Exception('Timeout: le serveur ne répond pas'),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> acceptDevis(int devisId) async {
    try {
      final uri = HttpInterceptor.apiUri('devis-validate/$devisId');

      AppLogger.httpRequest('POST', uri.toString(), tag: 'DEVIS_SERVICE');

      final response = await RetryHelper.retryNetwork(
        operation: () => HttpInterceptor.post(uri),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(response.statusCode, uri.toString(), tag: 'DEVIS_SERVICE');

      // Gérer les erreurs d'authentification
      await AuthErrorHandler.handleHttpResponse(response);

      return response.statusCode == 200;
    } catch (e) {
      AppLogger.error(
        'Erreur lors de la validation du devis: $e',
        tag: 'DEVIS_SERVICE',
      );
      return false;
    }
  }

  Future<bool> rejectDevis(int devisId, String commentaire) async {
    try {
      final token = storage.read('token');
      final url = '${AppConfig.baseUrl}/devis-reject/$devisId';
      final body = json.encode({'commentaire': commentaire});

      AppLogger.httpRequest('POST', url, tag: 'DEVIS_SERVICE');

      final response = await RetryHelper.retryNetwork(
        operation:
            () => HttpInterceptor.post(
              Uri.parse(url),
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: body,
            ),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(response.statusCode, url, tag: 'DEVIS_SERVICE');

      // Gérer les erreurs d'authentification
      await AuthErrorHandler.handleHttpResponse(response);

      return response.statusCode == 200;
    } catch (e) {
      AppLogger.error(
        'Erreur lors du rejet du devis: $e',
        tag: 'DEVIS_SERVICE',
      );
      return false;
    }
  }

  Future<String> generatePDF(int devisId) async {
    try {
      final response = await HttpInterceptor.get(
        HttpInterceptor.apiUri('devis/$devisId/pdf'),
      ).timeout(
        AppConfig.defaultTimeout,
        onTimeout:
            () => throw Exception('Timeout: le serveur ne répond pas'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body)['url'];
      }
      throw Exception('Erreur lors de la génération du PDF');
    } catch (e) {
      throw Exception('Erreur lors de la génération du PDF');
    }
  }

  Future<Map<String, dynamic>> getDevisStats() async {
    try {
      final response = await HttpInterceptor.get(
        HttpInterceptor.apiUri('devis/stats'),
      ).timeout(
        AppConfig.defaultTimeout,
        onTimeout:
            () => throw Exception('Timeout: le serveur ne répond pas'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body)['data'];
      }
      throw Exception('Erreur lors de la récupération des statistiques');
    } catch (e) {
      throw Exception('Erreur lors de la récupération des statistiques');
    }
  }

  /// Endpoint de debug pour diagnostiquer les problèmes de chargement
  Future<Map<String, dynamic>> getDevisDebug() async {
    try {
      final userRole = storage.read('userRole');
      final userId = storage.read('userId');

      final uri = HttpInterceptor.apiUri('devis-debug');
      AppLogger.httpRequest('GET', uri.toString(), tag: 'DEVIS_SERVICE_DEBUG');
      AppLogger.info(
        'Debug - User ID: $userId, Role: $userRole',
        tag: 'DEVIS_SERVICE_DEBUG',
      );

      final response = await RetryHelper.retryNetwork(
        operation:
            () => HttpInterceptor.get(uri).timeout(
                  AppConfig.defaultTimeout,
                  onTimeout:
                      () =>
                          throw Exception('Timeout: le serveur ne répond pas'),
                ),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(
        response.statusCode,
        uri.toString(),
        tag: 'DEVIS_SERVICE_DEBUG',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        AppLogger.info(
          'Debug response: ${jsonEncode(data)}',
          tag: 'DEVIS_SERVICE_DEBUG',
        );
        return data;
      } else {
        AppLogger.error(
          'Erreur HTTP ${response.statusCode} dans debug: ${response.body}',
          tag: 'DEVIS_SERVICE_DEBUG',
        );
        throw Exception(
          'Erreur lors de la récupération des informations de debug: ${response.statusCode}',
        );
      }
    } catch (e) {
      AppLogger.error(
        'Erreur dans getDevisDebug: $e',
        tag: 'DEVIS_SERVICE_DEBUG',
      );
      rethrow;
    }
  }

  static void _saveDevisToHive(List<Devis> list, int? status) {
    try {
      final key = '${HiveStorageService.keyDevis}_${status ?? 'all'}';
      HiveStorageService.saveEntityList(
        key,
        list.map((e) => e.toJson()).toList(),
      );
      AppLogger.debug(
        'Hive: Mise à jour cache devis (statut ${status ?? 'all'}), ${list.length} élément(s)',
        tag: 'DEVIS_SERVICE',
      );
    } catch (e) {
      AppLogger.warning('Hive: Erreur sauvegarde devis: $e', tag: 'DEVIS_SERVICE');
    }
  }

  static void saveDevisToHive(List<Devis> list, int? status) {
    _saveDevisToHive(list, status);
  }

  /// Invalide le cache Hive des devis (tous les statuts) après validation/rejet.
  static Future<void> clearDevisHiveCache() async {
    try {
      final keys = [
        '${HiveStorageService.keyDevis}_all',
        '${HiveStorageService.keyDevis}_1',
        '${HiveStorageService.keyDevis}_2',
        '${HiveStorageService.keyDevis}_3',
      ];
      for (final key in keys) {
        await HiveStorageService.clearEntity(key);
      }
      AppLogger.debug('Hive: cache devis invalidé', tag: 'DEVIS_SERVICE');
    } catch (e) {
      AppLogger.warning('Hive: erreur invalidation cache devis: $e', tag: 'DEVIS_SERVICE');
    }
  }

  /// Cache Hive (sync) : affichage instantané Cache-First.
  static List<Devis> getCachedDevis([int? status]) {
    try {
      final key = '${HiveStorageService.keyDevis}_${status ?? 'all'}';
      final raw = HiveStorageService.getEntityList(key);
      if (raw.isNotEmpty) {
        return raw.map((e) => Devis.fromJson(Map<String, dynamic>.from(e))).toList();
      }
      if (status != null) return [];
      final fallback = HiveStorageService.getEntityList(HiveStorageService.keyDevis);
      return fallback.map((e) => Devis.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }
}

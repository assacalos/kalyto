import 'package:http/http.dart' as http;
import 'package:easyconnect/services/http_interceptor.dart';
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/Models/client_model.dart';
import 'package:easyconnect/Models/pagination_response.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/services/api_service.dart';
import 'package:easyconnect/utils/auth_error_handler.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/retry_helper.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/utils/pagination_helper.dart';
import 'package:easyconnect/services/storage_service.dart';
import 'package:easyconnect/services/company_service.dart';

class ClientService {
  final storage = GetStorage();

  Map<String, String> _getHeaders(String? token, {bool isJson = false}) {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (isJson) headers['Content-Type'] = 'application/json; charset=utf-8';
    return headers;
  }

  /// Récupérer les clients avec pagination côté serveur
  /// [timeout] : délai max (défaut 15s). Utiliser [AppConfig.extraLongTimeout] pour la génération PDF.
  Future<PaginationResponse<Client>> getClientsPaginated({
    int? status,
    bool? isPending = false,
    int page = 1,
    int perPage = 15,
    String? search,
    Duration? timeout,
  }) async {
    final effectiveTimeout = timeout ?? AppConfig.defaultTimeout;
    try {
      final token = storage.read('token');
      final userRole = storage.read('userRole');
      final userId = storage.read('userId');

      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      if (status != null) {
        // status=0 (En attente), 1 (Validé), 2 (Rejeté) : le serveur doit recevoir une valeur explicite
        queryParams['status'] = status.toString();
      } else {
        // Mode patron / tous : demander tous les statuts (backend attend include_pending)
        queryParams['include_pending'] = '1';
      }
      if (isPending == true) queryParams['pending'] = 'true';
      if (userRole == 2 && userId != null) queryParams['user_id'] = userId.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      queryParams.addAll(CompanyService.companyQueryParam());

      final uri = Uri.parse('${AppConfig.baseUrl}/clients-list').replace(
        queryParameters: queryParams,
      );
      AppLogger.httpRequest('GET', uri.toString(), tag: 'CLIENT_SERVICE');

      final response = await RetryHelper.retryNetwork(
        operation:
            () => http
                .get(
                  uri,
                  headers: _getHeaders(token as String?),
                )
                .timeout(
                  effectiveTimeout,
                  onTimeout: () =>
                      throw Exception('Timeout: le serveur ne répond pas'),
                ),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(response.statusCode, uri.toString(), tag: 'CLIENT_SERVICE');
      await AuthErrorHandler.handleHttpResponse(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final paginatedResponse = PaginationHelper.parseResponseSafe<Client>(
          json: data,
          fromJsonT: (json) {
            try {
              return Client.fromJson(json);
            } catch (_) {
              return null;
            }
          },
        );
        if (page == 1) _saveClientsToHive(paginatedResponse.data, status);
        return paginatedResponse;
      } else {
        throw Exception(
          'Erreur lors de la récupération paginée des clients: ${response.statusCode}',
        );
      }
    } catch (e) {
      AppLogger.error(
        'Erreur dans getClientsPaginated: $e',
        tag: 'CLIENT_SERVICE',
      );
      rethrow;
    }
  }

  /// Récupère la première page (délégation vers getClientsPaginated pour compatibilité).
  /// [timeout] : utiliser [AppConfig.extraLongTimeout] pour opérations lentes (ex. génération PDF).
  Future<List<Client>> getClients({
    int? status,
    bool? isPending = false,
    bool forceRefresh = false,
    Duration? timeout,
  }) async {
    final res = await getClientsPaginated(
      status: status,
      isPending: isPending,
      page: 1,
      perPage: 500,
      search: null,
      timeout: timeout,
    );
    return res.data;
  }

  // _fetchClientsByStatus supprimé : utiliser getClientsPaginated (getClients délègue à getClientsPaginated).

  Future<Client> createClient(Client client) async {
    try {
      final token = storage.read('token');
      final userId = storage.read('userId');
      final url = '${AppConfig.baseUrl}/clients-create';

      AppLogger.httpRequest('POST', url, tag: 'CLIENT_SERVICE');

      var clientData = client.toJson();
      clientData['user_id'] = userId;
      clientData['status'] = 0; // Toujours en attente à la création
      CompanyService.addCompanyIdToBody(clientData);

      final response = await RetryHelper.retryNetwork(
        operation:
            () => http
                .post(
                  Uri.parse(url),
                  headers: _getHeaders(token as String?, isJson: true),
                  body: json.encode(clientData),
                )
                .timeout(
                  AppConfig.defaultTimeout,
                  onTimeout: () =>
                      throw Exception('Timeout: le serveur ne répond pas'),
                ),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(response.statusCode, url, tag: 'CLIENT_SERVICE');
      await AuthErrorHandler.handleHttpResponse(response);

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        final responseData = result['data'];
        if (responseData != null) {
          AppLogger.info('Client créé avec succès', tag: 'CLIENT_SERVICE');
          return Client.fromJson(responseData);
        }
        // Si pas de data mais success true, le client a été créé
        // On retourne le client original
        return client;
      }

      throw Exception(
        result['message'] ?? 'Erreur lors de la création du client',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erreur lors de la création du client: $e',
        tag: 'CLIENT_SERVICE',
        error: e,
        stackTrace: stackTrace,
      );
      // Si c'est déjà une Exception avec un message, la relancer
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Erreur lors de la création du client: $e');
    }
  }

  Future<Client> updateClient(Client client) async {
    try {
      final token = storage.read('token');
      final body = client.toJson();
      CompanyService.addCompanyIdToBody(body);
      // Backend attend POST pour clients-update (pas PUT)
      final response = await http
          .post(
            Uri.parse('${AppConfig.baseUrl}/clients-update/${client.id}'),
            headers: _getHeaders(token as String?, isJson: true),
            body: json.encode(body),
          )
          .timeout(
            AppConfig.defaultTimeout,
            onTimeout: () =>
                throw Exception('Timeout: le serveur ne répond pas'),
          );

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        return Client.fromJson(result['data']);
      }

      throw Exception(
        result['message'] ?? 'Erreur lors de la mise à jour du client',
      );
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du client');
    }
  }

  Future<bool> approveClient(int clientId) async {
    try {
      final token = storage.read('token');
      final q = CompanyService.companyQueryParam();
      final uri = Uri.parse('${AppConfig.baseUrl}/clients-validate/$clientId').replace(queryParameters: q.isEmpty ? null : q);
      final response = await HttpInterceptor.post(
        uri,
        headers: _getHeaders(token as String?),
      );

      // Si le status code est 200 ou 201, considérer comme succès même si le body dit false
      // (le backend peut retourner success:false mais avoir validé quand même)
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Invalider le cache après validation
        CacheHelper.clearByPrefix('clients_');
        return true;
      }

      // Gérer les erreurs d'authentification seulement si ce n'est pas un succès
      await AuthErrorHandler.handleHttpResponse(response);

      // Utiliser ApiService.parseResponse pour gérer le format standardisé
      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        // Invalider le cache après validation
        CacheHelper.clearByPrefix('clients_');
        return true;
      }

      return false;
    } catch (e) {
      // Si le status code était 200/201, considérer comme succès malgré l'exception
      return false;
    }
  }

  Future<bool> rejectClient(int clientId, String comment) async {
    try {
      final token = storage.read('token');
      final bodyMap = <String, dynamic>{'commentaire': comment};
      CompanyService.addCompanyIdToBody(bodyMap);
      final q = CompanyService.companyQueryParam();
      final uri = Uri.parse('${AppConfig.baseUrl}/clients-reject/$clientId').replace(queryParameters: q.isEmpty ? null : q);
      final response = await HttpInterceptor.post(
        uri,
        headers: _getHeaders(token as String?, isJson: true),
        body: json.encode(bodyMap),
      );

      // Gérer les erreurs d'authentification
      await AuthErrorHandler.handleHttpResponse(response);

      final result = ApiService.parseResponse(response);
      if (result['success'] == true) {
        // Invalider le cache après rejet
        CacheHelper.clearByPrefix('clients_');
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteClient(int clientId) async {
    try {
      final token = storage.read('token');
      final q = CompanyService.companyQueryParam();
      final uri = Uri.parse('${AppConfig.baseUrl}/clients-delete/$clientId').replace(queryParameters: q.isEmpty ? null : q);
      final response = await HttpInterceptor.delete(
        uri,
        headers: _getHeaders(token as String?),
      );

      final result = ApiService.parseResponse(response);
      return result['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getClientStats() async {
    try {
      final token = storage.read('token');
      final q = CompanyService.companyQueryParam();
      final uri = Uri.parse('${AppConfig.baseUrl}/clients/stats').replace(queryParameters: q.isEmpty ? null : q);
      final response = await http
          .get(
            uri,
            headers: _getHeaders(token as String?),
          )
          .timeout(
            AppConfig.defaultTimeout,
            onTimeout: () =>
                throw Exception('Timeout: le serveur ne répond pas'),
          );

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        return result['data'] ?? {};
      }

      throw Exception(
        result['message'] ?? 'Erreur lors de la récupération des statistiques',
      );
    } catch (e) {
      throw Exception('Erreur lors de la récupération des statistiques');
    }
  }

  static void _saveClientsToHive(List<Client> list, int? status) {
    try {
      final key = '${HiveStorageService.keyClients}_${status ?? 'all'}';
      HiveStorageService.saveEntityList(
        key,
        list.map((e) => e.toJson()).toList(),
      );
      AppLogger.debug(
        'Hive: Mise à jour cache clients (statut ${status ?? 'all'}), ${list.length} élément(s)',
        tag: 'CLIENT_SERVICE',
      );
    } catch (e) {
      AppLogger.warning('Hive: Erreur sauvegarde clients: $e', tag: 'CLIENT_SERVICE');
    }
  }

  /// Expose pour le contrôleur : sauvegarder la liste complète en Hive (après création locale).
  static void saveClientsToHive(List<Client> list, int? status) {
    _saveClientsToHive(list, status);
  }

  /// Cache Hive (sync, sans await) : affichage instantané Cache-First.
  static List<Client> getCachedClients([int? status]) {
    try {
      final key = '${HiveStorageService.keyClients}_${status ?? 'all'}';
      final raw = HiveStorageService.getEntityList(key);
      if (raw.isNotEmpty) {
        return raw.map((e) => Client.fromJson(Map<String, dynamic>.from(e))).toList();
      }
      if (status != null) return [];
      final fallback = HiveStorageService.getEntityList(HiveStorageService.keyClients);
      return fallback.map((e) => Client.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }
}

import 'package:http/http.dart' as http;
import 'package:easyconnect/services/session_service.dart';
import 'package:easyconnect/services/api_service.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/utils/auth_error_handler.dart';
import 'package:easyconnect/utils/logger.dart';

/// Intercepteur HTTP pour gérer automatiquement le rafraîchissement du token
/// et les erreurs d'authentification
class HttpInterceptor {
  /// Construit une [Uri] à partir de [AppConfig.baseUrl] et d'un segment de chemin (ex. `clients-list` ou `/quotes`).
  static Uri apiUri(String path) {
    final base = AppConfig.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final p = path.replaceAll(RegExp(r'^/+'), '');
    return Uri.parse('$base/$p');
  }

  /// Intercepte une requête HTTP et gère automatiquement le rafraîchissement du token
  /// en cas d'erreur 401
  static Future<http.Response> interceptRequest(
    Future<http.Response> Function() request, {
    int maxRetries = 1,
  }) async {
    // S'assurer que le token est valide avant la requête
    await SessionService.ensureValidToken();

    // Effectuer la requête
    var response = await request();

    // Si 401, essayer de rafraîchir et réessayer une fois
    if (response.statusCode == 401 && maxRetries > 0) {
      AppLogger.info(
        'Erreur 401 détectée - Tentative de rafraîchissement du token',
        tag: 'HTTP_INTERCEPTOR',
      );

      final refreshed = await SessionService.refreshToken();
      if (refreshed) {
        // Réessayer la requête avec le nouveau token
        AppLogger.info(
          'Token rafraîchi - Nouvelle tentative de la requête',
          tag: 'HTTP_INTERCEPTOR',
        );
        response = await request();
      } else {
        // Si le rafraîchissement échoue, gérer la déconnexion
        AppLogger.warning(
          'Échec du rafraîchissement - Déconnexion requise',
          tag: 'HTTP_INTERCEPTOR',
        );
        await AuthErrorHandler.handleHttpResponse(response);
      }
    }

    return response;
  }

  /// Wrapper pour les requêtes GET
  static Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    int maxRetries = 1,
  }) async {
    return await interceptRequest(
      () => http.get(url, headers: headers ?? ApiService.headers()),
      maxRetries: maxRetries,
    );
  }

  /// Wrapper pour les requêtes POST
  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    int maxRetries = 1,
  }) async {
    return await interceptRequest(
      () =>
          http.post(url, headers: headers ?? ApiService.headers(), body: body),
      maxRetries: maxRetries,
    );
  }

  /// Wrapper pour les requêtes PUT
  static Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    int maxRetries = 1,
  }) async {
    return await interceptRequest(
      () => http.put(url, headers: headers ?? ApiService.headers(), body: body),
      maxRetries: maxRetries,
    );
  }

  /// Wrapper pour les requêtes DELETE
  static Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    int maxRetries = 1,
  }) async {
    return await interceptRequest(
      () => http.delete(
            url,
            headers: headers ?? ApiService.headers(),
            body: body,
          ),
      maxRetries: maxRetries,
    );
  }

  /// Wrapper pour les requêtes PATCH
  static Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    int maxRetries = 1,
  }) async {
    return await interceptRequest(
      () =>
          http.patch(url, headers: headers ?? ApiService.headers(), body: body),
      maxRetries: maxRetries,
    );
  }
}

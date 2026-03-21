import 'dart:io';
import 'package:http/http.dart' as http;

class CustomHttpClient {
  static const Duration _defaultTimeout = Duration(seconds: 15);
  static const Duration _longTimeout = Duration(seconds: 30);

  // Client HTTP avec timeout court pour les requêtes rapides
  static Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    return await http
        .get(url, headers: headers)
        .timeout(
          timeout ?? _defaultTimeout,
          onTimeout: () {
            throw SocketException('Timeout: Connexion trop lente');
          },
        );
  }

  // Client HTTP avec timeout long pour les requêtes lourdes
  static Future<http.Response> getLong(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    return await http
        .get(url, headers: headers)
        .timeout(
          _longTimeout,
          onTimeout: () {
            throw SocketException('Timeout: Connexion trop lente');
          },
        );
  }

  // Client HTTP POST avec timeout
  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
  }) async {
    return await http
        .post(url, headers: headers, body: body)
        .timeout(
          timeout ?? _defaultTimeout,
          onTimeout: () {
            throw SocketException('Timeout: Connexion trop lente');
          },
        );
  }

  // Client HTTP POST avec timeout long
  static Future<http.Response> postLong(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return await http
        .post(url, headers: headers, body: body)
        .timeout(
          _longTimeout,
          onTimeout: () {
            throw SocketException('Timeout: Connexion trop lente');
          },
        );
  }

  // Test de connectivité simple
  static Future<bool> testConnection(String baseUrl) async {
    try {
      final response = await get(
        Uri.parse('$baseUrl/api/attendance/test'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        timeout: const Duration(seconds: 5),
      );
      return response.statusCode == 200 ||
          response.statusCode ==
              401; // 401 = serveur accessible mais auth requise
    } catch (e) {
      return false;
    }
  }

  // Test de connectivité avec diagnostic détaillé
  static Future<Map<String, dynamic>> testConnectionDetailed(
    String baseUrl,
  ) async {
    try {
      // Test 1: Connexion de base
      final response = await get(
        Uri.parse('$baseUrl/api/attendance/test'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        timeout: const Duration(seconds: 5),
      );

      return {
        'success': true,
        'statusCode': response.statusCode,
        'body': response.body,
        'message': 'Serveur accessible',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Serveur inaccessible',
      };
    }
  }
}

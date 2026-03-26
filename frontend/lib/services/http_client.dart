import 'dart:io';
import 'package:easyconnect/services/http_interceptor.dart';
import 'package:http/http.dart' as http;

/// Client HTTP léger : délègue à [HttpInterceptor] (headers [ApiService], refresh token sur 401).
class CustomHttpClient {
  static const Duration _defaultTimeout = Duration(seconds: 15);
  static const Duration _longTimeout = Duration(seconds: 30);

  static Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    return await HttpInterceptor.get(url, headers: headers).timeout(
      timeout ?? _defaultTimeout,
      onTimeout: () {
        throw SocketException('Timeout: Connexion trop lente');
      },
    );
  }

  static Future<http.Response> getLong(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    return await HttpInterceptor.get(url, headers: headers).timeout(
      _longTimeout,
      onTimeout: () {
        throw SocketException('Timeout: Connexion trop lente');
      },
    );
  }

  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
  }) async {
    return await HttpInterceptor.post(url, headers: headers, body: body)
        .timeout(
      timeout ?? _defaultTimeout,
      onTimeout: () {
        throw SocketException('Timeout: Connexion trop lente');
      },
    );
  }

  static Future<http.Response> postLong(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return await HttpInterceptor.post(url, headers: headers, body: body)
        .timeout(
      _longTimeout,
      onTimeout: () {
        throw SocketException('Timeout: Connexion trop lente');
      },
    );
  }

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

  static Future<Map<String, dynamic>> testConnectionDetailed(
    String baseUrl,
  ) async {
    try {
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

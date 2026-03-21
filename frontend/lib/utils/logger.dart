import 'dart:developer' as developer;

/// Système de logging professionnel pour l'application
class AppLogger {
  static const bool _isDebugMode = true; // À changer en false pour production

  /// Log d'information
  static void info(String message, {String? tag}) {
    if (_isDebugMode) {
      developer.log(message, name: tag ?? 'APP', level: 0);
    }
  }

  /// Log d'avertissement
  static void warning(String message, {String? tag, Object? error}) {
    if (_isDebugMode) {
      developer.log(message, name: tag ?? 'APP', level: 1, error: error);
    }
  }

  /// Log d'erreur
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: tag ?? 'APP',
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log de débogage
  static void debug(String message, {String? tag}) {
    if (_isDebugMode) {
      developer.log(message, name: tag ?? 'APP', level: 500);
    }
  }

  /// Log de requête HTTP
  static void httpRequest(
    String method,
    String url, {
    Map<String, dynamic>? headers,
    dynamic body,
    String? tag,
  }) {
    if (_isDebugMode) {
      developer.log('$method $url', name: tag ?? 'HTTP', level: 0);
    }
  }

  /// Log de réponse HTTP
  static void httpResponse(
    int statusCode,
    String url, {
    String? body,
    String? tag,
  }) {
    developer.log(
      'Response $statusCode for $url',
      name: tag ?? 'HTTP',
      level: statusCode >= 400 ? 1000 : 0,
    );
  }
}

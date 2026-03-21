import 'dart:async';
import 'dart:math';

/// Helper pour gérer les tentatives de retry avec backoff exponentiel
class RetryHelper {
  /// Exécute une fonction avec retry automatique
  ///
  /// [maxRetries] : Nombre maximum de tentatives (défaut: 3)
  /// [initialDelay] : Délai initial avant le premier retry (défaut: 1 seconde)
  /// [maxDelay] : Délai maximum entre les tentatives (défaut: 30 secondes)
  /// [backoffFactor] : Facteur d'augmentation du délai (défaut: 2.0)
  /// [retryIf] : Fonction pour déterminer si on doit retry (défaut: retry sur toutes les exceptions)
  static Future<T> retry<T>({
    required Future<T> Function() operation,
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    Duration maxDelay = const Duration(seconds: 30),
    double backoffFactor = 2.0,
    bool Function(Object)? retryIf,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (attempt < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempt++;

        // Vérifier si on doit retry
        if (retryIf != null && !retryIf(e)) {
          rethrow;
        }

        // Si c'est la dernière tentative, relancer l'erreur
        if (attempt >= maxRetries) {
          rethrow;
        }

        // Attendre avant de réessayer avec backoff exponentiel
        await Future.delayed(delay);

        // Calculer le prochain délai avec backoff exponentiel
        delay = Duration(
          milliseconds: min(
            (delay.inMilliseconds * backoffFactor).round(),
            maxDelay.inMilliseconds,
          ),
        );
      }
    }

    throw Exception('Retry failed after $maxRetries attempts');
  }

  /// Retry spécifique pour les erreurs réseau
  static Future<T> retryNetwork<T>({
    required Future<T> Function() operation,
    int maxRetries = 3,
  }) async {
    return retry(
      operation: operation,
      maxRetries: maxRetries,
      retryIf: (error) {
        final errorString = error.toString().toLowerCase();
        return errorString.contains('socketexception') ||
            errorString.contains('timeout') ||
            errorString.contains('connection') ||
            errorString.contains('network');
      },
    );
  }
}

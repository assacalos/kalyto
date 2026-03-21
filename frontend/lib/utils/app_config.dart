import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

/// Configuration centralisée de l'application
class AppConfig {
  static final _storage = GetStorage();

  // URLs (pour déploiement cPanel : flutter build web --dart-define=PRODUCTION_URL=https://votredomaine.com/api)
  /// URL locale : localhost pour le web (Chrome), 10.0.2.2 pour l'émulateur Android
  static String get _localBaseUrl =>
      kIsWeb ? 'http://localhost:8000/api' : 'http://10.0.2.2:8000/api';
  static String get _productionBaseUrl =>
      const String.fromEnvironment('PRODUCTION_URL', defaultValue: 'https://kalyto.smil-app.com/api');
  /// Clé Pusher – ne pas mettre de secret en dur. Build : `--dart-define=PUSHER_APP_KEY=xxx`
  static String get websocketKey =>
      const String.fromEnvironment('PUSHER_APP_KEY', defaultValue: '');
  /// Cluster Pusher – doit correspondre à PUSHER_APP_CLUSTER. Build avec --dart-define=PUSHER_APP_CLUSTER=eu si besoin.
  static String get websocketCluster =>
      const String.fromEnvironment('PUSHER_APP_CLUSTER', defaultValue: 'eu');

  /// Clé VAPID (Web Push) pour FCM sur le web. À générer dans Firebase Console → Paramètres du projet → Cloud Messaging → Certificats Web Push.
  /// Build : --dart-define=FIREBASE_WEB_VAPID_KEY=VOTRE_CLE_VAPID ou définir ici en dur pour la prod.
  static String get firebaseWebVapidKey =>
      const String.fromEnvironment('FIREBASE_WEB_VAPID_KEY', defaultValue: '');

  /// Récupère l'URL de base de l'API
  /// - En mode debug (flutter run -d chrome / run) → API locale (localhost ou 10.0.2.2)
  /// - En release/build → production, sauf si URL personnalisée ou FORCE_PRODUCTION_URL=false
  static String get baseUrl {
    // 1. URL personnalisée stockée (Paramètres app) a la priorité
    final customUrl = _storage.read<String>('api_base_url');
    if (customUrl != null && customUrl.isNotEmpty) {
      return customUrl;
    }

    // 2. En build/release, forcer la prod si demandé
    const bool forceProduction = bool.fromEnvironment(
      'FORCE_PRODUCTION_URL',
      defaultValue: false,
    );
    if (forceProduction) {
      return _productionBaseUrl;
    }

    // 3. En mode debug → API locale (BD locale avec flutter run -d chrome)
    if (kDebugMode) {
      return _localBaseUrl;
    }

    // 4. Release / profile → production
    return _productionBaseUrl;
  }

  /// URL racine du serveur (sans /api). Utilisée pour l'auth broadcasting Laravel (/broadcasting/auth).
  static String get baseUrlWithoutApi {
    final url = baseUrl;
    if (url.endsWith('/api')) return url.substring(0, url.length - 4);
    if (url.endsWith('/api/')) return url.substring(0, url.length - 5);
    return url;
  }

  /// true si le WebSocket (Pusher) est activé. En production la clé est définie → connexion active.
  static bool get websocketEnabled =>
      websocketKey.isNotEmpty && websocketKey.length > 5;

  /// Retourne l'URL de production
  static String get productionUrl => _productionBaseUrl;

  /// Retourne l'URL locale (pour développement)
  static String get localUrl => _localBaseUrl;

  /// Vérifie quelle URL est actuellement utilisée
  static String getCurrentUrlInfo() {
    final currentUrl = baseUrl;
    if (currentUrl == _productionBaseUrl) {
      return 'Production: $_productionBaseUrl';
    } else if (currentUrl == _localBaseUrl) {
      return 'Locale: $_localBaseUrl';
    } else {
      return 'Personnalisée: $currentUrl';
    }
  }

  /// Définit l'URL de base de l'API
  static Future<void> setBaseUrl(String url) async {
    await _storage.write('api_base_url', url);
  }

  /// Réinitialise l'URL à la valeur par défaut
  static Future<void> resetBaseUrl() async {
    await _storage.remove('api_base_url');
  }

  // Timeouts
  static const Duration defaultTimeout = Duration(seconds: 15);
  static const Duration longTimeout = Duration(seconds: 30);
  /// Timeout étendu pour endpoints lents (ex. liste employés sur serveur distant)
  static const Duration extraLongTimeout = Duration(seconds: 60);
  static const Duration shortTimeout = Duration(seconds: 5);

  // Retry
  static const int defaultMaxRetries = 3;
  static const Duration retryInitialDelay = Duration(seconds: 1);
  static const Duration retryMaxDelay = Duration(seconds: 30);

  // Cache (stratégie : court = listes/compteurs, moyen = employés/fournisseurs, long = référentiels)
  static const Duration defaultCacheDuration = Duration(minutes: 5);
  static const Duration mediumCacheDuration = Duration(minutes: 15);
  static const Duration longCacheDuration = Duration(hours: 1);

  // Pagination
  static const int defaultPageSize = 20;
  static const int largePageSize = 50;

  // Version
  static const String appVersion = '1.0.0';
  static const String appName = 'Kalyto';

  // Affichage des erreurs
  /// Masquer les messages d'erreur techniques aux utilisateurs finaux
  /// En production, les erreurs techniques ne sont pas affichées
  static bool get showErrorMessagesToUsers {
    // En mode debug, on peut afficher les erreurs pour le développement
    // En production (release), on masque les erreurs techniques
    return kDebugMode;
  }

  /// Retourne un message utilisateur-friendly pour les erreurs
  static String getUserFriendlyErrorMessage(dynamic error) {
    // Ne jamais afficher les détails techniques aux utilisateurs
    if (!showErrorMessagesToUsers) {
      // Messages génériques pour les utilisateurs finaux
      final errorString = error.toString().toLowerCase();

      if (errorString.contains('timeout') ||
          errorString.contains('timed out')) {
        return 'Connexion lente. Veuillez réessayer.';
      }
      if (errorString.contains('network') ||
          errorString.contains('connection')) {
        return 'Problème de connexion. Vérifiez votre internet.';
      }
      if (errorString.contains('404') || errorString.contains('not found')) {
        return 'Ressource introuvable.';
      }
      if (errorString.contains('500') || errorString.contains('server')) {
        return 'Erreur serveur. Réessayez plus tard.';
      }
      if (errorString.contains('401') || errorString.contains('unauthorized')) {
        return 'Session expirée. Veuillez vous reconnecter.';
      }
      if (errorString.contains('403') || errorString.contains('forbidden')) {
        return 'Accès refusé.';
      }
      if (errorString.contains('422') || errorString.contains('validation')) {
        return 'Données invalides. Vérifiez vos saisies.';
      }

      // Message générique par défaut
      return 'Une erreur est survenue. Veuillez réessayer.';
    }

    // En mode debug, on peut afficher l'erreur complète
    return error.toString();
  }
}

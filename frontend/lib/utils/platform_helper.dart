import 'package:flutter/foundation.dart' show kIsWeb;

/// Helper pour détecter la plateforme et adapter les fonctionnalités
class PlatformHelper {
  /// Retourne true si l'application tourne sur le web
  static bool get isWeb => kIsWeb;

  /// Retourne true si l'application tourne sur mobile (Android/iOS)
  static bool get isMobile => !kIsWeb;

  /// Vérifier si la caméra est supportée (limitée sur web)
  static bool get supportsCamera => !kIsWeb;

  /// Vérifier si les notifications locales sont supportées
  static bool get supportsLocalNotifications => !kIsWeb;

  /// Vérifier si la géolocalisation est supportée (nécessite HTTPS sur web)
  static bool get supportsGeolocation => true;

  /// Vérifier si le stockage de fichiers local est supporté
  static bool get supportsFileSystem => !kIsWeb;

  /// Obtenir le nom de la plateforme actuelle
  static String get platformName {
    if (kIsWeb) return 'Web';
    return 'Mobile';
  }

  /// Logger les informations de plateforme
  static void logPlatformInfo() {
    print('=== Platform Info ===');
    print('Platform: $platformName');
    print('Is Web: $isWeb');
    print('Supports Camera: $supportsCamera');
    print('Supports Local Notifications: $supportsLocalNotifications');
    print('Supports Geolocation: $supportsGeolocation');
    print('Supports File System: $supportsFileSystem');
    print('====================');
  }
}

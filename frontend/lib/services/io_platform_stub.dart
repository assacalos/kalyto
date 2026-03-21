/// Stub pour remplacer dart:io Platform sur la plateforme web.
/// Ne pas utiliser dart:io sur le web (non disponible).
class Platform {
  static bool get isAndroid => false;
  static bool get isIOS => false;
}

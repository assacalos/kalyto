/// Helper pour accéder aux contrôleurs de façon sécurisée.
/// Sans Get : findOrNull retourne null, require lance une erreur.
/// Préférer Riverpod (ref.read(provider)) à la place.
class ControllerHelper {
  ControllerHelper._();

  static T? findOrNull<T>() {
    return null;
  }

  static T require<T>() {
    throw StateError(
      'Contrôleur $T non disponible. Utilisez Riverpod ref.read(provider) à la place.',
    );
  }
}

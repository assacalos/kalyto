import 'package:url_launcher/url_launcher.dart';

class MapHelper {
  /// Ouvre Google Maps avec les coordonnées spécifiées
  static Future<void> openGoogleMaps({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    try {
      // URL pour Google Maps - format simplifié et plus fiable
      final String googleMapsUrl;

      // Construire l'URL avec les coordonnées (format simple et fiable)
      googleMapsUrl =
          'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

      final Uri uri = Uri.parse(googleMapsUrl);

      // Essayer d'abord d'ouvrir avec l'application Google Maps si disponible
      try {
        // URL pour l'application Google Maps (Android)
        final String androidAppUrl = 'google.navigation:q=$latitude,$longitude';
        final Uri androidAppUri = Uri.parse(androidAppUrl);

        if (await canLaunchUrl(androidAppUri)) {
          await launchUrl(androidAppUri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (e) {
        // Si l'app n'est pas disponible, continuer avec l'URL web
      }

      // Essayer aussi avec le format geo: (fallback)
      try {
        final String geoUrl = 'geo:$latitude,$longitude?q=$latitude,$longitude';
        final Uri geoUri = Uri.parse(geoUrl);

        if (await canLaunchUrl(geoUri)) {
          await launchUrl(geoUri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (e) {
        // Si le format geo: n'est pas disponible, continuer avec l'URL web
      }

      // Ouvrir dans le navigateur web ou l'application par défaut
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception(
          'Impossible d\'ouvrir Google Maps. Vérifiez votre connexion internet.',
        );
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'ouverture de Google Maps: $e');
    }
  }

  /// Ouvre Google Maps avec une adresse (géocodage)
  static Future<void> openGoogleMapsWithAddress(String address) async {
    try {
      final String googleMapsUrl =
          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}';

      final Uri uri = Uri.parse(googleMapsUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Impossible d\'ouvrir Google Maps');
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'ouverture de Google Maps: $e');
    }
  }
}

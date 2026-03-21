import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Vérifier et demander les permissions
  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status == PermissionStatus.granted;
  }

  // Vérifier si la localisation est activée
  Future<bool> isLocationEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Obtenir la position actuelle
  Future<Position?> getCurrentPosition() async {
    try {
      // Vérifier les permissions
      if (!await requestLocationPermission()) {
        throw Exception('Permission de localisation refusée');
      }

      // Vérifier si la localisation est activée
      if (!await isLocationEnabled()) {
        throw Exception('Service de localisation désactivé');
      }

      // Obtenir la position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return position;
    } catch (e) {
      return null;
    }
  }

  // Obtenir l'adresse à partir des coordonnées
  Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return '${place.street}, ${place.locality}, ${place.administrativeArea}';
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Calculer la distance entre deux points
  double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  // Vérifier si l'utilisateur est dans une zone autorisée
  Future<bool> isInAllowedZone(
    double userLat,
    double userLng,
    double allowedLat,
    double allowedLng,
    double radiusMeters,
  ) async {
    final distance = calculateDistance(
      userLat,
      userLng,
      allowedLat,
      allowedLng,
    );
    return distance <= radiusMeters;
  }

  // Obtenir les informations de localisation complètes
  Future<LocationInfo?> getLocationInfo() async {
    try {
      final position = await getCurrentPosition();
      if (position == null) return null;

      final address = await getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      return LocationInfo(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address ?? 'Adresse inconnue',
        accuracy: position.accuracy,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }
}

class LocationInfo {
  final double latitude;
  final double longitude;
  final String address;
  final double accuracy;
  final DateTime timestamp;

  LocationInfo({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.accuracy,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory LocationInfo.fromJson(Map<String, dynamic> json) {
    return LocationInfo(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      address: json['address'] ?? '',
      accuracy: json['accuracy']?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

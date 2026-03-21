import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  final ImagePicker _picker = ImagePicker();

  // Vérifier et demander les permissions caméra
  Future<bool> requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      if (status.isDenied) {
        // Permission refusée, demander à nouveau
        final reRequest = await Permission.camera.request();
        return reRequest.isGranted;
      }
      return status.isGranted;
    } catch (e) {
      debugPrint(
        '❌ [CameraService] Erreur lors de la demande de permission caméra: $e',
      );
      return false;
    }
  }

  // Vérifier et demander les permissions de stockage (compatible Android 13+)
  Future<bool> requestStoragePermission() async {
    try {
      // Pour Android 13+ (API 33+), utiliser READ_MEDIA_IMAGES
      // Pour les versions antérieures, utiliser READ_EXTERNAL_STORAGE
      if (Platform.isAndroid) {
        // Vérifier d'abord si on a déjà la permission
        if (await Permission.photos.isGranted) {
          return true;
        }
        if (await Permission.storage.isGranted) {
          return true;
        }

        // Demander la permission appropriée
        PermissionStatus status;
        try {
          // Essayer d'abord READ_MEDIA_IMAGES (Android 13+)
          status = await Permission.photos.request();
          if (status.isGranted) {
            return true;
          }
        } catch (e) {
          // Si READ_MEDIA_IMAGES n'est pas disponible, utiliser READ_EXTERNAL_STORAGE
          debugPrint(
            '⚠️ [CameraService] READ_MEDIA_IMAGES non disponible, utilisation de READ_EXTERNAL_STORAGE',
          );
        }

        // Fallback sur READ_EXTERNAL_STORAGE pour Android < 13
        status = await Permission.storage.request();
        if (status.isDenied) {
          // Permission refusée, demander à nouveau
          final reRequest = await Permission.storage.request();
          return reRequest.isGranted;
        }
        return status.isGranted;
      } else if (Platform.isIOS) {
        // Pour iOS, utiliser photos
        final status = await Permission.photos.request();
        if (status.isDenied) {
          final reRequest = await Permission.photos.request();
          return reRequest.isGranted;
        }
        return status.isGranted;
      }
      return false;
    } catch (e) {
      debugPrint(
        '❌ [CameraService] Erreur lors de la demande de permission stockage: $e',
      );
      return false;
    }
  }

  // Prendre une photo avec la caméra
  Future<File?> takePicture() async {
    try {
      // Vérifier les permissions
      final hasPermission = await requestCameraPermission();
      if (!hasPermission) {
        throw Exception(
          'Permission caméra refusée. Veuillez autoriser l\'accès à la caméra dans les paramètres de l\'application.',
        );
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        final file = File(image.path);
        // Vérifier que le fichier existe
        if (await file.exists()) {
          return file;
        } else {
          throw Exception('Le fichier image n\'existe pas: ${image.path}');
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ [CameraService] Erreur lors de la prise de photo: $e');
      rethrow; // Propager l'erreur au lieu de retourner null silencieusement
    }
  }

  // Sélectionner une image depuis la galerie
  Future<File?> pickImageFromGallery() async {
    try {
      // Vérifier les permissions
      final hasPermission = await requestStoragePermission();
      if (!hasPermission) {
        throw Exception(
          'Permission d\'accès aux photos refusée. Veuillez autoriser l\'accès aux photos dans les paramètres de l\'application.',
        );
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        final file = File(image.path);
        // Vérifier que le fichier existe
        if (await file.exists()) {
          return file;
        } else {
          throw Exception('Le fichier image n\'existe pas: ${image.path}');
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ [CameraService] Erreur lors de la sélection d\'image: $e');
      rethrow; // Propager l'erreur au lieu de retourner null silencieusement
    }
  }

  // Vérifier la taille du fichier
  bool isFileSizeValid(File file, {int maxSizeMB = 2}) {
    final fileSize = file.lengthSync();
    final maxSizeBytes = maxSizeMB * 1024 * 1024;
    return fileSize <= maxSizeBytes;
  }

  // Vérifier le type de fichier
  bool isImageFile(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png'].contains(extension);
  }

  // Valider une image
  Future<bool> validateImage(File file) async {
    if (!isImageFile(file)) {
      throw Exception(
        'Format de fichier non supporté. Utilisez JPG, JPEG ou PNG.',
      );
    }

    if (!isFileSizeValid(file)) {
      throw Exception('Fichier trop volumineux. Taille maximale: 2MB.');
    }

    return true;
  }

  // Obtenir les métadonnées d'une image
  Future<ImageMetadata> getImageMetadata(File file) async {
    final stat = file.statSync();
    return ImageMetadata(
      path: file.path,
      size: stat.size,
      modified: stat.modified,
      created: stat.changed,
    );
  }
}

class ImageMetadata {
  final String path;
  final int size;
  final DateTime modified;
  final DateTime created;

  ImageMetadata({
    required this.path,
    required this.size,
    required this.modified,
    required this.created,
  });

  String get sizeFormatted {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String get fileName {
    return path.split('/').last;
  }

  String get fileExtension {
    return path.split('.').last.toLowerCase();
  }
}

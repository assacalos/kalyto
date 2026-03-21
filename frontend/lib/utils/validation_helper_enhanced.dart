import 'package:flutter/material.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/app_config.dart';

/// Callback pour afficher un snackbar (défini par l'app).
void Function(String title, String message,
    {Color? backgroundColor, Color? colorText, Duration? duration})?
    validationHelperEnhancedShowSnackbar;

/// Helper amélioré pour la validation des formulaires
class ValidationHelperEnhanced {
  /// Valide un email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'email est requis';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Format d\'email invalide';
    }
    return null;
  }

  /// Valide un numéro de téléphone
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le numéro de téléphone est requis';
    }
    final phoneRegex = RegExp(r'^[0-9+\-\s()]+$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Format de téléphone invalide';
    }
    return null;
  }

  /// Valide un champ requis
  static String? validateRequired(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Ce champ'} est requis';
    }
    return null;
  }

  /// Valide un nombre
  static String? validateNumber(
    String? value, {
    double? min,
    double? max,
    String? fieldName,
  }) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Ce champ'} est requis';
    }
    final number = double.tryParse(value);
    if (number == null) {
      return '${fieldName ?? 'Ce champ'} doit être un nombre';
    }
    if (min != null && number < min) {
      return '${fieldName ?? 'Ce champ'} doit être supérieur ou égal à $min';
    }
    if (max != null && number > max) {
      return '${fieldName ?? 'Ce champ'} doit être inférieur ou égal à $max';
    }
    return null;
  }

  /// Valide une date
  static String? validateDate(DateTime? value, {String? fieldName}) {
    if (value == null) {
      return '${fieldName ?? 'La date'} est requise';
    }
    return null;
  }

  /// Valide une date future
  static String? validateFutureDate(DateTime? value, {String? fieldName}) {
    final baseError = validateDate(value, fieldName: fieldName);
    if (baseError != null) return baseError;
    if (value!.isBefore(DateTime.now())) {
      return '${fieldName ?? 'La date'} doit être dans le futur';
    }
    return null;
  }

  /// Valide le NINEA (numéro d'identification ivoirien) : exactement 9 chiffres.
  /// Si [required] est false, le champ peut être vide (optionnel).
  static String? validateNinea(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      if (required) return 'Le NINEA est requis';
      return null;
    }
    final digitsOnly = value.replaceAll(RegExp(r'\s'), '');
    if (digitsOnly.length != 9) {
      return 'Le NINEA doit contenir exactement 9 chiffres';
    }
    if (!RegExp(r'^\d{9}$').hasMatch(digitsOnly)) {
      return 'Le NINEA ne doit contenir que des chiffres';
    }
    return null;
  }

  /// Valide une longueur de texte
  static String? validateLength(
    String? value, {
    int? min,
    int? max,
    String? fieldName,
  }) {
    if (value == null) {
      return '${fieldName ?? 'Ce champ'} est requis';
    }
    if (min != null && value.length < min) {
      return '${fieldName ?? 'Ce champ'} doit contenir au moins $min caractères';
    }
    if (max != null && value.length > max) {
      return '${fieldName ?? 'Ce champ'} doit contenir au plus $max caractères';
    }
    return null;
  }

  /// Affiche une erreur de validation
  static void showValidationError(String message, {bool showToUser = true}) {
    AppLogger.warning('Validation error: $message');

    // Les erreurs de validation peuvent être affichées car elles sont utilisateur-friendly
    if (!showToUser && !AppConfig.showErrorMessagesToUsers) {
      return;
    }

    validationHelperEnhancedShowSnackbar?.call(
      'Erreur de validation',
      message,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  static void showSuccess(String message) {
    AppLogger.info('Success: $message');
    validationHelperEnhancedShowSnackbar?.call(
      'Succès',
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }
}

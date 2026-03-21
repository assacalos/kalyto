import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/utils/logger.dart';

/// Callback pour afficher un snackbar (défini par l'app, ex: ScaffoldMessenger).
void Function(String title, String message,
    {Color? backgroundColor,
    Color? colorText,
    Duration? duration,
    Icon? icon})? errorHelperShowSnackbar;

/// Helper pour gérer l'affichage des erreurs aux utilisateurs
class ErrorHelper {
  static void showError(
    dynamic error, {
    String? title,
    String? customMessage,
    bool showToUser = false,
    Duration? duration,
    bool ignorePostSuccess = false,
  }) {
    AppLogger.error(
      'Error: $error',
      tag: 'ERROR_HELPER',
      error: error is Exception ? error : Exception(error.toString()),
    );

    if (!ignorePostSuccess && isPostSuccessError(error)) {
      AppLogger.debug('Erreur post-succès ignorée: $error', tag: 'ERROR_HELPER');
      return;
    }

    if (!showToUser && !AppConfig.showErrorMessagesToUsers) return;

    final message = customMessage ??
        (AppConfig.showErrorMessagesToUsers
            ? error.toString()
            : AppConfig.getUserFriendlyErrorMessage(error));

    if (kDebugMode || showToUser) {
      errorHelperShowSnackbar?.call(
        title ?? 'Erreur',
        message,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: duration ?? const Duration(seconds: 3),
      );
    }
  }

  static void showValidationError(String message) {
    errorHelperShowSnackbar?.call(
      'Erreur de validation',
      message,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  static void showSuccess(String message, {String? title}) {
    errorHelperShowSnackbar?.call(
      title ?? 'Succès',
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  static void showInfo(String message, {String? title}) {
    errorHelperShowSnackbar?.call(
      title ?? 'Information',
      message,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  static bool isPostSuccessError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('parsing') ||
        errorStr.contains('json') ||
        errorStr.contains('type') ||
        errorStr.contains('cast') ||
        errorStr.contains('null') ||
        errorStr.contains('no such method') ||
        errorStr.contains('method not found');
  }

  static void showErrorIfNotPostSuccess(
    dynamic error, {
    String? title,
    String? customMessage,
    bool forceShow = false,
  }) {
    if (isPostSuccessError(error)) {
      AppLogger.debug('Erreur post-succès ignorée: $error', tag: 'ERROR_HELPER');
      return;
    }
    showError(
      error,
      title: title,
      customMessage: customMessage,
      showToUser: forceShow || kDebugMode,
      ignorePostSuccess: true,
    );
  }

  static void showErrorDebugOnly(
    dynamic error, {
    String? title,
    String? customMessage,
  }) {
    AppLogger.error(
      'Error (debug only): $error',
      tag: 'ERROR_HELPER',
      error: error is Exception ? error : Exception(error.toString()),
    );
    if (kDebugMode) {
      final message = customMessage ?? error.toString();
      errorHelperShowSnackbar?.call(
        title ?? 'Erreur (Debug)',
        message,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }
}

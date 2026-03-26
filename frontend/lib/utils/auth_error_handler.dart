import 'package:flutter/foundation.dart';
import 'package:easyconnect/services/session_service.dart';
import 'package:http/http.dart' as http;
import 'package:easyconnect/utils/logger.dart';

/// Helper centralisé pour gérer les erreurs d'authentification
/// Utilise des callbacks pour la déconnexion et l'affichage (plus de Get).
class AuthErrorHandler {
  static bool _isHandlingLogout = false;

  /// Callback pour effectuer la déconnexion (à définir par l'app, ex: ref.read(authProvider.notifier).logout).
  static Future<void> Function({bool silent, String? redirectTo})? logoutCallback;

  /// Callback pour récupérer la route actuelle (ex: go_router).
  static String Function()? currentRouteCallback;

  /// Callback pour afficher un snackbar (ex: ScaffoldMessenger).
  static void Function(String title, String message, {Duration? duration})? showSnackbarCallback;

  static Future<void> handleHttpResponse(
    http.Response response, {
    bool skipRefresh = false,
  }) async {
    if (response.statusCode == 401) {
      if (SessionService.isWithinGracePeriodAfterLogin()) {
        AppLogger.info(
          '401 ignoré (période de grâce après connexion)',
          tag: 'AUTH_ERROR_HANDLER',
        );
        return;
      }
      if (!skipRefresh) {
        try {
          final refreshed = await SessionService.refreshToken();
          if (refreshed) {
            AppLogger.info(
              'Token rafraîchi avec succès après erreur 401',
              tag: 'AUTH_ERROR_HANDLER',
            );
            return;
          }
        } catch (e) {
          AppLogger.warning(
            'Erreur lors du rafraîchissement: $e',
            tag: 'AUTH_ERROR_HANDLER',
          );
        }
      }
      await _handleUnauthorized();
    }
  }

  static Future<void> handleException(dynamic error) async {
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('401') ||
        errorString.contains('unauthorized') ||
        errorString.contains('non autorisé')) {
      if (SessionService.isWithinGracePeriodAfterLogin()) {
        AppLogger.info(
          'Erreur auth ignorée (période de grâce après connexion)',
          tag: 'AUTH_ERROR_HANDLER',
        );
        return;
      }
      await _handleUnauthorized();
    }
  }

  static Future<void> _handleUnauthorized({bool? showMessage}) async {
    if (_isHandlingLogout) return;
    _isHandlingLogout = true;

    try {
      await Future.delayed(const Duration(milliseconds: 100));

      final route = currentRouteCallback?.call() ?? '';
      final isOnAuthPage = route == '/welcome' ||
          route == '/login' ||
          route == '/register' ||
          route.contains('welcome') ||
          route.contains('login') ||
          route.contains('register');
      final isOnSplash = route == '/splash' || route.contains('splash');
      final shouldShowMessage = isOnAuthPage
          ? false
          : (showMessage ?? kDebugMode);

      if (shouldShowMessage && showSnackbarCallback != null) {
        showSnackbarCallback!(
          'Session expirée',
          'Votre session a expiré. Veuillez vous reconnecter.',
          duration: const Duration(seconds: 3),
        );
        await Future.delayed(const Duration(milliseconds: 500));
      }

      final String? redirectTo = isOnAuthPage
          ? null
          : (isOnSplash ? '/welcome' : '/login');

      if (logoutCallback != null) {
        AppLogger.warning(
          'Session expirée - Déconnexion automatique',
          tag: 'AUTH_ERROR_HANDLER',
        );
        await logoutCallback!(silent: !shouldShowMessage, redirectTo: redirectTo);
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erreur lors de la gestion de la déconnexion: $e',
        tag: 'AUTH_ERROR_HANDLER',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      Future.delayed(const Duration(seconds: 2), () {
        _isHandlingLogout = false;
      });
    }
  }

  static bool shouldIgnoreError(dynamic error) =>
      _isHandlingLogout;

  static Future<bool> checkResponse(http.Response response) async {
    await handleHttpResponse(response);
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  static Future<bool> handleError(dynamic error) async {
    await handleException(error);
    return shouldIgnoreError(error);
  }
}

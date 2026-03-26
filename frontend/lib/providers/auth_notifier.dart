import 'package:flutter/material.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:easyconnect/Models/user_model.dart';
import 'package:easyconnect/providers/auth_state.dart';
import 'package:easyconnect/services/api_service.dart';
import 'package:easyconnect/services/session_service.dart';
import 'package:easyconnect/services/push_notification_service.dart';
import 'package:easyconnect/services/websocket_service.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Écouteur pour que GoRouter réévalue la redirect quand l'auth change.
/// Incrémenté à chaque mise à jour (évite `notifyListeners()` protégé sur [ChangeNotifier]).
final ValueNotifier<int> authRefreshNotifier = ValueNotifier<int>(0);

/// Dernier état auth connu (pour la redirect GoRouter qui n'a pas accès à ref).
AuthState? get currentAuthState => _currentAuthState;
AuthState? _currentAuthState;

void _setCurrentAuthState(AuthState s) {
  _currentAuthState = s;
  authRefreshNotifier.value++;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    loadUserFromStorage();
  }

  /// Pour les tests uniquement : n'appelle pas [loadUserFromStorage] (évite GetStorage / session).
  @visibleForTesting
  AuthNotifier.test() : super(const AuthState());

  void loadUserFromStorage() {
    try {
      final savedUser = SessionService.getUser();
      final savedToken = SessionService.getTokenSync();
      if (savedUser != null && savedToken != null && savedToken.isNotEmpty) {
        final s = state.copyWith(
          user: UserModel.fromJson(Map<String, dynamic>.from(savedUser)),
        );
        state = s;
        _setCurrentAuthState(s);
      } else {
        state = state.copyWith(user: null);
        _setCurrentAuthState(state);
      }
    } catch (_) {
      state = state.copyWith(user: null);
      _setCurrentAuthState(state);
    }
  }

  Future<void> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) return;

    SessionService.setLoginInProgress(true);
    state = state.copyWith(isLoading: true);

    try {
      final response = await ApiService.login(email.trim(), password.trim());
      state = state.copyWith(isLoading: false);

      if (response['success'] == true) {
        final data = response['data'];
        if (data == null || data['user'] == null) {
          SessionService.setLoginInProgress(false);
          return;
        }
        if (data['token'] == null || data['token'].toString().isEmpty) {
          SessionService.setLoginInProgress(false);
          return;
        }

        UserModel user;
        try {
          user = UserModel.fromJson(data['user']);
        } catch (_) {
          SessionService.setLoginInProgress(false);
          return;
        }

        final refreshToken = data['refresh_token'] as String?;
        await SessionService.saveToken(data['token'], refreshToken: refreshToken);
        await SessionService.saveUser(data['user']);
        SessionService.setLastSuccessfulLoginNow();
        SessionService.startPeriodicValidation();
        SessionService.startActivityTracking();
        SessionService.updateLastActivity();
        await Future.delayed(const Duration(milliseconds: 300));

        final savedToken = SessionService.getTokenSync();
        if (savedToken == null || savedToken.isEmpty) {
          SessionService.setLoginInProgress(false);
          return;
        }

        state = state.copyWith(user: user);
        _setCurrentAuthState(state);

        try {
          final pushService = PushNotificationService();
          await pushService.initialize();
          await pushService.registerTokenAfterLogin();
          Future.delayed(const Duration(seconds: 2), () async {
            try {
              await pushService.registerTokenAfterLogin();
            } catch (_) {}
          });
        } catch (e, stackTrace) {
          AppLogger.error(
            'Erreur enregistrement token FCM: $e',
            tag: 'AUTH_NOTIFIER',
            error: e,
            stackTrace: stackTrace,
          );
        }

        try {
          await WebSocketService.instance.initialize();
          AppLogger.info('WebSocket initialisé après connexion', tag: 'AUTH_NOTIFIER');
        } catch (e, stackTrace) {
          AppLogger.error(
            'Erreur init WebSocket: $e',
            tag: 'AUTH_NOTIFIER',
            error: e,
            stackTrace: stackTrace,
          );
        }

        SessionService.setLoginInProgress(false);
        return;
      }

      SessionService.setLoginInProgress(false);
      final errorMessage = response['message'] ?? 'Email ou mot de passe incorrect';
      final errors = response['errors'];
      final statusCode = response['statusCode'];

      if (statusCode == 429) {
        throw _AuthException('Trop de requêtes. Veuillez patienter.');
      }
      if (statusCode != null && statusCode >= 500) {
        throw _AuthException('Erreur serveur [$statusCode]: $errorMessage');
      }
      if (errors != null && errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        final msg = first is List && first.isNotEmpty
            ? first.first.toString()
            : errorMessage;
        throw _AuthException(msg);
      }
      throw _AuthException(
        statusCode != null ? '[$statusCode] $errorMessage' : errorMessage,
      );
    } catch (e) {
      SessionService.setLoginInProgress(false);
      state = state.copyWith(isLoading: false);
      if (e is _AuthException) rethrow;
      String msg = 'Une erreur est survenue lors de la connexion';
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        msg = 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.';
      } else if (e.toString().contains('TimeoutException') || e.toString().contains('Timeout')) {
        msg = 'Le serveur ne répond pas. Veuillez réessayer plus tard.';
      } else if (e.toString().contains('FormatException') || e.toString().contains('Invalid response')) {
        msg = 'Erreur de communication avec le serveur.';
      } else {
        msg = 'Erreur: ${e.toString()}';
      }
      throw _AuthException(msg);
    }
  }

  Future<void> logout({bool silent = false, String? redirectTo}) async {
    state = state.copyWith(isLoading: true);
    try {
      try {
        final pushService = PushNotificationService();
        await pushService.unregisterToken();
      } catch (_) {}
      try {
        await FlutterAppBadger.removeBadge();
      } catch (_) {}
      try {
        WebSocketService.instance.disconnect();
      } catch (_) {}
      try {
        await ApiService.logout().timeout(
          const Duration(seconds: 2),
          onTimeout: () => {'success': false, 'message': 'Timeout'},
        );
      } catch (_) {}
    } catch (_) {}

    try {
      await SessionService.clearSession();
    } catch (e) {
      AppLogger.warning('clearSession a échoué', tag: 'AUTH_NOTIFIER');
      try {
        await SessionService.clearSession();
      } catch (_) {}
    }

    state = state.copyWith(user: null, isLoading: false);
    CacheHelper.clear();
    _setCurrentAuthState(state);
  }

  Future<void> refreshUserData() async {
    try {
      final token = await SessionService.getToken();
      if (token == null || token.isEmpty) return;
      final response = await ApiService.getUser();
      if (response['success'] == true && response['data'] != null) {
        final user = UserModel.fromJson(response['data'] as Map<String, dynamic>);
        state = state.copyWith(user: user);
        await SessionService.saveUser(response['data'] as Map<String, dynamic>);
        _setCurrentAuthState(state);
      }
    } catch (_) {}
  }

  void togglePasswordVisibility() {
    state = state.copyWith(showPassword: !state.showPassword);
  }
}

class _AuthException implements Exception {
  final String message;
  _AuthException(this.message);
  @override
  String toString() => message;
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());

/// Route initiale selon le rôle (pour redirect GoRouter et messages).
String initialRouteForRole(int? role) {
  if (role == null) return '/login';
  switch (role) {
    case Roles.ADMIN:
      return '/admin';
    case Roles.COMMERCIAL:
      return '/commercial';
    case Roles.COMPTABLE:
      return '/comptable';
    case Roles.PATRON:
      return '/patron';
    case Roles.RH:
      return '/rh';
    case Roles.TECHNICIEN:
      return '/technicien';
    default:
      return '/login';
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/providers/notification_notifier.dart';
import 'package:easyconnect/services/session_service.dart';
import 'package:easyconnect/services/push_notification_service.dart';

/// Widget qui écoute le cycle de vie de l'application
/// et gère le rafraîchissement des données au retour au premier plan
class AppLifecycleWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const AppLifecycleWrapper({super.key, required this.child});

  @override
  ConsumerState<AppLifecycleWrapper> createState() =>
      _AppLifecycleWrapperState();
}

class _AppLifecycleWrapperState extends ConsumerState<AppLifecycleWrapper>
    with WidgetsBindingObserver {
  bool _wasInBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Mettre à jour l'état dans SessionService pour le suivi d'activité
    SessionService.updateAppLifecycleState(state);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _wasInBackground = true;
      try {
        ref.read(notificationProvider.notifier).refreshUnreadCount();
      } catch (_) {}
    } else if (state == AppLifecycleState.resumed) {
      // Dès qu'on rentre dans l'app : retirer le badge (nombre) sur l'icône
      try {
        FlutterAppBadger.removeBadge();
      } catch (_) {}
      // Effacer les notifications passées de la barre
      PushNotificationService().cancelAllNotifications();
      if (_wasInBackground) {
        _wasInBackground = false;
        _handleAppResumed();
      }
    }
  }

  /// Gère le retour de l'application au premier plan
  void _handleAppResumed() async {
    SessionService.updateLastActivity();

    final authState = ref.read(authProvider);
    final user = authState.user;
    final token = await SessionService.getToken();

    if (token == null || user == null) {
      ref.read(authProvider.notifier).logout(silent: true);
      return;
    }

    try {
      await ref.read(authProvider.notifier).refreshUserData();
    } catch (e) {
      // Si erreur 401, AuthErrorHandler déconnectera automatiquement
    }

    try {
      await ref.read(notificationProvider.notifier).refreshUnreadCount();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(notificationProvider);
    return widget.child;
  }
}
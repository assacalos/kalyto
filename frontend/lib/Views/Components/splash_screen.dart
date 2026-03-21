import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/Models/user_model.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/providers/company_provider.dart';
import 'package:easyconnect/services/api_service.dart';
import 'package:easyconnect/services/company_service.dart';
import 'package:easyconnect/services/session_service.dart';
import 'package:easyconnect/services/push_notification_service.dart';
import 'package:easyconnect/services/websocket_service.dart';
import 'package:easyconnect/utils/logger.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    ref.read(authProvider);
    var user = ref.read(authProvider).user;

    try {
      final loggedIn = await SessionService.isLoggedIn();
      AppLogger.info('Splash: SessionService.isLoggedIn = $loggedIn', tag: 'SPLASH');

      if (loggedIn && user != null) {
        _syncCompanyForNonAdmin(user);
        _runBackgroundInit();
        if (mounted) context.go(initialRouteForRole(user.role));
        return;
      }

      if (!loggedIn) {
        if (mounted) context.go('/welcome');
        return;
      }

      try {
        final result = await ApiService.getUser().timeout(
          const Duration(seconds: 5),
          onTimeout: () => <String, dynamic>{'success': false},
        );
        if (result['success'] == true && result['data'] != null) {
          final userData = Map<String, dynamic>.from(result['data'] as Map);
          await SessionService.saveUser(userData);
          await ref.read(authProvider.notifier).refreshUserData();
          user = ref.read(authProvider).user;
        }
      } catch (_) {}
      if (user == null) user = ref.read(authProvider).user;

      if (user != null) {
        _syncCompanyForNonAdmin(user);
        _runBackgroundInit();
        if (mounted) context.go(initialRouteForRole(user.role));
        return;
      }
      if (mounted) context.go('/welcome');
    } catch (e) {
      AppLogger.warning('Splash: erreur redirection: $e', tag: 'SPLASH');
      if (mounted) context.go('/welcome');
    }
  }

  void _syncCompanyForNonAdmin(UserModel user) {
    if (user.role == 1) return;
    if (user.companyId != null) {
      CompanyService.setCurrentCompanyId(user.companyId);
      ref.read(currentCompanyIdProvider.notifier).update((_) => user.companyId);
    }
  }

  void _runBackgroundInit() {
    Future(() async {
      try {
        final result = await ApiService.getUser().timeout(
          const Duration(seconds: 2),
          onTimeout: () => <String, dynamic>{'timeout': true},
        );
        if (result['timeout'] == true) return;
        if (result['success'] == true && result['data'] != null) {
          await SessionService.saveUser(
            Map<String, dynamic>.from(result['data'] as Map),
          );
          ref.read(authProvider.notifier).refreshUserData();
        }
      } catch (_) {}

      try {
        final pushService = PushNotificationService();
        await pushService.initialize();
        await pushService.registerTokenAfterLogin();
      } catch (_) {}

      try {
        await WebSocketService.instance.initialize();
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authProvider);
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.business,
                size: 60,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Kalyto',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Gestion d\'entreprise',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:easyconnect/router/app_router.dart' show rootGoRouter, createAppRouter, currentRouterLocation;
import 'package:easyconnect/Views/Components/app_lifecycle_wrapper.dart';
import 'package:easyconnect/Views/Components/responsive_web_wrapper.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/auth_error_handler.dart';
import 'package:easyconnect/utils/error_helper.dart';
import 'package:easyconnect/utils/validation_helper.dart';
import 'package:easyconnect/utils/validation_helper_enhanced.dart';
import 'package:easyconnect/gen_l10n/app_localizations.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/providers/locale_provider.dart';
import 'package:easyconnect/services/notification_service_enhanced.dart';
import 'package:easyconnect/services/push_notification_service.dart';
import 'package:easyconnect/providers/notification_notifier.dart';
import 'package:easyconnect/services/session_service.dart';
import 'package:easyconnect/services/notification_navigation_service.dart';
import 'package:easyconnect/services/storage_service.dart';

/// Clé globale pour afficher des snackbars depuis n'importe où (callbacks AuthErrorHandler, ErrorHelper, etc.)
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Handler pour les notifications en arrière-plan (doit être top-level)
/// Gère les notifications au format FCM v1 avec type, entity_id, action_route
/// Sur le web, les messages en arrière-plan sont gérés par firebase-messaging-sw.js.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kIsWeb) return; // Sur le web, le Service Worker affiche la notification

  // Initialiser Firebase si nécessaire
  await Firebase.initializeApp();

  AppLogger.info(
    'Notification reçue en arrière-plan: ${message.messageId}',
    tag: 'PUSH_NOTIFICATION_BACKGROUND',
  );

  // Logger les données FCM v1 pour debug
  AppLogger.info(
    'Données FCM v1 (background): ${message.data}',
    tag: 'PUSH_NOTIFICATION_BACKGROUND',
  );

  // Afficher la notification locale même en arrière-plan
  final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();

  // Initialiser les notifications locales si nécessaire
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await localNotifications.initialize(initSettings);

  // Créer le canal de notification Android
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'Notifications importantes',
    description: 'Ce canal est utilisé pour les notifications importantes',
    importance: Importance.high,
    playSound: true,
  );

  await localNotifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  // Afficher la notification
  final notification = message.notification;
  if (notification != null) {
    await localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'Notifications importantes',
          channelDescription:
              'Ce canal est utilisé pour les notifications importantes',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      // Inclure toutes les données FCM v1 dans le payload pour la navigation
      payload: jsonEncode(message.data),
    );

    AppLogger.info(
      'Notification locale affichée en arrière-plan avec données FCM v1',
      tag: 'PUSH_NOTIFICATION_BACKGROUND',
    );
  } else if (message.data.isNotEmpty) {
    // Si pas de notification mais des données, créer une notification à partir des données
    final title = message.data['title'] ?? 'Nouvelle notification';
    final body =
        message.data['body'] ??
        message.data['message'] ??
        'Vous avez une nouvelle notification';

    await localNotifications.show(
      message.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'Notifications importantes',
          channelDescription:
              'Ce canal est utilisé pour les notifications importantes',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );

    AppLogger.info(
      'Notification locale créée à partir des données (background)',
      tag: 'PUSH_NOTIFICATION_BACKGROUND',
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.info('=== DÉMARRAGE DE L\'APPLICATION ===', tag: 'MAIN');

  // Initialiser les données de formatage des dates pour les locales supportées
  await initializeDateFormatting('fr_FR');
  await initializeDateFormatting('en_US');

  // GetStorage : session (token, user), préférences. Hive : cache listes (clients, devis, etc.). Pas de conflit.
  await GetStorage.init();

  try {
    await HiveStorageService.init();
    AppLogger.info('HiveStorageService initialisé', tag: 'MAIN');
  } catch (e) {
    AppLogger.error('Erreur init Hive: $e', tag: 'MAIN');
  }

  // Initialiser le service de session (critique pour le premier écran / splash)
  try {
    await SessionService.initialize();
    AppLogger.info('SessionService initialisé avec succès', tag: 'MAIN');
  } catch (e) {
    AppLogger.error(
      'Erreur lors de l\'initialisation de SessionService: $e',
      tag: 'MAIN',
    );
  }

  // Lancer l'app sans attendre Firebase/push (premier écran plus rapide)
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );

  // Initialisations non bloquantes (pas critiques pour le premier écran)
  Future(() async {
    try {
      await Firebase.initializeApp();
      AppLogger.info('Firebase initialisé avec succès', tag: 'MAIN');
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final pushService = PushNotificationService();
      pushService.onNotificationTapped = (Map<String, dynamic> data) {
        NotificationNavigationService().handleNavigation(data);
      };
      pushService.onNotificationReceived = (Map<String, dynamic> data) {
        try {
          NotificationRefreshCallback.instance.refresh();
        } catch (e, stackTrace) {
          AppLogger.error(
            'Erreur lors de la mise à jour des notifications: $e',
            tag: 'PUSH_NOTIFICATION',
            error: e,
            stackTrace: stackTrace,
          );
        }
      };

      await pushService.initialize();

      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        AppLogger.info(
          'App ouverte depuis une notification: ${initialMessage.messageId}',
          tag: 'PUSH_NOTIFICATION',
        );
        final notificationData = pushService.extractNotificationData(
          initialMessage.data,
        );
        Future.delayed(const Duration(milliseconds: 500), () {
          NotificationNavigationService().handleNavigation(notificationData);
        });
      }
      AppLogger.info(
        'Service de notifications push initialisé avec succès',
        tag: 'MAIN',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erreur init Firebase/push: $e',
        tag: 'MAIN',
        error: e,
        stackTrace: stackTrace,
      );
    }

    NotificationServiceEnhanced().initialize().catchError((e) {
      AppLogger.error(
        'Erreur lors de l\'initialisation des notifications: $e',
        tag: 'MAIN',
      );
    });
  });
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  static bool _callbacksInitialized = false;

  void _initCallbacksOnce() {
    if (_callbacksInitialized) return;
    _callbacksInitialized = true;

    // AuthErrorHandler : déconnexion 401
    AuthErrorHandler.logoutCallback = ({bool silent = false, String? redirectTo}) async {
      await ref.read(authProvider.notifier).logout(silent: silent, redirectTo: redirectTo);
      if (redirectTo != null && redirectTo.isNotEmpty) {
        rootGoRouter?.go(redirectTo);
      }
    };
    AuthErrorHandler.currentRouteCallback = () => currentRouterLocation;
    AuthErrorHandler.showSnackbarCallback = (String title, String message, {Duration? duration}) {
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('$title\n$message'),
          duration: duration ?? const Duration(seconds: 3),
        ),
      );
    };

    // ErrorHelper : erreurs générales
    errorHelperShowSnackbar = (String title, String message,
        {Color? backgroundColor, Color? colorText, Duration? duration, Icon? icon}) {
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('$title: $message'),
          backgroundColor: backgroundColor ?? Colors.red,
          duration: duration ?? const Duration(seconds: 3),
        ),
      );
    };

    // ValidationHelper
    validationHelperShowSnackbar = (String title, String message,
        {Color? backgroundColor, Color? colorText, Duration? duration}) {
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('$title: $message'),
          backgroundColor: backgroundColor,
          duration: duration ?? const Duration(seconds: 3),
        ),
      );
    };

    // ValidationHelperEnhanced
    validationHelperEnhancedShowSnackbar = (String title, String message,
        {Color? backgroundColor, Color? colorText, Duration? duration}) {
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('$title: $message'),
          backgroundColor: backgroundColor ?? Colors.orange,
          duration: duration ?? const Duration(seconds: 3),
        ),
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    _initCallbacksOnce();
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      title: 'Kalyto',
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: createAppRouter(),
      builder: (context, child) {
        Widget content = AppLifecycleWrapper(
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
            child: child!,
          ),
        );
        if (kIsWeb) {
          content = Theme(
            data: Theme.of(context).copyWith(
              filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  minimumSize: const Size(64, 40),
                ),
              ),
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  minimumSize: const Size(64, 40),
                ),
              ),
              iconButtonTheme: IconButtonThemeData(
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(8),
                  minimumSize: const Size(40, 40),
                  iconSize: 22,
                ),
              ),
              listTileTheme: ListTileThemeData(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                minLeadingWidth: 40,
                dense: true,
              ),
            ),
            child: content,
          );
        }
        return ResponsiveWebWrapper(child: content);
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          iconTheme: IconThemeData(color: Colors.black87),
          actionsIconTheme: IconThemeData(color: Colors.black87),
        ),
        cardTheme: CardTheme(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
        ),
        dialogTheme: DialogTheme(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
        ),
      ),
    );
  }
}

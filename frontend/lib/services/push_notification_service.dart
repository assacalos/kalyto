import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' if (dart.library.html) 'io_platform_stub.dart' show Platform;
import 'package:easyconnect/services/http_interceptor.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../utils/app_config.dart';
import '../services/session_service.dart';
import '../utils/logger.dart';
import '../utils/encoding_helper.dart';

/// Service de gestion des notifications push Firebase Cloud Messaging
class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  StreamSubscription<String>? _tokenSubscription;

  // Callback pour gérer les notifications reçues
  Function(Map<String, dynamic>)? onNotificationReceived;

  // Callback pour gérer les clics sur les notifications
  Function(Map<String, dynamic>)? onNotificationTapped;

  bool _isInitialized = false;

  /// Initialiser le service de notifications push
  Future<void> initialize() async {
    if (_isInitialized) {
      AppLogger.info(
        'Service de notifications push déjà initialisé',
        tag: 'PUSH_NOTIFICATION',
      );
      return;
    }

    try {
      // Demander la permission pour les notifications
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        AppLogger.info(
          'L\'utilisateur a accordé la permission',
          tag: 'PUSH_NOTIFICATION',
        );
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        AppLogger.info(
          'L\'utilisateur a accordé une permission provisoire',
          tag: 'PUSH_NOTIFICATION',
        );
      } else {
        AppLogger.warning(
          'L\'utilisateur a refusé ou n\'a pas encore accordé la permission',
          tag: 'PUSH_NOTIFICATION',
        );
        _isInitialized = true;
        return;
      }

      // Sur le web, pas de notifications locales (FlutterLocalNotifications non supporté)
      if (!kIsWeb) {
        await _initializeLocalNotifications();
      }

      // Obtenir le token FCM (supporté sur web avec Firebase JS)
      await _getFCMToken();

      // Configurer les handlers pour les notifications
      _setupNotificationHandlers();

      // Écouter les changements de token
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _registerTokenToBackend(newToken);
      });

      _isInitialized = true;
      AppLogger.info(
        'Service de notifications push initialisé avec succès',
        tag: 'PUSH_NOTIFICATION',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erreur lors de l\'initialisation du service de notifications push: $e',
        tag: 'PUSH_NOTIFICATION',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Initialiser les notifications locales
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          try {
            final data = jsonDecode(response.payload!);
            onNotificationTapped?.call(data);
          } catch (e) {
            AppLogger.error(
              'Erreur lors du décodage du payload: $e',
              tag: 'PUSH_NOTIFICATION',
            );
          }
        }
      },
    );

    // Créer un canal de notification pour Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Notifications importantes',
      description: 'Ce canal est utilisé pour les notifications importantes',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  /// Obtenir le token FCM
  Future<void> _getFCMToken() async {
    try {
      // Sur le web, une clé VAPID est obligatoire pour obtenir un token FCM
      final vapidKey = kIsWeb ? AppConfig.firebaseWebVapidKey : null;
      if (kIsWeb && (vapidKey == null || vapidKey.isEmpty)) {
        AppLogger.warning(
          'Clé VAPID non configurée : FCM web désactivé. Voir FCM_WEB_SETUP.md',
          tag: 'PUSH_NOTIFICATION',
        );
        return;
      }
      _fcmToken = await _firebaseMessaging.getToken(vapidKey: vapidKey);
      if (_fcmToken != null) {
        AppLogger.info(
          'Token FCM obtenu: ${_fcmToken!.substring(0, 20)}...',
          tag: 'PUSH_NOTIFICATION',
        );
        // Enregistrer le token seulement si l'utilisateur est authentifié
        if (await SessionService.isAuthenticated()) {
          await _registerTokenToBackend(_fcmToken!);
        }
      }
    } catch (e) {
      AppLogger.error(
        'Erreur lors de l\'obtention du token FCM: $e',
        tag: 'PUSH_NOTIFICATION',
        error: e,
      );
    }
  }

  /// Enregistrer le token auprès du backend
  Future<void> _registerTokenToBackend(String fcmToken) async {
    if (!(await SessionService.isAuthenticated())) {
      return;
    }

    try {
      final deviceType = _getDeviceType();
      final deviceId = await _getDeviceId();
      final appVersion = await _getAppVersion();

      final authToken = await SessionService.getToken();
      if (authToken == null || authToken.isEmpty) {
        return;
      }

      final payload = {
        'fcm_token':
            fcmToken, // Format attendu par le nouveau NotificationService Laravel
        'token': fcmToken, // Garder pour compatibilité avec l'ancien système
        'device_type': deviceType,
        'device_id': deviceId,
        'app_version': appVersion,
      };

      final response = await HttpInterceptor.post(
            HttpInterceptor.apiUri('device-tokens'),
            body: jsonEncode(payload),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Timeout lors de l\'enregistrement du token FCM');
            },
          );

      if (response.statusCode == 201 || response.statusCode == 200) {
        AppLogger.info(
          'Token FCM enregistré avec succès',
          tag: 'PUSH_NOTIFICATION',
        );
      } else {
        AppLogger.error(
          'Erreur lors de l\'enregistrement du token FCM: ${response.statusCode}',
          tag: 'PUSH_NOTIFICATION',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erreur lors de l\'enregistrement du token FCM: $e',
        tag: 'PUSH_NOTIFICATION',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Configurer les handlers pour les notifications
  void _setupNotificationHandlers() {
    // Notification reçue quand l'app est au premier plan
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      AppLogger.info(
        'Notification reçue au premier plan: ${message.messageId}',
        tag: 'PUSH_NOTIFICATION',
      );

      // Logger les données reçues pour debug (format FCM v1)
      AppLogger.info(
        'Données de la notification (FCM v1): ${message.data}',
        tag: 'PUSH_NOTIFICATION',
      );

      // Extraire les données au format FCM v1
      final notificationData = extractNotificationData(message.data);
      AppLogger.info(
        'Données extraites - Type: ${notificationData['type']}, EntityId: ${notificationData['entity_id']}, ActionRoute: ${notificationData['action_route']}',
        tag: 'PUSH_NOTIFICATION',
      );

      // Sur le web, pas de notification locale (on s'appuie sur le polling et la liste)
      if (!kIsWeb) {
        _showLocalNotification(message)
          .then((_) {
            AppLogger.info(
              'Notification locale affichée avec succès',
              tag: 'PUSH_NOTIFICATION',
            );
          })
          .catchError((e) {
            AppLogger.error(
              'Erreur lors de l\'affichage de la notification locale: $e',
              tag: 'PUSH_NOTIFICATION',
              error: e,
            );
          });
      }

      // Appeler le callback si défini avec les données extraites
      // Note: Quand l'app est ouverte, Pusher devrait gérer les notifications en temps réel
      // mais on garde ce callback pour la compatibilité et les cas où FCM arrive avant Pusher
      if (onNotificationReceived != null) {
        onNotificationReceived!(notificationData);
      }
    });

    // Notification reçue quand l'app est en arrière-plan et que l'utilisateur clique dessus
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      AppLogger.info(
        'Notification ouverte depuis l\'arrière-plan: ${message.messageId}',
        tag: 'PUSH_NOTIFICATION',
      );
      AppLogger.info(
        'Données de la notification: ${message.data}',
        tag: 'PUSH_NOTIFICATION',
      );

      // Extraire les données au format FCM v1
      final notificationData = extractNotificationData(message.data);
      _handleNotificationTap(notificationData);
    });

    // Note: getInitialMessage() est maintenant géré dans main.dart après l'initialisation complète
    // pour éviter les problèmes de timing avant que le routeur soit prêt
  }

  /// Extrait et normalise les données de notification au format FCM v1
  /// Supporte les formats: {type, entity_id, action_route} et l'ancien format pour compatibilité
  /// Format FCM v1 attendu depuis Laravel NotificationService:
  /// {
  ///   'type': 'client' | 'devis' | 'conge' | etc.,
  ///   'entity_id': '123',
  ///   'action_route': '/devis/12' (optionnel, prioritaire sur type+entity_id)
  /// }
  Map<String, dynamic> extractNotificationData(Map<String, dynamic> rawData) {
    final data = <String, dynamic>{};

    AppLogger.info(
      'Extraction des données FCM v1 - Raw data: $rawData',
      tag: 'PUSH_NOTIFICATION',
    );

    // Format FCM v1 (prioritaire) - type
    if (rawData.containsKey('type')) {
      data['type'] = rawData['type']?.toString().toLowerCase();
    } else if (rawData.containsKey('entity_type')) {
      // Ancien format pour compatibilité
      data['type'] = rawData['entity_type']?.toString().toLowerCase();
    }

    // Entity ID - format FCM v1
    if (rawData.containsKey('entity_id')) {
      final entityId = rawData['entity_id'];
      data['entity_id'] = entityId?.toString();
    } else if (rawData.containsKey('id')) {
      // Fallback sur 'id' si entity_id n'existe pas
      data['entity_id'] = rawData['id']?.toString();
    } else if (rawData.containsKey('devis_id')) {
      data['entity_id'] = rawData['devis_id']?.toString();
      if (data['type'] == null) data['type'] = 'devis';
    } else if (rawData.containsKey('client_id')) {
      data['entity_id'] = rawData['client_id']?.toString();
      if (data['type'] == null) data['type'] = 'client';
    } else if (rawData.containsKey('conge_id')) {
      data['entity_id'] = rawData['conge_id']?.toString();
      if (data['type'] == null) data['type'] = 'conge';
    }

    // Action route (nouveau format FCM v1) - PRIORITAIRE pour la navigation
    if (rawData.containsKey('action_route')) {
      final actionRoute = rawData['action_route'];
      if (actionRoute != null && actionRoute.toString().isNotEmpty) {
        data['action_route'] = actionRoute.toString();
      }
    }

    // Conserver toutes les autres données pour compatibilité
    rawData.forEach((key, value) {
      if (!data.containsKey(key)) {
        data[key] = value;
      }
    });

    AppLogger.info(
      'Données extraites - Type: ${data['type']}, EntityId: ${data['entity_id']}, ActionRoute: ${data['action_route']}',
      tag: 'PUSH_NOTIFICATION',
    );

    return data;
  }

  /// Afficher une notification locale (no-op sur le web)
  Future<void> _showLocalNotification(RemoteMessage message) async {
    if (kIsWeb) return;
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      try {
        await _localNotifications.show(
          message.hashCode,
          fixUtf8Mojibake(notification.title),
          fixUtf8Mojibake(notification.body),
          NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'Notifications importantes',
              channelDescription:
                  'Ce canal est utilisé pour les notifications importantes',
              importance: Importance.high,
              priority: Priority.high,
              playSound: true,
              enableVibration: true,
              showWhen: true,
              icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: jsonEncode(message.data),
        );

        AppLogger.info(
          'Notification locale affichée avec succès: ${notification.title}',
          tag: 'PUSH_NOTIFICATION',
        );
      } catch (e, stackTrace) {
        AppLogger.error(
          'Erreur lors de l\'affichage de la notification locale: $e',
          tag: 'PUSH_NOTIFICATION',
          error: e,
          stackTrace: stackTrace,
        );
      }
    } else {
      // Si pas de notification, créer une notification à partir des données
      final title = fixUtf8Mojibake(message.data['title'] ?? 'Nouvelle notification');
      final body = fixUtf8Mojibake(message.data['body'] ?? message.data['message'] ?? '');

      if (body.isNotEmpty) {
        try {
          await _localNotifications.show(
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
                showWhen: true,
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
            'Notification locale créée à partir des données: $title',
            tag: 'PUSH_NOTIFICATION',
          );
        } catch (e, stackTrace) {
          AppLogger.error(
            'Erreur lors de l\'affichage de la notification locale (data): $e',
            tag: 'PUSH_NOTIFICATION',
            error: e,
            stackTrace: stackTrace,
          );
        }
      }
    }
  }

  /// Gérer le clic sur une notification
  void _handleNotificationTap(Map<String, dynamic> data) {
    if (onNotificationTapped != null) {
      onNotificationTapped!(data);
    }
  }

  /// Obtenir le type d'appareil
  String _getDeviceType() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'web';
  }

  /// Obtenir l'ID unique de l'appareil
  Future<String> _getDeviceId() async {
    if (kIsWeb) {
      // Identifiant stable par session pour le web (pas d'accès device natif)
      return 'web_${identityHashCode(this)}';
    }
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown';
      }
    } catch (e) {
      AppLogger.error(
        'Erreur lors de l\'obtention de l\'ID de l\'appareil: $e',
        tag: 'PUSH_NOTIFICATION',
        error: e,
      );
    }
    return 'unknown';
  }

  /// Obtenir la version de l'application
  Future<String> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      AppLogger.error(
        'Erreur lors de l\'obtention de la version: $e',
        tag: 'PUSH_NOTIFICATION',
        error: e,
      );
      return AppConfig.appVersion;
    }
  }

  /// Enregistrer le token après connexion
  /// Cette méthode est appelée après une connexion réussie pour s'assurer
  /// que le token FCM est bien enregistré sur le backend
  /// Retourne true si l'enregistrement a réussi, false sinon
  Future<bool> registerTokenAfterLogin() async {
    if (!(await SessionService.isAuthenticated())) {
      return false;
    }

    // Obtenir le token FCM s'il n'est pas déjà disponible
    if (_fcmToken == null || _fcmToken!.isEmpty) {
      await _getFCMToken();
    }

    if (_fcmToken == null || _fcmToken!.isEmpty) {
      AppLogger.error(
        'Impossible d\'obtenir le token FCM',
        tag: 'PUSH_NOTIFICATION',
      );
      return false;
    }

    // Enregistrer le token sur le backend
    try {
      await _registerTokenToBackend(_fcmToken!);
      return true;
    } catch (e) {
      AppLogger.error(
        'Exception lors de l\'enregistrement du token FCM: $e',
        tag: 'PUSH_NOTIFICATION',
        error: e,
      );
      return false;
    }
  }

  /// Forcer l'enregistrement du token (utile pour le débogage)
  /// Cette méthode peut être appelée manuellement pour réessayer l'enregistrement
  Future<bool> forceRegisterToken() async {
    // Réinitialiser le token pour forcer une nouvelle obtention
    _fcmToken = null;

    // Obtenir un nouveau token
    await _getFCMToken();

    if (_fcmToken == null || _fcmToken!.isEmpty) {
      AppLogger.error(
        'Impossible d\'obtenir le token FCM',
        tag: 'PUSH_NOTIFICATION',
      );
      return false;
    }

    // Enregistrer le token
    return await registerTokenAfterLogin();
  }

  /// Supprimer le token du backend (lors de la déconnexion)
  Future<void> unregisterToken() async {
    if (_fcmToken == null || _fcmToken!.isEmpty) {
      return;
    }

    try {
      final token = await SessionService.getToken();
      if (token == null || token.isEmpty) {
        return;
      }

      final response = await HttpInterceptor.delete(
        HttpInterceptor.apiUri('device-tokens'),
      );

      if (response.statusCode == 200) {
        AppLogger.info(
          'Token supprimé avec succès du backend',
          tag: 'PUSH_NOTIFICATION',
        );
      }
    } catch (e) {
      AppLogger.error(
        'Erreur lors de la suppression du token: $e',
        tag: 'PUSH_NOTIFICATION',
        error: e,
      );
    }
  }

  /// Obtenir le token FCM actuel
  String? get fcmToken => _fcmToken;

  /// Efface toutes les notifications locales de la barre de notification.
  /// À appeler quand l'app revient au premier plan pour éviter que les anciennes
  /// notifications s'affichent encore comme nouvelles.
  Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      AppLogger.info(
        'Notifications locales effacées de la barre',
        tag: 'PUSH_NOTIFICATION',
      );
    } catch (e) {
      AppLogger.error(
        'Erreur lors de l\'effacement des notifications: $e',
        tag: 'PUSH_NOTIFICATION',
        error: e,
      );
    }
  }

  /// Nettoyer les ressources
  void dispose() {
    _tokenSubscription?.cancel();
  }
}

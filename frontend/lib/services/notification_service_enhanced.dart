import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/router/app_router.dart' show rootGoRouter;
import 'package:easyconnect/Models/notification_model.dart';
import 'package:easyconnect/utils/encoding_helper.dart';
import 'package:easyconnect/utils/logger.dart';

/// Service de notifications amélioré avec sons et notifications locales
/// Ne bloque pas l'application grâce à l'exécution asynchrone
class NotificationServiceEnhanced {
  static final NotificationServiceEnhanced _instance =
      NotificationServiceEnhanced._internal();
  factory NotificationServiceEnhanced() => _instance;
  NotificationServiceEnhanced._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final List<AppNotification> notifications = [];
  int get unreadCount => notifications.where((n) => !n.isRead).length;

  bool _isInitialized = false;
  bool _soundsEnabled = true;
  bool _notificationsEnabled = true;
  final _storage = GetStorage();

  /// Initialiser le service de notifications
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configuration Android
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      // Configuration iOS
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Créer le canal de notification Android avec le son activé
      if (Platform.isAndroid) {
        await _createNotificationChannel();
        await _requestAndroidPermissions();
      }

      _isInitialized = true;
      AppLogger.info(
        'Service de notifications initialisé',
        tag: 'NOTIFICATION',
      );
    } catch (e) {
      AppLogger.error(
        'Erreur lors de l\'initialisation des notifications: $e',
        tag: 'NOTIFICATION',
        error: e,
      );
    }
  }

  /// Créer le canal de notification Android avec le son activé
  Future<void> _createNotificationChannel() async {
    if (Platform.isAndroid) {
      try {
        const androidChannel = AndroidNotificationChannel(
          'easyconnect_notifications',
          'Notifications EasyConnect',
          description: 'Notifications pour les validations et soumissions',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );

        final androidImplementation =
            _localNotifications
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();

        if (androidImplementation != null) {
          await androidImplementation.createNotificationChannel(androidChannel);
          AppLogger.info(
            'Canal de notification Android créé avec succès',
            tag: 'NOTIFICATION',
          );
        }
      } catch (e) {
        AppLogger.error(
          'Erreur lors de la création du canal de notification: $e',
          tag: 'NOTIFICATION',
          error: e,
        );
      }
    }
  }

  /// Demander les permissions Android
  Future<void> _requestAndroidPermissions() async {
    if (Platform.isAndroid) {
      try {
        final androidImplementation =
            _localNotifications
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();

        if (androidImplementation != null) {
          // Vérifier si les permissions ont déjà été demandées
          final permissionsRequested =
              _storage.read<bool>('notifications_permissions_requested') ??
              false;

          if (!permissionsRequested) {
            // Demander la permission de notifications (Android 13+)
            await androidImplementation.requestNotificationsPermission();

            // Demander la permission d'alarmes exactes (Android 12+)
            // Cette permission peut nécessiter une redirection vers les paramètres système
            try {
              final alarmPermission =
                  await androidImplementation.requestExactAlarmsPermission();

              if (alarmPermission != null && !alarmPermission) {
                AppLogger.warning(
                  'Permission d\'alarmes exactes non accordée. '
                  'Les notifications programmées peuvent ne pas fonctionner correctement.',
                  tag: 'NOTIFICATION',
                );
              }
            } catch (e) {
              // Sur certains appareils, cette permission peut nécessiter une action manuelle
              AppLogger.warning(
                'Impossible de demander la permission d\'alarmes exactes: $e. '
                'L\'utilisateur peut devoir l\'activer manuellement dans les paramètres.',
                tag: 'NOTIFICATION',
              );
            }

            // Marquer que les permissions ont été demandées
            await _storage.write('notifications_permissions_requested', true);
          } else {
            // Vérifier si les permissions sont toujours accordées
            // Si elles ont été révoquées, on peut les redemander une fois
            try {
              final canScheduleExactAlarms =
                  await androidImplementation.canScheduleExactNotifications();
              if (canScheduleExactAlarms == false) {
                // La permission a été révoquée, on peut la redemander une fois
                final alarmPermission =
                    await androidImplementation.requestExactAlarmsPermission();
                if (alarmPermission != null && alarmPermission) {
                  AppLogger.info(
                    'Permission d\'alarmes exactes réaccordée',
                    tag: 'NOTIFICATION',
                  );
                }
              }
            } catch (e) {
              // Ignorer les erreurs de vérification
            }
          }
        }
      } catch (e) {
        AppLogger.error(
          'Erreur lors de la demande de permissions Android: $e',
          tag: 'NOTIFICATION',
          error: e,
        );
      }
    }
  }

  /// Gérer le tap sur une notification
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        // Le payload peut contenir des données pour naviguer
        // Exemple: "route:/invoices/123"
        final parts = response.payload!.split(':');
        if (parts.length == 2) {
          final route = parts[0];
          final data = parts[1];
          rootGoRouter?.go(route, extra: data);
        }
      } catch (e) {
        AppLogger.error(
          'Erreur lors de la navigation depuis la notification: $e',
          tag: 'NOTIFICATION',
        );
      }
    }
  }

  /// Activer/désactiver les sons
  void setSoundsEnabled(bool enabled) {
    _soundsEnabled = enabled;
  }

  /// Activer/désactiver les notifications
  void setNotificationsEnabled(bool enabled) {
    _notificationsEnabled = enabled;
  }

  /// Notifier qu'une entité a été soumise
  Future<void> notifyEntitySubmitted({
    required String entityType,
    required String entityName,
    required String entityId,
    String? recipientRole,
    String? route,
  }) async {
    final notification = AppNotification(
      id: 'submitted_${entityType}_$entityId',
      title: 'Soumission $entityType',
      message: '$entityName a été soumis pour validation',
      type: 'info',
      entityType: entityType,
      entityId: entityId,
      isRead: false,
      createdAt: DateTime.now(),
      actionRoute: route ?? '',
      metadata: null,
    );

    await showNotification(notification, soundType: 'submit');
  }

  /// Notifier qu'une entité a été validée
  Future<void> notifyEntityValidated({
    required String entityType,
    required String entityName,
    required String entityId,
    String? recipientRole,
    String? route,
  }) async {
    final notification = AppNotification(
      id: 'validated_${entityType}_$entityId',
      title: 'Validation $entityType',
      message: '$entityName a été validé',
      type: 'success',
      entityType: entityType,
      entityId: entityId,
      isRead: false,
      createdAt: DateTime.now(),
      actionRoute: route ?? '',
      metadata: null,
    );

    await showNotification(notification, soundType: 'success');
  }

  /// Notifier qu'une entité a été rejetée
  Future<void> notifyEntityRejected({
    required String entityType,
    required String entityName,
    required String entityId,
    String? reason,
    String? recipientRole,
    String? route,
  }) async {
    final message =
        reason != null
            ? '$entityName a été rejeté. Raison: $reason'
            : '$entityName a été rejeté';

    final notification = AppNotification(
      id: 'rejected_${entityType}_$entityId',
      title: 'Rejet $entityType',
      message: message,
      type: 'error',
      entityType: entityType,
      entityId: entityId,
      isRead: false,
      createdAt: DateTime.now(),
      actionRoute: route ?? '',
      metadata: reason != null ? {'reason': reason} : null,
    );

    await showNotification(notification, soundType: 'error');
  }

  /// Afficher une notification (locale + snackbar + son)
  /// Méthode publique pour permettre l'affichage depuis d'autres contrôleurs
  Future<void> showNotification(
    AppNotification notification, {
    required String soundType,
    bool addToList = true, // Par défaut, ajouter à la liste
  }) async {
    AppLogger.info(
      'showNotification appelé: ID=${notification.id}, Title=${notification.title}, SoundType=$soundType, AddToList=$addToList',
      tag: 'NOTIFICATION',
    );

    if (!_isInitialized) {
      AppLogger.info(
        'Service non initialisé, initialisation en cours...',
        tag: 'NOTIFICATION',
      );
      await initialize();
    }

    // Ajouter à la liste des notifications (si demandé)
    if (addToList) {
      notifications.insert(0, notification);
      _updateUnreadCount();
    }

    // Afficher la notification locale (non-bloquant)
    if (_notificationsEnabled) {
      AppLogger.info(
        'Affichage notification locale activé, affichage en cours...',
        tag: 'NOTIFICATION',
      );
      _showLocalNotification(notification)
          .then((_) {
            AppLogger.info(
              'Notification locale affichée avec succès: ID=${notification.id}',
              tag: 'NOTIFICATION',
            );
          })
          .catchError((e, stackTrace) {
            AppLogger.error(
              'Erreur lors de l\'affichage de la notification locale: $e\nStack: $stackTrace',
              tag: 'NOTIFICATION',
            );
          });
    } else {
      AppLogger.warning(
        'Notifications locales désactivées',
        tag: 'NOTIFICATION',
      );
    }

    // Jouer le son (non-bloquant)
    if (_soundsEnabled) {
      AppLogger.info(
        'Sons activés, lecture du son: $soundType',
        tag: 'NOTIFICATION',
      );
      _playSound(soundType).catchError((e) {
        AppLogger.error(
          'Erreur lors de la lecture du son: $e',
          tag: 'NOTIFICATION',
        );
      });
    } else {
      AppLogger.warning('Sons désactivés', tag: 'NOTIFICATION');
    }

    // Afficher le snackbar seulement si l'app est au premier plan
    // (pour éviter les doublons avec les notifications système)
    if (addToList) {
      _showSnackbar(notification).catchError((e) {
        AppLogger.error(
          'Erreur lors de l\'affichage du snackbar: $e',
          tag: 'NOTIFICATION',
        );
      });
    }
  }

  /// Afficher une notification locale
  Future<void> _showLocalNotification(AppNotification notification) async {
    AppLogger.info(
      'Affichage notification locale: ID=${notification.id}, Title=${notification.title}',
      tag: 'NOTIFICATION',
    );

    final androidDetails = AndroidNotificationDetails(
      'easyconnect_notifications', // Channel ID - doit correspondre au canal créé
      'Notifications EasyConnect',
      channelDescription: 'Notifications pour les validations et soumissions',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: _getNotificationColorFromString(notification.type),
      playSound: _soundsEnabled, // Le son sera joué si activé
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final payload =
        notification.actionRoute.isNotEmpty
            ? '${notification.actionRoute}:${notification.entityId}'
            : null;

    AppLogger.info(
      'Appel _localNotifications.show: ID=${notification.id.hashCode}, Title=${notification.title}, Sound=${_soundsEnabled}',
      tag: 'NOTIFICATION',
    );

    try {
      await _localNotifications.show(
        notification.id.hashCode,
        fixUtf8Mojibake(notification.title),
        fixUtf8Mojibake(notification.message),
        details,
        payload: payload,
      );
      AppLogger.info(
        'Notification locale affichée avec succès via _localNotifications.show',
        tag: 'NOTIFICATION',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erreur lors de l\'appel _localNotifications.show: $e\nStack: $stackTrace',
        tag: 'NOTIFICATION',
      );
      rethrow;
    }
  }

  /// Jouer un son selon le type
  /// Les sons sont gérés par les notifications locales (sons système)
  /// Pour des sons personnalisés, ajouter des fichiers dans assets/sounds/
  /// et utiliser le package audioplayers
  Future<void> _playSound(String soundType) async {
    // Les sons sont automatiquement joués par les notifications locales
    // via la configuration playSound: true dans AndroidNotificationDetails
    // et presentSound: true dans DarwinNotificationDetails
    AppLogger.debug(
      'Son géré par la notification locale (type: $soundType)',
      tag: 'NOTIFICATION',
    );
  }

  /// Afficher un snackbar (optionnel: défini par l'app via showSnackbarCallback)
  static void Function(String title, String message, Color? backgroundColor,
      VoidCallback? onTap)? showSnackbarCallback;

  Future<void> _showSnackbar(AppNotification notification) async {
    final title = fixUtf8Mojibake(notification.title);
    final message = fixUtf8Mojibake(notification.message);
    final backgroundColor =
        _getSnackbarColorFromString(notification.type);
    if (showSnackbarCallback != null) {
      showSnackbarCallback!(title, message, backgroundColor, () {
        if (notification.actionRoute.isNotEmpty) {
          rootGoRouter?.go(
            notification.actionRoute,
            extra: {
              'entityId': notification.entityId,
              'entityType': notification.entityType,
            },
          );
        }
      });
      return;
    }
    // Fallback: navigation si route présente
    if (notification.actionRoute.isNotEmpty) {
      rootGoRouter?.go(
        notification.actionRoute,
        extra: {
          'entityId': notification.entityId,
          'entityType': notification.entityType,
        },
      );
    }
  }

  /// Obtenir la couleur selon le type de notification (String)
  Color _getNotificationColorFromString(String type) {
    switch (type) {
      case 'success':
        return Colors.green;
      case 'error':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'task':
        return Colors.purple;
      default: // 'info'
        return Colors.blue;
    }
  }

  /// Obtenir la couleur du snackbar (String)
  Color _getSnackbarColorFromString(String type) {
    switch (type) {
      case 'success':
        return Colors.green.shade700;
      case 'error':
        return Colors.red.shade700;
      case 'warning':
        return Colors.orange.shade700;
      case 'task':
        return Colors.purple.shade700;
      default: // 'info'
        return Colors.blue.shade700;
    }
  }

  /// Obtenir l'icône selon le type (String)
  IconData _getNotificationIconFromString(String type) {
    switch (type) {
      case 'success':
        return Icons.check_circle;
      case 'error':
        return Icons.error;
      case 'warning':
        return Icons.warning;
      case 'task':
        return Icons.task;
      default: // 'info'
        return Icons.info;
    }
  }

  /// Marquer une notification comme lue
  void markAsRead(String notificationId) {
    final index = notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      notifications[index] = notifications[index].copyWith(isRead: true);
      _updateUnreadCount();
    }
  }

  /// Marquer toutes les notifications comme lues
  void markAllAsRead() {
    for (int i = 0; i < notifications.length; i++) {
      if (!notifications[i].isRead) {
        notifications[i] = notifications[i].copyWith(isRead: true);
      }
    }
    _updateUnreadCount();
  }

  /// Mettre à jour le compteur de notifications non lues
  void _updateUnreadCount() {
    // Compteur dérivé via getter unreadCount
  }

  /// Supprimer une notification
  void removeNotification(String notificationId) {
    notifications.removeWhere((n) => n.id == notificationId);
    _updateUnreadCount();
  }

  /// Supprimer toutes les notifications
  void clearAllNotifications() {
    notifications.clear();
    _updateUnreadCount();
  }

  /// Annuler toutes les notifications locales
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }
}

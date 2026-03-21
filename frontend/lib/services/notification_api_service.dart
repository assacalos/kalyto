import 'dart:convert';
import 'package:easyconnect/services/http_interceptor.dart';
import 'package:easyconnect/Models/notification_model.dart';
import 'package:easyconnect/services/api_service.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/utils/auth_error_handler.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/retry_helper.dart';
import 'package:easyconnect/services/storage_service.dart';

/// Service API pour récupérer les notifications depuis le backend
class NotificationApiService {
  static final NotificationApiService _instance =
      NotificationApiService._internal();
  factory NotificationApiService() => _instance;
  NotificationApiService._internal();

  /// Récupérer les notifications avec filtres
  Future<List<AppNotification>> getNotifications({
    bool unreadOnly = false,
    String? type,
    String? entityType,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final params = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (unreadOnly) params['unread_only'] = 'true';
      if (type != null) params['type'] = type;
      if (entityType != null) params['entity_type'] = entityType;

      final queryString = Uri(queryParameters: params).query;
      final url = '${AppConfig.baseUrl}/notifications?$queryString';

      AppLogger.httpRequest('GET', url, tag: 'NOTIFICATION_API_SERVICE');

      final response = await RetryHelper.retryNetwork(
        operation:
            () => HttpInterceptor.get(Uri.parse(url), headers: ApiService.headers()),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(
        response.statusCode,
        url,
        tag: 'NOTIFICATION_API_SERVICE',
      );
      await AuthErrorHandler.handleHttpResponse(response);

      if (response.statusCode == 200) {
        final data = ApiService.parseResponse(response);
        if (data['success'] == true) {
          final notificationsData = data['data'] as List<dynamic>;

          // Log détaillé pour déboguer
          AppLogger.info(
            'Notifications reçues depuis l\'API: ${notificationsData.length}',
            tag: 'NOTIFICATION_API_SERVICE',
          );

          // Log du contenu brut pour déboguer (première notification seulement)
          if (notificationsData.isNotEmpty) {
            AppLogger.info(
              'Exemple de notification reçue: ${notificationsData[0]}',
              tag: 'NOTIFICATION_API_SERVICE',
            );
          }

          final notifications =
              notificationsData
                  .map((json) {
                    try {
                      final notification = AppNotification.fromJson(json);
                      // Log chaque notification parsée pour déboguer
                      AppLogger.info(
                        'Notification parsée: ID=${notification.id}, Title=${notification.title}, EntityType=${notification.entityType}, EntityId=${notification.entityId}',
                        tag: 'NOTIFICATION_API_SERVICE',
                      );
                      return notification;
                    } catch (e, stackTrace) {
                      AppLogger.error(
                        'Erreur lors du parsing d\'une notification: $e\nStack: $stackTrace\nJSON: $json',
                        tag: 'NOTIFICATION_API_SERVICE',
                      );
                      return null;
                    }
                  })
                  .whereType<AppNotification>()
                  .toList();

          AppLogger.info(
            'Notifications parsées avec succès: ${notifications.length}/${notificationsData.length}',
            tag: 'NOTIFICATION_API_SERVICE',
          );

          _saveNotificationsToHive(notifications);
          return notifications;
        } else {
          AppLogger.warning(
            'Réponse API sans success=true: $data',
            tag: 'NOTIFICATION_API_SERVICE',
          );
        }
      } else {
        AppLogger.warning(
          'Réponse API avec code ${response.statusCode}: ${response.body}',
          tag: 'NOTIFICATION_API_SERVICE',
        );
      }

      return [];
    } catch (e) {
      AppLogger.error(
        'Erreur lors de la récupération des notifications: $e',
        tag: 'NOTIFICATION_API_SERVICE',
      );
      return [];
    }
  }

  /// Marquer une notification comme lue
  Future<bool> markAsRead(String notificationId) async {
    try {
      final url = '${AppConfig.baseUrl}/notifications/$notificationId/read';

      AppLogger.httpRequest('PUT', url, tag: 'NOTIFICATION_API_SERVICE');

      final response = await RetryHelper.retryNetwork(
        operation:
            () => HttpInterceptor.put(Uri.parse(url), headers: ApiService.headers()),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(
        response.statusCode,
        url,
        tag: 'NOTIFICATION_API_SERVICE',
      );
      await AuthErrorHandler.handleHttpResponse(response);

      if (response.statusCode == 200) {
        final data = ApiService.parseResponse(response);
        return data['success'] == true;
      }

      return false;
    } catch (e) {
      AppLogger.error(
        'Erreur lors du marquage de la notification comme lue: $e',
        tag: 'NOTIFICATION_API_SERVICE',
      );
      return false;
    }
  }

  /// Marquer toutes les notifications comme lues
  Future<bool> markAllAsRead() async {
    try {
      final url = '${AppConfig.baseUrl}/notifications/read-all';

      AppLogger.httpRequest('PUT', url, tag: 'NOTIFICATION_API_SERVICE');

      final response = await RetryHelper.retryNetwork(
        operation:
            () => HttpInterceptor.put(Uri.parse(url), headers: ApiService.headers()),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(
        response.statusCode,
        url,
        tag: 'NOTIFICATION_API_SERVICE',
      );
      await AuthErrorHandler.handleHttpResponse(response);

      if (response.statusCode == 200) {
        final data = ApiService.parseResponse(response);
        return data['success'] == true;
      }

      return false;
    } catch (e) {
      AppLogger.error(
        'Erreur lors du marquage de toutes les notifications comme lues: $e',
        tag: 'NOTIFICATION_API_SERVICE',
      );
      return false;
    }
  }

  /// Obtenir le nombre de notifications non lues
  Future<int> getUnreadCount() async {
    try {
      final url = '${AppConfig.baseUrl}/notifications/unread';

      AppLogger.httpRequest('GET', url, tag: 'NOTIFICATION_API_SERVICE');

      final response = await RetryHelper.retryNetwork(
        operation:
            () => HttpInterceptor.get(Uri.parse(url), headers: ApiService.headers()),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(
        response.statusCode,
        url,
        tag: 'NOTIFICATION_API_SERVICE',
      );
      await AuthErrorHandler.handleHttpResponse(response);

      if (response.statusCode == 200) {
        final data = ApiService.parseResponse(response);
        if (data['success'] == true) {
          return data['count'] ?? 0;
        }
      }

      return 0;
    } catch (e) {
      AppLogger.error(
        'Erreur lors de la récupération du nombre de notifications non lues: $e',
        tag: 'NOTIFICATION_API_SERVICE',
      );
      return 0;
    }
  }

  /// Supprimer une notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final url = '${AppConfig.baseUrl}/notifications/$notificationId';

      AppLogger.httpRequest('DELETE', url, tag: 'NOTIFICATION_API_SERVICE');

      final response = await RetryHelper.retryNetwork(
        operation:
            () => HttpInterceptor.delete(Uri.parse(url), headers: ApiService.headers()),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(
        response.statusCode,
        url,
        tag: 'NOTIFICATION_API_SERVICE',
      );
      await AuthErrorHandler.handleHttpResponse(response);

      if (response.statusCode == 200) {
        final data = ApiService.parseResponse(response);
        return data['success'] == true;
      }

      return false;
    } catch (e) {
      AppLogger.error(
        'Erreur lors de la suppression de la notification: $e',
        tag: 'NOTIFICATION_API_SERVICE',
      );
      return false;
    }
  }

  /// Créer une notification dans le backend
  /// Cette méthode envoie une requête au backend pour créer une notification
  /// Le backend créera la notification dans la BDD et enverra les push FCM
  Future<bool> createNotification({
    required String title,
    required String message,
    required String type,
    required String entityType,
    required String entityId,
    String? actionRoute,
    Map<String, dynamic>? metadata,
    List<int>? recipientIds,
    String? recipientRole,
  }) async {
    try {
      final url = '${AppConfig.baseUrl}/notifications';

      final body = {
        'title': title,
        'message': message,
        'type': type,
        'entity_type': entityType,
        'entity_id': entityId,
        if (actionRoute != null) 'action_route': actionRoute,
        if (metadata != null) 'metadata': metadata,
        if (recipientIds != null) 'recipient_ids': recipientIds,
        if (recipientRole != null) 'recipient_role': recipientRole,
      };

      AppLogger.httpRequest('POST', url, tag: 'NOTIFICATION_API_SERVICE');
      AppLogger.info(
        'Création de notification: $body',
        tag: 'NOTIFICATION_API_SERVICE',
      );

      final response = await RetryHelper.retryNetwork(
        operation: () => HttpInterceptor.post(
          Uri.parse(url),
          headers: {
            ...ApiService.headers(),
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        ),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(
        response.statusCode,
        url,
        tag: 'NOTIFICATION_API_SERVICE',
      );
      await AuthErrorHandler.handleHttpResponse(response);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = ApiService.parseResponse(response);
        if (data['success'] == true) {
          AppLogger.info(
            'Notification créée avec succès dans le backend',
            tag: 'NOTIFICATION_API_SERVICE',
          );
          return true;
        }
      }

      AppLogger.warning(
        'Échec de la création de notification: ${response.statusCode} - ${response.body}',
        tag: 'NOTIFICATION_API_SERVICE',
      );
      return false;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erreur lors de la création de la notification: $e',
        tag: 'NOTIFICATION_API_SERVICE',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  static void _saveNotificationsToHive(List<AppNotification> list) {
    try {
      HiveStorageService.saveEntityList(
        HiveStorageService.keyNotifications,
        list.map((e) => e.toJson()).toList(),
      );
    } catch (_) {}
  }

  /// Cache Hive : liste des notifications pour affichage instantané.
  static List<AppNotification> getCachedNotifications() {
    try {
      final raw = HiveStorageService.getEntityList(HiveStorageService.keyNotifications);
      return raw.map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/Models/notification_model.dart';
import 'package:easyconnect/providers/notification_state.dart';
import 'package:easyconnect/services/notification_api_service.dart';
import 'package:easyconnect/services/notification_navigation_service.dart';
import 'package:easyconnect/services/notification_service_enhanced.dart';
import 'package:easyconnect/services/session_service.dart';
import 'package:easyconnect/utils/logger.dart';

final notificationProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(
  NotificationNotifier.new,
);

/// Callback enregistré pour rafraîchir les notifications sans accès à [ref]
/// (ex: main.dart push, websocket, app_lifecycle).
class NotificationRefreshCallback {
  NotificationRefreshCallback._();
  static final NotificationRefreshCallback instance =
      NotificationRefreshCallback._();

  VoidCallback? _refresh;

  void register(VoidCallback refresh) {
    _refresh = refresh;
  }

  void refresh() => _refresh?.call();
}

class NotificationNotifier extends Notifier<NotificationState> {
  final NotificationApiService _apiService = NotificationApiService();
  final NotificationServiceEnhanced _notificationService =
      NotificationServiceEnhanced();

  Timer? _pollingTimer;
  bool _isPolling = false;
  final Set<String> _seenNotificationIds = <String>{};
  bool _isFirstLoad = true;
  bool _isLoadingInProgress = false;

  @override
  NotificationState build() {
    NotificationRefreshCallback.instance.register(() {
      loadNotifications(forceRefresh: true);
    });
    _notificationService.initialize().catchError((e) {
      AppLogger.error(
        'Erreur lors de l\'initialisation du service de notifications: $e',
        tag: 'NOTIFICATION_NOTIFIER',
      );
    });
    Future.microtask(() => loadNotifications());
    startPolling();
    return const NotificationState();
  }

  Future<void> _updateAppIconBadge() async {
    if (kIsWeb) return; // Pas de badge icône sur le web
    try {
      final supported = await FlutterAppBadger.isAppBadgeSupported();
      if (!supported) return;
      if (!SessionService.isAppInBackground()) {
        await FlutterAppBadger.removeBadge();
        return;
      }
      final count = state.unreadCount;
      if (count <= 0) {
        await FlutterAppBadger.removeBadge();
      } else {
        final displayCount = count > 99 ? 99 : count;
        await FlutterAppBadger.updateBadgeCount(displayCount);
      }
    } catch (e) {
      AppLogger.error(
        'Erreur lors de la mise à jour du badge icône: $e',
        tag: 'NOTIFICATION_NOTIFIER',
        error: e,
      );
    }
  }

  Future<void> loadNotifications({
    bool forceRefresh = false,
    int page = 1,
  }) async {
    if (_isLoadingInProgress) return;
    _isLoadingInProgress = true;

    if (page == 1) {
      state = state.copyWith(isLoading: true);
      final cached = NotificationApiService.getCachedNotifications();
      if (cached.isNotEmpty && !forceRefresh) {
        state = state.copyWith(
          notifications: cached,
          isLoading: false,
          currentPage: 1,
        );
        _isLoadingInProgress = false;
        await refreshUnreadCount();
        return;
      }
      state = state.copyWith(notifications: []);
    } else {
      state = state.copyWith(isLoadingMore: true);
    }

    try {
      final loadedNotifications = await _apiService.getNotifications(
        unreadOnly: state.unreadOnly,
        type: state.selectedType,
        entityType: state.selectedEntityType,
        page: page,
        perPage: state.perPage,
      );

      if (page == 1) {
        if (!_isFirstLoad && forceRefresh) {
          _detectAndShowNewNotifications(loadedNotifications);
        }
        state = state.copyWith(
          notifications: loadedNotifications,
          isLoading: false,
          currentPage: 1,
          totalPages: loadedNotifications.length < state.perPage
              ? 1
              : page + 1,
          totalItems: loadedNotifications.length,
        );
        _seenNotificationIds.addAll(loadedNotifications.map((n) => n.id));
        _isFirstLoad = false;
      } else {
        final merged = [...state.notifications, ...loadedNotifications];
        state = state.copyWith(
          notifications: merged,
          isLoadingMore: false,
          currentPage: page,
          totalPages: loadedNotifications.length < state.perPage
              ? page
              : page + 1,
          totalItems: state.totalItems + loadedNotifications.length,
        );
        _seenNotificationIds.addAll(loadedNotifications.map((n) => n.id));
      }
      await refreshUnreadCount();
    } catch (e) {
      AppLogger.error(
        'Erreur chargement notifications: $e',
        tag: 'NOTIFICATION_NOTIFIER',
      );
      if (state.notifications.isEmpty) {
        final fallback = NotificationApiService.getCachedNotifications();
        if (fallback.isNotEmpty) {
          state = state.copyWith(notifications: fallback, isLoading: false);
        }
      }
      state = state.copyWith(isLoading: false, isLoadingMore: false);
    } finally {
      _isLoadingInProgress = false;
    }
  }

  void _detectAndShowNewNotifications(
    List<AppNotification> loadedNotifications,
  ) {
    try {
      final newNotifications = loadedNotifications
          .where((n) =>
              !_seenNotificationIds.contains(n.id) && !n.isRead)
          .toList();
      for (final notification in newNotifications) {
        String soundType = 'info';
        if (notification.type == 'success') soundType = 'success';
        else if (notification.type == 'error' || notification.type == 'warning')
          soundType = 'error';
        else if (notification.type == 'task') soundType = 'submit';
        _notificationService
            .showNotification(
              notification,
              soundType: soundType,
              addToList: false,
            )
            .catchError((e, st) {
          AppLogger.error(
            'Erreur affichage notification locale: $e',
            tag: 'NOTIFICATION_NOTIFIER',
            error: e,
            stackTrace: st,
          );
        });
      }
    } catch (e, st) {
      AppLogger.error(
        'Erreur détection nouvelles notifications: $e',
        tag: 'NOTIFICATION_NOTIFIER',
        error: e,
        stackTrace: st,
      );
    }
  }

  void loadMore() {
    if (state.hasNextPage && !state.isLoading && !state.isLoadingMore) {
      loadNotifications(page: state.currentPage + 1);
    }
  }

  Future<void> refreshUnreadCount() async {
    try {
      final count = await _apiService.getUnreadCount();
      state = state.copyWith(unreadCount: count);
      await _updateAppIconBadge();
    } catch (e) {
      AppLogger.error(
        'Erreur récupération compteur non lues: $e',
        tag: 'NOTIFICATION_NOTIFIER',
      );
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final success = await _apiService.markAsRead(notificationId);
      if (success) {
        final index = state.notifications
            .indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          final updated = state.notifications[index].copyWith(isRead: true);
          final newList = List<AppNotification>.from(state.notifications);
          newList[index] = updated;
          state = state.copyWith(notifications: newList);
          await refreshUnreadCount();
        }
      }
    } catch (e) {
      AppLogger.error(
        'Erreur marquage comme lue: $e',
        tag: 'NOTIFICATION_NOTIFIER',
      );
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final success = await _apiService.markAllAsRead();
      if (success) {
        final newList = state.notifications
            .map((n) => n.isRead ? n : n.copyWith(isRead: true))
            .toList();
        state = state.copyWith(notifications: newList, unreadCount: 0);
      }
    } catch (e) {
      AppLogger.error(
        'Erreur marquage toutes comme lues: $e',
        tag: 'NOTIFICATION_NOTIFIER',
      );
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      final success = await _apiService.deleteNotification(notificationId);
      if (success) {
        final newList =
            state.notifications.where((n) => n.id != notificationId).toList();
        state = state.copyWith(notifications: newList);
        await refreshUnreadCount();
      }
    } catch (e) {
      AppLogger.error(
        'Erreur suppression notification: $e',
        tag: 'NOTIFICATION_NOTIFIER',
      );
    }
  }

  void startPolling({Duration? interval}) {
    if (_isPolling) return;
    _isPolling = true;
    final duration = interval ??
        (kIsWeb ? const Duration(seconds: 45) : const Duration(seconds: 30));
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(duration, (_) {
      loadNotifications(forceRefresh: true);
    });
  }

  void stopPolling() {
    _isPolling = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void filterByType(String? type) {
    state = state.copyWith(
      selectedType: type?.isEmpty == true ? null : type,
    );
    loadNotifications(forceRefresh: true, page: 1);
  }

  void filterByEntityType(String? entityType) {
    state = state.copyWith(
      selectedEntityType: entityType?.isEmpty == true ? null : entityType,
    );
    loadNotifications(forceRefresh: true, page: 1);
  }

  void toggleUnreadOnly() {
    state = state.copyWith(unreadOnly: !state.unreadOnly);
    loadNotifications(forceRefresh: true, page: 1);
  }

  void handleNotificationTap(AppNotification notification) {
    if (!notification.isRead) {
      markAsRead(notification.id);
    }
    NotificationNavigationService().handleNavigationFromNotification(notification);
  }
}

import 'package:easyconnect/Models/notification_model.dart';
import 'package:easyconnect/utils/encoding_helper.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  static NotificationService get to => _instance;
  factory NotificationService() => _instance;
  NotificationService._();

  final List<AppNotification> notifications = [];
  int get unreadCount => notifications.where((n) => !n.isRead).length;

  void startNotificationListener() {}

  void addNotification(AppNotification notification) {
    notifications.insert(0, notification);
    _updateUnreadCount();
  }

  void markAsRead(String notificationId) {
    final index = notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      notifications[index] = notifications[index].copyWith(isRead: true);
      _updateUnreadCount();
    }
  }

  void _updateUnreadCount() {
    // Caller peut écouter ou rafraîchir via notifier Riverpod
  }

  /// À appeler par l'UI pour afficher un snackbar (ex: avec ScaffoldMessenger).
  static String getNotificationTitle(AppNotification n) =>
      fixUtf8Mojibake(n.title);
  static String getNotificationMessage(AppNotification n) =>
      fixUtf8Mojibake(n.message);
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/Views/Components/paginated_list_view.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/providers/notification_notifier.dart';
import 'package:easyconnect/Models/notification_model.dart';
import 'package:easyconnect/utils/encoding_helper.dart' show fixUtf8Mojibake;

/// Page de liste des notifications (Riverpod).
class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);
    final notifier = ref.read(notificationProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: Icon(
              state.unreadOnly ? Icons.filter_list : Icons.filter_list_off,
            ),
            tooltip: 'Filtrer les non lues',
            onPressed: () => notifier.toggleUnreadOnly(),
          ),
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () async {
                await notifier.markAllAsRead();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Toutes les notifications ont été marquées comme lues',
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text(
                'Tout marquer comme lu',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: state.isLoading && state.notifications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.unreadOnly
                            ? 'Aucune notification non lue'
                            : 'Aucune notification',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      notifier.loadNotifications(forceRefresh: true),
                  child: PaginatedListView(
                    scrollController: _scrollController,
                    onLoadMore: notifier.loadMore,
                    hasNextPage: state.hasNextPage,
                    isLoadingMore: state.isLoadingMore,
                    padding: const EdgeInsets.all(8),
                    itemCount: state.notifications.length,
                    itemBuilder: (context, index) {
                      final notification = state.notifications[index];
                      return NotificationItemWidget(
                        notification: notification,
                        onTap: () =>
                            notifier.handleNotificationTap(notification),
                        onLongPress: () => _showDeleteDialog(
                          context,
                          notifier,
                          notification,
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    NotificationNotifier notifier,
    AppNotification notification,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la notification'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer cette notification ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              notifier.deleteNotification(notification.id);
              Navigator.of(context).pop();
            },
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget pour afficher un élément de notification.
class NotificationItemWidget extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const NotificationItemWidget({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColorFromHex(notification.colorHex);
    final icon = _getIconFromName(notification.iconName);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: notification.isRead ? 1 : 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          fixUtf8Mojibake(notification.title),
          style: TextStyle(
            fontWeight:
                notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(fixUtf8Mojibake(notification.message)),
            if (notification.rejectionReason != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.red.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Raison: ${notification.rejectionReason}',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.red.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              _formatDate(notification.createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: notification.isRead
            ? null
            : const Icon(Icons.circle, color: Colors.blue, size: 8),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }

  static Color _getColorFromHex(String hex) {
    return Color(int.parse(hex.replaceAll('#', '0xFF')));
  }

  static IconData _getIconFromName(String name) {
    switch (name) {
      case 'check_circle':
        return Icons.check_circle;
      case 'error':
        return Icons.error;
      case 'warning':
        return Icons.warning;
      case 'task':
        return Icons.task;
      default:
        return Icons.info;
    }
  }

  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'Il y a ${difference.inMinutes} min';
      }
      return 'Il y a ${difference.inHours} h';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }
}

/// Widget badge pour afficher le compteur de notifications non lues.
class NotificationBadge extends ConsumerWidget {
  final Widget child;

  const NotificationBadge({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(notificationProvider).unreadCount;
    if (count == 0) return child;
    return Badge(label: Text('$count'), child: child);
  }
}

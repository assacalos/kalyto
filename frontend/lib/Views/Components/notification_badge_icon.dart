import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/providers/notification_notifier.dart';

/// Icône de notifications avec badge (compteur non lues) - Riverpod.
/// Utilisée dans la barre du dashboard, la bottom bar et la page Profil (Patron).
class NotificationBadgeIcon extends ConsumerWidget {
  const NotificationBadgeIcon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(notificationProvider).unreadCount;
    if (count > 0) {
      return Badge(
        label: Text(
          count > 99 ? '99+' : '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        child: const Icon(Icons.notifications),
      );
    }
    return const Icon(Icons.notifications);
  }
}

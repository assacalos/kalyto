import 'package:easyconnect/providers/host_provider.dart';
import 'package:easyconnect/Views/Components/notification_badge_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BottomBarItem {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool showBadge;

  BottomBarItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.showBadge = false,
  });
}

class BottomBarWidget extends ConsumerWidget {
  final List<BottomBarItem> items;

  const BottomBarWidget({super.key, required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(hostIndexProvider);

    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blueGrey.shade800,
      unselectedItemColor: Colors.grey,
      items: items.map((item) {
        if (item.showBadge && item.icon == Icons.notifications) {
          return BottomNavigationBarItem(
            icon: const NotificationBadgeIcon(),
            label: item.label,
          );
        }
        return BottomNavigationBarItem(
          icon: Icon(item.icon),
          label: item.label,
        );
      }).toList(),
      onTap: (index) {
        ref.read(hostIndexProvider.notifier).state = index;
        if (items[index].onTap != null) {
          items[index].onTap!();
        }
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/favorites_notifier.dart';

class FavoritesBar extends ConsumerWidget {
  final List<FavoriteItem> items;
  final bool showTitle;

  const FavoritesBar({super.key, required this.items, this.showTitle = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesState = ref.watch(favoritesProvider);
    final favoriteItems = items.where((item) => favoritesState.isFavorite(item.id)).toList();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTitle) ...[
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    'Favoris',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            if (favoriteItems.isEmpty)
              Center(
                child: Text(
                  'Aucun favori',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: favoriteItems.map((item) {
                  return InputChip(
                    avatar: Icon(item.icon, size: 18),
                    label: Text(item.label),
                    onPressed: () {
                      if (item.onTap != null) {
                        item.onTap!();
                      } else if (item.route != null) {
                        context.go(item.route!);
                      }
                    },
                    deleteIcon: const Icon(Icons.star, size: 18),
                    onDeleted: () => ref.read(favoritesProvider.notifier).toggleFavorite(item.id),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class FavoriteItem {
  final String id;
  final String label;
  final IconData icon;
  final String? route;
  final Function()? onTap;

  const FavoriteItem({
    required this.id,
    required this.label,
    required this.icon,
    this.route,
    this.onTap,
  }) : assert(
         route != null || onTap != null,
         'Either route or onTap must be provided',
       );
}

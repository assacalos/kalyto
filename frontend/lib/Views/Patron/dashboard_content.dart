import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/patron_dashboard_notifier.dart';
import 'package:easyconnect/Views/Components/stats_grid.dart';
import 'package:easyconnect/Views/Components/favorites_bar.dart';

/// Contenu du dashboard patron (stats). Utilise le notifier Riverpod.
/// Note: Non utilisé par le routeur actuel (PatronDashboardEnhanced a son propre contenu).
class DashboardContent extends ConsumerWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(patronDashboardProvider);
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 1200 ? 3 : 2;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FavoritesBar(
            items: [
              FavoriteItem(
                id: 'revenue',
                label: "Chiffre d'affaires",
                icon: Icons.euro,
                onTap: () => context.go('/patron/finances'),
              ),
              FavoriteItem(
                id: 'employees',
                label: 'Employés',
                icon: Icons.people,
                onTap: () => context.go('/admin/users'),
              ),
              FavoriteItem(
                id: 'tickets',
                label: 'Tickets',
                icon: Icons.build,
                onTap: () => context.go('/technicien'),
              ),
            ],
          ),
          asyncState.when(
            data: (state) => Padding(
              padding: const EdgeInsets.all(16),
              child: StatsGrid(
                stats: state.enhancedStats,
                isLoading: state.isLoading,
                crossAxisCount: crossAxisCount,
              ),
            ),
            loading: () => Padding(
              padding: const EdgeInsets.all(16),
              child: StatsGrid(
                stats: const [],
                isLoading: true,
                crossAxisCount: crossAxisCount,
              ),
            ),
            error: (_, __) => Padding(
              padding: const EdgeInsets.all(16),
              child: StatsGrid(
                stats: const [],
                isLoading: false,
                crossAxisCount: crossAxisCount,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

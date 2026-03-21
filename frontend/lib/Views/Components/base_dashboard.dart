import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/Views/Components/interactive_chart.dart';
import 'package:easyconnect/Views/Components/filter_bar.dart';
import 'package:easyconnect/Views/Components/stats_grid.dart';
import 'package:easyconnect/Views/Components/favorites_bar.dart';
import 'package:easyconnect/Views/Components/paginated_data_view.dart';
import 'package:easyconnect/Views/Components/user_profile_card.dart';
import 'package:easyconnect/Views/Components/notification_badge_icon.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/utils/dashboard_entity_colors.dart';
import 'package:easyconnect/Views/Components/data_chart.dart';
import 'package:easyconnect/utils/permissions.dart';

/// Base dashboard abstrait. Les sous-classes doivent fournir [controller] (objet avec
/// loadNextPage, hasMoreData, isLoading, chartData, loadInitialData) et les getters
/// title, primaryColor, etc. Pour une migration complète vers Riverpod, préférez
/// les dashboards *Enhanced qui utilisent les notifiers Riverpod.
abstract class BaseDashboard<T> extends ConsumerWidget {
  const BaseDashboard({super.key});

  T get controller;

  String get title;
  Color get primaryColor;
  List<Filter> get availableFilters;
  List<FavoriteItem> get favoriteItems;
  List<StatCard> get statsCards;
  Map<String, ChartConfig> get charts;
  Widget buildCustomContent(BuildContext context);

  bool get hasMoreData;
  bool get isLoading;
  List<ChartData> getChartData(String chartKey);

  /// Override to enable pull-to-refresh.
  Future<void> Function()? get onRefresh => null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bodyContent = PaginatedDataView(
        scrollController: ScrollController(),
        onLoadMore: () => (controller as dynamic).loadNextPage(),
        hasMoreData: hasMoreData,
        isLoading: isLoading,
        children: [
          UserProfileCard(showPermissions: false),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: charts.entries.map((entry) {
                final chartKey = entry.key;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: InteractiveChart(
                    title: entry.value.title,
                    data: getChartData(chartKey),
                    type: entry.value.type,
                    color: entry.value.color,
                    isLoading: isLoading,
                    subtitle: entry.value.subtitle,
                    requiredPermission: entry.value.requiredPermission,
                    enableZoom: entry.value.enableZoom,
                    showTooltips: entry.value.showTooltips,
                    showLegend: entry.value.showLegend,
                    onDataPointTap: entry.value.onDataPointTap,
                  ),
                );
              }).toList(),
            ),
          ),
          buildCustomContent(context),
        ],
      );

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: buildAppBarActions(context),
      ),
      drawer: buildDrawer(context, ref),
      body: onRefresh != null
          ? RefreshIndicator(
              onRefresh: onRefresh!,
              child: bodyContent,
            )
          : bodyContent,
      bottomNavigationBar: buildBottomNavigationBar(context),
      floatingActionButton: buildFloatingActionButton(),
    );
  }

  List<Widget> buildAppBarActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.refresh, color: Colors.white),
        onPressed: () => (controller as dynamic).loadInitialData(),
        tooltip: 'Actualiser',
      ),
    ];
  }

  Widget? buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.grey,
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
        const BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Rechercher'),
        BottomNavigationBarItem(
          icon: const NotificationBadgeIcon(),
          label: 'Notifications',
        ),
        // BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Chat'),
        const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        const BottomNavigationBarItem(
          icon: Icon(Icons.photo_library),
          label: 'Médias',
        ),
      ],
      onTap: (index) {
        // Navigation basée sur l'index
        switch (index) {
          case 0:
            // Accueil - déjà sur le dashboard
            break;
          case 1:
            // Rechercher
            context.go('/search');
            break;
          case 2:
            // Notifications
            context.go('/notifications');
            break;
          // case 3:
          //   // Chat
          //   break;
          case 3:
            // Profil
            context.go('/profile');
            break;
          case 4:
            // Médias
            context.go('/media');
            break;
        }
      },
    );
  }

  Widget? buildFloatingActionButton() => null;

  Widget buildDrawer(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Drawer(
      child: Container(
        color: Colors.grey.shade900,
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: primaryColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Rôle: ${Roles.getRoleName(user?.role)}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            ...buildDrawerItems(context),

            const Divider(color: Colors.white54),

            ListTile(
              leading: Icon(Icons.access_time, color: DashboardEntityColors.pointages, size: 22),
              title: const Text(
                'Pointage',
                style: TextStyle(color: Colors.white70),
              ),
              onTap: () {
                Navigator.pop(context);
                context.go('/attendance-punch');
              },
            ),
            ListTile(
              leading: Icon(Icons.analytics, color: DashboardEntityColors.rapports, size: 22),
              title: const Text(
                'Reporting',
                style: TextStyle(color: Colors.white70),
              ),
              onTap: () {
                Navigator.pop(context);
                context.go('/reporting');
              },
            ),
            ListTile(
              leading: Icon(Icons.task_alt, color: DashboardEntityColors.tasks, size: 22),
              title: const Text(
                'Mes tâches',
                style: TextStyle(color: Colors.white70),
              ),
              onTap: () {
                Navigator.pop(context);
                context.go('/tasks');
              },
            ),
            if (user?.role == 1)
              ListTile(
                leading: Icon(Icons.settings, color: DashboardEntityColors.parametres, size: 22),
                title: const Text(
                  'Paramètres',
                  style: TextStyle(color: Colors.white70),
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/admin/settings');
                },
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> buildDrawerItems(BuildContext context);
}

class ChartConfig {
  final String title;
  final ChartType type;
  final Color color;
  final String? subtitle;
  final Permission? requiredPermission;
  final bool enableZoom;
  final bool showTooltips;
  final bool showLegend;
  final Function(ChartData)? onDataPointTap;

  const ChartConfig({
    required this.title,
    required this.type,
    required this.color,
    this.subtitle,
    this.requiredPermission,
    this.enableZoom = true,
    this.showTooltips = true,
    this.showLegend = true,
    this.onDataPointTap,
  });
}

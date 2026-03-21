import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/providers/rh_dashboard_notifier.dart';
import 'package:easyconnect/providers/rh_dashboard_state.dart';
import 'package:easyconnect/providers/dashboard_refresh_callback.dart';
import 'package:easyconnect/Views/Components/notification_badge_icon.dart';
import 'package:easyconnect/Views/Components/user_profile_card.dart';
import 'package:easyconnect/Views/Components/paginated_data_view.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/utils/dashboard_entity_colors.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';
import 'package:easyconnect/Views/Components/rendements_et_alertes_card.dart';

/// Dashboard RH migré vers Riverpod.
class RhDashboardEnhanced extends ConsumerStatefulWidget {
  const RhDashboardEnhanced({super.key});

  static const String title = 'RH';
  static const Color primaryColor = Color(0xFF6B21A8);

  @override
  ConsumerState<RhDashboardEnhanced> createState() =>
      _RhDashboardEnhancedState();
}

class _RhDashboardEnhancedState extends ConsumerState<RhDashboardEnhanced> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DashboardRefreshCallback.instance.refreshRh = () {
        ref.read(rhDashboardProvider.notifier).refresh();
      };
    });
  }

  @override
  void dispose() {
    DashboardRefreshCallback.instance.refreshRh = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(rhDashboardProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text(RhDashboardEnhanced.title),
        backgroundColor: RhDashboardEnhanced.primaryColor,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => ref.read(rhDashboardProvider.notifier).refresh(),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: asyncState.when(
        data: (state) => RefreshIndicator(
          onRefresh: () => ref.read(rhDashboardProvider.notifier).refresh(),
          child: _buildBody(context, state),
        ),
        loading: () =>
            _buildBody(context, const RhDashboardState(isLoading: true)),
        error: (e, _) => _buildErrorBody(context, e, () => ref.read(rhDashboardProvider.notifier).refresh()),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildErrorBody(BuildContext context, Object error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              'Impossible de charger le dashboard.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, RhDashboardState state) {
    return PaginatedDataView(
      scrollController: _scrollController,
      onLoadMore: () {},
      hasMoreData: false,
      isLoading: state.isLoading,
      children: [
        const UserProfileCard(showPermissions: false),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(context),
              const SizedBox(height: 24),
              _buildQuickActions(context),
              const SizedBox(height: 24),
              _buildRendementsEtAlertes(context, state),
              const SizedBox(height: 28),
              _buildSectionLabel(
                  'En attente', Icons.schedule, const Color(0xFFF59E0B)),
              const SizedBox(height: 12),
              _buildPendingSection(context, state),
              const SizedBox(height: 28),
              _buildSectionLabel(
                  'Validés', Icons.check_circle_outline, const Color(0xFF059669)),
              const SizedBox(height: 12),
              _buildValidatedSection(context, state),
              const SizedBox(height: 28),
              _buildSectionLabel(
                  'Montants', Icons.trending_up, const Color(0xFF7C3AED)),
              const SizedBox(height: 12),
              _buildStatisticsSection(context, state, isWeb: kIsWeb),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final prenom =
        user?.prenom?.trim().isNotEmpty == true ? user!.prenom! : 'RH';
    final hour = DateTime.now().hour;
    final greeting =
        hour < 12 ? 'Bonjour' : hour < 18 ? 'Bon après-midi' : 'Bonsoir';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6B21A8), Color(0xFF7C3AED)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting, $prenom',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(DateTime.now()),
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(
          label: 'Employés',
          icon: Icons.people,
          route: '/employees',
          color: DashboardEntityColors.employes),
      _QuickAction(
          label: 'Congés',
          icon: Icons.beach_access,
          route: '/leaves',
          color: DashboardEntityColors.conges),
      _QuickAction(
          label: 'Recrutement',
          icon: Icons.person_add,
          route: '/recruitment',
          color: DashboardEntityColors.recruitment),
      _QuickAction(
          label: 'Contrats',
          icon: Icons.description,
          route: '/contracts',
          color: DashboardEntityColors.contracts),
      _QuickAction(
          label: 'Pointages',
          icon: Icons.access_time,
          route: '/attendance-punch',
          color: DashboardEntityColors.attendance),
    ];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final a = actions[index];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.go(a.route),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: a.color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: a.color.withOpacity(0.2), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(a.icon, size: 20, color: a.color),
                    const SizedBox(width: 8),
                    Text(
                      a.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRendementsEtAlertes(
    BuildContext context,
    RhDashboardState state,
  ) {
    final rendements = <RendementItem>[
      RendementItem(
        label: 'Employés actifs',
        value: state.activeEmployees.toString(),
        route: '/employees',
        icon: Icons.people,
        color: const Color(0xFF059669),
      ),
      RendementItem(
        label: 'Congés approuvés',
        value: state.approvedLeaves.toString(),
        route: '/leaves',
        icon: Icons.beach_access,
        color: DashboardEntityColors.conges,
      ),
      RendementItem(
        label: 'Recrutements finalisés',
        value: state.completedRecruitments.toString(),
        route: '/recruitment',
        icon: Icons.person_add,
        color: DashboardEntityColors.recruitment,
      ),
      RendementItem(
        label: 'Salaires versés',
        value: state.paidSalaries.toString(),
        route: '/salaries',
        icon: Icons.account_balance_wallet,
        color: DashboardEntityColors.salaries,
      ),
      RendementItem(
        label: 'Contrats approuvés',
        value: state.approvedContracts.toString(),
        route: '/contracts',
        icon: Icons.description,
        color: DashboardEntityColors.contracts,
      ),
    ];
    final alertes = <AlerteItem>[
      if (state.pendingLeaves > 0)
        AlerteItem(
          message: '${state.pendingLeaves} demande(s) de congé en attente',
          route: '/leaves',
          icon: Icons.beach_access,
          color: const Color(0xFFF59E0B),
        ),
      if (state.pendingRecruitments > 0)
        AlerteItem(
          message: '${state.pendingRecruitments} recrutement(s) en attente',
          route: '/recruitment',
          icon: Icons.person_add,
          color: const Color(0xFFF59E0B),
        ),
      if (state.pendingAttendance > 0)
        AlerteItem(
          message: '${state.pendingAttendance} pointage(s) en attente',
          route: '/attendance-punch',
          icon: Icons.access_time,
          color: const Color(0xFFF59E0B),
        ),
      if (state.pendingContracts > 0)
        AlerteItem(
          message: '${state.pendingContracts} contrat(s) en attente',
          route: '/contracts',
          icon: Icons.description,
          color: const Color(0xFFF59E0B),
        ),
      if (state.pendingTasks > 0)
        AlerteItem(
          message: '${state.pendingTasks} tâche(s) à traiter',
          route: '/tasks',
          icon: Icons.task_alt,
          color: const Color(0xFFDC2626),
        ),
    ];
    return RendementsEtAlertesCard(
      titleRendements: 'Mes rendements',
      rendements: rendements,
      titleAlertes: 'À faire / Ce qui ne va pas',
      alertes: alertes,
    );
  }

  Widget _buildPendingSection(BuildContext context, RhDashboardState state) {
    final items = [
      _Item('Congés', state.pendingLeaves, Icons.beach_access,
          DashboardEntityColors.conges, '/leaves'),
      _Item('Recrutements', state.pendingRecruitments, Icons.person_add,
          DashboardEntityColors.recruitment, '/recruitment'),
      _Item('Pointages', state.pendingAttendance, Icons.access_time,
          DashboardEntityColors.attendance, '/attendance-punch'),
      _Item('Contrats', state.pendingContracts, Icons.description,
          DashboardEntityColors.contracts, '/contracts'),
      _Item('Tâches', state.pendingTasks, Icons.task_alt,
          DashboardEntityColors.tasks, '/tasks'),
    ];
    final crossCount = MediaQuery.of(context).size.width > 800 ? 4 : 2;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossCount,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: items
          .map((e) => _buildModernCard(
                title: e.title,
                count: e.count,
                icon: e.icon,
                color: e.color,
                onTap: () => context.go(e.route),
                badgeColor: const Color(0xFFF59E0B),
                isLoading: state.isLoading,
              ))
          .toList(),
    );
  }

  Widget _buildValidatedSection(BuildContext context, RhDashboardState state) {
    final items = [
      _ValidatedItem('Congés', state.approvedLeaves, Icons.beach_access,
          DashboardEntityColors.conges, 'Validés', '/leaves?tab=2'),
      _ValidatedItem('Recrutements', state.completedRecruitments,
          Icons.person_add, DashboardEntityColors.recruitment, 'Embauches',
          '/recruitment?tab=2'),
      _ValidatedItem('Contrats', state.approvedContracts, Icons.description,
          DashboardEntityColors.contracts, 'Actifs', '/contracts?tab=2'),
    ];
    final crossCount = MediaQuery.of(context).size.width > 800 ? 3 : 2;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossCount,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: items
          .map((e) => _buildModernCard(
                title: e.title,
                count: e.count,
                icon: e.icon,
                color: e.color,
                subtitle: e.subtitle,
                onTap: () => context.go(e.route),
                badgeColor: const Color(0xFF059669),
                isLoading: state.isLoading,
              ))
          .toList(),
    );
  }

  Widget _buildStatisticsSection(BuildContext context, RhDashboardState state, {bool isWeb = false}) {
    final items = [
      _RhStatItem('Employés actifs', state.activeEmployees.toString(), null, Icons.people, const Color(0xFF3B82F6), 'Effectif total'),
      _RhStatItem('Primes versées', _formatAmount(state.totalBonuses), state.totalBonuses, Icons.card_giftcard, const Color(0xFF10B981), 'Montant des primes distribuées'),
      _RhStatItem('Coût recrutement', _formatAmount(state.recruitmentCost), state.recruitmentCost, Icons.person_add, const Color(0xFFF59E0B), 'Coût total du recrutement'),
      _RhStatItem('Coût formation', _formatAmount(state.trainingCost), state.trainingCost, Icons.school, const Color(0xFF3B82F6), 'Investissement formation'),
    ];
    if (isWeb) {
      final values = [state.totalBonuses, state.recruitmentCost, state.trainingCost];
      final maxVal = values.fold<double>(0, (a, b) => b > a ? b : a);
      final scale = maxVal <= 0 ? 1.0 : maxVal;
      final colors = [const Color(0xFF10B981), const Color(0xFFF59E0B), const Color(0xFF3B82F6)];
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: _buildRhBarChart(context, state, scale, colors),
          ),
          const SizedBox(width: 20),
          SizedBox(
            width: 260,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildRhStatCompact(context, item),
              )).toList(),
            ),
          ),
        ],
      );
    }
    return Column(
      children: items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildStatRow(item.title, item.displayValue, item.icon, item.color, item.subtitle),
      )).toList(),
    );
  }

  Widget _buildRhBarChart(BuildContext context, RhDashboardState state, double scale, List<Color> colors) {
    const double minBarY = 0.04;
    final values = [state.totalBonuses, state.recruitmentCost, state.trainingCost];
    final labels = ['Primes', 'Recrut.', 'Formation'];
    double toYVisible(double v) {
      final y = (scale <= 0 ? 0.0 : (v / scale).clamp(0.0, 1.0));
      return (scale > 0 && y < minBarY) ? minBarY : y;
    }
    final hasNoData = scale <= 0 || values.every((v) => v <= 0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Montants RH', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            width: double.infinity,
            child: state.isLoading
                ? Center(child: CircularProgressIndicator(color: RhDashboardEnhanced.primaryColor))
                : hasNoData
                    ? Center(child: Text('Aucune donnée', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)))
                    : LayoutBuilder(
                        builder: (ctx, constraints) => BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: 1.15,
                            barTouchData: BarTouchData(enabled: false),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, meta) => Text(labels[v.toInt().clamp(0, 2)], style: TextStyle(fontSize: 11, color: Colors.grey.shade600)))),
                              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade200, strokeWidth: 1)),
                            borderData: FlBorderData(show: false),
                            barGroups: List.generate(3, (i) => BarChartGroupData(
                              x: i,
                              barRods: [BarChartRodData(
                                toY: toYVisible(values[i]),
                                color: colors[i],
                                width: 36,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                              )],
                            )),
                          ),
                          duration: const Duration(milliseconds: 300),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildRhStatCompact(BuildContext context, _RhStatItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: item.color, width: 3)),
        boxShadow: [BoxShadow(color: item.color.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Icon(item.icon, size: 18, color: item.color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item.title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(item.displayValue, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: item.color), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatAmount(double value) {
    if (value >= 1e6) {
      return '${NumberFormat('#,##0', 'fr_FR').format(value ~/ 1e6)} M FCFA';
    }
    if (value >= 1e3) {
      return '${NumberFormat('#,##0', 'fr_FR').format(value ~/ 1e3)} k FCFA';
    }
    return '${NumberFormat('#,##0', 'fr_FR').format(value)} FCFA';
  }

  Widget _buildStatRow(
      String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required Color badgeColor,
    String? subtitle,
    bool isLoading = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border(left: BorderSide(color: color, width: 4)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 22, color: color),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: isLoading
                        ? Shimmer(
                            baseColor: badgeColor.withOpacity(0.25),
                            highlightColor: badgeColor.withOpacity(0.5),
                            child: Text(
                              count.toString(),
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: badgeColor),
                            ),
                          )
                        : Text(
                            count.toString(),
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: badgeColor),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    subtitle,
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final userRole = ref.watch(authProvider).user?.role;
    return Drawer(
      child: Container(
        color: Colors.grey.shade900,
        child: ListView(
          children: [
            DrawerHeader(
              decoration:
                  BoxDecoration(color: RhDashboardEnhanced.primaryColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    RhDashboardEnhanced.title,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rôle: ${Roles.getRoleName(userRole)}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            _drawerItem(Icons.people, 'Employés', DashboardEntityColors.employes,
                () => _nav(context, '/employees')),
            _drawerItem(Icons.beach_access, 'Congés',
                DashboardEntityColors.conges, () => _nav(context, '/leaves')),
            _drawerItem(Icons.person_add, 'Recrutement',
                DashboardEntityColors.recruitment,
                () => _nav(context, '/recruitment')),
            _drawerItem(Icons.description, 'Contrats',
                DashboardEntityColors.contracts,
                () => _nav(context, '/contracts')),
            _drawerItem(Icons.access_time, 'Pointages',
                DashboardEntityColors.attendance, () {
              Navigator.pop(context);
              context.go('/attendance-punch');
            }),
            if (userRole == 1)
              _drawerItem(Icons.settings, 'Paramètres',
                  DashboardEntityColors.parametres, () {
                Navigator.pop(context);
                context.go('/admin/settings');
              }),
            const Divider(color: Colors.white54),
            ListTile(
              leading: Icon(Icons.task_alt,
                  color: DashboardEntityColors.tasks, size: 22),
              title:
                  const Text('Mes tâches', style: TextStyle(color: Colors.white70)),
              onTap: () {
                Navigator.pop(context);
                context.go('/tasks');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: RhDashboardEnhanced.primaryColor,
      unselectedItemColor: Colors.grey,
      items: [
        const BottomNavigationBarItem(
            icon: Icon(Icons.home), label: 'Accueil'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.search), label: 'Rechercher'),
        const BottomNavigationBarItem(
            icon: NotificationBadgeIcon(), label: 'Notifications'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.person), label: 'Profil'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.photo_library), label: 'Médias'),
      ],
      onTap: (index) {
        switch (index) {
          case 1:
            context.go('/search');
            break;
          case 2:
            context.go('/notifications');
            break;
          case 3:
            context.go('/profile');
            break;
          case 4:
            context.go('/media');
            break;
        }
      },
    );
  }

  void _nav(BuildContext context, String route) {
    Navigator.pop(context);
    context.go(route);
  }

  Widget _drawerItem(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(label,
          style: const TextStyle(color: Colors.white70, fontSize: 15)),
      onTap: onTap,
    );
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final String route;
  final Color color;
  _QuickAction(
      {required this.label,
      required this.icon,
      required this.route,
      required this.color});
}

class _Item {
  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final String route;
  _Item(this.title, this.count, this.icon, this.color, this.route);
}

class _ValidatedItem {
  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final String subtitle;
  final String route;
  _ValidatedItem(
      this.title, this.count, this.icon, this.color, this.subtitle, this.route);
}

class _RhStatItem {
  final String title;
  final String displayValue;
  final double? chartValue;
  final IconData icon;
  final Color color;
  final String subtitle;
  _RhStatItem(this.title, this.displayValue, this.chartValue, this.icon, this.color, this.subtitle);
}

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/providers/patron_dashboard_notifier.dart';
import 'package:easyconnect/providers/patron_dashboard_state.dart';
import 'package:easyconnect/providers/patron_validation_item.dart';
import 'package:easyconnect/providers/dashboard_refresh_callback.dart';
import 'package:easyconnect/Views/Components/notification_badge_icon.dart';
import 'package:easyconnect/Views/Components/user_profile_card.dart';
import 'package:easyconnect/Views/Components/paginated_data_view.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/utils/dashboard_entity_colors.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';
import 'package:easyconnect/utils/error_helper.dart';

/// Dashboard Patron migré vers Riverpod.
class PatronDashboardEnhanced extends ConsumerStatefulWidget {
  const PatronDashboardEnhanced({super.key});

  static const String title = 'Direction';
  static const Color primaryColor = Color(0xFF0F172A);

  @override
  ConsumerState<PatronDashboardEnhanced> createState() =>
      _PatronDashboardEnhancedState();
}

class _PatronDashboardEnhancedState extends ConsumerState<PatronDashboardEnhanced> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DashboardRefreshCallback.instance.refreshPatron = () {
        ref.read(patronDashboardProvider.notifier).refresh();
      };
    });
  }

  @override
  void dispose() {
    DashboardRefreshCallback.instance.refreshPatron = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(patronDashboardProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text(PatronDashboardEnhanced.title),
        backgroundColor: PatronDashboardEnhanced.primaryColor,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () =>
                ref.read(patronDashboardProvider.notifier).refresh(),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: asyncState.when(
        data: (state) => RefreshIndicator(
          onRefresh: () =>
              ref.read(patronDashboardProvider.notifier).refresh(),
          child: _buildBody(context, state),
        ),
        loading: () => _buildBody(
          context,
          const PatronDashboardState(isLoading: true),
        ),
        error: (e, _) => _buildErrorBody(context, e, () => ref.read(patronDashboardProvider.notifier).refresh()),
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

  Widget _buildBody(BuildContext context, PatronDashboardState state) {
    return PaginatedDataView(
      scrollController: _scrollController,
      onLoadMore: () {},
      hasMoreData: false,
      isLoading: state.isLoading,
      children: [
        const UserProfileCard(showPermissions: false),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(context),
              const SizedBox(height: 20),
              _buildSectionLabel('Chiffres clés', Icons.insights, const Color(0xFF059669)),
              const SizedBox(height: 8),
              _buildKpiPeriodSelector(context, state),
              const SizedBox(height: 10),
              _buildKpisSection(context, state),
              if (state.rappels.isNotEmpty) ...[
                const SizedBox(height: 14),
                _buildRappelsSection(context, state),
              ],
              const SizedBox(height: 24),
              _buildSectionLabel('Urgence & validations', Icons.pending_actions, const Color(0xFFEA580C)),
              const SizedBox(height: 10),
              _buildUrgenceSection(context, state),
              const SizedBox(height: 24),
              _buildSectionLabel('Opérations en cours', Icons.sync_alt, const Color(0xFF6366F1)),
              const SizedBox(height: 10),
              _buildOperationsSection(context, state),
              const SizedBox(height: 20),
              _buildQuickActions(context),
              const SizedBox(height: 16),
              _buildSectionLabel('Toutes les validations', Icons.approval, const Color(0xFFF59E0B)),
              const SizedBox(height: 12),
              _buildValidationSection(context, state),
              const SizedBox(height: 24),
              _buildSectionLabel('Métriques', Icons.trending_up, const Color(0xFF059669)),
              const SizedBox(height: 12),
              _buildPerformanceSection(context, state),
            ],
          ),
        ),
      ],
    );
  }

  static String _formatKpi(double value) {
    if (value >= 1e6) return '${NumberFormat('#,##0', 'fr_FR').format(value / 1e6)} M';
    if (value >= 1e3) return '${NumberFormat('#,##0', 'fr_FR').format(value / 1e3)} k';
    return NumberFormat('#,##0', 'fr_FR').format(value);
  }

  Widget _buildKpiPeriodSelector(BuildContext context, PatronDashboardState state) {
    final period = state.kpiPeriod;
    return Row(
      children: [
        _periodChip(context, 'day', 'Jour', period),
        const SizedBox(width: 8),
        _periodChip(context, 'week', 'Semaine', period),
        const SizedBox(width: 8),
        _periodChip(context, 'month', 'Mois', period),
      ],
    );
  }

  Widget _periodChip(BuildContext context, String value, String label, String current) {
    final selected = current == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => ref.read(patronDashboardProvider.notifier).setKpiPeriod(value),
      selectedColor: PatronDashboardEnhanced.primaryColor.withOpacity(0.2),
      checkmarkColor: PatronDashboardEnhanced.primaryColor,
    );
  }

  Widget _buildRappelsSection(BuildContext context, PatronDashboardState state) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: const Color(0xFFF59E0B), width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active, size: 18, color: Colors.orange.shade800),
              const SizedBox(width: 8),
              Text('Rappels', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.orange.shade800)),
            ],
          ),
          const SizedBox(height: 8),
          ...state.rappels.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold)),
                Expanded(child: Text(r, style: TextStyle(fontSize: 12, color: Colors.grey.shade800))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildKpisSection(BuildContext context, PatronDashboardState state) {
    final p = state.kpiPeriod;
    final ca = p == 'day' ? state.kpiCaJour : p == 'week' ? state.kpiCaSemaine : state.kpiCaMois;
    final dep = p == 'day' ? state.kpiDepensesJour : p == 'week' ? state.kpiDepensesSemaine : state.kpiDepensesMois;
    final marge = p == 'day' ? state.kpiMargeJour : p == 'week' ? state.kpiMargeSemaine : state.kpiMargeBrute;
    final periodLabel = p == 'day' ? 'du jour' : p == 'week' ? 'de la semaine' : 'du mois';
    final kpis = [
      _KpiCard('CA $periodLabel', ca, 'FCFA', Icons.trending_up, const Color(0xFF059669), '/invoices'),
      _KpiCard('Encaissable', state.kpiEncaissable, 'FCFA', Icons.schedule, const Color(0xFFEA580C), '/invoices'),
      _KpiCard('Dépenses $periodLabel', dep, 'FCFA', Icons.money_off, const Color(0xFFDC2626), '/expenses'),
      _KpiCard('Marge $periodLabel', marge, 'FCFA', Icons.savings, const Color(0xFF059669), '/patron/finances'),
    ];
    if (kIsWeb) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: _buildKpiBarChart(context, state, ca, dep, marge, periodLabel),
          ),
          const SizedBox(width: 20),
          SizedBox(
            width: 260,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: kpis.map((k) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildKpiCardCompact(context, k, state.isLoading),
              )).toList(),
            ),
          ),
        ],
      );
    }
    return _buildKpisGrid(context, state);
  }

  Widget _buildKpiBarChart(BuildContext context, PatronDashboardState state, double ca, double dep, double marge, String periodLabel) {
    const double minBarY = 0.04; // Hauteur minimale pour qu'une barre soit visible (évite barres à 0 invisibles)
    final maxVal = [ca, dep, marge].fold<double>(0, (a, b) => b > a ? b : a);
    final scale = maxVal <= 0 ? 1.0 : maxVal;
    double toY(double raw) {
      final y = (raw / scale).clamp(0.0, 1.0);
      return (maxVal > 0 && y < minBarY) ? minBarY : y;
    }
    final y0 = toY(ca);
    final y1 = toY(dep);
    final y2 = toY(marge);
    final labels = ['CA', 'Dépenses', 'Marge'];
    final colors = [const Color(0xFF059669), const Color(0xFFDC2626), const Color(0xFF059669)];
    final hasNoData = maxVal <= 0;
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
          Text('Répartition $periodLabel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            width: double.infinity,
            child: state.isLoading
                ? Shimmer(baseColor: Colors.grey.shade300, highlightColor: Colors.grey.shade100, child: Container(height: 180, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12))))
                : hasNoData
                    ? Center(child: Text('Aucune donnée pour cette période', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)))
                    : LayoutBuilder(
                        builder: (ctx, constraints) {
                          return BarChart(
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
                              gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.shade200, strokeWidth: 1)),
                              borderData: FlBorderData(show: false),
                              barGroups: [
                                BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: y0, color: colors[0], width: 28, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))]),
                                BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: y1, color: colors[1], width: 28, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))]),
                                BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: y2, color: colors[2], width: 28, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))]),
                              ],
                            ),
                            duration: const Duration(milliseconds: 300),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCardCompact(BuildContext context, _KpiCard k, bool isLoading) {
    final valueStr = _formatKpi(k.value) + (k.suffix.isNotEmpty ? ' ${k.suffix}' : '');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: k.route != null ? () => context.go(k.route!) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: k.color, width: 3)),
            boxShadow: [BoxShadow(color: k.color.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Icon(k.icon, size: 18, color: k.color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(k.title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    if (isLoading)
                      Shimmer(baseColor: Colors.grey.shade300, highlightColor: Colors.grey.shade100, child: Container(height: 14, width: 60, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))))
                    else
                      Text(valueStr, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: k.color), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpisGrid(BuildContext context, PatronDashboardState state) {
    final p = state.kpiPeriod;
    final ca = p == 'day' ? state.kpiCaJour : p == 'week' ? state.kpiCaSemaine : state.kpiCaMois;
    final dep = p == 'day' ? state.kpiDepensesJour : p == 'week' ? state.kpiDepensesSemaine : state.kpiDepensesMois;
    final marge = p == 'day' ? state.kpiMargeJour : p == 'week' ? state.kpiMargeSemaine : state.kpiMargeBrute;
    final periodLabel = p == 'day' ? 'du jour' : p == 'week' ? 'de la semaine' : 'du mois';
    final kpis = [
      _KpiCard('CA $periodLabel', ca, 'FCFA', Icons.trending_up, const Color(0xFF059669), '/invoices'),
      _KpiCard('Encaissable', state.kpiEncaissable, 'FCFA', Icons.schedule, const Color(0xFFEA580C), '/invoices'),
      _KpiCard('Dépenses $periodLabel', dep, 'FCFA', Icons.money_off, const Color(0xFFDC2626), '/expenses'),
      _KpiCard('Marge $periodLabel', marge, 'FCFA', Icons.savings, const Color(0xFF059669), '/patron/finances'),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.35,
      children: kpis.map((k) => _buildKpiCard(context, k, state.isLoading)).toList(),
    );
  }

  Widget _buildKpiCard(BuildContext context, _KpiCard k, bool isLoading) {
    final valueStr = _formatKpi(k.value) + (k.suffix.isNotEmpty ? ' ${k.suffix}' : '');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: k.route != null ? () => context.go(k.route!) : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: k.color, width: 4)),
        boxShadow: [BoxShadow(color: k.color.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(k.icon, size: 20, color: k.color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  k.title,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isLoading)
            Shimmer(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Text(valueStr, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: k.color)),
            )
          else
            Text(
              valueStr,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: k.color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
        ),
      ),
    );
  }

  Widget _buildUrgenceSection(BuildContext context, PatronDashboardState state) {
    final total = state.totalPendingValidations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'En attente: $total',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFDC2626),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (state.validationQueue.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.grey.shade600, size: 28),
                const SizedBox(width: 12),
                Text('Aucune validation en attente', style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.validationQueue.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = state.validationQueue[index];
              return _buildValidationDismissibleCard(context, state, item, index);
            },
          ),
      ],
    );
  }

  Widget _buildValidationDismissibleCard(BuildContext context, PatronDashboardState state, PatronValidationItem item, int index) {
    return Dismissible(
      key: ValueKey('${item.entityType}_${item.entityId}_$index'),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(color: const Color(0xFF059669), borderRadius: BorderRadius.circular(14)),
        child: const Row(
          children: [
            Icon(Icons.check, color: Colors.white, size: 28),
            SizedBox(width: 8),
            Text('Accepter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: const Color(0xFFDC2626), borderRadius: BorderRadius.circular(14)),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Rejeter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            SizedBox(width: 8),
            Icon(Icons.close, color: Colors.white, size: 28),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        final notifier = ref.read(patronDashboardProvider.notifier);
        if (direction == DismissDirection.startToEnd) {
          final ok = await notifier.approveValidationItem(item);
          if (context.mounted) {
            if (ok) errorHelperShowSnackbar?.call('Succès', 'Élément approuvé');
            else errorHelperShowSnackbar?.call('Erreur', 'Impossible d\'approuver');
          }
          return ok;
        } else {
          final ok = await notifier.rejectValidationItem(item, reason: 'Rejet depuis le dashboard');
          if (context.mounted) {
            if (ok) errorHelperShowSnackbar?.call('Info', 'Élément rejeté');
            else errorHelperShowSnackbar?.call('Erreur', 'Impossible de rejeter');
          }
          return ok;
        }
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(item.route),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border(left: BorderSide(color: item.color, width: 4)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: item.color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(item.icon, size: 22, color: item.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(item.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(item.subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOperationsSection(BuildContext context, PatronDashboardState state) {
    return Column(
      children: [
        if (state.stockAlertsCount > 0)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border(left: BorderSide(color: const Color(0xFFDC2626), width: 4)),
            ),
            child: InkWell(
              onTap: () => context.go('/stock'),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${state.stockAlertsCount} alerte(s) stock (rupture ou sous seuil)',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFDC2626)),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFDC2626)),
                ],
              ),
            ),
          ),
        if (state.lastInvoices.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Dernières factures', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
          const SizedBox(height: 6),
          ...state.lastInvoices.map((inv) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text((inv['clientName'] as String?) ?? '', style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                Text('${_formatKpi((inv['totalAmount'] as num?)?.toDouble() ?? 0)} FCFA', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          )),
        ],
        if (state.interventionPie.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text('Interventions par statut', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
          const SizedBox(height: 8),
          SizedBox(
            height: 140,
            child: _buildInterventionPieChart(state.interventionPie),
          ),
          const SizedBox(height: 10),
          _buildInterventionPieLegend(state.interventionPie),
        ],
      ],
    );
  }

  Widget _buildInterventionPieChart(Map<String, int> pieData) {
    final total = pieData.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();
    final colors = [
      const Color(0xFFEA580C), // pending
      const Color(0xFF6366F1), // in_progress
      const Color(0xFF059669), // completed
      const Color(0xFFDC2626), // rejected
    ];
    int idx = 0;
    final sections = pieData.entries.map((e) {
      final color = colors[idx % colors.length];
      idx++;
      return PieChartSectionData(
        value: e.value.toDouble(),
        title: '${e.value}',
        color: color,
        radius: 48,
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
      );
    }).toList();
    return SizedBox(
      height: 140,
      width: double.infinity,
      child: PieChart(
        PieChartData(
          sections: sections,
          sectionsSpace: 2,
          centerSpaceRadius: 28,
        ),
        duration: const Duration(milliseconds: 300),
      ),
    );
  }

  static const Map<String, String> _interventionStatusLabels = {
    'pending': 'En attente',
    'in_progress': 'En cours',
    'completed': 'Terminées',
    'rejected': 'Rejetées',
    'approved': 'Approuvées',
  };

  Widget _buildInterventionPieLegend(Map<String, int> pieData) {
    final colors = [
      const Color(0xFFEA580C),
      const Color(0xFF6366F1),
      const Color(0xFF059669),
      const Color(0xFFDC2626),
      const Color(0xFF8B5CF6),
    ];
    int idx = 0;
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: pieData.entries.map((e) {
        final color = colors[idx % colors.length];
        idx++;
        final label = _interventionStatusLabels[e.key] ?? e.key;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text('$label : ${e.value}', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
          ],
        );
      }).toList(),
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
    final prenom = user?.prenom?.trim().isNotEmpty == true ? user!.prenom! : 'Direction';
      final hour = DateTime.now().hour;
      final greeting = hour < 12 ? 'Bonjour' : hour < 18 ? 'Bon après-midi' : 'Bonsoir';
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0F172A),
              const Color(0xFF1E293B),
            ],
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
      _QuickAction('Inscriptions', Icons.person_add, '/patron/registrations/validation', DashboardEntityColors.inscriptions),
      _QuickAction('Clients', Icons.people, '/clients/validation', DashboardEntityColors.clients),
      _QuickAction('Devis', Icons.description, '/devis/validation', DashboardEntityColors.devis),
      _QuickAction('Factures', Icons.receipt, '/factures/validation', DashboardEntityColors.factures),
      _QuickAction('Pointages', Icons.access_time, '/pointage/validation', DashboardEntityColors.pointages),
      _QuickAction('Présences', Icons.calendar_view_month, '/pointage/presence-summary', DashboardEntityColors.finances),
      _QuickAction('Tâches', Icons.task_alt, '/tasks', DashboardEntityColors.tasks),
    ];
    final screenWidth = MediaQuery.of(context).size.width;
    return SizedBox(
      height: 48,
      width: screenWidth - 40,
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

  Widget _buildValidationSection(BuildContext context, PatronDashboardState state) {
    final items = [
      _ValItem('Inscriptions', state.pendingRegistrations, Icons.person_add, DashboardEntityColors.inscriptions, '/patron/registrations/validation'),
      _ValItem('Clients', state.pendingClients, Icons.people, DashboardEntityColors.clients, '/clients/validation'),
      _ValItem('Devis', state.pendingDevis, Icons.description, DashboardEntityColors.devis, '/devis/validation'),
      _ValItem('Bordereaux', state.pendingBordereaux, Icons.assignment_turned_in, DashboardEntityColors.bordereaux, '/bordereaux/validation'),
      _ValItem('Bons de Commande', state.pendingBonCommandes, Icons.shopping_cart, DashboardEntityColors.bonCommandes, '/bon-commandes/validation'),
      _ValItem('Bons Fournisseur', null, Icons.inventory_2, DashboardEntityColors.bonCommandesFournisseur, '/bons-de-commande-fournisseur/validation'),
      _ValItem('Factures', state.pendingFactures, Icons.receipt, DashboardEntityColors.factures, '/factures/validation'),
      _ValItem('Paiements', state.pendingPaiements, Icons.payment, DashboardEntityColors.paiements, '/paiements/validation'),
      _ValItem('Dépenses', state.pendingDepenses, Icons.money_off, DashboardEntityColors.depenses, '/depenses/validation'),
      _ValItem('Salaires', state.pendingSalaires, Icons.account_balance_wallet, DashboardEntityColors.salaires, '/salaires/validation'),
      _ValItem('Reporting', state.pendingReporting, Icons.analytics, DashboardEntityColors.reporting, '/reporting/validation'),
      _ValItem('Pointages', state.pendingPointages, Icons.access_time, DashboardEntityColors.pointages, '/pointage/validation'),
      _ValItem('Employés', null, Icons.people, DashboardEntityColors.employes, '/employees/validation'),
      _ValItem('Tâches', state.pendingTasks, Icons.task_alt, DashboardEntityColors.tasks, '/tasks'),
    ];
    final crossCount = MediaQuery.of(context).size.width > 1200 ? 4 : MediaQuery.of(context).size.width > 800 ? 3 : 2;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossCount,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: items.map((e) => _buildModernCard(
        title: e.title,
        count: e.count,
        icon: e.icon,
        color: e.color,
        onTap: () => context.go(e.route),
        badgeColor: const Color(0xFFF59E0B),
        isLoading: state.isLoading,
      )).toList(),
    );
  }

  Widget _buildPerformanceSection(BuildContext context, PatronDashboardState state) {
    return Column(
      children: [
        _buildStatRow<int>(
          'Clients validés',
          state.validatedClients,
          (v) => v.toString(),
          Icons.verified_user,
          const Color(0xFF059669),
          'Clients actifs',
        ),
        const SizedBox(height: 12),
        _buildStatRow<int>(
          'Fournisseurs',
          state.totalSuppliers,
          (v) => v.toString(),
          Icons.business,
          const Color(0xFFEA580C),
          'Partenaires',
        ),
        const SizedBox(height: 12),
        _buildStatRow<double>(
          'Chiffre d\'affaires',
          state.totalRevenue,
          _formatAmount,
          Icons.euro,
          const Color(0xFF7C3AED),
          'Montant total des factures',
        ),
      ],
    );
  }

  String _formatAmount(double value) {
    if (value >= 1e6) return '${NumberFormat('#,##0', 'fr_FR').format(value ~/ 1e6)} M FCFA';
    if (value >= 1e3) return '${NumberFormat('#,##0', 'fr_FR').format(value ~/ 1e3)} k FCFA';
    return '${NumberFormat('#,##0', 'fr_FR').format(value)} FCFA';
  }

  Widget _buildStatRow<T>(String title, T value, String Function(T) valueFormat, IconData icon, Color color, String subtitle) {
    final valueStr = valueFormat(value);
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
                    valueStr,
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
    required int? count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required Color badgeColor,
    bool isLoading = false,
  }) {
    final badge = count != null
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                        color: badgeColor,
                      ),
                    ),
                  )
                : Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                    ),
                  ),
          )
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '0',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: badgeColor,
              ),
            ),
          );
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
            border: Border(
              left: BorderSide(color: color, width: 4),
            ),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 22, color: color),
                  ),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: badge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Align(
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
              ),
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
              decoration: BoxDecoration(color: PatronDashboardEnhanced.primaryColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    PatronDashboardEnhanced.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Rôle: ${Roles.getRoleName(userRole)}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white54),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'NAVIGATION',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ),
            _drawerItem(context, Icons.list, 'Liste des Clients', DashboardEntityColors.clients, '/clients'),
            _drawerItem(context, Icons.book, 'Journal des comptes', DashboardEntityColors.journal, '/journal'),
            _drawerItem(context, Icons.analytics, 'Rapports', DashboardEntityColors.rapports, '/patron/reports'),
            _drawerItem(context, Icons.notifications_active, 'Besoins / Rappels techniciens', DashboardEntityColors.besoins, '/besoins'),
            if (userRole == 1)
              _drawerItem(context, Icons.settings_applications, 'Paramètres', DashboardEntityColors.parametres, '/admin/settings'),
            const Divider(color: Colors.white54),
            ListTile(
              leading: Icon(Icons.access_time, color: DashboardEntityColors.pointages, size: 22),
              title: const Text('Pointage', style: TextStyle(color: Colors.white70)),
              onTap: () { Navigator.pop(context); context.go('/attendance-punch'); },
            ),
            ListTile(
              leading: Icon(Icons.analytics, color: DashboardEntityColors.rapports, size: 22),
              title: const Text('Reporting', style: TextStyle(color: Colors.white70)),
              onTap: () { Navigator.pop(context); context.go('/reporting'); },
            ),
            ListTile(
              leading: Icon(Icons.task_alt, color: DashboardEntityColors.tasks, size: 22),
              title: const Text('Mes tâches', style: TextStyle(color: Colors.white70)),
              onTap: () { Navigator.pop(context); context.go('/tasks'); },
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
      selectedItemColor: PatronDashboardEnhanced.primaryColor,
      unselectedItemColor: Colors.grey,
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
        const BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Rechercher'),
        const BottomNavigationBarItem(icon: NotificationBadgeIcon(), label: 'Notifications'),
        const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        const BottomNavigationBarItem(icon: Icon(Icons.photo_library), label: 'Médias'),
      ],
      onTap: (index) {
        switch (index) {
          case 1: context.go('/search'); break;
          case 2: context.go('/notifications'); break;
          case 3: context.go('/profile'); break;
          case 4: context.go('/media'); break;
        }
      },
    );
  }

  Widget _drawerItem(BuildContext context, IconData icon, String label, Color color, String route) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 15)),
      onTap: () {
        Navigator.pop(context);
        context.go(route);
      },
    );
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final String route;
  final Color color;
  _QuickAction(this.label, this.icon, this.route, this.color);
}

class _ValItem {
  final String title;
  final int? count;
  final IconData icon;
  final Color color;
  final String route;
  _ValItem(this.title, this.count, this.icon, this.color, this.route);
}

class _KpiCard {
  final String title;
  final double value;
  final String suffix;
  final IconData icon;
  final Color color;
  final String? route;
  _KpiCard(this.title, this.value, this.suffix, this.icon, this.color, [this.route]);
}

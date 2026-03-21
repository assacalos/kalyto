import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';
import 'package:easyconnect/Views/Components/paginated_list_view.dart';
import 'package:easyconnect/providers/reporting_notifier.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/Models/reporting_model.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';
import 'package:easyconnect/Views/Components/app_bar_back_button.dart';

class ReportingList extends ConsumerStatefulWidget {
  const ReportingList({super.key});

  @override
  ConsumerState<ReportingList> createState() => _ReportingListState();
}

class _ReportingListState extends ConsumerState<ReportingList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        ref.read(reportingProvider.notifier).loadReports(forceRefresh: true);
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportingProvider);
    final notifier = ref.read(reportingProvider.notifier);
    final userRole = ref.watch(authProvider).user?.role;
    final userId = ref.watch(authProvider).user?.id;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBarBackButton(fallbackRoute: '/reporting', iconColor: Colors.white),
        title: const Text('Rapports'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context, notifier, userRole),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (state.isLoading)
            const SkeletonSearchResults(itemCount: 6)
          else if (state.reports.isEmpty)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assessment, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucun rapport trouvé',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Créez votre premier rapport',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          else ...[
            Builder(
              builder: (context) {
                final filteredReports = (userRole == Roles.ADMIN || userRole == Roles.PATRON)
                    ? state.reports
                    : state.reports.where((report) => report.userId == userId).toList();
                if (filteredReports.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assessment, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Aucun rapport trouvé',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Créez votre premier rapport',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }
                return PaginatedListView(
                  scrollController: _scrollController,
                  onLoadMore: notifier.loadMore,
                  hasNextPage: state.hasNextPage,
                  isLoadingMore: state.isLoadingMore,
                  itemCount: filteredReports.length,
                  itemBuilder: (context, index) {
                    final report = filteredReports[index];
                    return _buildReportCard(
                      context,
                      report,
                      notifier,
                      userRole,
                      userId,
                    );
                  },
                );
              },
            ),
          ],
          Positioned(
            bottom: 80,
            right: 16,
            child: UniformAddButton(
              onPressed: () => context.push('/reporting/new'),
              label: 'Nouveau Rapport',
              icon: Icons.assessment,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context,
    ReportingModel report,
    ReportingNotifier notifier,
    int? userRole,
    int? userId,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rapport du ${_formatDate(report.reportDate)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        report.userRole.toLowerCase().contains('comptable')
                            ? report.userName
                            : '${report.userName} (${report.userRole})',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(report.status),
              ],
            ),
            const SizedBox(height: 16),
            if (report.userRole.toLowerCase().contains('commercial')) ...[
              _buildCommercialMetrics(report.metrics),
            ] else if (report.userRole.toLowerCase().contains('comptable')) ...[
              _buildComptableMetrics(report.metrics),
            ] else if (report.userRole.toLowerCase().contains('technicien')) ...[
              _buildTechnicienMetrics(report.metrics),
            ],
            const SizedBox(height: 16),
            if (report.commentaire != null && report.commentaire!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  report.commentaire!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                if (report.status == 'submitted' &&
                    (userRole == Roles.ADMIN || userRole == Roles.PATRON)) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => notifier.approveReport(report.id),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approuver'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (report.status == 'submitted' &&
                    (report.userId == userId || userRole == Roles.ADMIN || userRole == Roles.PATRON)) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/reporting/new', extra: report),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Modifier'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.deepPurple,
                        side: const BorderSide(color: Colors.deepPurple),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/user-reportings/${report.id}', extra: report),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Détails'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.deepPurple,
                      side: const BorderSide(color: Colors.deepPurple),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    switch (status) {
      case 'submitted':
        color = Colors.blue;
        label = 'Soumis';
        break;
      case 'approved':
        color = Colors.green;
        label = 'Approuvé';
        break;
      default:
        color = Colors.grey;
        label = status;
    }
    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
    );
  }

  Widget _buildCommercialMetrics(Map<String, dynamic> metrics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Métriques Commerciales:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _buildMetricChip('Clients prospectés', metrics['clients_prospectes']?.toString() ?? '0'),
            _buildMetricChip('RDV obtenus', metrics['rdv_obtenus']?.toString() ?? '0'),
            _buildMetricChip('Devis créés', metrics['devis_crees']?.toString() ?? '0'),
            _buildMetricChip('Devis acceptés', metrics['devis_acceptes']?.toString() ?? '0'),
            _buildMetricChip('Nouveaux clients', metrics['nouveaux_clients']?.toString() ?? '0'),
          ],
        ),
      ],
    );
  }

  Widget _buildComptableMetrics(Map<String, dynamic> metrics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Métriques Comptables:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _buildMetricChip('Factures émises', metrics['factures_emises']?.toString() ?? '0'),
            _buildMetricChip('Factures payées', metrics['factures_payees']?.toString() ?? '0'),
            _buildMetricChip('Montant facturé (fcfa)', metrics['montant_facture']?.toString() ?? '0'),
            _buildMetricChip('Montant encaissé (fcfa)', metrics['montant_encaissement']?.toString() ?? '0'),
            _buildMetricChip('Bordereaux traités', metrics['bordereaux_traites']?.toString() ?? '0'),
            _buildMetricChip('Bons de commande', metrics['bons_commande_traites']?.toString() ?? '0'),
          ],
        ),
      ],
    );
  }

  Widget _buildTechnicienMetrics(Map<String, dynamic> metrics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Métriques Techniques:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _buildMetricChip('Interventions planifiées', metrics['interventions_planifiees']?.toString() ?? '0'),
            _buildMetricChip('Interventions réalisées', metrics['interventions_realisees']?.toString() ?? '0'),
            _buildMetricChip('Clients visités', metrics['clients_visites']?.toString() ?? '0'),
            _buildMetricChip('Problèmes résolus', metrics['problemes_resolus']?.toString() ?? '0'),
            _buildMetricChip('Temps de travail (h)', metrics['temps_travail']?.toString() ?? '0'),
            _buildMetricChip('Déplacements', metrics['deplacements']?.toString() ?? '0'),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
      ),
      child: Text('$label: $value', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }

  void _showFilterDialog(BuildContext context, ReportingNotifier notifier, int? userRole) {
    final state = ref.read(reportingProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrer les rapports'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (userRole == Roles.ADMIN || userRole == Roles.PATRON) ...[
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Rôle utilisateur'),
                value: state.selectedUserRole,
                items: const [
                  DropdownMenuItem(value: null, child: Text('Tous les rôles')),
                  DropdownMenuItem(value: 'Commercial', child: Text('Commercial')),
                  DropdownMenuItem(value: 'Comptable', child: Text('Comptable')),
                  DropdownMenuItem(value: 'Technicien', child: Text('Technicien')),
                ],
                onChanged: (value) => notifier.filterByUserRole(value),
              ),
              const SizedBox(height: 16),
            ],
            ListTile(
              title: const Text('Période'),
              subtitle: Text('${_formatDate(state.startDate)} - ${_formatDate(state.endDate)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now(),
                  initialDateRange: DateTimeRange(start: state.startDate, end: state.endDate),
                );
                if (range != null) notifier.updateDateRange(range.start, range.end);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

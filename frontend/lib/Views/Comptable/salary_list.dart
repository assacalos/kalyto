import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/salary_notifier.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/Models/salary_model.dart';
import 'package:easyconnect/Views/Components/paginated_list_view.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/services/pdf_service.dart';
import 'package:easyconnect/Views/Components/export_format_dialog.dart';
import 'package:easyconnect/services/export_service.dart';

class SalaryList extends ConsumerStatefulWidget {
  const SalaryList({super.key});

  @override
  ConsumerState<SalaryList> createState() => _SalaryListState();
}

class _SalaryListState extends ConsumerState<SalaryList>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  static String _statusForIndex(int index) {
    switch (index) {
      case 0: return 'all';
      case 1: return 'pending';
      case 2: return 'approved';
      case 3: return 'paid';
      case 4: return 'rejected';
      default: return 'all';
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(salaryProvider.notifier).filterByStatus(
          _statusForIndex(_tabController.index),
        );
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(salaryProvider.notifier).loadSalaries(forceRefresh: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(salaryProvider);
    final notifier = ref.read(salaryProvider.notifier);
    final userRole = ref.watch(authProvider).user?.role;
    final canManage = userRole == Roles.ADMIN || userRole == Roles.COMPTABLE;
    final formatCurrency = NumberFormat.currency(locale: 'fr_FR', symbol: 'fcfa');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Salaires'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Exporter',
            onPressed: state.salaries.isEmpty ? null : () => _exportSalaries(context, state.salaries),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.loadSalaries(forceRefresh: true),
            tooltip: 'Actualiser',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Tous', icon: Icon(Icons.list)),
            Tab(text: 'En attente', icon: Icon(Icons.pending)),
            Tab(text: 'Approuvés', icon: Icon(Icons.check_circle)),
            Tab(text: 'Payés', icon: Icon(Icons.payment)),
            Tab(text: 'Rejetés', icon: Icon(Icons.cancel)),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par employé...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: state.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          notifier.searchSalaries('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (value) => notifier.searchSalaries(value),
            ),
          ),
          Expanded(
            child: state.isLoading && state.salaries.isEmpty
                ? const SkeletonSearchResults(itemCount: 6)
                : state.salaries.isEmpty
                    ? const Center(child: Text('Aucun salaire trouvé'))
                    : PaginatedListView(
                        scrollController: _scrollController,
                        onLoadMore: notifier.loadMore,
                        hasNextPage: state.hasNextPage,
                        isLoadingMore: state.isLoadingMore,
                        itemCount: state.salaries.length,
                        itemBuilder: (context, index) {
                          final salary = state.salaries[index];
                          return _buildSalaryCard(
                            context,
                            salary,
                            formatCurrency,
                            canManage,
                            notifier,
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/salaries/new'),
        tooltip: 'Nouveau salaire',
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSalaryCard(
    BuildContext context,
    Salary salary,
    NumberFormat formatCurrency,
    bool canManage,
    SalaryNotifier notifier,
  ) {
    final status = salary.status ?? 'pending';
    final statusColor = _getStatusColor(status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: () => context.go('/salaries/${salary.id}', extra: salary),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      salary.employeeName ?? 'Sans nom',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      _getStatusLabel(status),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (salary.employeeEmail != null) ...[
                Row(
                  children: [
                    Icon(Icons.email, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        salary.employeeEmail!,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    salary.periodText,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Text(
                    formatCurrency.format(salary.netSalary),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
              if (salary.status == 'rejected' &&
                  salary.rejectionReason != null &&
                  salary.rejectionReason!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.report, size: 16, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Raison: ${salary.rejectionReason}',
                        style: TextStyle(color: Colors.red[700], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.picture_as_pdf, size: 16),
                    label: const Text('Bulletin'),
                    onPressed: () => _generateBulletin(context, salary),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Détails'),
                    onPressed: () =>
                        context.go('/salaries/${salary.id}', extra: salary),
                  ),
                  if (salary.status == 'pending' && canManage) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Modifier'),
                      onPressed: () => context.go(
                        '/salaries/${salary.id}/edit',
                        extra: salary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportSalaries(BuildContext context, List<Salary> list) async {
    final format = await showExportFormatDialog(context, title: 'Exporter les salaires');
    if (format == null || !context.mounted) return;
    const headers = ['Id', 'Employé', 'Email', 'Période', 'Base', 'Primes', 'Déductions', 'Net', 'Statut'];
    final rows = list.map((s) => [
      s.id,
      s.employeeName ?? '',
      s.employeeEmail ?? '',
      s.periodText,
      s.baseSalary,
      s.bonus,
      s.deductions,
      s.netSalary,
      s.statusText,
    ]).toList();
    final base = 'salaires_${DateFormat('yyyy-MM-dd').format(DateTime.now())}';
    try {
      if (format == 'excel') {
        await ExportService.exportExcel(headers: headers, rows: rows, filenameBase: base, sheetName: 'Salaires');
      } else {
        await ExportService.exportCsv(headers: headers, rows: rows, filenameBase: base);
      }
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export réussi')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _generateBulletin(BuildContext context, Salary salary) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Génération du bulletin en cours...'),
          duration: Duration(seconds: 2),
        ),
      );
      await PdfService().generateBulletinPaiePdf(salary);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bulletin de paie généré'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Erreur: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'paid':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'approved':
        return 'Approuvé';
      case 'paid':
        return 'Payé';
      case 'rejected':
        return 'Rejeté';
      default:
        return 'Inconnu';
    }
  }
}

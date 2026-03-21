import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/expense_notifier.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/Models/expense_model.dart';
import 'package:easyconnect/Views/Components/paginated_list_view.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/Views/Components/export_format_dialog.dart';
import 'package:easyconnect/services/export_service.dart';
import 'package:easyconnect/Views/Components/app_bar_back_button.dart';

class ExpenseList extends ConsumerStatefulWidget {
  const ExpenseList({super.key});

  @override
  ConsumerState<ExpenseList> createState() => _ExpenseListState();
}

class _ExpenseListState extends ConsumerState<ExpenseList>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _updateFilter();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(expenseProvider.notifier).loadExpenses(forceRefresh: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _exportExpenses(BuildContext context, List<Expense> list) async {
    final format = await showExportFormatDialog(context, title: 'Exporter les dépenses');
    if (format == null || !context.mounted) return;
    const headers = ['Id', 'Libellé', 'Description', 'Catégorie', 'Date', 'Montant', 'Statut', 'Notes'];
    final rows = list.map((e) => [
      e.id,
      e.title,
      e.description,
      e.category,
      e.expenseDate,
      e.amount,
      e.status,
      e.notes ?? '',
    ]).toList();
    final base = 'depenses_${DateFormat('yyyy-MM-dd').format(DateTime.now())}';
    try {
      if (format == 'excel') {
        await ExportService.exportExcel(headers: headers, rows: rows, filenameBase: base, sheetName: 'Dépenses');
      } else {
        await ExportService.exportCsv(headers: headers, rows: rows, filenameBase: base);
      }
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export réussi')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  void _updateFilter() {
    String status;
    switch (_tabController.index) {
      case 0:
        status = 'all';
        break;
      case 1:
        status = 'pending';
        break;
      case 2:
        status = 'approved';
        break;
      case 3:
        status = 'rejected';
        break;
      default:
        status = 'all';
    }
    ref.read(expenseProvider.notifier).filterByStatus(status);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expenseProvider);
    final notifier = ref.read(expenseProvider.notifier);
    final userRole = ref.watch(authProvider).user?.role;
    final canManage = userRole == Roles.ADMIN || userRole == Roles.COMPTABLE;
    final canApprove = userRole == Roles.ADMIN || userRole == Roles.PATRON;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBarBackButton(fallbackRoute: '/comptable', iconColor: Colors.white),
        title: const Text('Dépenses'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Exporter',
            onPressed: state.expenses.isEmpty ? null : () => _exportExpenses(context, state.expenses),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.loadExpenses(forceRefresh: true),
            tooltip: 'Actualiser',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Toutes', icon: Icon(Icons.list)),
            Tab(text: 'En attente', icon: Icon(Icons.pending)),
            Tab(text: 'Validées', icon: Icon(Icons.check_circle)),
            Tab(text: 'Rejetées', icon: Icon(Icons.cancel)),
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
                hintText: 'Rechercher par titre ou description...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: state.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          notifier.searchExpenses('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) => notifier.searchExpenses(value),
            ),
          ),
          Expanded(
            child: state.isLoading && state.expenses.isEmpty
                ? const SkeletonSearchResults(itemCount: 6)
                : state.expenses.isEmpty
                    ? const Center(child: Text('Aucune dépense trouvée'))
                    : PaginatedListView(
                        scrollController: _scrollController,
                        onLoadMore: notifier.loadMore,
                        hasNextPage: state.hasNextPage,
                        isLoadingMore: state.isLoadingMore,
                        itemCount: state.expenses.length,
                        itemBuilder: (context, index) {
                          final expense = state.expenses[index];
                          return _buildExpenseCard(
                            context,
                            expense,
                            notifier,
                            canManage,
                            canApprove,
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/expenses/new'),
        tooltip: 'Nouvelle dépense',
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildExpenseCard(
    BuildContext context,
    Expense expense,
    ExpenseNotifier notifier,
    bool canManage,
    bool canApprove,
  ) {
    final formatCurrency = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'fcfa',
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: () => context.go('/expenses/${expense.id}', extra: expense),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec titre et statut
              Row(
                children: [
                  Expanded(
                    child: Text(
                      expense.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: expense.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: expense.statusColor.withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      expense.statusText,
                      style: TextStyle(
                        color: expense.statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Catégorie
              Row(
                children: [
                  Icon(Icons.category, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    expense.categoryText,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Date
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(expense.expenseDate),
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Montant
              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Text(
                    formatCurrency.format(expense.amount),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),

              // Raison du rejet si rejeté
              if (expense.status == 'rejected' &&
                  (expense.rejectionReason != null &&
                      expense.rejectionReason!.isNotEmpty)) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.report, size: 16, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Raison: ${expense.rejectionReason}',
                        style: TextStyle(color: Colors.red[700], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],

              // Actions
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Détails'),
                    onPressed: () =>
                        context.go('/expenses/${expense.id}', extra: expense),
                  ),
                  if (expense.status == 'pending' && canManage) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Modifier'),
                      onPressed: () => context.go(
                        '/expenses/${expense.id}/edit',
                        extra: expense,
                      ),
                    ),
                  ],
                  if (expense.status == 'pending' && canApprove) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approuver'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
                      ),
                      onPressed: () => _showApproveDialog(context, expense, notifier),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Rejeter'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () => _showRejectDialog(context, expense, notifier),
                    ),
                  ],
                  // Note: Pas de méthode generatePDF pour les dépenses
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showApproveDialog(
      BuildContext context, Expense expense, ExpenseNotifier notifier) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approuver la dépense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Êtes-vous sûr de vouloir approuver cette dépense ?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              await notifier.approveExpense(expense,
                  notes: notesController.text.trim().isEmpty
                      ? null
                      : notesController.text.trim());
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dépense approuvée')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approuver'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(
      BuildContext context, Expense expense, ExpenseNotifier notifier) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeter la dépense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Veuillez indiquer la raison du rejet :'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Raison du rejet *',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Veuillez indiquer la raison du rejet')),
                );
                return;
              }
              await notifier.rejectExpense(
                  expense, reasonController.text.trim());
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dépense rejetée')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }
}

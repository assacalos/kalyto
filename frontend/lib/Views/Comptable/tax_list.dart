import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/tax_notifier.dart';
import 'package:easyconnect/Models/tax_model.dart';
import 'package:easyconnect/Views/Components/paginated_list_view.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';

class TaxList extends ConsumerStatefulWidget {
  const TaxList({super.key});

  @override
  ConsumerState<TaxList> createState() => _TaxListState();
}

class _TaxListState extends ConsumerState<TaxList>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _updateFilter();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(taxProvider.notifier).loadTaxes(forceRefresh: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _updateFilter() {
    String status;
    switch (_tabController.index) {
      case 0:
        status = 'all';
        break;
      case 1:
        status = 'en_attente';
        break;
      case 2:
        status = 'valide';
        break;
      case 3:
        status = 'rejete';
        break;
      case 4:
        status = 'paid';
        break;
      default:
        status = 'all';
    }
    ref.read(taxProvider.notifier).filterByStatus(status);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(taxProvider);
    final notifier = ref.read(taxProvider.notifier);
    final formatCurrency = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Taxes et Impôts'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.loadTaxes(forceRefresh: true),
            tooltip: 'Actualiser',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tous', icon: Icon(Icons.list)),
            Tab(text: 'En attente', icon: Icon(Icons.pending)),
            Tab(text: 'Validés', icon: Icon(Icons.check_circle)),
            Tab(text: 'Rejetés', icon: Icon(Icons.cancel)),
            Tab(text: 'Payés', icon: Icon(Icons.payment)),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher par nom ou description...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: state.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          notifier.searchTaxes('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              controller: _searchController,
              onChanged: (value) => notifier.searchTaxes(value),
            ),
          ),
          Expanded(
            child: state.isLoading && state.taxes.isEmpty
                ? const SkeletonSearchResults(itemCount: 6)
                : state.taxes.isEmpty
                    ? const Center(child: Text('Aucune taxe trouvée'))
                    : PaginatedListView(
                        scrollController: _scrollController,
                        onLoadMore: notifier.loadMore,
                        hasNextPage: state.hasNextPage,
                        isLoadingMore: state.isLoadingMore,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: state.taxes.length,
                        itemBuilder: (context, index) {
                          final tax = state.taxes[index];
                          return _buildTaxCard(tax, formatCurrency, notifier);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/taxes/new'),
        tooltip: 'Nouvelle taxe',
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTaxCard(
      Tax tax, NumberFormat formatCurrency, TaxNotifier notifier) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => context.go('/taxes/${tax.id}'),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec nom et statut
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tax.name,
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
                      color: _getStatusColor(tax.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(tax.status).withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      tax.statusText,
                      style: TextStyle(
                        color: _getStatusColor(tax.status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Montant
              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    formatCurrency.format(tax.amount),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Date d'échéance
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Échéance: ${_formatDate(tax.dueDateTime)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),

              // Description si disponible
              if (tax.description != null && tax.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.description, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tax.description!,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              // Raison du rejet si rejeté
              if (tax.isRejected &&
                  tax.rejectionReason != null &&
                  tax.rejectionReason!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.report, size: 16, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Raison: ${tax.rejectionReason}',
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
                    onPressed: () => context.go('/taxes/${tax.id}'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Modifier'),
                    onPressed: () => _showEditDialog(tax),
                  ),
                  /*  if (tax.isPending) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Valider'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
                      ),
                      onPressed: () => _showValidateDialog(tax),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Rejeter'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () => _showRejectDialog(tax),
                    ),
                  ], */
                  if (tax.isValidated && !tax.isPaid) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.payment, size: 16),
                      label: const Text('Payé'),
                      style: TextButton.styleFrom(foregroundColor: Colors.blue),
                      onPressed: () => _showMarkPaidDialog(tax, notifier),
                    ),
                  ],
                  const SizedBox(width: 8),
                  /*  TextButton.icon(
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Supprimer'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () => _showDeleteDialog(tax),
                  ), */
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    final statusLower = status.toLowerCase();
    if (statusLower == 'en_attente' ||
        statusLower == 'pending' ||
        statusLower == 'draft' ||
        statusLower == 'declared' ||
        statusLower == 'calculated') {
      return Colors.orange;
    }
    if (statusLower == 'valide' || statusLower == 'validated') {
      return Colors.green;
    }
    if (statusLower == 'rejete' || statusLower == 'rejected') {
      return Colors.red;
    }
    if (statusLower == 'paid' || statusLower == 'paye') {
      return Colors.blue;
    }
    return Colors.grey;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showEditDialog(Tax tax) {
    context.go('/taxes/${tax.id}/edit', extra: tax);
  }

  void _showMarkPaidDialog(Tax tax, TaxNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Marquer comme payé'),
        content: Text('Marquer la taxe "${tax.name}" comme payée ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await notifier.markTaxAsPaid(tax);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Taxe marquée comme payée avec succès'),
                        backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Erreur: $e'),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}

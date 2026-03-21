import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/stock_notifier.dart';
import 'package:easyconnect/Models/stock_model.dart';
import 'package:easyconnect/Views/Components/paginated_list_view.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';

class StockList extends ConsumerStatefulWidget {
  const StockList({super.key});

  @override
  ConsumerState<StockList> createState() => _StockListState();
}

class _StockListState extends ConsumerState<StockList>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  static String _statusForIndex(int index) {
    switch (index) {
      case 0: return 'all';
      case 1: return 'en_attente';
      case 2: return 'valide';
      case 3: return 'rejete';
      default: return 'all';
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(stockProvider.notifier).filterByStatus(
          _statusForIndex(_tabController.index),
        );
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(stockProvider.notifier).loadStocks(forceRefresh: true);
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
    final state = ref.watch(stockProvider);
    final notifier = ref.read(stockProvider.notifier);
    final formatCurrency = NumberFormat.currency(locale: 'fr_FR', symbol: 'fcfa');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.loadStocks(forceRefresh: true),
            tooltip: 'Actualiser',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tous', icon: Icon(Icons.list)),
            Tab(text: 'En attente', icon: Icon(Icons.pending)),
            Tab(text: 'Approuvés', icon: Icon(Icons.check_circle)),
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
                hintText: 'Rechercher par nom, SKU ou description...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: state.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          notifier.searchStocks('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) => notifier.searchStocks(value),
            ),
          ),
          Expanded(
            child: state.isLoading && state.stocks.isEmpty
                ? const SkeletonSearchResults(itemCount: 6)
                : state.stocks.isEmpty
                    ? const Center(child: Text('Aucun produit trouvé'))
                    : PaginatedListView(
                        scrollController: _scrollController,
                        onLoadMore: notifier.loadMore,
                        hasNextPage: state.hasNextPage,
                        isLoadingMore: state.isLoadingMore,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: state.stocks.length,
                        itemBuilder: (context, index) {
                          final stock = state.stocks[index];
                          return _buildStockCard(
                            context,
                            stock,
                            formatCurrency,
                            notifier,
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/stocks/new'),
        tooltip: 'Nouveau produit',
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStockCard(
    BuildContext context,
    Stock stock,
    NumberFormat formatCurrency,
    StockNotifier notifier,
  ) {
    final statusColor = _getStatusColor(stock.status);
    final statusLabel = _getStatusLabel(stock.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => context.go('/stocks/${stock.id}', extra: stock),
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
                      stock.name,
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
                      statusLabel,
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
              Row(
                children: [
                  Icon(Icons.qr_code, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'SKU: ${stock.sku}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.inventory, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Quantité: ${stock.quantity.toStringAsFixed(0)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Prix unitaire: ${formatCurrency.format(stock.unitPrice)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calculate, size: 16, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Total: ${formatCurrency.format(stock.unitPrice * stock.quantity)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
              if ((stock.status == 'rejete' || stock.status == 'rejected') &&
                  stock.commentaire != null &&
                  stock.commentaire!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.report, size: 16, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Raison: ${stock.commentaire}',
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
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Détails'),
                    onPressed: () =>
                        context.go('/stocks/${stock.id}', extra: stock),
                  ),
                  if (stock.status == 'en_attente' || stock.status == 'pending') ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Modifier'),
                      onPressed: () =>
                          context.go('/stocks/${stock.id}/edit', extra: stock),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'en_attente':
      case 'pending':
        return Colors.orange;
      case 'valide':
      case 'approved':
        return Colors.green;
      case 'rejete':
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'en_attente':
      case 'pending':
        return 'En attente';
      case 'valide':
      case 'approved':
        return 'Validé';
      case 'rejete':
      case 'rejected':
        return 'Rejeté';
      default:
        return 'Inconnu';
    }
  }
}

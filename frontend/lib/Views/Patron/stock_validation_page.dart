import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/providers/stock_notifier.dart';
import 'package:easyconnect/Models/stock_model.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';
import 'package:easyconnect/utils/app_config.dart';

class StockValidationPage extends ConsumerStatefulWidget {
  const StockValidationPage({super.key});

  @override
  ConsumerState<StockValidationPage> createState() =>
      _StockValidationPageState();
}

class _StockValidationPageState extends ConsumerState<StockValidationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _autoRefreshTimer;

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
      _loadStocks();
      _startAutoRefresh();
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStocks() async {
    await ref.read(stockProvider.notifier).loadStocks(forceRefresh: true);
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer =
        Timer.periodic(AppConfig.realtimeListRefreshInterval, (_) {
      if (!mounted) return;
      _loadStocks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stockProvider);
    final notifier = ref.read(stockProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation du Stock'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStocks,
            tooltip: 'Actualiser',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Tous', icon: Icon(Icons.list)),
            Tab(text: 'En attente', icon: Icon(Icons.pending)),
            Tab(text: 'Validés', icon: Icon(Icons.check_circle)),
            Tab(text: 'Rejetés', icon: Icon(Icons.cancel)),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par nom, catégorie...',
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
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => notifier.searchStocks(value),
            ),
          ),
          Expanded(
            child: state.isLoading && state.stocks.isEmpty
                ? const SkeletonSearchResults(itemCount: 6)
                : _buildStockList(state.stocks),
          ),
        ],
      ),
    );
  }

  Widget _buildStockList(List<Stock> filteredStocks) {
    final searchQuery = ref.watch(stockProvider).searchQuery;
    final formatDate = DateFormat('dd/MM/yyyy');

    if (filteredStocks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              searchQuery.isEmpty
                  ? 'Aucun article trouvé'
                  : 'Aucun article correspondant à "$searchQuery"',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            if (searchQuery.isNotEmpty) ...[
              const SizedBox(height: 6),
              ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  ref.read(stockProvider.notifier).searchStocks('');
                },
                icon: const Icon(Icons.clear),
                label: const Text('Effacer la recherche'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredStocks.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final stock = filteredStocks[index];
        return _buildStockCard(context, stock, formatDate);
      },
    );
  }

  Widget _buildStockCard(
      BuildContext context, Stock stock, DateFormat formatDate) {
    final statusColor = _getStatusColor(stock.status);
    final statusIcon = _getStatusIcon(stock.status);
    final statusText = stock.statusText;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          stock.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Catégorie: ${stock.category}'),
            Text('Quantité: ${stock.quantity}'),
            Text(
              'Date: ${stock.createdAt != null ? formatDate.format(stock.createdAt!) : "N/A"}',
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informations générales',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nom: ${stock.name}'),
                      Text('Catégorie: ${stock.category}'),
                      Text('Quantité: ${stock.quantity}'),
                      Text('Prix unitaire: ${stock.unitPrice}'),
                      Text(
                        'Date: ${stock.createdAt != null ? formatDate.format(stock.createdAt!) : "N/A"}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildActionButtons(context, stock, statusColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, Stock stock, Color statusColor) {
    if (stock.isPending) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showApproveConfirmation(context, stock),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Valider', style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 36),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showRejectDialog(context, stock),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Rejeter', style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 36),
                ),
              ),
            ],
          ),
        ],
      );
    } else if (stock.isValidated) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(
              'Article validé',
              style: TextStyle(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else if (stock.isRejected) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cancel, color: Colors.red),
            const SizedBox(width: 8),
            Text(
              'Article rejeté',
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.help, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              'Statut: ${stock.status}',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
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

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'en_attente':
      case 'pending':
        return Icons.pending;
      case 'valide':
      case 'approved':
        return Icons.check_circle;
      case 'rejete':
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  void _showApproveConfirmation(BuildContext context, Stock stock) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Voulez-vous valider cet article ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(stockProvider.notifier).approveStock(stock);
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Article validé')),
                );
              }
              _loadStocks();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, Stock stock) {
    final commentController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeter l\'article'),
        content: TextField(
          controller: commentController,
          decoration: const InputDecoration(
            labelText: 'Motif du rejet',
            hintText: 'Entrez le motif du rejet',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (commentController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez entrer un motif de rejet'),
                  ),
                );
                return;
              }
              await ref.read(stockProvider.notifier).rejectStock(
                  stock, commentController.text.trim());
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Article rejeté')),
                );
              }
              _loadStocks();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }
}

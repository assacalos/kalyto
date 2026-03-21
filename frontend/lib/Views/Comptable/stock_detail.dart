import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/stock_notifier.dart';
import 'package:easyconnect/Models/stock_model.dart';
import 'package:intl/intl.dart';

class StockDetail extends ConsumerWidget {
  final Stock stock;

  const StockDetail({super.key, required this.stock});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(stockProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(stock.name),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () =>
                context.go('/stocks/${stock.id}/edit', extra: stock),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareStock(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec statut
            _buildHeaderCard(),
            const SizedBox(height: 16),

            // Informations de base
            _buildInfoCard('Informations de base', [
              _buildInfoRow(Icons.inventory, 'Nom', stock.name),
              _buildInfoRow(Icons.qr_code, 'SKU', stock.sku),
              _buildInfoRow(Icons.category, 'Catégorie', stock.category),
              if (stock.description != null && stock.description!.isNotEmpty)
                _buildInfoRow(
                  Icons.description,
                  'Description',
                  stock.description!,
                ),
              _buildInfoRow(
                Icons.euro,
                'Prix unitaire',
                stock.formattedUnitPrice,
              ),
            ]),

            // Informations de stock
            const SizedBox(height: 16),
            _buildInfoCard('Informations de stock', [
              _buildInfoRow(
                Icons.inventory,
                'Quantité actuelle',
                stock.formattedQuantity,
                isHighlight: true,
              ),
              _buildInfoRow(
                Icons.warning,
                'Seuil minimum',
                '${stock.minQuantity.toStringAsFixed(0)}',
              ),
              _buildInfoRow(
                Icons.trending_up,
                'Seuil maximum',
                '${stock.maxQuantity.toStringAsFixed(0)}',
              ),
              _buildInfoRow(
                Icons.account_balance_wallet,
                'Valeur totale',
                stock.formattedTotalValue,
                isHighlight: true,
              ),
            ]),

            // Statut du stock
            const SizedBox(height: 16),
            _buildInfoCard('Statut du stock', [
              _buildInfoRow(
                Icons.info,
                'Statut',
                stock.stockStatusText,
                isOverdue: stock.isOutOfStock,
                isWarning: stock.isLowStock,
              ),
              if (stock.isLowStock)
                _buildInfoRow(
                  Icons.warning,
                  'Alerte',
                  'Stock faible - Seuil minimum atteint',
                  isWarning: true,
                ),
              if (stock.isOutOfStock)
                _buildInfoRow(
                  Icons.error,
                  'Alerte',
                  'Rupture de stock',
                  isOverdue: true,
                ),
              if (stock.isOverstocked)
                _buildInfoRow(
                  Icons.info,
                  'Alerte',
                  'Surstock - Seuil maximum dépassé',
                  isInfo: true,
                ),
            ]),

            // Commentaire si disponible
            if (stock.commentaire != null && stock.commentaire!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Commentaire', [
                _buildInfoRow(Icons.note, 'Commentaire', stock.commentaire!),
              ]),
            ],

            // Historique des mouvements
            const SizedBox(height: 16),
            _buildMovementsCard(),

            const SizedBox(height: 16),

            // Actions
            _buildActionButtons(context, ref, notifier),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: _getStatusColor().withOpacity(0.1),
              child: Icon(Icons.inventory, size: 30, color: _getStatusColor()),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stock.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildStatusChip(),
                  const SizedBox(height: 8),
                  Text(
                    'SKU: ${stock.sku}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getStatusColor().withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(), size: 16, color: _getStatusColor()),
          const SizedBox(width: 4),
          Text(
            stock.stockStatusText,
            style: TextStyle(
              color: _getStatusColor(),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool? isOverdue,
    bool? isWarning,
    bool? isInfo,
    bool? isHighlight,
  }) {
    Color? textColor;
    if (isOverdue == true) {
      textColor = Colors.red;
    } else if (isWarning == true) {
      textColor = Colors.orange;
    } else if (isInfo == true) {
      textColor = Colors.blue;
    } else if (isHighlight == true) {
      textColor = Colors.green;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        isHighlight == true ? FontWeight.bold : FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mouvements récents',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),
            if (stock.movements != null && stock.movements!.isNotEmpty) ...[
              ...stock.movements!
                  .take(5)
                  .map((movement) => _buildMovementItem(movement)),
            ] else ...[
              const Center(
                child: Text(
                  'Aucun mouvement récent',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMovementItem(StockMovement movement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(
            _getMovementIcon(movement.type),
            color: _getMovementColor(movement.type),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.typeText,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  movement.quantity.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (movement.reason != null)
                  Text(
                    movement.reason!,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
          Text(
            DateFormat('dd/MM/yyyy').format(movement.createdAt),
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, WidgetRef ref, StockNotifier notifier) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Entrée'),
                    onPressed: () =>
                        _showMovementDialog(context, ref, notifier, 'in'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.remove),
                    label: const Text('Sortie'),
                    onPressed: () =>
                        _showMovementDialog(context, ref, notifier, 'out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('Modifier'),
                    onPressed: () =>
                        context.go('/stocks/${stock.id}/edit', extra: stock),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.tune),
                    label: const Text('Ajuster'),
                    onPressed: () =>
                        _showAdjustmentDialog(context, ref, notifier),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
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

  Color _getStatusColor() {
    switch (stock.stockStatusColor) {
      case 'red':
        return Colors.red;
      case 'orange':
        return Colors.orange;
      case 'blue':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  IconData _getStatusIcon() {
    switch (stock.stockStatusIcon) {
      case 'error':
        return Icons.error;
      case 'warning':
        return Icons.warning;
      case 'info':
        return Icons.info;
      default:
        return Icons.check_circle;
    }
  }

  IconData _getMovementIcon(String type) {
    switch (type) {
      case 'in':
        return Icons.add;
      case 'out':
        return Icons.remove;
      case 'adjustment':
        return Icons.edit;
      case 'transfer':
        return Icons.swap_horiz;
      default:
        return Icons.help;
    }
  }

  Color _getMovementColor(String type) {
    switch (type) {
      case 'in':
        return Colors.green;
      case 'out':
        return Colors.red;
      case 'adjustment':
        return Colors.blue;
      case 'transfer':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _shareStock(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité de partage à implémenter'),
      ),
    );
  }

  void _showMovementDialog(
      BuildContext context, WidgetRef ref, StockNotifier notifier, String type) {
    final quantityController = TextEditingController();
    final reasonController = TextEditingController();
    final referenceController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${type == 'in' ? 'Entrée' : 'Sortie'} de stock'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantité *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Raison *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.help_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: referenceController,
                decoration: const InputDecoration(
                  labelText: 'Référence (optionnel)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.tag),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optionnel)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (quantityController.text.isNotEmpty &&
                  reasonController.text.isNotEmpty) {
                final qty = double.tryParse(quantityController.text) ?? 0;
                if (stock.id == null) return;
                await notifier.addStockMovement(
                  stockId: stock.id!,
                  type: type,
                  quantity: qty,
                  reason: reasonController.text.trim(),
                  reference: referenceController.text.trim().isEmpty
                      ? null
                      : referenceController.text.trim(),
                  notes: notesController.text.trim().isEmpty
                      ? null
                      : notesController.text.trim(),
                );
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mouvement enregistré')),
                  );
                }
              }
            },
            child: Text('${type == 'in' ? 'Ajouter' : 'Retirer'}'),
          ),
        ],
      ),
    );
  }

  void _showAdjustmentDialog(
      BuildContext context, WidgetRef ref, StockNotifier notifier) {
    final quantityController = TextEditingController(
      text: stock.quantity.toString(),
    );
    final reasonController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajuster le stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(
                labelText: 'Nouvelle quantité *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Raison *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.help_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
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
              if (quantityController.text.isNotEmpty &&
                  reasonController.text.isNotEmpty) {
                final newQty = double.tryParse(quantityController.text) ?? 0;
                if (stock.id == null) return;
                await notifier.adjustStock(
                  stockId: stock.id!,
                  newQuantity: newQty,
                  reason: reasonController.text.trim(),
                  notes: notesController.text.trim().isEmpty
                      ? null
                      : notesController.text.trim(),
                );
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Stock ajusté')),
                  );
                }
              }
            },
            child: const Text('Ajuster'),
          ),
        ],
      ),
    );
  }
}

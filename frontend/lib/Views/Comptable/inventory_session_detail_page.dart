import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/providers/inventory_session_notifier.dart';
import 'package:easyconnect/providers/inventory_session_state.dart';
import 'package:easyconnect/Models/inventory_session_model.dart';
import 'package:easyconnect/utils/dashboard_entity_colors.dart';

class InventorySessionDetailPage extends ConsumerStatefulWidget {
  final int sessionId;
  final InventorySession? session;

  const InventorySessionDetailPage({
    super.key,
    required this.sessionId,
    this.session,
  });

  @override
  ConsumerState<InventorySessionDetailPage> createState() =>
      _InventorySessionDetailPageState();
}

class _InventorySessionDetailPageState
    extends ConsumerState<InventorySessionDetailPage> {
  final Map<int, TextEditingController> _countedControllers = {};
  final NumberFormat _fmt = NumberFormat('#,##0.##', 'fr_FR');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inventorySessionProvider.notifier).loadSession(widget.sessionId);
      if (widget.session != null) {
        ref.read(inventorySessionProvider.notifier).setCurrentSession(widget.session);
      }
    });
  }

  @override
  void dispose() {
    for (final c in _countedControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _getCountedController(int index, double? initial) {
    if (!_countedControllers.containsKey(index)) {
      _countedControllers[index] = TextEditingController(
        text: initial != null && initial != 0 ? _fmt.format(initial) : '',
      );
    }
    return _countedControllers[index]!;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventorySessionProvider);
    final notifier = ref.read(inventorySessionProvider.notifier);
    final session = state.currentSession ?? widget.session;

    if (session == null && !state.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Inventaire')),
        body: const Center(child: Text('Session non trouvée')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(session != null
            ? 'Inventaire — ${session.date ?? 'Session ${session.id}'}'
            : 'Inventaire'),
        backgroundColor: DashboardEntityColors.inventaire,
        foregroundColor: Colors.white,
        actions: [
          if (session != null && !session.isClosed)
            IconButton(
              icon: const Icon(Icons.add_box),
              onPressed: state.isLoadingLines
                  ? null
                  : () => _addLinesFromStock(context, ref, notifier),
              tooltip: 'Remplir depuis le stock',
            ),
        ],
      ),
      body: state.error != null
          ? _buildError(state.error!, notifier)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (session != null) _buildSessionInfo(session),
                Expanded(
                  child: state.isLoadingLines && state.lines.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : state.lines.isEmpty
                          ? _buildEmptyLines(context, ref, notifier)
                          : _buildLinesList(state, notifier, session!.isClosed),
                ),
                if (session != null && !session.isClosed && state.lines.isNotEmpty)
                  _buildCloseButton(context, state, notifier),
              ],
            ),
    );
  }

  Widget _buildError(String message, InventorySessionNotifier notifier) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => notifier.loadSession(widget.sessionId),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionInfo(InventorySession session) {
    final dateStr = session.date != null
        ? (DateTime.tryParse(session.date!) != null
            ? DateFormat('dd/MM/yyyy').format(DateTime.parse(session.date!))
            : session.date)
        : '—';
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: session.statusColor.withOpacity(0.2),
            child: Icon(Icons.inventory_2, color: session.statusColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.statusLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: session.statusColor,
                  ),
                ),
                Text('Date: $dateStr'),
                if (session.depot != null && session.depot!.isNotEmpty)
                  Text('Dépôt: ${session.depot}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyLines(
      BuildContext context, WidgetRef ref, InventorySessionNotifier notifier) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.list_alt, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Aucune ligne d\'inventaire',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez les articles du stock pour commencer le comptage.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _addLinesFromStock(context, ref, notifier),
              icon: const Icon(Icons.add_box),
              label: const Text('Remplir depuis le stock'),
              style: FilledButton.styleFrom(
                backgroundColor: DashboardEntityColors.inventaire,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinesList(InventorySessionState state,
      InventorySessionNotifier notifier, bool readOnly) {
    final lines = state.lines;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        if (state.linesWithEcart > 0 || state.totalEcart != 0)
          Card(
            color: state.totalEcart != 0 ? Colors.orange.shade50 : null,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Écarts: ${state.linesWithEcart} ligne(s)',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Total écart: ${_fmt.format(state.totalEcart)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: state.totalEcart != 0 ? Colors.orange.shade800 : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        ...List.generate(lines.length, (index) {
          final line = lines[index];
          return _buildLineCard(index, line, readOnly, notifier);
        }),
      ],
    );
  }

  Widget _buildLineCard(int index, InventoryLine line, bool readOnly,
      InventorySessionNotifier notifier) {
    final controller = _getCountedController(index, line.countedQty);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    line.productName ?? line.sku ?? 'Article',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                if (line.sku != null)
                  Text(
                    line.sku!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Théorique', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      Text('${_fmt.format(line.theoreticalQty)} ${line.unit ?? ''}'),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Compté', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      if (readOnly)
                        Text(
                          '${_fmt.format(line.countedOrZero)} ${line.unit ?? ''}',
                        )
                      else
                        TextField(
                          controller: controller,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            hintText: '0',
                            isDense: true,
                            suffixText: line.unit,
                          ),
                          onSubmitted: (v) {
                            final qty = double.tryParse(v.replaceAll(',', '.')) ?? 0;
                            notifier.setLineCountedLocally(index, qty);
                            if (line.id != null) {
                              notifier.updateLineCounted(
                                  widget.sessionId, line.id!, qty);
                            }
                          },
                          onChanged: (v) {
                            final qty = double.tryParse(v.replaceAll(',', '.'));
                            if (qty != null) {
                              notifier.setLineCountedLocally(index, qty);
                            }
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 70,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Écart', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      Text(
                        '${line.ecart >= 0 ? '+' : ''}${_fmt.format(line.ecart)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: line.ecart == 0
                              ? Colors.grey
                              : line.ecart > 0
                                  ? Colors.green
                                  : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context, InventorySessionState state,
      InventorySessionNotifier notifier) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: state.isLoading
              ? null
              : () => _closeInventory(context, notifier),
          icon: state.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.lock),
          label: const Text('Clôturer l\'inventaire'),
          style: FilledButton.styleFrom(
            backgroundColor: DashboardEntityColors.inventaire,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Future<void> _addLinesFromStock(BuildContext context, WidgetRef ref,
      InventorySessionNotifier notifier) async {
    final ok = await notifier.addLinesFromStocks(widget.sessionId);
    if (context.mounted) {
      final err = ref.read(inventorySessionProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Lignes ajoutées' : err ?? 'Erreur'),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _closeInventory(
      BuildContext context, InventorySessionNotifier notifier) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clôturer l\'inventaire'),
        content: const Text(
          'Cela mettra à jour les quantités en stock selon les écarts. Continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clôturer'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    final ok = await notifier.closeSession(widget.sessionId);
      if (context.mounted) {
      final err = ref.read(inventorySessionProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Inventaire clôturé' : err ?? 'Erreur'),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
      if (ok) context.go('/stock/inventaire');
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/providers/inventory_session_notifier.dart';
import 'package:easyconnect/Models/inventory_session_model.dart';
import 'package:easyconnect/utils/dashboard_entity_colors.dart';

class InventorySessionListPage extends ConsumerStatefulWidget {
  const InventorySessionListPage({super.key});

  @override
  ConsumerState<InventorySessionListPage> createState() =>
      _InventorySessionListPageState();
}

class _InventorySessionListPageState
    extends ConsumerState<InventorySessionListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inventorySessionProvider.notifier).loadSessions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventorySessionProvider);
    final notifier = ref.read(inventorySessionProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventaire physique'),
        backgroundColor: DashboardEntityColors.inventaire,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: state.isLoading ? null : () => notifier.loadSessions(),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: state.error != null
          ? _buildError(state.error!, notifier)
          : state.isLoading && state.sessions.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : state.sessions.isEmpty
                  ? _buildEmpty(context)
                  : RefreshIndicator(
                      onRefresh: () => notifier.loadSessions(),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: state.sessions.length,
                        itemBuilder: (context, index) {
                          final session = state.sessions[index];
                          return _buildSessionCard(context, session);
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, notifier),
        backgroundColor: DashboardEntityColors.inventaire,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        tooltip: 'Nouvelle session',
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
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => notifier.loadSessions(),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucune session d\'inventaire',
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              'Créez une session pour lancer un inventaire physique.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, InventorySession session) {
    final dateStr = session.date != null
        ? (DateTime.tryParse(session.date!) != null
            ? DateFormat('dd/MM/yyyy').format(DateTime.parse(session.date!))
            : session.date)
        : '—';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: session.statusColor.withOpacity(0.2),
          child: Icon(Icons.inventory_2, color: session.statusColor),
        ),
        title: Text(
          'Session ${session.id ?? ''} — $dateStr',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${session.depot != null && session.depot!.isNotEmpty ? session.depot! + ' • ' : ''}${session.statusLabel}${session.linesCount != null ? ' • ${session.linesCount} ligne(s)' : ''}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go('/stock/inventaire/${session.id}',
            extra: session),
      ),
    );
  }

  Future<void> _showCreateDialog(
      BuildContext context, InventorySessionNotifier notifier) async {
    final dateCtrl = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    final depotCtrl = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouvelle session d\'inventaire'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  hintText: 'YYYY-MM-DD',
                ),
                controller: dateCtrl,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Dépôt / Entrepôt (optionnel)',
                ),
                controller: depotCtrl,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Créer'),
          ),
        ],
      ),
    );
    final date = dateCtrl.text.trim().isEmpty ? null : dateCtrl.text.trim();
    final depot = depotCtrl.text.trim().isEmpty ? null : depotCtrl.text.trim();
    dateCtrl.dispose();
    depotCtrl.dispose();
    if (created != true || !context.mounted) return;
    final session = await notifier.createSession(date: date, depot: depot);
    if (session != null && context.mounted) {
      context.go('/stock/inventaire/${session.id}', extra: session);
    } else if (context.mounted) {
      final err = ref.read(inventorySessionProvider).error;
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Colors.red),
        );
      }
    }
  }
}

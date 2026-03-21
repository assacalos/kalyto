import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/besoin_notifier.dart';
import 'package:easyconnect/providers/besoin_state.dart';
import 'package:easyconnect/Models/besoin_model.dart';
import 'package:intl/intl.dart';

class BesoinListPage extends ConsumerStatefulWidget {
  const BesoinListPage({super.key});

  @override
  ConsumerState<BesoinListPage> createState() => _BesoinListPageState();
}

class _BesoinListPageState extends ConsumerState<BesoinListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(besoinProvider.notifier).loadBesoins(forceRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(besoinProvider);
    final notifier = ref.read(besoinProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Besoins / Rappels patron'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.loadBesoins(forceRefresh: true),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Wrap(
              spacing: 8,
              children: [
                _chip(context, notifier, state.selectedStatus, 'all', 'Tous'),
                _chip(context, notifier, state.selectedStatus, 'pending', 'En attente'),
                _chip(context, notifier, state.selectedStatus, 'treated', 'Traités'),
              ],
            ),
          ),
          Expanded(
            child: _buildBody(context, state, notifier),
          ),
        ],
      ),
      floatingActionButton: state.isTechnicien
          ? FloatingActionButton.extended(
              onPressed: () async {
                await context.push('/besoins/new');
                if (context.mounted) {
                  ref.read(besoinProvider.notifier).loadBesoins(forceRefresh: true);
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Nouveau besoin'),
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _chip(
    BuildContext context,
    BesoinNotifier notifier,
    String selectedValue,
    String value,
    String label,
  ) {
    final selected = selectedValue == value;
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => notifier.filterByStatus(value),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    BesoinState state,
    BesoinNotifier notifier,
  ) {
    if (state.isLoading && state.besoins.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.besoins.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_active, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucun besoin',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Créez un besoin pour que le patron soit rappelé automatiquement',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.besoins.length,
      itemBuilder: (context, index) {
        final besoin = state.besoins[index];
        return _BesoinCard(
          besoin: besoin,
          canMarkTreated: state.canMarkTreated,
          onMarkTreated: () => _showMarkTreatedDialog(context, besoin, notifier),
        );
      },
    );
  }

  void _showMarkTreatedDialog(
    BuildContext context,
    Besoin besoin,
    BesoinNotifier notifier,
  ) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Marquer comme traité'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Note optionnelle :'),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                hintText: 'Commentaire...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await notifier.markTreated(
                  besoin.id!,
                  note: noteController.text.trim().isEmpty
                      ? null
                      : noteController.text.trim(),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Besoin marqué comme traité.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceFirst('Exception: ', '')),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Marquer traité'),
          ),
        ],
      ),
    );
  }
}

class _BesoinCard extends StatelessWidget {
  final Besoin besoin;
  final bool canMarkTreated;
  final VoidCallback onMarkTreated;

  const _BesoinCard({
    required this.besoin,
    required this.canMarkTreated,
    required this.onMarkTreated,
  });

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('dd/MM/yyyy HH:mm');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          besoin.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (besoin.description != null && besoin.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  besoin.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(
                    besoin.reminderFrequencyLabel,
                    style: const TextStyle(fontSize: 12),
                  ),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 8),
                Chip(
                  backgroundColor:
                      besoin.isPending ? Colors.orange.shade100 : Colors.green.shade100,
                  label: Text(
                    besoin.isPending ? 'En attente' : 'Traité',
                    style: const TextStyle(fontSize: 12),
                  ),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Créé le ${format.format(besoin.createdAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        trailing: canMarkTreated && besoin.isPending
            ? IconButton(
                icon: const Icon(Icons.check_circle),
                tooltip: 'Marquer comme traité',
                onPressed: onMarkTreated,
              )
            : null,
      ),
    );
  }
}

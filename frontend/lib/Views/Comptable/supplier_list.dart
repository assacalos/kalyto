import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/supplier_notifier.dart';
import 'package:easyconnect/providers/supplier_state.dart';
import 'package:easyconnect/Models/supplier_model.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';

class SupplierList extends ConsumerStatefulWidget {
  const SupplierList({super.key});

  @override
  ConsumerState<SupplierList> createState() => _SupplierListState();
}

class _SupplierListState extends ConsumerState<SupplierList> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(supplierProvider.notifier).loadSuppliers();
      ref.read(supplierProvider.notifier).loadSupplierStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(supplierProvider);
    final notifier = ref.read(supplierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Fournisseurs'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.loadSuppliers(forceRefresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(context, state, notifier),
          _buildQuickStats(state),
          Expanded(child: _buildSupplierList(context, state, notifier)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreate(context),
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchAndFilters(
      BuildContext context, SupplierState state, SupplierNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher un fournisseur...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) => notifier.searchSuppliers(value),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(context, 'Tous', 'all', state, notifier),
                const SizedBox(width: 8),
                _buildFilterChip(context, 'En attente', 'en_attente', state, notifier),
                const SizedBox(width: 8),
                _buildFilterChip(context, 'Validés', 'valide', state, notifier),
                const SizedBox(width: 8),
                _buildFilterChip(context, 'Rejetés', 'rejete', state, notifier),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    String value,
    SupplierState state,
    SupplierNotifier notifier,
  ) {
    return FilterChip(
      label: Text(label),
      selected: state.selectedStatus == value,
      onSelected: (selected) {
        if (selected) notifier.filterByStatus(value);
      },
      selectedColor: Colors.deepPurple.withOpacity(0.2),
      checkmarkColor: Colors.deepPurple,
    );
  }

  Widget _buildQuickStats(SupplierState state) {
    if (state.supplierStats == null) return const SizedBox.shrink();
    final stats = state.supplierStats!;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total',
              stats.total.toString(),
              Icons.business,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'En attente',
              stats.pending.toString(),
              Icons.schedule,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Validés',
              stats.validated.toString(),
              Icons.check_circle,
              Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Rejetés',
              stats.rejected.toString(),
              Icons.cancel,
              Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierList(
      BuildContext context, SupplierState state, SupplierNotifier notifier) {
    if (state.isLoading) {
      return const SkeletonSearchResults(itemCount: 6);
    }
    if (state.suppliers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucun fournisseur trouvé',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Commencez par ajouter un fournisseur',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.suppliers.length,
      itemBuilder: (context, index) {
        final supplier = state.suppliers[index];
        return _buildSupplierCard(context, supplier, notifier);
      },
    );
  }

  Widget _buildSupplierCard(
      BuildContext context, Supplier supplier, SupplierNotifier notifier) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.go('/suppliers/${supplier.id}', extra: supplier),
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
                      supplier.nom,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(supplier),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.email, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      supplier.email,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    supplier.telephone,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${supplier.ville}, ${supplier.pays}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),
                ],
              ),
              if (supplier.noteEvaluation != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.star, size: 16, color: Colors.amber[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Note: ${supplier.noteEvaluation!.toStringAsFixed(1)}/5',
                      style: TextStyle(
                        color: Colors.amber[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (supplier.isValidated)
                    TextButton.icon(
                      icon: const Icon(Icons.star, size: 16),
                      label: const Text('Évaluer'),
                      onPressed: () =>
                          _showRatingDialog(context, supplier, notifier),
                    ),
                  TextButton.icon(
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Modifier'),
                    onPressed: () =>
                        context.go('/suppliers/${supplier.id}/edit', extra: supplier),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Supprimer'),
                    onPressed: () =>
                        _showDeleteDialog(context, supplier, notifier),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(Supplier supplier) {
    Color color;
    switch (supplier.statusColor) {
      case 'orange':
        color = Colors.orange;
        break;
      case 'blue':
        color = Colors.blue;
        break;
      case 'green':
        color = Colors.green;
        break;
      case 'red':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        supplier.statusText,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _navigateToCreate(BuildContext context) {
    context.go('/suppliers/new');
  }

  void _showRatingDialog(
      BuildContext context, Supplier supplier, SupplierNotifier notifier) {
    final commentsController = TextEditingController();
    double rating = supplier.noteEvaluation ?? 0.0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Évaluer le fournisseur'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Note (1-5 étoiles) :'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < rating.round() ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () => setState(() => rating = index + 1.0),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                const Text('Commentaires (optionnel) :'),
                const SizedBox(height: 8),
                TextField(
                  controller: commentsController,
                  decoration: const InputDecoration(
                    hintText: 'Ajouter des commentaires...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
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
                    await notifier.rateSupplier(
                      supplier,
                      rating,
                      comments: commentsController.text.trim().isEmpty
                          ? null
                          : commentsController.text.trim(),
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fournisseur évalué avec succès'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Évaluer'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteDialog(
      BuildContext context, Supplier supplier, SupplierNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le fournisseur'),
        content: Text(
            'Êtes-vous sûr de vouloir supprimer ${supplier.nom} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await notifier.deleteSupplier(supplier);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fournisseur supprimé avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Impossible de supprimer: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

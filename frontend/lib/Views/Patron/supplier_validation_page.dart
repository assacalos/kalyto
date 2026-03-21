import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/providers/supplier_notifier.dart';
import 'package:easyconnect/providers/supplier_state.dart';
import 'package:easyconnect/Models/supplier_model.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';

class SupplierValidationPage extends ConsumerStatefulWidget {
  const SupplierValidationPage({super.key});

  @override
  ConsumerState<SupplierValidationPage> createState() =>
      _SupplierValidationPageState();
}

class _SupplierValidationPageState extends ConsumerState<SupplierValidationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(supplierProvider.notifier).loadSuppliers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      ref.read(supplierProvider.notifier).loadSuppliers();
    }
  }

  Future<void> _loadSuppliers() async {
    ref.read(supplierProvider.notifier).filterByStatus('all');
    await ref.read(supplierProvider.notifier).loadSuppliers();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(supplierProvider);
    final notifier = ref.read(supplierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation des Fournisseurs'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSuppliers,
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
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par nom, email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(child: _buildSupplierList(state, notifier)),
        ],
      ),
    );
  }

  Widget _buildSupplierList(SupplierState state, SupplierNotifier notifier) {
    if (state.isLoading) {
      return const SkeletonSearchResults(itemCount: 6);
    }

    List<Supplier> filteredSuppliers = List.from(state.allSuppliers);
    switch (_tabController.index) {
      case 0:
        filteredSuppliers = state.allSuppliers;
        break;
      case 1:
        filteredSuppliers =
            state.allSuppliers.where((s) => s.isPending).toList();
        break;
      case 2:
        filteredSuppliers =
            state.allSuppliers.where((s) => s.isValidated).toList();
        break;
      case 3:
        filteredSuppliers =
            state.allSuppliers.where((s) => s.isRejected).toList();
        break;
      default:
        filteredSuppliers = state.allSuppliers;
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filteredSuppliers = filteredSuppliers.where((s) {
        return s.nom.toLowerCase().contains(query) ||
            s.email.toLowerCase().contains(query) ||
            s.telephone.toLowerCase().contains(query) ||
            s.ville.toLowerCase().contains(query) ||
            s.pays.toLowerCase().contains(query);
      }).toList();
    }

    if (filteredSuppliers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucun fournisseur trouvé',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredSuppliers.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final supplier = filteredSuppliers[index];
        return _buildSupplierCard(context, supplier, notifier);
      },
    );
  }

  Widget _buildSupplierCard(
      BuildContext context, Supplier supplier, SupplierNotifier notifier) {
    Color statusColor;
    switch (supplier.statusColor) {
      case 'orange':
        statusColor = Colors.orange;
        break;
      case 'green':
        statusColor = Colors.green;
        break;
      case 'red':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(Icons.business, color: statusColor),
        ),
        title: Text(
          supplier.nom,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.email, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    supplier.email,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  supplier.telephone,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withOpacity(0.5)),
          ),
          child: Text(
            supplier.statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Adresse', supplier.adresse),
                _buildInfoRow('Ville', supplier.ville),
                _buildInfoRow('Pays', supplier.pays),
                if (supplier.description != null)
                  _buildInfoRow('Description', supplier.description!),
                if (supplier.noteEvaluation != null)
                  _buildInfoRow(
                    'Note',
                    '${supplier.noteEvaluation!.toStringAsFixed(1)}/5',
                  ),
                const SizedBox(height: 16),
                _buildActionButtons(context, supplier, statusColor, notifier),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Expanded(
              child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Supplier supplier,
      Color statusColor, SupplierNotifier notifier) {
    if (supplier.isPending) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showApproveConfirmation(context, supplier, notifier),
                icon: const Icon(Icons.check),
                label: const Text('Valider'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showRejectDialog(context, supplier, notifier),
                icon: const Icon(Icons.close),
                label: const Text('Rejeter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      );
    }

    if (supplier.isValidated) {
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
              'Fournisseur validé',
              style: TextStyle(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (supplier.isRejected) {
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
              'Fournisseur rejeté',
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

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
            'Statut: ${supplier.statusText}',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showApproveConfirmation(
      BuildContext context, Supplier supplier, SupplierNotifier notifier) {
    final commentsController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Voulez-vous valider le fournisseur ${supplier.nom} ?'),
            const SizedBox(height: 16),
            TextField(
              controller: commentsController,
              decoration: const InputDecoration(
                labelText: 'Commentaires d\'approbation (optionnel)',
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
                await notifier.approveSupplier(
                  supplier,
                  validationComment: commentsController.text.trim().isEmpty
                      ? null
                      : commentsController.text.trim(),
                );
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Fournisseur validé avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
                _loadSuppliers();
              } catch (_) {}
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(
      BuildContext context, Supplier supplier, SupplierNotifier notifier) {
    final reasonController = TextEditingController();
    final commentController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeter le fournisseur'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Voulez-vous rejeter le fournisseur ${supplier.nom} ?'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Motif du rejet (obligatoire)',
                  hintText: 'Expliquez la raison du rejet...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  labelText: 'Commentaire (optionnel)',
                  hintText: 'Commentaire supplémentaire...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Le motif du rejet est obligatoire',
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              notifier.rejectSupplier(
                supplier,
                rejectionReason: reasonController.text.trim(),
                rejectionComment: commentController.text.trim().isEmpty
                    ? null
                    : commentController.text.trim(),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fournisseur rejeté'),
                  backgroundColor: Colors.orange,
                ),
              );
              _loadSuppliers();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }
}

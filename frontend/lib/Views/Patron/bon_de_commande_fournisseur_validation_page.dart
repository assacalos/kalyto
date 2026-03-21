import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/bon_de_commande_fournisseur_notifier.dart';
import 'package:easyconnect/Models/bon_de_commande_fournisseur_model.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';

class BonDeCommandeFournisseurValidationPage
    extends ConsumerStatefulWidget {
  const BonDeCommandeFournisseurValidationPage({super.key});

  @override
  ConsumerState<BonDeCommandeFournisseurValidationPage> createState() =>
      _BonDeCommandeFournisseurValidationPageState();
}

class _BonDeCommandeFournisseurValidationPageState
    extends ConsumerState<BonDeCommandeFournisseurValidationPage>
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
      _loadBonDeCommandes(forceRefresh: true);
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
      _loadBonDeCommandes();
    }
  }

  Future<void> _loadBonDeCommandes({bool forceRefresh = false}) async {
    String? status;
    switch (_tabController.index) {
      case 0:
        status = null;
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
      default:
        status = null;
    }
    ref.read(bonDeCommandeFournisseurProvider.notifier).setCurrentStatus(status);
    await ref
        .read(bonDeCommandeFournisseurProvider.notifier)
        .loadBonDeCommandes(status: status, forceRefresh: forceRefresh);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bonDeCommandeFournisseurProvider);
    final notifier = ref.read(bonDeCommandeFournisseurProvider.notifier);

    List<BonDeCommande> filteredBonDeCommandes;
    switch (_tabController.index) {
      case 0:
        filteredBonDeCommandes = state.bonDeCommandes;
        break;
      case 1:
        filteredBonDeCommandes = state.bonDeCommandes
            .where((bc) {
              final s = bc.statut.toLowerCase().trim();
              return s == 'en_attente' || s == 'pending';
            })
            .toList();
        break;
      case 2:
        filteredBonDeCommandes = state.bonDeCommandes
            .where((bc) {
              final s = bc.statut.toLowerCase().trim();
              return s == 'valide' || s == 'approved' || s == 'validated';
            })
            .toList();
        break;
      case 3:
        filteredBonDeCommandes = state.bonDeCommandes
            .where((bc) {
              final s = bc.statut.toLowerCase().trim();
              return s == 'rejete' || s == 'rejected';
            })
            .toList();
        break;
      default:
        filteredBonDeCommandes = state.bonDeCommandes;
    }
    if (_searchQuery.isNotEmpty) {
      filteredBonDeCommandes = filteredBonDeCommandes
          .where(
            (bc) => bc.numeroCommande
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation des Bons de Commande Fournisseur'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadBonDeCommandes(forceRefresh: true),
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
                hintText: 'Rechercher par numéro de commande...',
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
          Expanded(
            child: state.isLoading
                ? const SkeletonSearchResults(itemCount: 6)
                : filteredBonDeCommandes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_cart,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun bon de commande trouvé',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredBonDeCommandes.length,
                        padding: const EdgeInsets.all(8),
                        itemBuilder: (context, index) {
                          final bonDeCommande = filteredBonDeCommandes[index];
                          return _buildBonDeCommandeCard(
                            context,
                            bonDeCommande,
                            notifier,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildBonDeCommandeCard(
    BuildContext context,
    BonDeCommande bonDeCommande,
    BonDeCommandeFournisseurNotifier notifier,
  ) {
    final formatCurrency =
        NumberFormat.currency(locale: 'fr_FR', symbol: 'fcfa');
    final formatDate = DateFormat('dd/MM/yyyy');

    Color statusColor;
    IconData statusIcon;
    switch (bonDeCommande.statut.toLowerCase()) {
      case 'en_attente':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'valide':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejete':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'livre':
        statusColor = Colors.blue;
        statusIcon = Icons.local_shipping;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.1),
                  child: Icon(statusIcon, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bonDeCommande.numeroCommande,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          bonDeCommande.statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatCurrency.format(bonDeCommande.montantTotalCalcule),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.calendar_today,
              'Date de commande',
              formatDate.format(bonDeCommande.dateCommande),
            ),
            _buildInfoRow(
              Icons.shopping_cart,
              'Nombre d\'articles',
              '${bonDeCommande.items.length}',
            ),
            if (bonDeCommande.description != null &&
                bonDeCommande.description!.isNotEmpty)
              _buildInfoRow(
                Icons.description,
                'Description',
                bonDeCommande.description!,
              ),
            if (bonDeCommande.statut == 'rejete' &&
                bonDeCommande.commentaire != null &&
                bonDeCommande.commentaire!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.report, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Motif du rejet:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            bonDeCommande.commentaire!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            _buildActionButtons(context, bonDeCommande, notifier, statusColor),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    BonDeCommande bonDeCommande,
    BonDeCommandeFournisseurNotifier notifier,
    Color statusColor,
  ) {
    switch (bonDeCommande.statut.toLowerCase()) {
      case 'en_attente':
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () =>
                      _showApproveConfirmation(context, bonDeCommande, notifier),
                  icon: const Icon(Icons.check),
                  label: const Text('Valider'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () =>
                      _showRejectDialog(context, bonDeCommande, notifier),
                  icon: const Icon(Icons.close),
                  label: const Text('Rejeter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => context.go(
                '/bons-de-commande-fournisseur/${bonDeCommande.id}',
              ),
              icon: const Icon(Icons.visibility),
              label: const Text('Voir les détails'),
            ),
          ],
        );
      case 'valide':
        return Column(
          children: [
            Container(
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
                    'Bon de commande validé',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                final id = bonDeCommande.id;
                if (id == null) return;
                notifier.generatePDF(id).then((_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('PDF généré avec succès'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }).catchError((e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                });
              },
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Générer PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      case 'rejete':
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
                'Bon de commande rejeté',
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _showApproveConfirmation(
    BuildContext context,
    BonDeCommande bonDeCommande,
    BonDeCommandeFournisseurNotifier notifier,
  ) {
    final id = bonDeCommande.id;
    if (id == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text(
          'Voulez-vous valider ce bon de commande ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              notifier.approveBonDeCommande(id).then((_) {
                _loadBonDeCommandes();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bon de commande validé avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }).catchError((e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              });
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(
    BuildContext context,
    BonDeCommande bonDeCommande,
    BonDeCommandeFournisseurNotifier notifier,
  ) {
    final id = bonDeCommande.id;
    if (id == null) return;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeter le bon de commande'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                labelText: 'Motif du rejet *',
                hintText: 'Entrez le motif du rejet',
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
            onPressed: () {
              if (commentController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez entrer un motif de rejet'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              notifier
                  .rejectBonDeCommande(id, commentController.text)
                  .then((_) {
                _loadBonDeCommandes();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bon de commande rejeté avec succès'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }).catchError((e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              });
            },
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/bon_de_commande_fournisseur_notifier.dart';
import 'package:easyconnect/providers/bon_de_commande_fournisseur_state.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/Models/bon_de_commande_fournisseur_model.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';

class BonDeCommandeFournisseurListPage extends ConsumerStatefulWidget {
  final int? supplierId;

  const BonDeCommandeFournisseurListPage({super.key, this.supplierId});

  @override
  ConsumerState<BonDeCommandeFournisseurListPage> createState() =>
      _BonDeCommandeFournisseurListPageState();
}

class _BonDeCommandeFournisseurListPageState
    extends ConsumerState<BonDeCommandeFournisseurListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bonDeCommandeFournisseurProvider.notifier).loadBonDeCommandes(
            forceRefresh: true,
          );
    });
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
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
        case 4:
          status = 'livre';
          break;
        default:
          status = null;
      }
      ref.read(bonDeCommandeFournisseurProvider.notifier).setCurrentStatus(status);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bonDeCommandeFournisseurProvider);
    final notifier = ref.read(bonDeCommandeFournisseurProvider.notifier);
    final userRole = ref.read(authProvider).user?.role;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bons de commande fournisseur'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context, notifier),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusTabs(state),
          Expanded(child: _buildBonDeCommandeList(state, notifier, userRole)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/bons-de-commande-fournisseur/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau bon de commande'),
      ),
    );
  }

  Widget _buildStatusTabs(BonDeCommandeFournisseurState state) {
    final list = state.bonDeCommandes;
    return Container(
      color: Colors.grey[100],
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: Colors.blue,
        labelColor: Colors.blue,
        unselectedLabelColor: Colors.grey[600],
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.all_inclusive, size: 16),
                const SizedBox(width: 4),
                Text('Tous (${list.length})'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.pending, size: 16),
                const SizedBox(width: 4),
                Text(
                  'En attente (${list.where((bc) => bc.statut == 'en_attente').length})',
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Validés (${list.where((bc) => bc.statut == 'valide').length})',
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cancel, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Rejetés (${list.where((bc) => bc.statut == 'rejete').length})',
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_shipping, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Livrés (${list.where((bc) => bc.statut == 'livre').length})',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBonDeCommandeList(
    BonDeCommandeFournisseurState state,
    BonDeCommandeFournisseurNotifier notifier,
    int? userRole,
  ) {
    final filtered = state.getFilteredBonDeCommandes();

    if (state.isLoading) {
      return const SkeletonSearchResults(itemCount: 6);
    }

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucun bon de commande trouvé',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              state.bonDeCommandes.isEmpty
                  ? 'Créez votre premier bon de commande fournisseur'
                  : 'Aucun bon de commande ne correspond au filtre sélectionné',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await notifier.loadBonDeCommandes(status: state.currentStatus);
      },
      child: ListView.builder(
        itemCount: filtered.length,
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, index) {
          final bonDeCommande = filtered[index];
          return _buildBonDeCommandeCard(
            context,
            bonDeCommande,
            notifier,
            userRole,
          );
        },
      ),
    );
  }

  Widget _buildBonDeCommandeCard(
    BuildContext context,
    BonDeCommande bonDeCommande,
    BonDeCommandeFournisseurNotifier notifier,
    int? userRole,
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
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          bonDeCommande.numeroCommande,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Date: ${formatDate.format(bonDeCommande.dateCommande)}'),
            Text(
              'Montant: ${formatCurrency.format(bonDeCommande.montantTotalCalcule)}',
            ),
            Text(
              'Status: ${bonDeCommande.statusText}',
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (bonDeCommande.statut == 'rejete' &&
                bonDeCommande.commentaire != null &&
                bonDeCommande.commentaire!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.report, size: 14, color: Colors.red),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Raison du rejet: ${bonDeCommande.commentaire}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: () {
                if (bonDeCommande.id != null) {
                  notifier.generatePDF(bonDeCommande.id!).then((_) {
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
                          content: Text('Erreur PDF: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  });
                }
              },
              tooltip: 'Générer PDF',
            ),
            _buildActionButton(context, bonDeCommande, notifier, userRole),
          ],
        ),
        onTap: () => context.go(
          '/bons-de-commande-fournisseur/${bonDeCommande.id}',
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    BonDeCommande bonDeCommande,
    BonDeCommandeFournisseurNotifier notifier,
    int? userRole,
  ) {
    if (userRole == Roles.COMMERCIAL) {
      if (bonDeCommande.statut == 'en_attente') {
        return PopupMenuButton<String>(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Modifier')),
            const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
          ],
          onSelected: (value) {
            switch (value) {
              case 'edit':
                context.go(
                  '/bons-de-commande-fournisseur/${bonDeCommande.id}/edit',
                );
                break;
              case 'delete':
                _showDeleteConfirmation(context, bonDeCommande, notifier);
                break;
            }
          },
        );
      }
    }

    if (userRole == Roles.PATRON && bonDeCommande.statut == 'en_attente') {
      return PopupMenuButton<String>(
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'approve', child: Text('Valider')),
          const PopupMenuItem(value: 'reject', child: Text('Rejeter')),
        ],
        onSelected: (value) {
          switch (value) {
            case 'approve':
              _showApproveConfirmation(
                context,
                bonDeCommande,
                notifier,
              );
              break;
            case 'reject':
              _showRejectDialog(context, bonDeCommande, notifier);
              break;
          }
        },
      );
    }

    return const SizedBox.shrink();
  }

  void _showFilterDialog(
    BuildContext context,
    BonDeCommandeFournisseurNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filtrer par statut'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Tous'),
              onTap: () {
                Navigator.pop(ctx);
                notifier.loadBonDeCommandes();
              },
            ),
            ListTile(
              title: const Text('En attente'),
              onTap: () {
                Navigator.pop(ctx);
                notifier.loadBonDeCommandes(status: 'en_attente');
              },
            ),
            ListTile(
              title: const Text('Validés'),
              onTap: () {
                Navigator.pop(ctx);
                notifier.loadBonDeCommandes(status: 'valide');
              },
            ),
            ListTile(
              title: const Text('Rejetés'),
              onTap: () {
                Navigator.pop(ctx);
                notifier.loadBonDeCommandes(status: 'rejete');
              },
            ),
            ListTile(
              title: const Text('Livrés'),
              onTap: () {
                Navigator.pop(ctx);
                notifier.loadBonDeCommandes(status: 'livre');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
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
          'Voulez-vous supprimer ce bon de commande ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              notifier.deleteBonDeCommande(id).then((_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bon de commande supprimé avec succès'),
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
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
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
                labelText: 'Motif du rejet',
                hintText: 'Entrez le motif du rejet',
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
              if (commentController.text.trim().isEmpty) {
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
                  .rejectBonDeCommande(id, commentController.text.trim())
                  .then((_) {
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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/bon_commande_notifier.dart';
import 'package:easyconnect/providers/bon_commande_state.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/Views/Components/paginated_list_view.dart';
import 'package:easyconnect/Models/bon_commande_model.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';
import 'package:easyconnect/utils/app_config.dart';

class BonCommandeListPage extends ConsumerStatefulWidget {
  const BonCommandeListPage({super.key});

  @override
  ConsumerState<BonCommandeListPage> createState() => _BonCommandeListPageState();
}

class _BonCommandeListPageState extends ConsumerState<BonCommandeListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  bool _hasLoaded = false;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _scrollController = ScrollController();
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_hasLoaded) return;
      _hasLoaded = true;
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      ref.read(bonCommandeProvider.notifier).setSelectedStatus(null);
      ref.read(bonCommandeProvider.notifier).loadBonCommandes(forceRefresh: true);
      _startAutoRefresh();
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final index = _tabController.index;
      ref.read(bonCommandeProvider.notifier).setSelectedStatus(index);
      ref.read(bonCommandeProvider.notifier).loadBonCommandes(
        status: index == 0 ? null : index,
        forceRefresh: true,
      );
    }
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(AppConfig.realtimeListRefreshInterval, (_) {
      if (!mounted) return;
      final status = _tabController.index == 0 ? null : _tabController.index;
      ref.read(bonCommandeProvider.notifier).loadBonCommandes(
        status: status,
        forceRefresh: true,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bonCommandeProvider);
    final notifier = ref.read(bonCommandeProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bons de commande'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.loadBonCommandes(
              status: _tabController.index == 0 ? null : _tabController.index,
              forceRefresh: true,
            ),
            tooltip: 'Actualiser',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context, notifier),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusTabs(state),
          Expanded(
            child: state.isLoading
                ? const SkeletonSearchResults(itemCount: 6)
                : _buildBonCommandeList(state, notifier),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/bon-commandes/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau bon de commande'),
      ),
    );
  }

  Widget _buildStatusTabs(BonCommandeState state) {
    final list = state.bonCommandes;
    final enAttente = list.where((bc) => bc.status == 0 || bc.status == 1).length;
    return Container(
      color: Colors.grey[100],
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: Colors.blue,
        labelColor: Colors.blue,
        unselectedLabelColor: Colors.grey[600],
        tabs: [
          Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.all_inclusive, size: 16), const SizedBox(width: 4), Text('Tous (${list.length})')])),
          Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.pending, size: 16), const SizedBox(width: 4), Text('En attente ($enAttente)')])),
          Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.check_circle, size: 16), const SizedBox(width: 4), Text('Validés (${list.where((bc) => bc.status == 2).length})')])),
          Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cancel, size: 16), const SizedBox(width: 4), Text('Rejetés (${list.where((bc) => bc.status == 3).length})')])),
          Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.local_shipping, size: 16), const SizedBox(width: 4), Text('Livrés (${list.where((bc) => bc.status == 4).length})')])),
        ],
      ),
    );
  }

  Widget _buildBonCommandeList(BonCommandeState state, BonCommandeNotifier notifier) {
    final filtered = state.getFilteredBonCommandes();
    if (filtered.isEmpty) {
      return const Center(child: Text('Aucun bon de commande trouvé'));
    }
    return PaginatedListView(
      scrollController: _scrollController,
      onLoadMore: notifier.loadMore,
      hasNextPage: state.hasNextPage,
      isLoadingMore: state.isLoadingMore,
      padding: const EdgeInsets.all(8),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final bonCommande = filtered[index];
        return _buildBonCommandeCard(ref, bonCommande);
      },
    );
  }

  Widget _buildBonCommandeCard(WidgetRef ref, BonCommande bonCommande) {
    final userRole = ref.read(authProvider).user?.role;
    Color statusColor;
    IconData statusIcon;
    switch (bonCommande.status) {
      case 1:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 2:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 3:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 4:
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
        leading: CircleAvatar(backgroundColor: statusColor.withOpacity(0.1), child: Icon(statusIcon, color: statusColor)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              bonCommande.clientNomEntreprise?.isNotEmpty == true ? bonCommande.clientNomEntreprise! : 'Client #${bonCommande.clientId}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 2),
            Text('Bon de commande #${bonCommande.id ?? 'N/A'}', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Status: ${bonCommande.statusText}', style: TextStyle(color: statusColor, fontWeight: FontWeight.w500)),
            if (bonCommande.fichiers.isNotEmpty) Text('Fichiers: ${bonCommande.fichiers.length}'),
          ],
        ),
        trailing: _buildActionButton(ref, bonCommande, userRole),
        onTap: () => context.go('/bon-commandes/${bonCommande.id}'),
      ),
    );
  }

  Widget _buildActionButton(WidgetRef ref, BonCommande bonCommande, int? userRole) {
    final notifier = ref.read(bonCommandeProvider.notifier);
    if (userRole == Roles.COMMERCIAL) {
      if (bonCommande.status == 0 || bonCommande.status == 1) {
        return PopupMenuButton<String>(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Modifier')),
            const PopupMenuItem(value: 'submit', child: Text('Soumettre')),
            const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
          ],
          onSelected: (value) {
            switch (value) {
              case 'edit':
                context.go('/bon-commandes/${bonCommande.id}/edit');
                break;
              case 'submit':
                _showSubmitConfirmation(ref, bonCommande, notifier);
                break;
              case 'delete':
                _showDeleteConfirmation(ref, bonCommande, notifier);
                break;
            }
          },
        );
      }
      if (bonCommande.status == 2 || bonCommande.status == 3) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit), onPressed: () => context.go('/bon-commandes/${bonCommande.id}/edit'), tooltip: 'Modifier'),
            if (bonCommande.status == 2)
              IconButton(
                icon: const Icon(Icons.local_shipping),
                onPressed: () => _showDeliveryConfirmation(ref, bonCommande, notifier),
                tooltip: 'Marquer comme livré',
              ),
          ],
        );
      }
    }
    if (userRole == Roles.PATRON && (bonCommande.status == 0 || bonCommande.status == 1)) {
      return PopupMenuButton<String>(
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'approve', child: Text('Valider')),
          const PopupMenuItem(value: 'reject', child: Text('Rejeter')),
        ],
        onSelected: (value) {
          switch (value) {
            case 'approve':
              _showApproveConfirmation(ref, bonCommande, notifier);
              break;
            case 'reject':
              _showRejectDialog(ref, bonCommande, notifier);
              break;
          }
        },
      );
    }
    return const SizedBox.shrink();
  }

  void _showFilterDialog(BuildContext context, BonCommandeNotifier notifier) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filtrer par statut'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: const Text('Tous'), onTap: () { Navigator.pop(ctx); notifier.loadBonCommandes(); }),
            ListTile(title: const Text('En attente'), onTap: () { Navigator.pop(ctx); notifier.loadBonCommandes(status: 1); }),
            ListTile(title: const Text('Validés'), onTap: () { Navigator.pop(ctx); notifier.loadBonCommandes(status: 2); }),
            ListTile(title: const Text('Rejetés'), onTap: () { Navigator.pop(ctx); notifier.loadBonCommandes(status: 3); }),
            ListTile(title: const Text('Livrés'), onTap: () { Navigator.pop(ctx); notifier.loadBonCommandes(status: 4); }),
          ],
        ),
      ),
    );
  }

  void _showSubmitConfirmation(WidgetRef ref, BonCommande bonCommande, BonCommandeNotifier notifier) {
    final id = bonCommande.id;
    if (id == null) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Voulez-vous soumettre ce bon de commande pour validation ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              notifier.submitBonCommande(id).then((_) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bon de commande soumis avec succès')));
              }).catchError((e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
              });
            },
            child: const Text('Soumettre'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(WidgetRef ref, BonCommande bonCommande, BonCommandeNotifier notifier) {
    final id = bonCommande.id;
    if (id == null) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Voulez-vous supprimer ce bon de commande ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              notifier.deleteBonCommande(id).then((_) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bon de commande supprimé avec succès')));
              }).catchError((e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
              });
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showApproveConfirmation(WidgetRef ref, BonCommande bonCommande, BonCommandeNotifier notifier) {
    final id = bonCommande.id;
    if (id == null) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Voulez-vous valider ce bon de commande ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await notifier.approveBonCommande(id);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bon de commande approuvé avec succès'), backgroundColor: Colors.green));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(WidgetRef ref, BonCommande bonCommande, BonCommandeNotifier notifier) {
    final id = bonCommande.id;
    if (id == null) return;
    final commentController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeter le bon de commande'),
        content: TextField(
          controller: commentController,
          decoration: const InputDecoration(labelText: 'Motif du rejet', hintText: 'Entrez le motif du rejet'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (commentController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez entrer un motif de rejet'), backgroundColor: Colors.red));
                return;
              }
              Navigator.pop(ctx);
              try {
                await notifier.rejectBonCommande(id, commentController.text.trim());
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bon de commande rejeté avec succès'), backgroundColor: Colors.orange));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }

  void _showDeliveryConfirmation(WidgetRef ref, BonCommande bonCommande, BonCommandeNotifier notifier) {
    final id = bonCommande.id;
    if (id == null) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmation de livraison'),
        content: const Text('Confirmez-vous la livraison de ce bon de commande ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await notifier.markAsDelivered(id);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bon de commande marqué comme livré')));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/bordereau_notifier.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/Models/bordereau_model.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';
import 'package:easyconnect/Views/Components/paginated_list_view.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';
import 'package:easyconnect/Views/Components/app_bar_back_button.dart';

class BordereauListPage extends ConsumerStatefulWidget {
  final int? clientId;

  const BordereauListPage({super.key, this.clientId});

  @override
  ConsumerState<BordereauListPage> createState() => _BordereauListPageState();
}

class _BordereauListPageState extends ConsumerState<BordereauListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;

  int _statusFromIndex(int index) =>
      index == 0 ? 1 : index == 1 ? 2 : 3;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      ref.read(bordereauProvider.notifier).loadBordereaux(status: null, forceRefresh: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(bordereauProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBarBackButton(fallbackRoute: '/bordereaux'),
        title: const Text('Bordereaux'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.loadBordereaux(forceRefresh: true),
            tooltip: 'Actualiser',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'En attente'),
            Tab(text: 'Validés'),
            Tab(text: 'Rejetés'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildBordereauList(ref, 1),
              _buildBordereauList(ref, 2),
              _buildBordereauList(ref, 3),
            ],
          ),
          Positioned(
            bottom: 80,
            right: 16,
            child: UniformAddButton(
              onPressed: () => context.go('/bordereaux/new'),
              label: 'Nouveau Bordereau',
              icon: Icons.assignment,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBordereauList(WidgetRef ref, int status) {
    final bordereauState = ref.watch(bordereauProvider);
    final notifier = ref.read(bordereauProvider.notifier);
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final filterClientId = widget.clientId ?? args?['clientId'] as int?;

    if (bordereauState.isLoading) {
      return const SkeletonSearchResults(itemCount: 6);
    }

    var bordereauList = bordereauState.bordereaux
        .where((b) => b.status == status)
        .toList();
    if (filterClientId != null) {
      bordereauList =
          bordereauList.where((b) => b.clientId == filterClientId).toList();
    }

    if (bordereauList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == 1
                  ? Icons.access_time
                  : status == 2
                  ? Icons.check_circle
                  : Icons.cancel,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              status == 1
                  ? 'Aucun bordereau en attente'
                  : status == 2
                  ? 'Aucun bordereau validé'
                  : 'Aucun bordereau rejeté',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return PaginatedListView(
      scrollController: _scrollController,
      onLoadMore: notifier.loadMore,
      hasNextPage: bordereauState.hasNextPage,
      isLoadingMore: bordereauState.isLoadingMore,
      itemCount: bordereauList.length,
      itemBuilder: (context, index) {
        final bordereau = bordereauList[index];
        return _buildBordereauCard(ref, bordereau);
      },
    );
  }

  Widget _buildBordereauCard(WidgetRef ref, Bordereau bordereau) {
    final formatCurrency = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'fcfa',
    );
    final formatDate = DateFormat('dd/MM/yyyy');
    final userRole = ref.read(authProvider).user?.role;

    Color statusColor;
    IconData statusIcon;

    switch (bordereau.status) {
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              bordereau.clientNomEntreprise?.isNotEmpty == true
                  ? bordereau.clientNomEntreprise!
                  : 'Client #${bordereau.clientId}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              bordereau.reference,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Date: ${formatDate.format(bordereau.dateCreation)}'),
            Text('Montant: ${formatCurrency.format(bordereau.montantTTC)}'),
            Text(
              'Status: ${bordereau.statusText}',
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w500),
            ),
            if (bordereau.status == 3 &&
                (bordereau.commentaireRejet != null &&
                    bordereau.commentaireRejet!.isNotEmpty)) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.report, size: 14, color: Colors.red),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Raison du rejet: ${bordereau.commentaireRejet}',
                      style: const TextStyle(color: Colors.red, fontSize: 13),
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
            if (bordereau.id != null)
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: () => _generatePdf(ref, bordereau.id!),
                tooltip: 'Générer PDF',
              ),
            _buildActionButton(ref, bordereau, userRole),
          ],
        ),
        onTap: () => context.go('/bordereaux/${bordereau.id}'),
      ),
    );
  }

  Future<void> _generatePdf(WidgetRef ref, int id) async {
    try {
      await ref.read(bordereauProvider.notifier).generatePDF(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF généré avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la génération du PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildActionButton(WidgetRef ref, Bordereau bordereau, int? userRole) {
    if (userRole == Roles.COMMERCIAL && bordereau.status == 1) {
      return PopupMenuButton<String>(
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'edit', child: Text('Modifier')),
          const PopupMenuItem(value: 'submit', child: Text('Soumettre')),
          const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
        ],
        onSelected: (value) {
          switch (value) {
            case 'edit':
              context.go('/bordereaux/${bordereau.id}/edit');
              break;
            case 'submit':
              _showSubmitConfirmation(ref, bordereau);
              break;
            case 'delete':
              _showDeleteConfirmation(ref, bordereau);
              break;
          }
        },
      );
    }

    if (userRole == Roles.COMMERCIAL &&
        (bordereau.status == 2 || bordereau.status == 3)) {
      return IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () => context.go('/bordereaux/${bordereau.id}/edit'),
        tooltip: 'Modifier',
      );
    }

    if (userRole == Roles.PATRON && bordereau.status == 1) {
      return PopupMenuButton<String>(
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'approve', child: Text('Valider')),
          const PopupMenuItem(value: 'reject', child: Text('Rejeter')),
        ],
        onSelected: (value) {
          switch (value) {
            case 'approve':
              _showApproveConfirmation(ref, bordereau);
              break;
            case 'reject':
              _showRejectDialog(ref, bordereau);
              break;
          }
        },
      );
    }

    return const SizedBox.shrink();
  }

  void _showSubmitConfirmation(WidgetRef ref, Bordereau bordereau) {
    final id = bordereau.id;
    if (id == null) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text(
          'Voulez-vous soumettre ce bordereau pour validation ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(bordereauProvider.notifier).submitBordereau(id).then((_) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bordereau soumis avec succès')),
                );
              }).catchError((e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Impossible de soumettre: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              });
            },
            child: const Text('Soumettre'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(WidgetRef ref, Bordereau bordereau) {
    final id = bordereau.id;
    if (id == null) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Voulez-vous supprimer ce bordereau ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(bordereauProvider.notifier).deleteBordereau(id).then((_) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bordereau supprimé avec succès')),
                );
              }).catchError((e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Impossible de supprimer: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              });
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showApproveConfirmation(WidgetRef ref, Bordereau bordereau) {
    final id = bordereau.id;
    if (id == null) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Voulez-vous valider ce bordereau ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref.read(bordereauProvider.notifier).approveBordereau(id);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bordereau approuvé avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
                ref.read(bordereauProvider.notifier).loadBordereaux(
                  status: _statusFromIndex(_tabController.index),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(WidgetRef ref, Bordereau bordereau) {
    final id = bordereau.id;
    if (id == null) return;
    final commentController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeter le bordereau'),
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
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (commentController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez entrer un motif de rejet'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.of(ctx).pop();
              try {
                await ref.read(bordereauProvider.notifier).rejectBordereau(
                  id,
                  commentController.text.trim(),
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bordereau rejeté avec succès'),
                    backgroundColor: Colors.orange,
                  ),
                );
                ref.read(bordereauProvider.notifier).loadBordereaux(
                  status: _statusFromIndex(_tabController.index),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }
}

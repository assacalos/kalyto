import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/recruitment_notifier.dart';
import 'package:easyconnect/providers/recruitment_state.dart';
import 'package:easyconnect/Models/recruitment_model.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';

class RecruitmentList extends ConsumerStatefulWidget {
  const RecruitmentList({super.key});

  @override
  ConsumerState<RecruitmentList> createState() => _RecruitmentListState();
}

class _RecruitmentListState extends ConsumerState<RecruitmentList> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(recruitmentProvider.notifier);
      notifier.filterByStatus('all');
      notifier.loadDepartments();
      notifier.loadPositions();
      notifier.loadRecruitmentRequests(forceRefresh: true);
      notifier.loadRecruitmentStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recruitmentProvider);
    final notifier = ref.read(recruitmentProvider.notifier);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Recrutements'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                notifier.filterByStatus('all');
                notifier.loadRecruitmentRequests(forceRefresh: true);
              },
              tooltip: 'Actualiser',
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'En attente'),
              Tab(text: 'Validés'),
              Tab(text: 'Rejetés'),
            ],
          ),
        ),
        body: Stack(
          children: [
            TabBarView(
              children: [
                _buildRecruitmentList('published', state, notifier),
                _buildRecruitmentList('closed', state, notifier),
                _buildRecruitmentList('cancelled', state, notifier),
              ],
            ),
            if (state.canManageRecruitment)
              Positioned(
                bottom: 80,
                right: 16,
                child: UniformAddButton(
                  onPressed: () => context.go('/recruitment/new'),
                  label: 'Nouvelle Demande',
                  icon: Icons.work,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecruitmentList(
    String status,
    RecruitmentState state,
    RecruitmentNotifier notifier,
  ) {
    if (state.isLoading) {
      return const SkeletonSearchResults(itemCount: 6);
    }

    List<RecruitmentRequest> recruitmentList;
    if (status == 'published') {
      recruitmentList = state.recruitmentRequests.where((r) => r.status == 'published').toList();
    } else if (status == 'closed') {
      recruitmentList = state.recruitmentRequests.where((r) => r.status == 'closed').toList();
    } else {
      recruitmentList = state.recruitmentRequests.where((r) => r.status == 'cancelled').toList();
    }

    if (recruitmentList.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          notifier.filterByStatus('all');
          await notifier.loadRecruitmentRequests(forceRefresh: true);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 300,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    status == 'published' ? Icons.pending : status == 'closed' ? Icons.check_circle : Icons.cancel,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    status == 'published'
                        ? 'Aucun recrutement en attente'
                        : status == 'closed'
                            ? 'Aucun recrutement validé'
                            : 'Aucun recrutement rejeté',
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        notifier.filterByStatus('all');
        await notifier.loadRecruitmentRequests(forceRefresh: true);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: recruitmentList.length,
        itemBuilder: (context, index) {
          final request = recruitmentList[index];
          return _buildRecruitmentCard(context, request, notifier, state);
        },
      ),
    );
  }

  Widget _buildRecruitmentCard(
    BuildContext context,
    RecruitmentRequest request,
    RecruitmentNotifier notifier,
    RecruitmentState state,
  ) {
    final formatDate = DateFormat('dd/MM/yyyy');
    Color statusColor;
    IconData statusIcon;
    if (request.status == 'published') {
      statusColor = Colors.orange;
      statusIcon = Icons.pending;
    } else if (request.status == 'closed') {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (request.status == 'cancelled') {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
    } else {
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
        title: Text(request.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${request.position} - ${request.department}'),
            Text('Échéance: ${formatDate.format(request.applicationDeadline)}'),
            Text('Status: ${request.statusText}', style: TextStyle(color: statusColor, fontWeight: FontWeight.w500)),
            if (request.status == 'cancelled' && request.rejectionReason != null && request.rejectionReason!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.report, size: 14, color: Colors.red),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text('Raison du rejet: ${request.rejectionReason}', style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: _buildActionButton(context, request, notifier, state),
        onTap: () => context.go('/recruitment/${request.id}', extra: request),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    RecruitmentRequest request,
    RecruitmentNotifier notifier,
    RecruitmentState state,
  ) {
    if (request.isPublished && state.canApproveRecruitment) {
      return PopupMenuButton<String>(
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'approve', child: Text('Valider')),
          const PopupMenuItem(value: 'reject', child: Text('Rejeter')),
        ],
        onSelected: (value) {
          if (value == 'approve') _showApproveDialog(context, request, notifier);
          if (value == 'reject') _showRejectDialog(context, request, notifier);
        },
      );
    }
    if (request.isDraft && state.canManageRecruitment) {
      return PopupMenuButton<String>(
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'edit', child: Text('Modifier')),
          const PopupMenuItem(value: 'publish', child: Text('Publier')),
          const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
        ],
        onSelected: (value) {
          if (value == 'edit') context.go('/recruitment/${request.id}/edit', extra: request);
          if (value == 'publish') _showPublishDialog(context, request, notifier);
          if (value == 'delete') _showDeleteConfirmation(context, request, notifier);
        },
      );
    }
    return const SizedBox.shrink();
  }

  void _showPublishDialog(BuildContext context, RecruitmentRequest request, RecruitmentNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Voulez-vous publier cette demande de recrutement ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await notifier.publishRecruitmentRequest(request);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Demande publiée avec succès'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Publier'),
          ),
        ],
      ),
    );
  }

  void _showApproveDialog(BuildContext context, RecruitmentRequest request, RecruitmentNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Voulez-vous valider cette demande de recrutement ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await notifier.approveRecruitmentRequest(request);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Demande approuvée avec succès'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, RecruitmentRequest request, RecruitmentNotifier notifier) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeter la demande'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Êtes-vous sûr de vouloir rejeter cette demande ?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: 'Motif du rejet', hintText: 'Entrez le motif du rejet'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Veuillez entrer un motif de rejet'), backgroundColor: Colors.red),
                );
                return;
              }
              Navigator.pop(ctx);
              try {
                await notifier.rejectRecruitmentRequest(request, reasonController.text.trim());
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Demande rejetée'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, RecruitmentRequest request, RecruitmentNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Voulez-vous supprimer cette demande de recrutement ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await notifier.cancelRecruitmentRequest(request);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Demande supprimée'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

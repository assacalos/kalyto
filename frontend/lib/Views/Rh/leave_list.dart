import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/leave_notifier.dart';
import 'package:easyconnect/providers/leave_state.dart';
import 'package:easyconnect/Models/leave_model.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';
import 'package:easyconnect/Views/Components/paginated_list_view.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';

class LeaveList extends ConsumerStatefulWidget {
  const LeaveList({super.key});

  @override
  ConsumerState<LeaveList> createState() => _LeaveListState();
}

class _LeaveListState extends ConsumerState<LeaveList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(leaveProvider.notifier);
      notifier.loadLeaveTypes();
      notifier.loadEmployees();
      notifier.loadLeaveRequests(forceRefresh: true);
      notifier.loadLeaveStats();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(leaveProvider);
    final notifier = ref.read(leaveProvider.notifier);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Congés'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => notifier.loadLeaveRequests(forceRefresh: true),
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
                _buildLeaveList('pending', state, notifier),
                _buildLeaveList('approved', state, notifier),
                _buildLeaveList('rejected', state, notifier),
              ],
            ),
            if (state.canManageLeaves)
              Positioned(
                bottom: 80,
                right: 16,
                child: UniformAddButton(
                  onPressed: () => context.go('/leaves/new'),
                  label: 'Nouvelle Demande',
                  icon: Icons.event,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveList(
    String status,
    LeaveState state,
    LeaveNotifier notifier,
  ) {
    if (state.isLoading) {
      return const SkeletonSearchResults(itemCount: 6);
    }

    final leaveList =
        state.leaveRequests.where((l) => l.status == status).toList();

    if (leaveList.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => notifier.loadLeaveRequests(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 300,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    status == 'pending'
                        ? Icons.pending
                        : status == 'approved'
                            ? Icons.check_circle
                            : Icons.cancel,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    status == 'pending'
                        ? 'Aucun congé en attente'
                        : status == 'approved'
                            ? 'Aucun congé validé'
                            : 'Aucun congé rejeté',
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
      onRefresh: () => notifier.loadLeaveRequests(),
      child: PaginatedListView(
        scrollController: _scrollController,
        onLoadMore: notifier.loadMore,
        hasNextPage: state.hasNextPage,
        isLoadingMore: state.isLoadingMore,
        itemCount: leaveList.length,
        itemBuilder: (context, index) {
          final request = leaveList[index];
          return _buildLeaveCard(context, request, notifier);
        },
      ),
    );
  }

  Widget _buildLeaveCard(
    BuildContext context,
    LeaveRequest request,
    LeaveNotifier notifier,
  ) {
    final formatDate = DateFormat('dd/MM/yyyy');

    Color statusColor;
    IconData statusIcon;

    switch (request.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
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
        title: Text(
          request.employeeName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Type: ${request.leaveTypeText}'),
            Text(
              'Date: ${formatDate.format(request.startDate)} - ${formatDate.format(request.endDate)}',
            ),
            Text(
              'Durée: ${request.totalDays} jour${request.totalDays > 1 ? 's' : ''}',
            ),
            Text(
              'Status: ${request.statusText}',
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w500),
            ),
            if (request.status == 'rejected' &&
                (request.rejectionReason != null &&
                    request.rejectionReason!.isNotEmpty)) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.report, size: 14, color: Colors.red),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Raison du rejet: ${request.rejectionReason}',
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: _buildActionButton(context, request, notifier),
        onTap: () =>
            context.go('/leaves/${request.id}', extra: request),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    LeaveRequest request,
    LeaveNotifier notifier,
  ) {
    if (request.isPending && ref.read(leaveProvider).canApproveLeaves) {
      return PopupMenuButton<String>(
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'approve', child: Text('Valider')),
          const PopupMenuItem(value: 'reject', child: Text('Rejeter')),
        ],
        onSelected: (value) {
          switch (value) {
            case 'approve':
              _showApproveDialog(context, request, notifier);
              break;
            case 'reject':
              _showRejectDialog(context, request, notifier);
              break;
          }
        },
      );
    }

    if (request.isPending && ref.read(leaveProvider).canManageLeaves) {
      return IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () => context.go('/leaves/${request.id}/edit', extra: request),
        tooltip: 'Modifier',
      );
    }

    return const SizedBox.shrink();
  }

  void _showApproveDialog(
    BuildContext context,
    LeaveRequest request,
    LeaveNotifier notifier,
  ) {
    final commentsController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approuver la demande'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Êtes-vous sûr de vouloir approuver cette demande ?'),
            const SizedBox(height: 16),
            TextField(
              controller: commentsController,
              decoration: const InputDecoration(
                labelText: 'Commentaires (optionnel)',
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
                await notifier.approveLeaveRequest(
                  request,
                  comments: commentsController.text.trim().isEmpty
                      ? null
                      : commentsController.text.trim(),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Demande approuvée avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Approuver'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(
    BuildContext context,
    LeaveRequest request,
    LeaveNotifier notifier,
  ) {
    final rejectionReasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeter la demande'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Êtes-vous sûr de vouloir rejeter cette demande ?'),
            const SizedBox(height: 16),
            TextField(
              controller: rejectionReasonController,
              decoration: const InputDecoration(
                labelText: 'Raison du rejet *',
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
              if (rejectionReasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez entrer un motif de rejet'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              try {
                await notifier.rejectLeaveRequest(
                  request,
                  rejectionReasonController.text.trim(),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Demande rejetée'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
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
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }
}

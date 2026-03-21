import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/intervention_notifier.dart';
import 'package:easyconnect/providers/intervention_state.dart';
import 'package:easyconnect/Models/intervention_model.dart';
import 'package:easyconnect/Views/Components/role_based_widget.dart';
import 'package:easyconnect/Views/Components/paginated_list_view.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';
import 'package:easyconnect/Views/Components/app_bar_back_button.dart';

class InterventionList extends ConsumerStatefulWidget {
  final int? clientId;

  const InterventionList({super.key, this.clientId});

  @override
  ConsumerState<InterventionList> createState() => _InterventionListState();
}

class _InterventionListState extends ConsumerState<InterventionList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(interventionProvider.notifier).loadInterventions();
      ref.read(interventionProvider.notifier).loadInterventionStats();
      ref.read(interventionProvider.notifier).loadPendingInterventions();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(interventionProvider);
    final notifier = ref.read(interventionProvider.notifier);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          leading: const AppBarBackButton(fallbackRoute: '/technicien', iconColor: Colors.white),
          title: const Text('Gestion des Interventions'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => notifier.loadInterventions(forceRefresh: true),
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.schedule), text: 'En attente'),
              Tab(icon: Icon(Icons.check_circle), text: 'Validé'),
              Tab(icon: Icon(Icons.cancel), text: 'Rejeté'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildInterventionTab(state, notifier, 'pending'),
            _buildInterventionTab(state, notifier, 'approved'),
            _buildInterventionTab(state, notifier, 'rejected'),
          ],
        ),
        floatingActionButton: RoleBasedWidget(
          allowedRoles: [Roles.ADMIN, Roles.TECHNICIEN, Roles.PATRON],
          child: FloatingActionButton.extended(
            onPressed: () async {
              await context.push('/interventions/new');
              if (context.mounted) {
                notifier.loadInterventions(forceRefresh: true);
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Nouvelle Intervention'),
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            elevation: 8,
            tooltip: 'Créer une nouvelle intervention',
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _buildInterventionTab(
    InterventionState state,
    InterventionNotifier notifier,
    String status,
  ) {
    var interventions = state.interventions.where((intervention) {
      switch (status) {
        case 'pending':
          return intervention.status == 'pending';
        case 'approved':
          return intervention.status == 'approved' ||
              intervention.status == 'in_progress' ||
              intervention.status == 'completed';
        case 'rejected':
          return intervention.status == 'rejected';
        default:
          return true;
      }
    }).toList();

    final filterClientId = widget.clientId;
    if (filterClientId != null) {
      interventions =
          interventions.where((i) => i.clientId == filterClientId).toList();
    }

    if (state.isLoading) {
      return const SkeletonSearchResults(itemCount: 6);
    }

    if (interventions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getEmptyIcon(status), size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _getEmptyMessage(status),
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              _getEmptySubMessage(status),
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return PaginatedListView(
      scrollController: _scrollController,
      onLoadMore: notifier.loadMore,
      hasNextPage: state.hasNextPage,
      isLoadingMore: state.isLoadingMore,
      padding: const EdgeInsets.all(12),
      itemCount: interventions.length,
      itemBuilder: (context, index) {
        final intervention = interventions[index];
        return _buildInterventionCard(context, intervention, state, notifier);
      },
    );
  }

  IconData _getEmptyIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'approved':
        return Icons.check_circle_outline;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.build_outlined;
    }
  }

  String _getEmptyMessage(String status) {
    switch (status) {
      case 'pending':
        return 'Aucune intervention en attente';
      case 'approved':
        return 'Aucune intervention validée';
      case 'rejected':
        return 'Aucune intervention rejetée';
      default:
        return 'Aucune intervention trouvée';
    }
  }

  String _getEmptySubMessage(String status) {
    switch (status) {
      case 'pending':
        return 'Les nouvelles interventions apparaîtront ici';
      case 'approved':
        return 'Les interventions approuvées apparaîtront ici';
      case 'rejected':
        return 'Les interventions rejetées apparaîtront ici';
      default:
        return 'Commencez par ajouter une intervention';
    }
  }

  Widget _buildInterventionCard(
    BuildContext context,
    Intervention intervention,
    InterventionState state,
    InterventionNotifier notifier,
  ) {
    final formatDate = DateFormat('dd/MM/yyyy');

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          await context.push('/interventions/${intervention.id}', extra: intervention);
          if (context.mounted) {
            notifier.loadInterventions(forceRefresh: true);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      intervention.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(intervention),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    intervention.typeIcon,
                    size: 16,
                    color: intervention.typeColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    intervention.typeText,
                    style: TextStyle(
                      color: intervention.typeColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    intervention.priorityIcon,
                    size: 16,
                    color: intervention.priorityColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    intervention.priorityText,
                    style: TextStyle(
                      color: intervention.priorityColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                intervention.description,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              if (intervention.status == 'rejected' &&
                  (intervention.rejectionReason != null &&
                      intervention.rejectionReason!.isNotEmpty)) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.report, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Raison du rejet: ${intervention.rejectionReason}',
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Programmée: ${formatDate.format(intervention.scheduledDate)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  if (intervention.startDate != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.play_arrow, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Début: ${formatDate.format(intervention.startDate!)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ],
              ),
              if (intervention.location != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      intervention.location!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ],
              if (intervention.clientName != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      intervention.clientName!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (intervention.status == 'pending' &&
                      state.canManageInterventions) ...[
                    TextButton.icon(
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Modifier'),
                      onPressed: () => context.push(
                        '/interventions/${intervention.id}/edit',
                        extra: intervention,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (intervention.status == 'approved' &&
                      state.canManageInterventions) ...[
                    TextButton.icon(
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('Démarrer'),
                      onPressed: () =>
                          _showStartDialog(context, intervention, notifier),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (intervention.status == 'in_progress' &&
                      state.canManageInterventions) ...[
                    TextButton.icon(
                      icon: const Icon(Icons.stop, size: 16),
                      label: const Text('Terminer'),
                      onPressed: () => _showCompleteDialog(
                          context, intervention, notifier),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (intervention.status == 'pending' &&
                      state.canApproveInterventions) ...[
                    TextButton.icon(
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approuver'),
                      onPressed: () =>
                          _showApproveDialog(context, intervention, notifier),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Rejeter'),
                      onPressed: () =>
                          _showRejectDialog(context, intervention, notifier),
                    ),
                  ],
                  if (intervention.status == 'approved' ||
                      intervention.status == 'completed') ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.picture_as_pdf, size: 16),
                      label: const Text('PDF'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Génération PDF non disponible pour les interventions',
                            ),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(Intervention intervention) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: intervention.statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: intervention.statusColor.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        intervention.statusText,
        style: TextStyle(
          color: intervention.statusColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showStartDialog(
    BuildContext context,
    Intervention intervention,
    InterventionNotifier notifier,
  ) {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Démarrer l\'intervention'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Êtes-vous sûr de vouloir démarrer cette intervention ?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              notifier.startIntervention(intervention,
                  notes: notesController.text.trim().isEmpty
                      ? null
                      : notesController.text.trim());
              Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Intervention démarrée'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 36),
            ),
            child: const Text('Démarrer'),
          ),
        ],
      ),
    );
  }

  void _showCompleteDialog(
    BuildContext context,
    Intervention intervention,
    InterventionNotifier notifier,
  ) {
    final solutionController = TextEditingController();
    final completionNotesController = TextEditingController();
    final actualDurationController = TextEditingController();
    final costController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terminer l\'intervention'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: solutionController,
                decoration: const InputDecoration(
                  labelText: 'Solution appliquée *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: completionNotesController,
                decoration: const InputDecoration(
                  labelText: 'Notes de fin (optionnel)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: actualDurationController,
                decoration: const InputDecoration(
                  labelText: 'Durée réelle (heures)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: costController,
                decoration: const InputDecoration(
                  labelText: 'Coût (€)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              notifier.completeIntervention(
                intervention,
                solution: solutionController.text.trim(),
                completionNotes: completionNotesController.text.trim().isEmpty
                    ? null
                    : completionNotesController.text.trim(),
                actualDuration:
                    double.tryParse(actualDurationController.text),
                cost: double.tryParse(costController.text),
              );
              Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Intervention terminée'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 36),
            ),
            child: const Text('Terminer'),
          ),
        ],
      ),
    );
  }

  void _showApproveDialog(
    BuildContext context,
    Intervention intervention,
    InterventionNotifier notifier,
  ) {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approuver l\'intervention'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Êtes-vous sûr de vouloir approuver cette intervention ?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await notifier.approveIntervention(intervention,
                    notes: notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim());
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Intervention approuvée'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 36),
            ),
            child: const Text('Approuver'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(
    BuildContext context,
    Intervention intervention,
    InterventionNotifier notifier,
  ) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeter l\'intervention'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Veuillez indiquer la raison du rejet :'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
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
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez indiquer la raison du rejet'),
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              try {
                await notifier.rejectIntervention(
                    intervention, reasonController.text.trim());
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Intervention rejetée'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
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

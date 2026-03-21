import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/task_notifier.dart';
import 'package:easyconnect/providers/task_state.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/Models/task_model.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';
import 'package:easyconnect/Views/Components/task_form_page.dart';

class TaskListPage extends ConsumerStatefulWidget {
  const TaskListPage({super.key});

  @override
  ConsumerState<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends ConsumerState<TaskListPage> {
  bool _initialLoadScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_initialLoadScheduled) return;
      _initialLoadScheduled = true;
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      final notifier = ref.read(taskProvider.notifier);
      final canAssign = notifier.canAssignTasks;
      if (canAssign) {
        notifier.loadUsers();
        notifier.loadTasks(page: 1, forceRefresh: true);
      } else {
        final userId = ref.read(authProvider).user?.id;
        if (userId != null) notifier.setAssignedToFilter(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(taskProvider);
    final notifier = ref.read(taskProvider.notifier);
    final canAssign = notifier.canAssignTasks;
    final currentUserId = ref.watch(authProvider).user?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tâches'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () =>
                _showFilterDialog(context, notifier, canAssign, state),
          ),
        ],
      ),
      body: _buildBody(state, notifier, canAssign, currentUserId),
      floatingActionButton: canAssign
          ? UniformAddButton(
              onPressed: () {
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (_) => const TaskFormPage(),
                      ),
                    )
                    .then((_) => notifier.loadTasks(page: 1));
              },
              label: 'Assigner une tâche',
              icon: Icons.add_task,
            )
          : null,
    );
  }

  Widget _buildBody(
    TaskState state,
    TaskNotifier notifier,
    bool canAssign,
    int? currentUserId,
  ) {
    if (state.isLoading && state.tasks.isEmpty && !state.loadError) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.loadError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.orange.shade700,
              ),
              const SizedBox(height: 16),
              Text(
                'Impossible de charger les tâches',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  notifier.loadTasks(page: 1);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (state.tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              canAssign ? 'Aucune tâche' : 'Aucune tâche assignée',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            if (canAssign) ...[
              const SizedBox(height: 8),
              Text(
                'Assignez une tâche à un utilisateur',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => notifier.loadTasks(page: 1),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.tasks.length,
        itemBuilder: (context, index) {
          final task = state.tasks[index];
          return _buildTaskCard(
            context,
            task,
            notifier,
            canAssign,
            currentUserId,
          );
        },
      ),
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    TaskModel task,
    TaskNotifier notifier,
    bool canAssign,
    int? currentUserId,
  ) {
    final statusColor = _statusColor(task.status);
    final priorityColor = _priorityColor(task.priority);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.go('/tasks/${task.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.titre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      task.statusLibelle,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (task.description != null &&
                  task.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  task.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    task.assigneeName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      task.priorityLibelle,
                      style: TextStyle(fontSize: 11, color: priorityColor),
                    ),
                  ),
                  if (task.dueDate != null) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      task.dueDate!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
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

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _showFilterDialog(
    BuildContext context,
    TaskNotifier notifier,
    bool canAssign,
    TaskState state,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtrer par statut',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _filterChip(ctx, 'Tous', null,
                    state.selectedStatus == null, () {
                  notifier.setStatusFilter(null);
                  Navigator.pop(ctx);
                }),
                _filterChip(ctx, 'En attente', 'pending',
                    state.selectedStatus == 'pending', () {
                  notifier.setStatusFilter('pending');
                  Navigator.pop(ctx);
                }),
                _filterChip(ctx, 'En cours', 'in_progress',
                    state.selectedStatus == 'in_progress', () {
                  notifier.setStatusFilter('in_progress');
                  Navigator.pop(ctx);
                }),
                _filterChip(ctx, 'Terminée', 'completed',
                    state.selectedStatus == 'completed', () {
                  notifier.setStatusFilter('completed');
                  Navigator.pop(ctx);
                }),
              ],
            ),
            if (canAssign && state.users.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'Filtrer par utilisateur',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                value: state.selectedAssignedTo,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Tous')),
                  ...state.users.map((u) {
                    final name =
                        '${u.prenom ?? ''} ${u.nom ?? ''}'.trim();
                    final label =
                        name.isEmpty ? (u.email ?? '') : name;
                    return DropdownMenuItem(
                      value: u.id,
                      child: Text(label),
                    );
                  }),
                ],
                onChanged: (v) {
                  notifier.setAssignedToFilter(v);
                  Navigator.pop(ctx);
                },
              ),
            ],
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                notifier.clearFilters();
                Navigator.pop(ctx);
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Réinitialiser les filtres'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(
    BuildContext context,
    String label,
    String? value,
    bool selected,
    VoidCallback onTap,
  ) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:easyconnect/Views/Components/app_bar_back_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/providers/task_notifier.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/utils/roles.dart';

class TaskDetailPage extends ConsumerStatefulWidget {
  final int taskId;

  const TaskDetailPage({super.key, required this.taskId});

  @override
  ConsumerState<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends ConsumerState<TaskDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(taskProvider.notifier).loadTask(widget.taskId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(taskProvider);
    final notifier = ref.read(taskProvider.notifier);
    final userId = ref.watch(authProvider).user?.id;
    final role = ref.watch(authProvider).user?.role;
    final canAssign = role == Roles.ADMIN || role == Roles.PATRON;
    final task = state.currentTask;
    final isAssignee = task?.assignedTo == userId;
    final canChangeStatus = isAssignee || canAssign;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBarBackButton(fallbackRoute: '/tasks', iconColor: Colors.white),
        title: const Text('Détail de la tâche'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (canAssign)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Supprimer la tâche ?'),
                    content: const Text('Cette action est irréversible.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Annuler'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text(
                          'Supprimer',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  try {
                    final ok =
                        await notifier.deleteTask(widget.taskId);
                    if (ok && context.mounted) Navigator.pop(context);
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
                }
              },
            ),
        ],
      ),
      body: task == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.titre,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _statusChip(
                        task.statusLibelle,
                        _statusColor(task.status),
                      ),
                      const SizedBox(width: 8),
                      _statusChip(
                        task.priorityLibelle,
                        _priorityColor(task.priority),
                      ),
                    ],
                  ),
                  if (task.description != null &&
                      task.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Description',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.description!,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _infoRow(Icons.person_outline, 'Assigné à', task.assigneeName),
                  if (task.assignerName.isNotEmpty)
                    _infoRow(
                      Icons.person,
                      'Assigné par',
                      task.assignerName,
                    ),
                  if (task.dueDate != null)
                    _infoRow(
                      Icons.calendar_today,
                      'Date limite',
                      task.dueDate!,
                    ),
                  _infoRow(Icons.access_time, 'Créée le', task.createdAt),
                  if (task.completedAt != null)
                    _infoRow(
                      Icons.check_circle,
                      'Terminée le',
                      task.completedAt!,
                    ),
                  if (canChangeStatus &&
                      !task.isCompleted &&
                      !task.isCancelled) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    Text(
                      canAssign && !isAssignee
                          ? 'Valider la tâche'
                          : 'Changer le statut',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (task.status == 'pending')
                          ElevatedButton.icon(
                            onPressed: () async {
                              try {
                              await notifier.updateTaskStatus(
                                task.id,
                                'in_progress',
                              );
                              await notifier.loadTask(task.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text('Statut mis à jour'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text('Erreur: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.play_arrow, size: 18),
                            label: const Text('En cours'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        if (task.status == 'pending' ||
                            task.status == 'in_progress') ...[
                          if (task.status == 'in_progress')
                            const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              try {
                              await notifier.updateTaskStatus(
                                task.id,
                                'completed',
                              );
                              await notifier.loadTask(task.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text('Tâche terminée'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text('Erreur: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Terminer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey.shade800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
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
}

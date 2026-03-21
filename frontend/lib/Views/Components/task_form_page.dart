import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/task_notifier.dart';
import 'package:easyconnect/Models/user_model.dart';

class TaskFormPage extends ConsumerStatefulWidget {
  const TaskFormPage({super.key});

  @override
  ConsumerState<TaskFormPage> createState() => _TaskFormPageState();
}

class _TaskFormPageState extends ConsumerState<TaskFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  int? _selectedUserId;
  String _priority = 'medium';
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(taskProvider.notifier).loadUsers();
    });
  }

  void _clearForm() {
    _titreController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedUserId = null;
      _priority = 'medium';
      _dueDate = null;
    });
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(taskProvider);
    final notifier = ref.read(taskProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assigner une tâche'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titreController,
                decoration: const InputDecoration(
                  labelText: 'Titre de la tâche *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optionnel)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedUserId,
                decoration: const InputDecoration(
                  labelText: 'Assigner à *',
                  border: OutlineInputBorder(),
                ),
                items: state.users
                    .map(
                      (u) => DropdownMenuItem(
                        value: u.id,
                        child: Text(_userLabel(u)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedUserId = v),
                validator: (v) =>
                    v == null ? 'Choisissez un utilisateur' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _priority,
                decoration: const InputDecoration(
                  labelText: 'Priorité',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Basse')),
                  DropdownMenuItem(value: 'medium', child: Text('Moyenne')),
                  DropdownMenuItem(value: 'high', child: Text('Haute')),
                  DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                ],
                onChanged: (v) => setState(() => _priority = v ?? 'medium'),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dueDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate:
                        DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) setState(() => _dueDate = date);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date limite (optionnel)',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _dueDate != null
                        ? '${_dueDate!.day.toString().padLeft(2, '0')}/${_dueDate!.month.toString().padLeft(2, '0')}/${_dueDate!.year}'
                        : 'Choisir une date',
                    style: TextStyle(
                      color: _dueDate != null ? null : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: state.isLoading
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        if (_selectedUserId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Choisissez un utilisateur'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        final dueDateStr = _dueDate != null
                            ? '${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}'
                            : null;
                        try {
                          await notifier.createTask(
                            titre: _titreController.text.trim(),
                            description: _descriptionController
                                    .text
                                    .trim()
                                    .isEmpty
                                ? null
                                : _descriptionController.text.trim(),
                            assignedTo: _selectedUserId!,
                            priority: _priority,
                            dueDate: dueDateStr,
                          );
                          _clearForm();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Tâche assignée avec succès'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            context.go('/tasks');
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
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: state.isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Assigner la tâche'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _userLabel(UserModel u) {
    final name = '${u.prenom ?? ''} ${u.nom ?? ''}'.trim();
    final email = u.email ?? '';
    return name.isEmpty ? email : '$name ($email)';
  }
}

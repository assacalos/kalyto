import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/Models/leave_model.dart';
import 'package:easyconnect/providers/leave_notifier.dart';
import 'package:easyconnect/providers/leave_state.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/providers/services_providers.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';

class LeaveForm extends ConsumerStatefulWidget {
  final LeaveRequest? request;

  const LeaveForm({super.key, this.request});

  @override
  ConsumerState<LeaveForm> createState() => _LeaveFormState();
}

class _LeaveFormState extends ConsumerState<LeaveForm> {
  final _reasonController = TextEditingController();
  final _commentsController = TextEditingController();

  String _selectedEmployeeId = '';
  String _selectedLeaveType = '';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(leaveProvider.notifier).loadLeaveTypes();
      ref.read(leaveProvider.notifier).loadEmployees();
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  bool get _canViewAllLeaves {
    final role = ref.read(authProvider).user?.role;
    return role == Roles.PATRON || role == Roles.RH || role == Roles.ADMIN;
  }

  int get _totalDays {
    if (_startDate != null && _endDate != null) {
      return _endDate!.difference(_startDate!).inDays + 1;
    }
    return 0;
  }

  Future<bool> _checkConflicts() async {
    if (_selectedEmployeeId.isEmpty || _startDate == null || _endDate == null) {
      return false;
    }
    try {
      final result = await ref.read(leaveServiceProvider).checkLeaveConflicts(
            employeeId: int.parse(_selectedEmployeeId),
            startDate: _startDate!,
            endDate: _endDate!,
          );
      return result['has_conflicts'] == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final leaveState = ref.watch(leaveProvider);
    if (!_canViewAllLeaves && _selectedEmployeeId.isEmpty) {
      final user = ref.read(authProvider).user;
      final userId = user?.id.toString();
      if (userId != null && userId.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _selectedEmployeeId.isEmpty) {
            setState(() => _selectedEmployeeId = userId);
          }
        });
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.request == null
              ? 'Nouvelle Demande de Congé'
              : 'Modifier la Demande',
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _saveLeaveRequest(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Informations de base'),
              const SizedBox(height: 16),

              if (_canViewAllLeaves) ...[
                _buildEmployeeDropdown(leaveState),
                const SizedBox(height: 16),
              ],

              _buildLeaveTypeDropdown(leaveState),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(child: _buildDatePicker('Date de début *', _startDate, (d) => setState(() => _startDate = d))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDatePicker('Date de fin *', _endDate, (d) => setState(() => _endDate = d))),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Nombre de jours: $_totalDays',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Raison du congé *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.help_outline),
                  hintText: 'Expliquez la raison de votre demande de congé',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La raison est obligatoire';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _commentsController,
                decoration: const InputDecoration(
                  labelText: 'Commentaires',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.comment),
                  hintText: 'Commentaires supplémentaires (optionnel)',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              _buildConflictCheck(),
              const SizedBox(height: 24),
              _buildLeaveBalanceInfo(),
              const SizedBox(height: 32),

              UniformFormButtons(
                onCancel: () => context.pop(),
                onSubmit: () => _saveLeaveRequest(context),
                submitText: 'Soumettre',
                isLoading: _isSubmitting,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.deepPurple,
      ),
    );
  }

  Widget _buildEmployeeDropdown(LeaveState leaveState) {
    final options = leaveState.employees
        .where((e) => e['id'] != null)
        .map((e) => {'value': e['id'].toString(), 'label': e['name'] ?? ''})
        .toList();
    if (options.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chargement des employés...',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const LinearProgressIndicator(),
        ],
      );
    }
    return DropdownButtonFormField<String>(
      value: _selectedEmployeeId.isEmpty ? null : _selectedEmployeeId,
      decoration: const InputDecoration(
        labelText: 'Employé *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.person),
      ),
      items: options.map<DropdownMenuItem<String>>((emp) {
        return DropdownMenuItem<String>(
          value: emp['value']!,
          child: Text(emp['label']!),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedEmployeeId = value ?? ''),
      validator: (value) {
        if (_canViewAllLeaves && (value == null || value.isEmpty)) {
          return 'Veuillez sélectionner un employé';
        }
        return null;
      },
    );
  }

  Widget _buildLeaveTypeDropdown(LeaveState leaveState) {
    final types = leaveState.leaveTypes;
    if (types.isEmpty) {
      return const LinearProgressIndicator();
    }
    return DropdownButtonFormField<String>(
      value: _selectedLeaveType.isEmpty ? null : _selectedLeaveType,
      decoration: const InputDecoration(
        labelText: 'Type de congé *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.event),
      ),
      items: types.map<DropdownMenuItem<String>>((type) {
        return DropdownMenuItem<String>(
          value: type.value,
          child: Text(type.label),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedLeaveType = value ?? ''),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez sélectionner un type de congé';
        }
        return null;
      },
    );
  }

  Widget _buildDatePicker(String label, DateTime? value, ValueChanged<DateTime?> onPick) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          value != null ? DateFormat('dd/MM/yyyy').format(value) : 'Sélectionner une date',
          style: TextStyle(
            color: value != null ? Colors.black : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildConflictCheck() {
    if (_selectedEmployeeId.isEmpty || _startDate == null || _endDate == null) {
      return const SizedBox.shrink();
    }
    return FutureBuilder<bool>(
      future: _checkConflicts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  'Vérification des conflits...',
                  style: TextStyle(color: Colors.orange[700]),
                ),
              ],
            ),
          );
        }
        if (snapshot.hasData && snapshot.data == true) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Attention: Des conflits de congés ont été détectés pour cette période.',
                    style: TextStyle(color: Colors.red[700], fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        }
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Aucun conflit détecté pour cette période.',
                style: TextStyle(color: Colors.green[700], fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeaveBalanceInfo() {
    if (_selectedEmployeeId.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<LeaveBalance>(
      future: ref.read(leaveServiceProvider).getEmployeeLeaveBalance(int.parse(_selectedEmployeeId)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: SkeletonFormField(hasLabel: false, height: 40),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final balance = snapshot.data!;
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Solde de congés',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildBalanceItem(
                        'Congés payés',
                        '${balance.remainingAnnualLeave}/${balance.annualLeaveDays}',
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildBalanceItem(
                        'Congés maladie',
                        '${balance.remainingSickLeave}/${balance.sickLeaveDays}',
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildBalanceItem(
                  'Congés personnels',
                  '${balance.remainingPersonalLeave}/${balance.personalLeaveDays}',
                  Colors.green,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBalanceItem(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveLeaveRequest(BuildContext context) async {
    final userId = ref.read(authProvider).user?.id;
    final employeeId = _canViewAllLeaves ? _selectedEmployeeId : (userId?.toString() ?? '');
    if (employeeId.isEmpty ||
        _selectedLeaveType.isEmpty ||
        _startDate == null ||
        _endDate == null ||
        _reasonController.text.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez remplir tous les champs obligatoires'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (widget.request != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mise à jour à implémenter')),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final success = await ref.read(leaveProvider.notifier).createLeaveRequest(
            employeeId: int.parse(employeeId),
            leaveType: _selectedLeaveType,
            startDate: _startDate!,
            endDate: _endDate!,
            reason: _reasonController.text.trim(),
            comments: _commentsController.text.trim().isEmpty
                ? null
                : _commentsController.text.trim(),
          );
      if (!context.mounted) return;
      if (success) {
        await Future.delayed(const Duration(milliseconds: 500));
        context.go('/leaves');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la création de la demande'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

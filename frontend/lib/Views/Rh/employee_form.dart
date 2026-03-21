import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/Models/employee_model.dart';
import 'package:easyconnect/providers/employee_notifier.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';

/// Constantes pour les listes déroulantes (ex-EmployeeController).
class _FormOptions {
  static const genders = [
    {'value': 'male', 'label': 'Homme'},
    {'value': 'female', 'label': 'Femme'},
    {'value': 'other', 'label': 'Autre'},
  ];
  static const maritalStatuses = [
    {'value': 'single', 'label': 'Célibataire'},
    {'value': 'married', 'label': 'Marié(e)'},
    {'value': 'divorced', 'label': 'Divorcé(e)'},
    {'value': 'widowed', 'label': 'Veuf/Veuve'},
  ];
  static const contractTypes = [
    {'value': 'permanent', 'label': 'CDI'},
    {'value': 'temporary', 'label': 'CDD'},
    {'value': 'internship', 'label': 'Stage'},
    {'value': 'consultant', 'label': 'Consultant'},
  ];
  static const currencies = [
    {'value': 'fcfa', 'label': 'FCFA'},
    {'value': 'eur', 'label': 'EUR'},
    {'value': 'usd', 'label': 'USD'},
  ];
  static const workSchedules = [
    {'value': 'full_time', 'label': 'Temps plein'},
    {'value': 'part_time', 'label': 'Temps partiel'},
    {'value': 'flexible', 'label': 'Flexible'},
    {'value': 'shift', 'label': 'Par équipes'},
  ];
  static const employeeStatuses = [
    {'value': 'active', 'label': 'Actif'},
    {'value': 'inactive', 'label': 'Inactif'},
    {'value': 'on_leave', 'label': 'En congé'},
    {'value': 'terminated', 'label': 'Terminé'},
  ];
}

class EmployeeForm extends ConsumerStatefulWidget {
  final Employee? employee;

  const EmployeeForm({super.key, this.employee});

  @override
  ConsumerState<EmployeeForm> createState() => _EmployeeFormState();
}

class _EmployeeFormState extends ConsumerState<EmployeeForm> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _socialSecurityController = TextEditingController();
  final _positionController = TextEditingController();
  final _managerController = TextEditingController();
  final _salaryController = TextEditingController();
  final _notesController = TextEditingController();

  Employee? _selectedEmployeeForForm;
  DateTime? _selectedBirthDate;
  DateTime? _selectedHireDate;
  DateTime? _selectedContractStartDate;
  DateTime? _selectedContractEndDate;
  String _selectedGender = '';
  String _selectedMaritalStatus = '';
  String _selectedDepartment = '';
  String _selectedContractType = '';
  String _selectedCurrency = 'fcfa';
  String _selectedWorkSchedule = '';
  String _selectedStatus = 'active';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(employeeProvider.notifier);
      final state = ref.read(employeeProvider);
      if (state.departments.isEmpty) notifier.loadDepartments();
      if (widget.employee == null && state.employees.isEmpty) {
        notifier.loadEmployees(loadAll: true);
      }
      if (widget.employee != null) {
        _fillForm(widget.employee!);
        _selectedEmployeeForForm = widget.employee;
      } else {
        _clearForm();
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _idNumberController.dispose();
    _socialSecurityController.dispose();
    _positionController.dispose();
    _managerController.dispose();
    _salaryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _fillForm(Employee employee) {
    _firstNameController.text = employee.firstName;
    _lastNameController.text = employee.lastName;
    _emailController.text = employee.email;
    _phoneController.text = employee.phone ?? '';
    _addressController.text = employee.address ?? '';
    _idNumberController.text = employee.idNumber ?? '';
    _socialSecurityController.text = employee.socialSecurityNumber ?? '';
    _positionController.text = employee.position ?? '';
    _managerController.text = employee.manager ?? '';
    _salaryController.text = employee.salary?.toString() ?? '';
    _notesController.text = employee.notes ?? '';
    setState(() {
      _selectedBirthDate = employee.birthDate;
      _selectedHireDate = employee.hireDate;
      _selectedContractStartDate = employee.contractStartDate;
      _selectedContractEndDate = employee.contractEndDate;
      _selectedGender = employee.gender ?? '';
      _selectedMaritalStatus = employee.maritalStatus ?? '';
      _selectedDepartment = employee.department ?? '';
      _selectedContractType = employee.contractType ?? '';
      _selectedCurrency = employee.currency ?? 'fcfa';
      _selectedWorkSchedule = employee.workSchedule ?? '';
      _selectedStatus = employee.status ?? 'active';
    });
  }

  void _clearForm() {
    _firstNameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _addressController.clear();
    _idNumberController.clear();
    _socialSecurityController.clear();
    _positionController.clear();
    _managerController.clear();
    _salaryController.clear();
    _notesController.clear();
    setState(() {
      _selectedEmployeeForForm = null;
      _selectedBirthDate = null;
      _selectedHireDate = null;
      _selectedContractStartDate = null;
      _selectedContractEndDate = null;
      _selectedGender = '';
      _selectedMaritalStatus = '';
      _selectedDepartment = '';
      _selectedContractType = '';
      _selectedCurrency = 'fcfa';
      _selectedWorkSchedule = '';
      _selectedStatus = 'active';
    });
  }

  Future<void> _pickDate(DateTime? current, ValueChanged<DateTime?> onPick) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => onPick(picked));
  }

  static bool _isValidEmail(String value) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value);
  }

  @override
  Widget build(BuildContext context) {
    final employeeState = ref.watch(employeeProvider);
    final departments = employeeState.departments;
    final employees = employeeState.employees;
    final validDept = _selectedDepartment.isEmpty || (_selectedDepartment != 'all' && departments.contains(_selectedDepartment))
        ? _selectedDepartment
        : null;
    final validStatus = _FormOptions.employeeStatuses.any((s) => s['value'] == _selectedStatus) ? _selectedStatus : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.employee == null ? 'Nouvel Employé' : 'Modifier l\'Employé',
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _saveEmployee(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.employee == null) ...[
                DropdownButtonFormField<Employee?>(
                  value: _selectedEmployeeForForm,
                  decoration: const InputDecoration(
                    labelText: 'Sélectionner un employé existant (optionnel)',
                    hintText: 'Choisir un employé pour pré-remplir le formulaire',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                    helperText: 'Sélectionnez un employé pour remplir automatiquement les champs',
                  ),
                  items: [
                    const DropdownMenuItem<Employee?>(value: null, child: Text('Aucun (nouvel employé)')),
                    ...employees.map<DropdownMenuItem<Employee?>>((emp) {
                      return DropdownMenuItem<Employee?>(
                        value: emp,
                        child: Text('${emp.firstName} ${emp.lastName} - ${emp.email}'),
                      );
                    }),
                  ],
                  onChanged: (Employee? selectedEmp) {
                    setState(() {
                      _selectedEmployeeForForm = selectedEmp;
                      if (selectedEmp != null) _fillForm(selectedEmp);
                      else _clearForm();
                    });
                  },
                ),
                const SizedBox(height: 24),
              ],

              _buildSectionTitle('Informations personnelles'),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'Prénom *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Le prénom est obligatoire';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Le nom est obligatoire';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'L\'email est obligatoire';
                  if (!_isValidEmail(value)) return 'Format d\'email invalide';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Téléphone',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedGender.isEmpty ? null : _selectedGender,
                      decoration: const InputDecoration(
                        labelText: 'Genre',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: _FormOptions.genders.map<DropdownMenuItem<String>>((g) {
                        return DropdownMenuItem<String>(
                          value: g['value'] as String,
                          child: Text(g['label'] as String),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedGender = value ?? ''),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Adresse',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(_selectedBirthDate, (d) => _selectedBirthDate = d),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date de naissance',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.cake),
                        ),
                        child: Text(
                          _selectedBirthDate != null
                              ? DateFormat('dd/MM/yyyy').format(_selectedBirthDate!)
                              : 'Sélectionner une date',
                          style: TextStyle(
                            color: _selectedBirthDate != null ? Colors.black : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedMaritalStatus.isEmpty ? null : _selectedMaritalStatus,
                      decoration: const InputDecoration(
                        labelText: 'Statut matrimonial',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.favorite),
                      ),
                      items: _FormOptions.maritalStatuses.map<DropdownMenuItem<String>>((s) {
                        return DropdownMenuItem<String>(
                          value: s['value'] as String,
                          child: Text(s['label'] as String),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedMaritalStatus = value ?? ''),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Informations professionnelles'),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _positionController,
                      decoration: const InputDecoration(
                        labelText: 'Poste',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.work),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: validDept,
                      decoration: const InputDecoration(
                        labelText: 'Département',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                      ),
                      items: [
                        const DropdownMenuItem(value: '', child: Text('Sélectionner')),
                        ...departments.map<DropdownMenuItem<String>>((dept) {
                          return DropdownMenuItem<String>(value: dept, child: Text(dept));
                        }),
                      ],
                      onChanged: (value) => setState(() => _selectedDepartment = value ?? ''),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _managerController,
                decoration: const InputDecoration(
                  labelText: 'Manager',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.supervisor_account),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(_selectedHireDate, (d) => _selectedHireDate = d),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date d\'embauche',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.event),
                        ),
                        child: Text(
                          _selectedHireDate != null
                              ? DateFormat('dd/MM/yyyy').format(_selectedHireDate!)
                              : 'Sélectionner une date',
                          style: TextStyle(
                            color: _selectedHireDate != null ? Colors.black : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedContractType.isEmpty ? null : _selectedContractType,
                      decoration: const InputDecoration(
                        labelText: 'Type de contrat',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      items: _FormOptions.contractTypes.map<DropdownMenuItem<String>>((t) {
                        return DropdownMenuItem<String>(
                          value: t['value'] as String,
                          child: Text(t['label'] as String),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedContractType = value ?? ''),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(_selectedContractStartDate, (d) => _selectedContractStartDate = d),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Début du contrat',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.play_arrow),
                        ),
                        child: Text(
                          _selectedContractStartDate != null
                              ? DateFormat('dd/MM/yyyy').format(_selectedContractStartDate!)
                              : 'Sélectionner une date',
                          style: TextStyle(
                            color: _selectedContractStartDate != null ? Colors.black : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(_selectedContractEndDate, (d) => _selectedContractEndDate = d),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fin du contrat',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.stop),
                        ),
                        child: Text(
                          _selectedContractEndDate != null
                              ? DateFormat('dd/MM/yyyy').format(_selectedContractEndDate!)
                              : 'Sélectionner une date',
                          style: TextStyle(
                            color: _selectedContractEndDate != null ? Colors.black : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Informations financières'),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _salaryController,
                      decoration: const InputDecoration(
                        labelText: 'Salaire',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.euro),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCurrency,
                      decoration: const InputDecoration(
                        labelText: 'Devise',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      items: _FormOptions.currencies.map<DropdownMenuItem<String>>((c) {
                        return DropdownMenuItem<String>(
                          value: c['value'] as String,
                          child: Text(c['label'] as String),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedCurrency = value ?? 'fcfa'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedWorkSchedule.isEmpty ? null : _selectedWorkSchedule,
                      decoration: const InputDecoration(
                        labelText: 'Horaires de travail',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.schedule),
                      ),
                      items: _FormOptions.workSchedules.map<DropdownMenuItem<String>>((s) {
                        return DropdownMenuItem<String>(
                          value: s['value'] as String,
                          child: Text(s['label'] as String),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedWorkSchedule = value ?? ''),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: validStatus,
                      decoration: const InputDecoration(
                        labelText: 'Statut',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.info),
                      ),
                      items: _FormOptions.employeeStatuses.map<DropdownMenuItem<String>>((s) {
                        return DropdownMenuItem<String>(
                          value: s['value'] as String,
                          child: Text(s['label'] as String),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _selectedStatus = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Informations supplémentaires'),
              const SizedBox(height: 16),

              TextFormField(
                controller: _idNumberController,
                decoration: const InputDecoration(
                  labelText: 'Numéro d\'identité',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.credit_card),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _socialSecurityController,
                decoration: const InputDecoration(
                  labelText: 'Numéro de sécurité sociale',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.security),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                  hintText: 'Notes internes (optionnel)',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              UniformFormButtons(
                onCancel: () => context.pop(),
                onSubmit: () => _saveEmployee(context),
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

  void _saveEmployee(BuildContext context) async {
    setState(() => _isSubmitting = true);
    final notifier = ref.read(employeeProvider.notifier);
    bool success = false;
    try {
      if (widget.employee == null) {
        success = await notifier.createEmployee(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          birthDate: _selectedBirthDate,
          gender: _selectedGender.isEmpty ? null : _selectedGender,
          maritalStatus: _selectedMaritalStatus.isEmpty ? null : _selectedMaritalStatus,
          idNumber: _idNumberController.text.trim().isEmpty ? null : _idNumberController.text.trim(),
          socialSecurityNumber: _socialSecurityController.text.trim().isEmpty ? null : _socialSecurityController.text.trim(),
          position: _positionController.text.trim().isEmpty ? null : _positionController.text.trim(),
          department: _selectedDepartment.isEmpty ? null : _selectedDepartment,
          manager: _managerController.text.trim().isEmpty ? null : _managerController.text.trim(),
          hireDate: _selectedHireDate,
          contractStartDate: _selectedContractStartDate,
          contractEndDate: _selectedContractEndDate,
          contractType: _selectedContractType.isEmpty ? null : _selectedContractType,
          salary: double.tryParse(_salaryController.text.trim()),
          currency: _selectedCurrency,
          workSchedule: _selectedWorkSchedule.isEmpty ? null : _selectedWorkSchedule,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
      } else {
        success = await notifier.updateEmployee(
          widget.employee!,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          birthDate: _selectedBirthDate,
          gender: _selectedGender.isEmpty ? null : _selectedGender,
          maritalStatus: _selectedMaritalStatus.isEmpty ? null : _selectedMaritalStatus,
          idNumber: _idNumberController.text.trim().isEmpty ? null : _idNumberController.text.trim(),
          socialSecurityNumber: _socialSecurityController.text.trim().isEmpty ? null : _socialSecurityController.text.trim(),
          position: _positionController.text.trim().isEmpty ? null : _positionController.text.trim(),
          department: _selectedDepartment.isEmpty ? null : _selectedDepartment,
          manager: _managerController.text.trim().isEmpty ? null : _managerController.text.trim(),
          hireDate: _selectedHireDate,
          contractStartDate: _selectedContractStartDate,
          contractEndDate: _selectedContractEndDate,
          contractType: _selectedContractType.isEmpty ? null : _selectedContractType,
          salary: double.tryParse(_salaryController.text.trim()),
          currency: _selectedCurrency,
          workSchedule: _selectedWorkSchedule.isEmpty ? null : _selectedWorkSchedule,
          status: _selectedStatus,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
    if (!context.mounted) return;
    if (success) {
      await Future.delayed(const Duration(milliseconds: 500));
      context.go('/employees');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de l\'enregistrement'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

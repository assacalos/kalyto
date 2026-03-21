import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/Models/contract_model.dart';
import 'package:easyconnect/Models/employee_model.dart';
import 'package:easyconnect/providers/contract_notifier.dart';
import 'package:easyconnect/providers/employee_notifier.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:easyconnect/services/camera_service.dart';

class ContractForm extends ConsumerStatefulWidget {
  final Contract? contract;

  const ContractForm({super.key, this.contract});

  @override
  ConsumerState<ContractForm> createState() => _ContractFormState();
}

class _ContractFormState extends ConsumerState<ContractForm> {
  final _formKey = GlobalKey<FormState>();
  final _contractNumberController = TextEditingController();
  final _departmentController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _jobDescriptionController = TextEditingController();
  final _workLocationController = TextEditingController();
  final _workScheduleController = TextEditingController();
  final _reportingManagerController = TextEditingController();
  final _grossSalaryController = TextEditingController();
  final _netSalaryController = TextEditingController();
  final _weeklyHoursController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _employeeNameController = TextEditingController();
  final _employeeEmailController = TextEditingController();
  final _employeePhoneController = TextEditingController();
  final _healthInsuranceController = TextEditingController();
  final _retirementPlanController = TextEditingController();
  final _vacationDaysController = TextEditingController();
  final _otherBenefitsController = TextEditingController();
  final _notesController = TextEditingController();

  int _selectedEmployeeId = 0;
  String _selectedContractType = '';
  String _selectedDepartment = '';
  String _selectedPaymentFrequency = 'monthly';
  String _selectedProbationPeriod = 'none';
  final List<Map<String, dynamic>> _selectedAttachments = [];

  static const _contractTypeOptions = [
    {'value': 'permanent', 'label': 'CDI'},
    {'value': 'fixed_term', 'label': 'CDD'},
    {'value': 'temporary', 'label': 'Intérim'},
    {'value': 'internship', 'label': 'Stage'},
    {'value': 'consultant', 'label': 'Consultant'},
  ];
  static const _paymentFrequencyOptions = [
    {'value': 'monthly', 'label': 'Mensuel'},
    {'value': 'weekly', 'label': 'Hebdomadaire'},
    {'value': 'daily', 'label': 'Journalier'},
    {'value': 'hourly', 'label': 'Horaire'},
  ];
  static const _probationPeriodOptions = [
    {'value': 'none', 'label': 'Aucune'},
    {'value': '1_month', 'label': '1 mois'},
    {'value': '3_months', 'label': '3 mois'},
    {'value': '6_months', 'label': '6 mois'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final empState = ref.read(employeeProvider);
      final notifier = ref.read(employeeProvider.notifier);
      if (empState.departments.isEmpty) notifier.loadDepartments();
      if (empState.employees.isEmpty) notifier.loadEmployees(loadAll: true);
      if (widget.contract != null) _fillForm(widget.contract!);
    });
  }

  @override
  void dispose() {
    _contractNumberController.dispose();
    _departmentController.dispose();
    _jobTitleController.dispose();
    _jobDescriptionController.dispose();
    _workLocationController.dispose();
    _workScheduleController.dispose();
    _reportingManagerController.dispose();
    _grossSalaryController.dispose();
    _netSalaryController.dispose();
    _weeklyHoursController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _employeeNameController.dispose();
    _employeeEmailController.dispose();
    _employeePhoneController.dispose();
    _healthInsuranceController.dispose();
    _retirementPlanController.dispose();
    _vacationDaysController.dispose();
    _otherBenefitsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _fillForm(Contract c) {
    _contractNumberController.text = c.contractNumber;
    _selectedContractType = c.contractType;
    _selectedDepartment = c.department;
    _departmentController.text = c.department;
    _jobTitleController.text = c.jobTitle;
    _jobDescriptionController.text = c.jobDescription;
    _workLocationController.text = c.workLocation;
    _workScheduleController.text = c.workSchedule;
    _reportingManagerController.text = c.reportingManager ?? '';
    _grossSalaryController.text = c.grossSalary.toString();
    _netSalaryController.text = c.netSalary.toString();
    _weeklyHoursController.text = c.weeklyHours.toString();
    _startDateController.text = DateFormat('dd/MM/yyyy').format(c.startDate);
    if (c.endDate != null) _endDateController.text = DateFormat('dd/MM/yyyy').format(c.endDate!);
    _selectedPaymentFrequency = c.paymentFrequency;
    _selectedProbationPeriod = c.probationPeriod;
    _employeeNameController.text = c.employeeName;
    _employeeEmailController.text = c.employeeEmail;
    _employeePhoneController.text = c.employeePhone ?? '';
    _healthInsuranceController.text = c.healthInsurance ?? '';
    _retirementPlanController.text = c.retirementPlan ?? '';
    _vacationDaysController.text = c.vacationDays?.toString() ?? '';
    _otherBenefitsController.text = c.otherBenefits ?? '';
    _notesController.text = c.notes ?? '';
    _selectedEmployeeId = c.employeeId;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final empState = ref.watch(employeeProvider);
    final departments = empState.departments;
    final employees = empState.employees;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.contract == null ? 'Nouveau Contrat' : 'Modifier le Contrat',
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => _saveContract(),
            child: const Text(
              'Enregistrer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informations générales
              _buildSectionTitle('Informations Générales'),
              _buildGeneralInfoSection(departments),

              const SizedBox(height: 24),

              // Informations employé
              _buildSectionTitle('Informations Employé'),
              _buildEmployeeInfoSection(employees),

              const SizedBox(height: 24),

              // Détails du contrat
              _buildSectionTitle('Détails du Contrat'),
              _buildContractDetailsSection(),

              const SizedBox(height: 24),

              // Conditions de travail
              _buildSectionTitle('Conditions de Travail'),
              _buildWorkConditionsSection(),

              const SizedBox(height: 24),

              // Avantages et bénéfices
              _buildSectionTitle('Avantages et Bénéfices'),
              _buildBenefitsSection(),

              const SizedBox(height: 24),

              // Documents et notes
              _buildSectionTitle('Documents et Notes'),
              _buildDocumentsSection(),

              const SizedBox(height: 32),

              // Boutons d'action
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
        ),
      ),
    );
  }

  Widget _buildGeneralInfoSection(List<String> departments) {
    final contractTypeFiltered = _contractTypeOptions.where((t) => t['value'] != 'all').toList();
    final validContractType = _selectedContractType.isNotEmpty && contractTypeFiltered.any((t) => t['value'] == _selectedContractType) ? _selectedContractType : null;
    final deptList = List<String>.from(departments);
    if (_selectedDepartment.isNotEmpty && !deptList.contains(_selectedDepartment)) deptList.add(_selectedDepartment);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _contractNumberController,
              decoration: const InputDecoration(
                labelText: 'Numéro du contrat *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tag),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Le numéro du contrat est requis';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: validContractType,
              decoration: const InputDecoration(
                labelText: 'Type de contrat *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.work),
              ),
              items: contractTypeFiltered.map<DropdownMenuItem<String>>((type) {
                return DropdownMenuItem<String>(value: type['value']!, child: Text(type['label']!));
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedContractType = value);
              },
              validator: (value) {
                if (value == null || value.isEmpty) return 'Le type de contrat est requis';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedDepartment.isNotEmpty ? _selectedDepartment : null,
              decoration: const InputDecoration(
                labelText: 'Département *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              items: [
                const DropdownMenuItem(value: '', child: Text('Sélectionner')),
                ...deptList.map<DropdownMenuItem<String>>((dept) => DropdownMenuItem(value: dept, child: Text(dept))),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedDepartment = value ?? '';
                  _departmentController.text = value ?? '';
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) return 'Le département est requis';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _jobTitleController,
              decoration: const InputDecoration(
                labelText: 'Poste *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.work_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Le poste est requis';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeInfoSection(List<Employee> employees) {
    final validEmployeeId = employees.any((e) => e.id == _selectedEmployeeId) && _selectedEmployeeId != 0 ? _selectedEmployeeId : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<int>(
              value: validEmployeeId,
              decoration: const InputDecoration(
                labelText: 'Employé *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              items: [
                const DropdownMenuItem<int>(value: null, child: Text('Sélectionner un employé')),
                ...employees.map<DropdownMenuItem<int>>((employee) {
                  return DropdownMenuItem<int>(
                    value: employee.id,
                    child: Text('${employee.firstName} ${employee.lastName} - ${employee.email}'),
                  );
                }),
              ],
              onChanged: (value) {
                if (value != null && value != 0) {
                  Employee? emp;
                  for (final e in employees) {
                    if (e.id == value) { emp = e; break; }
                  }
                  setState(() {
                    _selectedEmployeeId = value;
                    if (emp != null) {
                      _employeeNameController.text = '${emp.firstName} ${emp.lastName}';
                      _employeeEmailController.text = emp.email;
                      _employeePhoneController.text = emp.phone ?? '';
                    }
                  });
                }
              },
              validator: (value) {
                if (value == null || value == 0) return "L'employé est requis";
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _employeeNameController,
              decoration: const InputDecoration(
                labelText: "Nom complet de l'employé",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _employeeEmailController,
              decoration: const InputDecoration(
                labelText: "Email de l'employé",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _employeePhoneController,
              decoration: const InputDecoration(
                labelText: "Téléphone de l'employé",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              readOnly: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContractDetailsSection() {
    final validFreq = _selectedPaymentFrequency.isNotEmpty && _paymentFrequencyOptions.any((f) => f['value'] == _selectedPaymentFrequency) ? _selectedPaymentFrequency : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _startDateController,
                    decoration: const InputDecoration(
                      labelText: 'Date de début *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(_startDateController, true),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'La date de début est requise';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _endDateController,
                    decoration: const InputDecoration(
                      labelText: 'Date de fin',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.event),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(_endDateController, false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _grossSalaryController,
                    decoration: const InputDecoration(
                      labelText: 'Salaire brut *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Le salaire brut est requis';
                      if (double.tryParse(value) == null) return 'Veuillez entrer un montant valide';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: validFreq,
                    decoration: const InputDecoration(
                      labelText: 'Fréquence de paiement *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.schedule),
                    ),
                    items: _paymentFrequencyOptions.map<DropdownMenuItem<String>>((freq) {
                      return DropdownMenuItem<String>(value: freq['value']!, child: Text(freq['label']!));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedPaymentFrequency = value);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'La fréquence de paiement est requise';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _weeklyHoursController,
                    decoration: const InputDecoration(
                      labelText: 'Heures par semaine *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.schedule),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Les heures par semaine sont requises';
                      if (double.tryParse(value) == null) return 'Veuillez entrer un nombre valide';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedProbationPeriod.isNotEmpty ? _selectedProbationPeriod : 'none',
                    decoration: const InputDecoration(
                      labelText: "Période d'essai",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.timer),
                    ),
                    items: _probationPeriodOptions.map<DropdownMenuItem<String>>((option) {
                      return DropdownMenuItem<String>(value: option['value'], child: Text(option['label']!));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedProbationPeriod = value);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkConditionsSection() {
    final validSchedule = _workScheduleController.text.trim().isNotEmpty &&
        ['full_time', 'part_time', 'flexible'].contains(_workScheduleController.text.trim())
        ? _workScheduleController.text.trim()
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _workLocationController,
              decoration: const InputDecoration(
                labelText: 'Lieu de travail *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Le lieu de travail est requis';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: validSchedule,
              decoration: const InputDecoration(
                labelText: 'Horaire de travail *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.schedule),
              ),
              items: const [
                DropdownMenuItem(value: 'full_time', child: Text('Temps plein')),
                DropdownMenuItem(value: 'part_time', child: Text('Temps partiel')),
                DropdownMenuItem(value: 'flexible', child: Text('Flexible')),
              ],
              onChanged: (value) {
                if (value != null) {
                  _workScheduleController.text = value;
                  setState(() {});
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) return "L'horaire de travail est requis";
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reportingManagerController,
              decoration: const InputDecoration(
                labelText: 'Superviseur direct',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.supervisor_account),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _jobDescriptionController,
              decoration: const InputDecoration(
                labelText: 'Description du poste',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _healthInsuranceController,
              decoration: const InputDecoration(
                labelText: 'Assurance maladie',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.health_and_safety),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _retirementPlanController,
              decoration: const InputDecoration(
                labelText: 'Plan de retraite',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_balance),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _vacationDaysController,
              decoration: const InputDecoration(
                labelText: 'Jours de congé par an',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.event),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _otherBenefitsController,
              decoration: const InputDecoration(
                labelText: 'Autres avantages',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.card_giftcard),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            if (_selectedAttachments.isNotEmpty) ...[
              const Text(
                'Fichiers sélectionnés:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _selectedAttachments.length,
                itemBuilder: (context, index) {
                  final file = _selectedAttachments[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(_getFileIcon(file['type'] ?? ''), color: Colors.blue),
                      title: Text(file['name'] ?? 'Fichier', style: const TextStyle(fontSize: 14)),
                      subtitle: file['size'] != null
                          ? Text(_formatFileSize(file['size']), style: const TextStyle(fontSize: 12))
                          : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          setState(() => _selectedAttachments.removeAt(index));
                        },
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
            ElevatedButton.icon(
              onPressed: _selectFiles,
              icon: const Icon(Icons.attach_file),
              label: const Text('Sélectionner des fichiers'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Formats acceptés: PDF, Images, Documents (max 10 MB par fichier)',
              style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return UniformFormButtons(
      onCancel: () => context.pop(),
      onSubmit: _saveContract,
      submitText: 'Soumettre',
    );
  }

  Future<void> _selectDate(TextEditingController controller, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? DateTime.now() : DateTime.now().add(const Duration(days: 365)),
      firstDate: isStartDate ? DateTime.now() : DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      controller.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  void _saveContract() async {
    if (!_formKey.currentState!.validate()) return;

    DateTime? startDate;
    try {
      startDate = DateFormat('dd/MM/yyyy').parse(_startDateController.text.trim());
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Date de début invalide (dd/MM/yyyy)')));
      return;
    }
    DateTime? endDate;
    if (_endDateController.text.trim().isNotEmpty) {
      try {
        endDate = DateFormat('dd/MM/yyyy').parse(_endDateController.text.trim());
      } catch (_) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Date de fin invalide (dd/MM/yyyy)')));
        return;
      }
    }

    final gross = double.tryParse(_grossSalaryController.text.trim());
    if (gross == null || gross <= 0) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salaire brut invalide')));
      return;
    }
    final weeklyHours = int.tryParse(_weeklyHoursController.text.trim());
    if (weeklyHours == null || weeklyHours <= 0) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Heures par semaine invalides')));
      return;
    }

    final notifier = ref.read(contractProvider.notifier);
    bool success = false;

    if (widget.contract == null) {
      success = await notifier.createContract(
        employeeId: _selectedEmployeeId,
        contractType: _selectedContractType,
        position: _jobTitleController.text.trim(),
        department: _selectedDepartment,
        jobTitle: _jobTitleController.text.trim(),
        jobDescription: _jobDescriptionController.text.trim(),
        grossSalary: gross,
        salaryCurrency: 'MAD',
        paymentFrequency: _selectedPaymentFrequency,
        startDate: startDate,
        endDate: endDate,
        workLocation: _workLocationController.text.trim(),
        workSchedule: _workScheduleController.text.trim(),
        weeklyHours: weeklyHours,
        probationPeriod: _selectedProbationPeriod,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );
    } else {
      success = await notifier.updateContract(
        id: widget.contract!.id!,
        contractType: _selectedContractType,
        position: _jobTitleController.text.trim(),
        department: _selectedDepartment,
        jobTitle: _jobTitleController.text.trim(),
        jobDescription: _jobDescriptionController.text.trim().isNotEmpty ? _jobDescriptionController.text.trim() : null,
        grossSalary: gross,
        netSalary: gross * 0.8,
        salaryCurrency: 'MAD',
        paymentFrequency: _selectedPaymentFrequency,
        startDate: startDate,
        endDate: endDate,
        workLocation: _workLocationController.text.trim(),
        workSchedule: _workScheduleController.text.trim(),
        weeklyHours: weeklyHours,
        probationPeriod: _selectedProbationPeriod,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );
    }

    if (!mounted) return;
    if (success) {
      await Future.delayed(const Duration(milliseconds: 500));
      context.go('/contracts');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de l\'enregistrement du contrat')),
      );
    }
  }

  Future<void> _selectFiles() async {
    try {
      final String? selectionType = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Sélectionner des fichiers'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: const Text('Fichiers (PDF, Documents, etc.)'),
                onTap: () => Navigator.pop(ctx, 'file'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Image depuis la galerie'),
                onTap: () => Navigator.pop(ctx, 'gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Prendre une photo'),
                onTap: () => Navigator.pop(ctx, 'camera'),
              ),
            ],
          ),
        ),
      );

      if (selectionType == null || !mounted) return;

      if (selectionType == 'file') {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: true,
        );

        if (result != null && result.files.isNotEmpty && mounted) {
          for (var platformFile in result.files) {
            if (platformFile.path != null) {
              final file = File(platformFile.path!);
              final fileSize = await file.length();
              if (fileSize > 10 * 1024 * 1024) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Le fichier "${platformFile.name}" est trop volumineux (max 10 MB)')),
                  );
                }
                continue;
              }
              String fileType = 'document';
              final extension = platformFile.extension?.toLowerCase() ?? '';
              if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) fileType = 'image';
              else if (extension == 'pdf') fileType = 'pdf';
              setState(() {
                _selectedAttachments.add({
                  'name': platformFile.name,
                  'path': platformFile.path!,
                  'size': fileSize,
                  'type': fileType,
                  'extension': extension,
                });
              });
            }
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${result.files.length} fichier(s) sélectionné(s)')),
            );
          }
        }
      } else {
        final cameraService = CameraService();
        File? imageFile;
        try {
          if (selectionType == 'camera') {
            imageFile = await cameraService.takePicture();
          } else {
            imageFile = await cameraService.pickImageFromGallery();
          }

          if (imageFile != null && await imageFile.exists() && mounted) {
            final fileSize = await imageFile.length();
            if (fileSize > 10 * 1024 * 1024) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Le fichier est trop volumineux (max 10 MB)')),
              );
              return;
            }
            try {
              await cameraService.validateImage(imageFile);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Image invalide: $e')),
                );
              }
              return;
            }
            final fileName = imageFile.path.split(RegExp(r'[/\\]')).last;
            final extension = fileName.split('.').last.toLowerCase();
            String fileType = 'image';
            if (extension == 'pdf') fileType = 'pdf';
            else if (!['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) fileType = 'document';
            final path = imageFile.path;
            setState(() {
              _selectedAttachments.add({
                'name': fileName,
                'path': path,
                'size': fileSize,
                'type': fileType,
                'extension': extension,
              });
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fichier sélectionné')));
            }
          }
        } catch (e) {
          String errorMessage = 'Erreur lors de la sélection du fichier';
          if (e.toString().contains('Permission')) {
            errorMessage = 'Permission refusée. Veuillez autoriser l\'accès à la caméra/photos dans les paramètres.';
          } else {
            errorMessage = e.toString().replaceFirst('Exception: ', '');
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString().replaceFirst('Exception: ', '')}')),
        );
      }
    }
  }

  IconData _getFileIcon(String fileType) {
    if (fileType.contains('pdf')) {
      return Icons.picture_as_pdf;
    } else if (fileType.contains('image')) {
      return Icons.image;
    } else if (fileType.contains('word') || fileType.contains('document')) {
      return Icons.description;
    } else {
      return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}

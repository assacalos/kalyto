import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/Models/salary_model.dart';
import 'package:easyconnect/providers/salary_notifier.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';

class SalaryForm extends ConsumerStatefulWidget {
  final Salary? salary;

  const SalaryForm({super.key, this.salary});

  @override
  ConsumerState<SalaryForm> createState() => _SalaryFormState();
}

class _SalaryFormState extends ConsumerState<SalaryForm> {
  final _formKey = GlobalKey<FormState>();
  final _baseSalaryController = TextEditingController();
  final _bonusController = TextEditingController();
  final _deductionsController = TextEditingController();
  final _notesController = TextEditingController();

  int _selectedEmployeeId = 0;
  String _selectedEmployeeName = '';
  String _selectedEmployeeEmail = '';
  String _selectedMonth = '';
  int _selectedYear = DateTime.now().year;
  double _netSalary = 0;
  final List<Map<String, dynamic>> _selectedFiles = [];

  static const _months = [
    {'value': '01', 'label': 'Janvier'},
    {'value': '02', 'label': 'Février'},
    {'value': '03', 'label': 'Mars'},
    {'value': '04', 'label': 'Avril'},
    {'value': '05', 'label': 'Mai'},
    {'value': '06', 'label': 'Juin'},
    {'value': '07', 'label': 'Juillet'},
    {'value': '08', 'label': 'Août'},
    {'value': '09', 'label': 'Septembre'},
    {'value': '10', 'label': 'Octobre'},
    {'value': '11', 'label': 'Novembre'},
    {'value': '12', 'label': 'Décembre'},
  ];

  List<int> get _years {
    final y = DateTime.now().year;
    return List.generate(5, (i) => y - 2 + i);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(salaryProvider.notifier).loadEmployees();
      if (widget.salary != null) _fillForm(widget.salary!);
    });
  }

  @override
  void dispose() {
    _baseSalaryController.dispose();
    _bonusController.dispose();
    _deductionsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _fillForm(Salary s) {
    _baseSalaryController.text = s.baseSalary.toString();
    _bonusController.text = s.bonus.toString();
    _deductionsController.text = s.deductions.toString();
    _notesController.text = s.notes ?? '';
    _selectedEmployeeId = s.employeeId ?? 0;
    _selectedEmployeeName = s.employeeName ?? '';
    _selectedEmployeeEmail = s.employeeEmail ?? '';
    _selectedMonth = s.month ?? '';
    _selectedYear = s.year ?? DateTime.now().year;
    _netSalary = s.netSalary;
    setState(() {});
  }

  void _updateNetSalary() {
    final base = double.tryParse(_baseSalaryController.text) ?? 0;
    final bonus = double.tryParse(_bonusController.text) ?? 0;
    final ded = double.tryParse(_deductionsController.text) ?? 0;
    setState(() => _netSalary = base + bonus - ded);
  }

  @override
  Widget build(BuildContext context) {
    final salaryState = ref.watch(salaryProvider);
    final employees = salaryState.employees;
    final isLoading = salaryState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.salary == null ? 'Nouveau Salaire' : 'Modifier le Salaire',
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSalary,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Informations de base'),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _showEmployeeDialog(employees),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Employé *',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person),
                    errorText: _selectedEmployeeId == 0 ? 'Sélectionnez un employé' : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedEmployeeName.isNotEmpty ? _selectedEmployeeName : 'Sélectionner un employé',
                        style: TextStyle(
                          color: _selectedEmployeeName.isNotEmpty ? Colors.black : Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_selectedEmployeeEmail.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(_selectedEmployeeEmail, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedMonth.isNotEmpty ? _selectedMonth : null,
                      decoration: const InputDecoration(
                        labelText: 'Mois *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_month),
                      ),
                      items: _months.map<DropdownMenuItem<String>>((m) {
                        return DropdownMenuItem<String>(
                          value: m['value'] as String,
                          child: Text(m['label'] as String),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _selectedMonth = value);
                      },
                      validator: (v) => v == null || v.isEmpty ? 'Le mois est obligatoire' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedYear,
                      decoration: const InputDecoration(
                        labelText: 'Année *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      items: _years.map<DropdownMenuItem<int>>((y) {
                        return DropdownMenuItem<int>(value: y, child: Text(y.toString()));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _selectedYear = value);
                      },
                      validator: (v) => v == null ? "L'année est obligatoire" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Détails du salaire'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _baseSalaryController,
                decoration: const InputDecoration(
                  labelText: 'Salaire de base (fcfa) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance_wallet),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => _updateNetSalary(),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Le salaire de base est obligatoire';
                  if (double.tryParse(value) == null) return 'Le salaire doit être un nombre';
                  if (double.parse(value) <= 0) return 'Le salaire doit être positif';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bonusController,
                decoration: const InputDecoration(
                  labelText: 'Prime (fcfa)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.star),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => _updateNetSalary(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _deductionsController,
                decoration: const InputDecoration(
                  labelText: 'Déductions (fcfa)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.remove_circle),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => _updateNetSalary(),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.calculate, color: Colors.blue, size: 32),
                    const SizedBox(height: 8),
                    const Text(
                      'Salaire net calculé',
                      style: TextStyle(fontSize: 14, color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      NumberFormat.currency(locale: 'fr_FR', symbol: 'fcfa').format(_netSalary),
                      style: const TextStyle(fontSize: 24, color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Justificatifs'),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Fichiers justificatifs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      if (_selectedFiles.isEmpty)
                        const Text('Aucun fichier sélectionné.')
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _selectedFiles.length,
                          itemBuilder: (context, index) {
                            final file = _selectedFiles[index];
                            final name = file['name'] ?? 'Fichier';
                            final type = file['type'] ?? 'document';
                            final size = file['size'] ?? 0;
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: Icon(_getFileIcon(type)),
                                title: Text(name),
                                subtitle: Text(_formatFileSize(size)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => setState(() => _selectedFiles.removeAt(index)),
                                ),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _selectFiles,
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Ajouter des justificatifs'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Informations supplémentaires'),
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
                onSubmit: _saveSalary,
                submitText: 'Soumettre',
                isLoading: isLoading,
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
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
    );
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'image':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _selectFiles() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélection de fichiers à brancher (optionnel)')),
      );
    }
  }

  void _showEmployeeDialog(List<Map<String, dynamic>> employees) {
    if (employees.isEmpty) {
      ref.read(salaryProvider.notifier).loadEmployees();
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sélectionner un employé'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: employees.isEmpty
              ? const Center(child: Text('Chargement...'))
              : ListView.builder(
                  itemCount: employees.length,
                  itemBuilder: (context, index) {
                    final e = employees[index];
                    final name = e['name'] ?? '${e['first_name'] ?? ''} ${e['last_name'] ?? ''}'.trim();
                    final email = e['email'] ?? '';
                    final id = e['id'] is int ? e['id'] as int : int.tryParse(e['id']?.toString() ?? '0') ?? 0;
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(name),
                      subtitle: Text(email),
                      onTap: () {
                        setState(() {
                          _selectedEmployeeId = id;
                          _selectedEmployeeName = name;
                          _selectedEmployeeEmail = email;
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSalary() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs obligatoires')),
      );
      return;
    }
    if (_selectedEmployeeId == 0 || _selectedEmployeeName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un employé')),
      );
      return;
    }
    if (_selectedMonth.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un mois')),
      );
      return;
    }

    final base = double.tryParse(_baseSalaryController.text.trim()) ?? 0;
    final bonus = double.tryParse(_bonusController.text.trim()) ?? 0;
    final ded = double.tryParse(_deductionsController.text.trim()) ?? 0;
    final net = base + bonus - ded;
    const justificatifs = <String>[];

    final notifier = ref.read(salaryProvider.notifier);

    if (widget.salary == null) {
      final salary = Salary(
        employeeId: _selectedEmployeeId,
        employeeName: _selectedEmployeeName,
        employeeEmail: _selectedEmployeeEmail,
        baseSalary: base,
        bonus: bonus,
        deductions: ded,
        netSalary: net,
        month: _selectedMonth,
        year: _selectedYear,
        status: 'pending',
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        justificatifs: justificatifs,
      );
      final created = await notifier.createSalary(salary);
      if (!mounted) return;
      if (created != null) {
        await Future.delayed(const Duration(milliseconds: 500));
        context.go('/salaries');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'enregistrement du salaire')),
        );
      }
    } else {
      final salary = Salary(
        id: widget.salary!.id,
        employeeId: _selectedEmployeeId,
        employeeName: _selectedEmployeeName,
        employeeEmail: _selectedEmployeeEmail,
        baseSalary: base,
        bonus: bonus,
        deductions: ded,
        netSalary: net,
        month: _selectedMonth,
        year: _selectedYear,
        status: widget.salary!.status ?? 'pending',
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        justificatifs: justificatifs,
      );
      final success = await notifier.updateSalary(salary);
      if (!mounted) return;
      if (success) {
        await Future.delayed(const Duration(milliseconds: 500));
        context.go('/salaries');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la mise à jour du salaire')),
        );
      }
    }
  }
}

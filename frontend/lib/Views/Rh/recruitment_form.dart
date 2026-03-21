import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/Models/recruitment_model.dart';
import 'package:easyconnect/providers/recruitment_notifier.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';

class RecruitmentForm extends ConsumerStatefulWidget {
  final RecruitmentRequest? request;

  const RecruitmentForm({super.key, this.request});

  @override
  ConsumerState<RecruitmentForm> createState() => _RecruitmentFormState();
}

class _RecruitmentFormState extends ConsumerState<RecruitmentForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _salaryRangeController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _responsibilitiesController = TextEditingController();

  final List<String> _selectedDepartments = [];
  final List<String> _selectedPositions = [];
  String _selectedEmploymentType = '';
  String _selectedExperienceLevel = '';
  int _numberOfPositions = 1;
  DateTime? _deadline;
  bool _isLoading = false;

  static const _employmentTypeOptions = [
    {'value': 'full_time', 'label': 'Temps plein'},
    {'value': 'part_time', 'label': 'Temps partiel'},
    {'value': 'contract', 'label': 'Contrat'},
    {'value': 'internship', 'label': 'Stage'},
  ];

  static const _experienceLevelOptions = [
    {'value': 'entry', 'label': 'Débutant'},
    {'value': 'junior', 'label': 'Junior (0-2 ans)'},
    {'value': 'mid', 'label': 'Intermédiaire (2-5 ans)'},
    {'value': 'senior', 'label': 'Senior (5-10 ans)'},
    {'value': 'expert', 'label': 'Expert (10+ ans)'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(recruitmentProvider.notifier);
      if (ref.read(recruitmentProvider).departments.isEmpty) notifier.loadDepartments();
      if (ref.read(recruitmentProvider).positions.isEmpty) notifier.loadPositions();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _salaryRangeController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    _responsibilitiesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recruitmentProvider);
    final departments = state.departments;
    final positions = state.positions;
    final deptOptions = departments.where((d) => d != 'all').map((d) => {'value': d, 'label': d}).toList();
    final posOptions = positions.where((p) => p != 'all').map((p) => {'value': p, 'label': p}).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.request == null ? 'Nouvelle Demande de Recrutement' : 'Modifier la Demande',
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveRecruitmentRequest,
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
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Titre de l'offre *",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Le titre est obligatoire';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: deptOptions.isEmpty
                    ? null
                    : () => _showMultiSelectDialog(
                          context,
                          'Sélectionner les départements',
                          deptOptions,
                          _selectedDepartments,
                          (value) => setState(() {
                            if (_selectedDepartments.contains(value)) {
                              _selectedDepartments.remove(value);
                            } else {
                              _selectedDepartments.add(value);
                            }
                          }),
                          (value) => _selectedDepartments.contains(value),
                        ),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Départements *',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.business),
                    errorText: _selectedDepartments.isEmpty ? 'Au moins un département est obligatoire' : null,
                  ),
                  child: _selectedDepartments.isEmpty
                      ? Text('Sélectionner les départements', style: TextStyle(color: Colors.grey[600]))
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedDepartments.map((dept) {
                            return Chip(
                              label: Text(dept),
                              onDeleted: () => setState(() => _selectedDepartments.remove(dept)),
                              deleteIcon: const Icon(Icons.close, size: 18),
                            );
                          }).toList(),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: posOptions.isEmpty
                    ? null
                    : () => _showMultiSelectDialog(
                          context,
                          'Sélectionner les postes',
                          posOptions,
                          _selectedPositions,
                          (value) => setState(() {
                            if (_selectedPositions.contains(value)) {
                              _selectedPositions.remove(value);
                            } else {
                              _selectedPositions.add(value);
                            }
                          }),
                          (value) => _selectedPositions.contains(value),
                        ),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Postes *',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.work),
                    errorText: _selectedPositions.isEmpty ? 'Au moins un poste est obligatoire' : null,
                  ),
                  child: _selectedPositions.isEmpty
                      ? Text('Sélectionner les postes', style: TextStyle(color: Colors.grey[600]))
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedPositions.map((pos) {
                            return Chip(
                              label: Text(pos),
                              onDeleted: () => setState(() => _selectedPositions.remove(pos)),
                              deleteIcon: const Icon(Icons.close, size: 18),
                            );
                          }).toList(),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedEmploymentType.isNotEmpty ? _selectedEmploymentType : null,
                      decoration: const InputDecoration(
                        labelText: "Type d'emploi *",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.schedule),
                      ),
                      items: _employmentTypeOptions.map<DropdownMenuItem<String>>((t) {
                        return DropdownMenuItem<String>(value: t['value']!, child: Text(t['label']!));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _selectedEmploymentType = value);
                      },
                      validator: (v) => v == null || v.isEmpty ? "Le type d'emploi est obligatoire" : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedExperienceLevel.isNotEmpty ? _selectedExperienceLevel : null,
                      decoration: const InputDecoration(
                        labelText: "Niveau d'expérience *",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.trending_up),
                      ),
                      items: _experienceLevelOptions.map<DropdownMenuItem<String>>((l) {
                        return DropdownMenuItem<String>(value: l['value']!, child: Text(l['label']!));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _selectedExperienceLevel = value);
                      },
                      validator: (v) => v == null || v.isEmpty ? "Le niveau d'expérience est obligatoire" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _salaryRangeController,
                      decoration: const InputDecoration(
                        labelText: 'Fourchette salariale *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'La fourchette salariale est obligatoire' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Localisation *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'La localisation est obligatoire' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Nombre de postes: '),
                  IconButton(
                    onPressed: () {
                      if (_numberOfPositions > 1) setState(() => _numberOfPositions--);
                    },
                    icon: const Icon(Icons.remove),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('$_numberOfPositions', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _numberOfPositions++),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _deadline ?? DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _deadline = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: "Date d'échéance *",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _deadline != null ? DateFormat('dd/MM/yyyy').format(_deadline!) : 'Sélectionner une date',
                    style: TextStyle(color: _deadline != null ? Colors.black : Colors.grey[600]),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Description du poste'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description du poste *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  hintText: 'Décrivez le poste et ses responsabilités principales',
                ),
                maxLines: 4,
                validator: (v) => v == null || v.trim().isEmpty ? 'La description est obligatoire' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _requirementsController,
                decoration: const InputDecoration(
                  labelText: 'Exigences et qualifications *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.checklist),
                  hintText: 'Listez les exigences et qualifications requises',
                ),
                maxLines: 4,
                validator: (v) => v == null || v.trim().isEmpty ? 'Les exigences sont obligatoires' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _responsibilitiesController,
                decoration: const InputDecoration(
                  labelText: 'Responsabilités principales *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.assignment),
                  hintText: 'Détaillez les responsabilités principales du poste',
                ),
                maxLines: 4,
                validator: (v) => v == null || v.trim().isEmpty ? 'Les responsabilités sont obligatoires' : null,
              ),
              const SizedBox(height: 32),
              UniformFormButtons(
                onCancel: () => context.pop(),
                onSubmit: _saveRecruitmentRequest,
                submitText: 'Soumettre',
                isLoading: _isLoading,
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

  void _showMultiSelectDialog(
    BuildContext context,
    String title,
    List<Map<String, String>> options,
    List<String> selectedValues,
    void Function(String) onToggle,
    bool Function(String) isSelected,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index];
                final value = option['value']!;
                final label = option['label']!;
                final selected = isSelected(value);
                return CheckboxListTile(
                  title: Text(label),
                  value: selected,
                  onChanged: (_) {
                    onToggle(value);
                    setDialogState(() {});
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Fermer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveRecruitmentRequest() async {
    if (_titleController.text.trim().isEmpty ||
        _selectedDepartments.isEmpty ||
        _selectedPositions.isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _requirementsController.text.trim().isEmpty ||
        _responsibilitiesController.text.trim().isEmpty ||
        _selectedEmploymentType.isEmpty ||
        _selectedExperienceLevel.isEmpty ||
        _salaryRangeController.text.trim().isEmpty ||
        _locationController.text.trim().isEmpty ||
        _deadline == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez remplir tous les champs obligatoires')),
        );
      }
      return;
    }

    if (_descriptionController.text.trim().length < 50) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'La description doit contenir au moins 50 caractères (actuellement: ${_descriptionController.text.trim().length})',
            ),
          ),
        );
      }
      return;
    }

    if (_requirementsController.text.trim().length < 20) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Les exigences doivent contenir au moins 20 caractères')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    final notifier = ref.read(recruitmentProvider.notifier);
    final success = await notifier.createRecruitmentRequest(
      title: _titleController.text.trim(),
      departments: _selectedDepartments,
      positions: _selectedPositions,
      description: _descriptionController.text.trim(),
      requirements: _requirementsController.text.trim(),
      responsibilities: _responsibilitiesController.text.trim(),
      numberOfPositions: _numberOfPositions,
      employmentType: _selectedEmploymentType,
      experienceLevel: _selectedExperienceLevel,
      salaryRange: _salaryRangeController.text.trim(),
      location: _locationController.text.trim(),
      applicationDeadline: _deadline!,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      await Future.delayed(const Duration(milliseconds: 500));
      context.go('/recruitment');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la création de la demande')),
      );
    }
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easyconnect/providers/expense_notifier.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/Models/expense_model.dart';
import 'package:easyconnect/services/camera_service.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';
import 'package:intl/intl.dart';

/// Catégories par défaut (affichées si l'API n'en renvoie pas).
final List<Map<String, dynamic>> _defaultExpenseCategoriesList = [
  {'value': 'office_supplies', 'label': 'Fournitures de bureau', 'color': Colors.blue},
  {'value': 'travel', 'label': 'Voyage', 'color': Colors.purple},
  {'value': 'meals', 'label': 'Repas', 'color': Colors.orange},
  {'value': 'transport', 'label': 'Transport', 'color': Colors.green},
  {'value': 'utilities', 'label': 'Services publics', 'color': Colors.red},
  {'value': 'marketing', 'label': 'Marketing', 'color': Colors.pink},
  {'value': 'equipment', 'label': 'Équipement', 'color': Colors.indigo},
  {'value': 'other', 'label': 'Autre', 'color': Colors.grey},
];

class ExpenseForm extends ConsumerStatefulWidget {
  final Expense? expense;

  const ExpenseForm({super.key, this.expense});

  @override
  ConsumerState<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends ConsumerState<ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedCategoryForm = 'office_supplies';
  int _selectedCategoryId = 0;
  DateTime? _selectedExpenseDate;
  String? _selectedReceiptPath;
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      ref.read(expenseProvider.notifier).loadExpenseCategories();
      if (widget.expense != null) {
        final e = widget.expense!;
        _titleController.text = e.title;
        _descriptionController.text = e.description;
        _amountController.text = e.amount.toString();
        _selectedCategoryForm = e.category;
        _selectedExpenseDate = e.expenseDate;
        _selectedReceiptPath = e.receiptPath;
        _notesController.text = e.notes ?? '';
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectExpenseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedExpenseDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedExpenseDate = picked);
  }

  Future<void> _selectReceipt() async {
    try {
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Sélectionner une source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Prendre une photo'),
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choisir depuis la galerie'),
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
      if (source == null) return;

      final cameraService = CameraService();
      File? imageFile;
      if (source == ImageSource.camera) {
        imageFile = await cameraService.takePicture();
      } else {
        imageFile = await cameraService.pickImageFromGallery();
      }

      if (imageFile != null) {
        await cameraService.validateImage(imageFile);
        setState(() => _selectedReceiptPath = imageFile!.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Justificatif sélectionné'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authProvider).user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur non connecté')),
      );
      return;
    }

    final expenseCategories = ref.read(expenseProvider).expenseCategories;
    int? categoryId;
    if (expenseCategories.isNotEmpty) {
      final match = expenseCategories.where((cat) =>
          cat.name.toLowerCase() == _selectedCategoryForm.toLowerCase() ||
          cat.name.toString() == _selectedCategoryForm).toList();
      categoryId = match.isNotEmpty ? (match.first.id ?? 0) : null;
    }
    if (categoryId == null && _selectedCategoryId > 0) categoryId = _selectedCategoryId;
    if (categoryId == null) categoryId = int.tryParse(_selectedCategoryForm);

    final expenseData = <String, dynamic>{
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'amount': double.tryParse(_amountController.text) ?? 0.0,
      'currency': 'FCFA',
      'expense_date': (_selectedExpenseDate ?? DateTime.now()).toIso8601String(),
      'user_id': user.id,
      'employee_id': user.id,
      'status': 'pending',
    };
    if (_selectedCategoryId > 0) {
      expenseData['category'] = _selectedCategoryId.toString();
    } else if (categoryId != null && categoryId > 0) {
      expenseData['category'] = categoryId.toString();
    } else {
      expenseData['category'] = _selectedCategoryForm;
    }
    if (_selectedReceiptPath != null && _selectedReceiptPath!.isNotEmpty) {
      expenseData['receipt_path'] = _selectedReceiptPath;
    }
    if (_notesController.text.trim().isNotEmpty) {
      expenseData['notes'] = _notesController.text.trim();
      expenseData['justification'] = _notesController.text.trim();
    }

    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(expenseProvider.notifier);
      if (widget.expense == null) {
        await notifier.createExpense(expenseData);
      } else {
        await notifier.updateExpense(widget.expense!.id!, expenseData);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dépense enregistrée')),
        );
        context.go('/expenses');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expenseProvider);
    final categoriesList = state.expenseCategories.isNotEmpty
        ? state.expenseCategories
            .map<Map<String, dynamic>>((c) => {
                  'value': c.name.toLowerCase().replaceAll(' ', '_'),
                  'label': c.name,
                  'id': c.id,
                })
            .toList()
        : _defaultExpenseCategoriesList;

    final values = categoriesList.map<String>((c) => (c['value'] ?? c['label']) as String).toList();
    final dropdownValue = values.contains(_selectedCategoryForm)
        ? _selectedCategoryForm
        : (values.isNotEmpty ? values.first : 'office_supplies');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.expense == null ? 'Nouvelle Dépense' : 'Modifier la Dépense',
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
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
                  labelText: 'Titre de la dépense *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Le titre est obligatoire' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: dropdownValue,
                decoration: const InputDecoration(
                  labelText: 'Catégorie *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: categoriesList.map<DropdownMenuItem<String>>((c) {
                  final value = (c['value'] ?? c['label']) as String;
                  final label = (c['label'] ?? value) as String;
                  return DropdownMenuItem(value: value, child: Text(label));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategoryForm = value;
                      if (state.expenseCategories.isNotEmpty) {
                        final apiCat = state.expenseCategories.where((cat) =>
                            cat.name.toLowerCase() == value.toLowerCase()).toList();
                        if (apiCat.isNotEmpty) {
                          _selectedCategoryId = apiCat.first.id ?? 0;
                        }
                      }
                    });
                  }
                },
                validator: (v) =>
                    v == null || v.isEmpty ? 'La catégorie est obligatoire' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Montant (fcfa) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_franc),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Le montant est obligatoire';
                  if (double.tryParse(v) == null) return 'Le montant doit être un nombre';
                  if (double.parse(v) <= 0) return 'Le montant doit être positif';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectExpenseDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date de la dépense *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _selectedExpenseDate != null
                        ? DateFormat('dd/MM/yyyy').format(_selectedExpenseDate!)
                        : 'Sélectionner une date',
                    style: TextStyle(
                      color: _selectedExpenseDate != null ? Colors.black : Colors.grey[600],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  hintText: 'Description de la dépense (optionnel)',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Informations supplémentaires'),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt,
                      size: 48,
                      color: _selectedReceiptPath != null ? Colors.green : Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedReceiptPath != null ? 'Justificatif ajouté' : 'Aucun justificatif',
                      style: TextStyle(
                        color: _selectedReceiptPath != null ? Colors.green : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: Icon(_selectedReceiptPath != null ? Icons.edit : Icons.add),
                      label: Text(
                        _selectedReceiptPath != null
                            ? 'Modifier le justificatif'
                            : 'Ajouter un justificatif',
                      ),
                      onPressed: _selectReceipt,
                    ),
                    if (_selectedReceiptPath != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_selectedReceiptPath!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.delete),
                        label: const Text('Supprimer'),
                        onPressed: () => setState(() => _selectedReceiptPath = null),
                      ),
                    ],
                  ],
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
                onCancel: () => context.go('/expenses'),
                onSubmit: _saveExpense,
                submitText: 'Soumettre',
                isLoading: _isSaving,
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
}

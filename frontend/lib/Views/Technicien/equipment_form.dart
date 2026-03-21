import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/Models/equipment_model.dart';
import 'package:easyconnect/providers/equipment_notifier.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';
import 'package:intl/intl.dart';

/// Options pour catégories, statuts et états (ex-EquipmentController).
class _EquipmentFormOptions {
  static const categories = [
    {'value': 'computer', 'label': 'Ordinateur'},
    {'value': 'printer', 'label': 'Imprimante'},
    {'value': 'network', 'label': 'Réseau'},
    {'value': 'phone', 'label': 'Téléphone'},
    {'value': 'furniture', 'label': 'Mobilier'},
    {'value': 'vehicle', 'label': 'Véhicule'},
    {'value': 'tool', 'label': 'Outil'},
    {'value': 'other', 'label': 'Autre'},
  ];
  static const statuses = [
    {'value': 'pending', 'label': 'En attente'},
    {'value': 'active', 'label': 'Actif'},
    {'value': 'inactive', 'label': 'Inactif'},
    {'value': 'maintenance', 'label': 'En maintenance'},
    {'value': 'broken', 'label': 'Hors service'},
  ];
  static const conditions = [
    {'value': 'excellent', 'label': 'Excellent'},
    {'value': 'good', 'label': 'Bon'},
    {'value': 'fair', 'label': 'Correct'},
    {'value': 'poor', 'label': 'Mauvais'},
    {'value': 'critical', 'label': 'Critique'},
  ];
}

class EquipmentForm extends ConsumerStatefulWidget {
  final Equipment? equipment;

  const EquipmentForm({super.key, this.equipment});

  @override
  ConsumerState<EquipmentForm> createState() => _EquipmentFormState();
}

class _EquipmentFormState extends ConsumerState<EquipmentForm> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _modelController = TextEditingController();
  final _brandController = TextEditingController();
  final _locationController = TextEditingController();
  final _departmentController = TextEditingController();
  final _assignedToController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _currentValueController = TextEditingController();
  final _supplierController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedCategory = '';
  String _selectedStatus = 'active';
  String _selectedCondition = 'good';
  DateTime? _purchaseDate;
  DateTime? _warrantyExpiry;
  DateTime? _lastMaintenance;
  DateTime? _nextMaintenance;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.equipment != null) {
      final e = widget.equipment!;
      _nameController.text = e.name;
      _descriptionController.text = e.description;
      _selectedCategory = e.category;
      _selectedStatus = e.status;
      _selectedCondition = e.condition;
      _serialNumberController.text = e.serialNumber ?? '';
      _modelController.text = e.model ?? '';
      _brandController.text = e.brand ?? '';
      _locationController.text = e.location ?? '';
      _departmentController.text = e.department ?? '';
      _assignedToController.text = e.assignedTo ?? '';
      _purchasePriceController.text = e.purchasePrice?.toString() ?? '';
      _currentValueController.text = e.currentValue?.toString() ?? '';
      _supplierController.text = e.supplier ?? '';
      _notesController.text = e.notes ?? '';
      _purchaseDate = e.purchaseDate;
      _warrantyExpiry = e.warrantyExpiry;
      _lastMaintenance = e.lastMaintenance;
      _nextMaintenance = e.nextMaintenance;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _serialNumberController.dispose();
    _modelController.dispose();
    _brandController.dispose();
    _locationController.dispose();
    _departmentController.dispose();
    _assignedToController.dispose();
    _purchasePriceController.dispose();
    _currentValueController.dispose();
    _supplierController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(DateTime? current, bool isPast, ValueChanged<DateTime?> onPick) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: isPast ? DateTime.now().subtract(const Duration(days: 3650)) : DateTime.now(),
      lastDate: isPast ? DateTime.now() : DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => onPick(picked));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.equipment == null ? 'Nouvel Équipement' : 'Modifier l\'Équipement',
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _saveEquipment(context),
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
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de l\'équipement *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.devices),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Le nom est obligatoire' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory.isEmpty ? null : _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Catégorie *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _EquipmentFormOptions.categories.map<DropdownMenuItem<String>>((c) {
                  return DropdownMenuItem<String>(
                    value: c['value'] as String,
                    child: Text(c['label'] as String),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v ?? ''),
                validator: (v) => (v == null || v.isEmpty) ? 'La catégorie est obligatoire' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedStatus.isEmpty ? null : _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Statut *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.info),
                      ),
                      items: _EquipmentFormOptions.statuses.map<DropdownMenuItem<String>>((s) {
                        return DropdownMenuItem<String>(
                          value: s['value'] as String,
                          child: Text(s['label'] as String),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedStatus = v ?? 'active'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Le statut est obligatoire' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCondition.isEmpty ? null : _selectedCondition,
                      decoration: const InputDecoration(
                        labelText: 'État *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.star),
                      ),
                      items: _EquipmentFormOptions.conditions.map<DropdownMenuItem<String>>((c) {
                        return DropdownMenuItem<String>(
                          value: c['value'] as String,
                          child: Text(c['label'] as String),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedCondition = v ?? 'good'),
                      validator: (v) => (v == null || v.isEmpty) ? 'L\'état est obligatoire' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'La description est obligatoire' : null,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Informations techniques'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _serialNumberController, decoration: const InputDecoration(labelText: 'Numéro de série', border: OutlineInputBorder(), prefixIcon: Icon(Icons.qr_code)))),
                  const SizedBox(width: 16),
                  Expanded(child: TextFormField(controller: _modelController, decoration: const InputDecoration(labelText: 'Modèle', border: OutlineInputBorder(), prefixIcon: Icon(Icons.model_training)))),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(controller: _brandController, decoration: const InputDecoration(labelText: 'Marque', border: OutlineInputBorder(), prefixIcon: Icon(Icons.branding_watermark))),
              const SizedBox(height: 24),
              _buildSectionTitle('Localisation et assignation'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _locationController, decoration: const InputDecoration(labelText: 'Localisation', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on)))),
                  const SizedBox(width: 16),
                  Expanded(child: TextFormField(controller: _departmentController, decoration: const InputDecoration(labelText: 'Département', border: OutlineInputBorder(), prefixIcon: Icon(Icons.business)))),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(controller: _assignedToController, decoration: const InputDecoration(labelText: 'Assigné à', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person))),
              const SizedBox(height: 24),
              _buildSectionTitle('Informations financières'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _purchasePriceController, decoration: const InputDecoration(labelText: 'Prix d\'achat (fcfa)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.euro)), keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: TextFormField(controller: _currentValueController, decoration: const InputDecoration(labelText: 'Valeur actuelle (fcfa)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.attach_money)), keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(controller: _supplierController, decoration: const InputDecoration(labelText: 'Fournisseur', border: OutlineInputBorder(), prefixIcon: Icon(Icons.store))),
              const SizedBox(height: 24),
              _buildSectionTitle('Dates importantes'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildDateField('Date d\'achat', _purchaseDate, true, (d) => _purchaseDate = d)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDateField('Expiration garantie', _warrantyExpiry, false, (d) => _warrantyExpiry = d)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildDateField('Dernière maintenance', _lastMaintenance, true, (d) => _lastMaintenance = d)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDateField('Prochaine maintenance', _nextMaintenance, false, (d) => _nextMaintenance = d)),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Notes'),
              const SizedBox(height: 16),
              TextFormField(controller: _notesController, decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder(), prefixIcon: Icon(Icons.note), hintText: 'Notes internes (optionnel)'), maxLines: 3),
              const SizedBox(height: 32),
              UniformFormButtons(
                onCancel: () => context.pop(),
                onSubmit: () => _saveEquipment(context),
                submitText: 'Soumettre',
                isLoading: _isSubmitting,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? value, bool isPast, ValueChanged<DateTime?> onPick) {
    return InkWell(
      onTap: () => _pickDate(value, isPast, onPick),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.calendar_today)),
        child: Text(value != null ? DateFormat('dd/MM/yyyy').format(value) : 'Sélectionner une date', style: TextStyle(color: value != null ? Colors.black : Colors.grey[600])),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
    );
  }

  void _saveEquipment(BuildContext context) async {
    if (_nameController.text.trim().isEmpty || _descriptionController.text.trim().isEmpty || _selectedCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez remplir les champs obligatoires'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _isSubmitting = true);
    final now = DateTime.now();
    final equipment = Equipment(
      id: widget.equipment?.id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      status: _selectedStatus,
      condition: _selectedCondition,
      serialNumber: _serialNumberController.text.trim().isEmpty ? null : _serialNumberController.text.trim(),
      model: _modelController.text.trim().isEmpty ? null : _modelController.text.trim(),
      brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      department: _departmentController.text.trim().isEmpty ? null : _departmentController.text.trim(),
      assignedTo: _assignedToController.text.trim().isEmpty ? null : _assignedToController.text.trim(),
      purchaseDate: _purchaseDate,
      warrantyExpiry: _warrantyExpiry,
      lastMaintenance: _lastMaintenance,
      nextMaintenance: _nextMaintenance,
      purchasePrice: double.tryParse(_purchasePriceController.text.trim()),
      currentValue: double.tryParse(_currentValueController.text.trim()),
      supplier: _supplierController.text.trim().isEmpty ? null : _supplierController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdAt: widget.equipment?.createdAt ?? now,
      updatedAt: now,
    );
    final notifier = ref.read(equipmentProvider.notifier);
    bool success;
    if (widget.equipment == null) {
      success = await notifier.createEquipment(equipment);
    } else {
      success = await notifier.updateEquipment(equipment);
    }
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (success) {
      context.go('/equipments');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de l\'enregistrement'), backgroundColor: Colors.red));
    }
  }
}

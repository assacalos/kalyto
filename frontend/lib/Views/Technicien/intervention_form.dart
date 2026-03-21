import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/Models/intervention_model.dart';
import 'package:easyconnect/Models/client_model.dart';
import 'package:easyconnect/providers/intervention_notifier.dart';
import 'package:easyconnect/Views/Components/client_selection_dialog.dart';
import 'package:intl/intl.dart';

/// Options pour type et priorité (ex-InterventionController).
class _InterventionFormOptions {
  static const interventionTypes = [
    {'value': 'external', 'label': 'Externe'},
    {'value': 'on_site', 'label': 'Sur place'},
  ];
  static const priorities = [
    {'value': 'low', 'label': 'Faible'},
    {'value': 'medium', 'label': 'Moyenne'},
    {'value': 'high', 'label': 'Élevée'},
    {'value': 'urgent', 'label': 'Urgente'},
  ];
}

class InterventionForm extends ConsumerStatefulWidget {
  final Intervention? intervention;

  const InterventionForm({super.key, this.intervention});

  @override
  ConsumerState<InterventionForm> createState() => _InterventionFormState();
}

class _InterventionFormState extends ConsumerState<InterventionForm> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _clientPhoneController = TextEditingController();
  final _clientEmailController = TextEditingController();
  final _equipmentController = TextEditingController();
  final _problemController = TextEditingController();
  final _locationController = TextEditingController();
  final _estimatedDurationController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedType = '';
  String _selectedPriority = 'medium';
  DateTime? _scheduledDate;
  Client? _selectedClient;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.intervention != null) {
      final i = widget.intervention!;
      _titleController.text = i.title;
      _descriptionController.text = i.description;
      _selectedType = i.type;
      _selectedPriority = i.priority;
      _scheduledDate = i.scheduledDate;
      _clientNameController.text = i.clientName ?? '';
      _clientPhoneController.text = i.clientPhone ?? '';
      _clientEmailController.text = i.clientEmail ?? '';
      _equipmentController.text = i.equipment ?? '';
      _problemController.text = i.problemDescription ?? '';
      _locationController.text = i.location ?? '';
      _estimatedDurationController.text = i.estimatedDuration?.toString() ?? '';
      _costController.text = i.cost?.toString() ?? '';
      _notesController.text = i.notes ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _clientNameController.dispose();
    _clientPhoneController.dispose();
    _clientEmailController.dispose();
    _equipmentController.dispose();
    _problemController.dispose();
    _locationController.dispose();
    _estimatedDurationController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.intervention == null
              ? 'Nouvelle Intervention'
              : 'Modifier l\'Intervention',
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
            tooltip: 'Fermer',
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
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre de l\'intervention *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Le titre est obligatoire' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType.isEmpty ? null : _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type d\'intervention *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _InterventionFormOptions.interventionTypes
                    .map<DropdownMenuItem<String>>((t) {
                  return DropdownMenuItem<String>(
                    value: t['value'] as String,
                    child: Text(t['label'] as String),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedType = v ?? ''),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Le type est obligatoire' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPriority.isEmpty ? null : _selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Priorité *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.priority_high),
                ),
                items: _InterventionFormOptions.priorities
                    .map<DropdownMenuItem<String>>((p) {
                  return DropdownMenuItem<String>(
                    value: p['value'] as String,
                    child: Text(p['label'] as String),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedPriority = v ?? 'medium'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'La priorité est obligatoire' : null,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _scheduledDate ?? DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now().add(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _scheduledDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date programmée *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _scheduledDate != null
                        ? DateFormat('dd/MM/yyyy').format(_scheduledDate!)
                        : 'Sélectionner une date',
                    style: TextStyle(
                      color: _scheduledDate != null ? Colors.black : Colors.grey[600],
                    ),
                  ),
                ),
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
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'La description est obligatoire' : null,
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('Informations client'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _clientNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom du client',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                        hintText: 'Sélectionner un client ou saisir manuellement',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showClientSelectionDialog(),
                    icon: const Icon(Icons.search, size: 16),
                    label: const Text('Sélectionner'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              if (_selectedClient != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedClient!.nomEntreprise?.isNotEmpty == true
                              ? _selectedClient!.nomEntreprise!
                              : '${_selectedClient!.nom ?? ''} ${_selectedClient!.prenom ?? ''}'.trim().isNotEmpty
                                  ? '${_selectedClient!.nom ?? ''} ${_selectedClient!.prenom ?? ''}'.trim()
                                  : 'Client #${_selectedClient!.id}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() {
                          _selectedClient = null;
                          _clientNameController.clear();
                          _clientPhoneController.clear();
                          _clientEmailController.clear();
                        }),
                        tooltip: 'Désélectionner le client',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _clientPhoneController,
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
                    child: TextFormField(
                      controller: _clientEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('Informations techniques'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _equipmentController,
                decoration: const InputDecoration(
                  labelText: 'Équipement',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.build),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _problemController,
                decoration: const InputDecoration(
                  labelText: 'Description du problème',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.warning),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              if (_selectedType == 'external')
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Localisation',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
              if (_selectedType == 'external') const SizedBox(height: 16),
              _buildSectionTitle('Planification'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _estimatedDurationController,
                      decoration: const InputDecoration(
                        labelText: 'Durée estimée (heures)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.schedule),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _costController,
                      decoration: const InputDecoration(
                        labelText: 'Coût estimé (€)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.euro),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('Notes'),
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
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : () => _saveIntervention(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Enregistrer l\'intervention',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
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

  void _showClientSelectionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => ClientSelectionDialog(
        onClientSelected: (client) {
          setState(() {
            _selectedClient = client;
            _clientNameController.text = client.nomEntreprise?.isNotEmpty == true
                ? client.nomEntreprise!
                : '${client.nom ?? ''} ${client.prenom ?? ''}'.trim();
            _clientPhoneController.text = client.contact ?? '';
            _clientEmailController.text = client.email ?? '';
          });
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  Future<void> _saveIntervention(BuildContext context) async {
    if (_titleController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _selectedType.isEmpty ||
        _selectedPriority.isEmpty ||
        _scheduledDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir les champs obligatoires'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    final notifier = ref.read(interventionProvider.notifier);
    final now = DateTime.now();
    final intervention = Intervention(
      id: widget.intervention?.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      type: _selectedType,
      priority: _selectedPriority,
      scheduledDate: _scheduledDate!,
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      clientId: _selectedClient?.id,
      clientName: _clientNameController.text.trim().isEmpty ? null : _clientNameController.text.trim(),
      clientPhone: _clientPhoneController.text.trim().isEmpty ? null : _clientPhoneController.text.trim(),
      clientEmail: _clientEmailController.text.trim().isEmpty ? null : _clientEmailController.text.trim(),
      equipment: _equipmentController.text.trim().isEmpty ? null : _equipmentController.text.trim(),
      problemDescription: _problemController.text.trim().isEmpty ? null : _problemController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      estimatedDuration: double.tryParse(_estimatedDurationController.text.trim()),
      cost: double.tryParse(_costController.text.trim()),
      createdAt: widget.intervention?.createdAt ?? now,
      updatedAt: now,
    );
    bool success;
    if (widget.intervention == null) {
      success = await notifier.createIntervention(intervention);
    } else {
      success = await notifier.updateIntervention(intervention);
    }
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Intervention enregistrée avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/interventions');
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

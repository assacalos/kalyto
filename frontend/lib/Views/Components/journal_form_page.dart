import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/providers/journal_notifier.dart';
import 'package:easyconnect/Models/journal_entry_model.dart';
import 'package:easyconnect/services/api_service.dart';

class JournalFormPage extends ConsumerStatefulWidget {
  final int? entryId;

  const JournalFormPage({super.key, this.entryId});

  @override
  ConsumerState<JournalFormPage> createState() => _JournalFormPageState();
}

class _JournalFormPageState extends ConsumerState<JournalFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _referenceController = TextEditingController();
  final _libelleController = TextEditingController();
  final _categorieController = TextEditingController();
  final _entreeController = TextEditingController(text: '0');
  final _sortieController = TextEditingController(text: '0');
  final _notesController = TextEditingController();
  String _modePaiement = 'especes';
  bool _loading = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateController.text = DateFormat('yyyy-MM-dd').format(now);
    if (widget.entryId != null) {
      _loadEntry();
    } else {
      _initialized = true;
    }
  }

  Future<void> _loadEntry() async {
    if (widget.entryId == null) return;
    setState(() => _loading = true);
    try {
      final res = await ApiService.getJournalShow(widget.entryId!);
      if (res['success'] == true && res['data'] != null) {
        final d = res['data'] as Map<String, dynamic>;
        _dateController.text = d['date']?.toString() ?? _dateController.text;
        _referenceController.text = d['reference']?.toString() ?? '';
        _libelleController.text = d['libelle']?.toString() ?? '';
        _categorieController.text = d['categorie']?.toString() ?? '';
        _modePaiement = d['mode_paiement']?.toString() ?? 'especes';
        _entreeController.text =
            (d['entree'] is num) ? (d['entree'] as num).toString() : '0';
        _sortieController.text =
            (d['sortie'] is num) ? (d['sortie'] as num).toString() : '0';
        _notesController.text = d['notes']?.toString() ?? '';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _loading = false;
        _initialized = true;
      });
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _referenceController.dispose();
    _libelleController.dispose();
    _categorieController.dispose();
    _entreeController.dispose();
    _sortieController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _toData() {
    final entree =
        double.tryParse(_entreeController.text.replaceAll(',', '.')) ?? 0.0;
    final sortie =
        double.tryParse(_sortieController.text.replaceAll(',', '.')) ?? 0.0;
    return {
      'date': _dateController.text.trim(),
      'reference': _referenceController.text.trim().isEmpty
          ? null
          : _referenceController.text.trim(),
      'libelle': _libelleController.text.trim(),
      'categorie': _categorieController.text.trim().isEmpty
          ? null
          : _categorieController.text.trim(),
      'mode_paiement': _modePaiement,
      'entree': entree,
      'sortie': sortie,
      'notes': _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    };
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final notifier = ref.read(journalProvider.notifier);
      final data = _toData();
      final ok = widget.entryId != null
          ? await notifier.updateEntry(widget.entryId!, data)
          : await notifier.createEntry(data);
      if (ok && mounted) {
        context.pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enregistrement réussi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized || (_loading && widget.entryId != null)) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
              widget.entryId != null ? 'Modifier l\'écriture' : 'Nouvelle écriture'),
          backgroundColor: Colors.teal.shade800,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.entryId != null ? 'Modifier l\'écriture' : 'Nouvelle écriture'),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: 'Date',
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate:
                      DateTime.tryParse(_dateController.text) ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate:
                      DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  _dateController.text = DateFormat('yyyy-MM-dd').format(date);
                }
              },
              validator: (v) => v == null || v.isEmpty ? 'Date requise' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _referenceController,
              decoration: const InputDecoration(
                labelText: 'Référence',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _libelleController,
              decoration: const InputDecoration(
                labelText: 'Libellé',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Libellé requis' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _categorieController,
              decoration: const InputDecoration(
                labelText: 'Catégorie',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _modePaiement,
              decoration: const InputDecoration(
                labelText: 'Mode de paiement',
                border: OutlineInputBorder(),
              ),
              items: JournalEntryModel.modePaiementValues
                  .map((v) => DropdownMenuItem(
                        value: v,
                        child: Text(JournalEntryModel.modePaiementLabel(v)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _modePaiement = v ?? 'especes'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _entreeController,
              decoration: const InputDecoration(
                labelText: 'Entrée (FCFA)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                final n = double.tryParse(v?.replaceAll(',', '.') ?? '');
                if (n == null || n < 0) return 'Montant invalide';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sortieController,
              decoration: const InputDecoration(
                labelText: 'Sortie (FCFA)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                final n = double.tryParse(v?.replaceAll(',', '.') ?? '');
                if (n == null || n < 0) return 'Montant invalide';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      widget.entryId != null ? 'Enregistrer' : 'Créer',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

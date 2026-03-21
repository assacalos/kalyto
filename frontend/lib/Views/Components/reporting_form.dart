import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/Models/reporting_model.dart';
import 'package:easyconnect/providers/reporting_notifier.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/router/app_router.dart' show rootGoRouter;
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/Views/Components/app_bar_back_button.dart';

class ReportingForm extends ConsumerStatefulWidget {
  final ReportingModel? reporting;

  const ReportingForm({super.key, this.reporting});

  @override
  ConsumerState<ReportingForm> createState() => _ReportingFormState();
}

class _ReportingFormState extends ConsumerState<ReportingForm> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  String _nature = '';
  String _moyenContact = '';
  String _typeRelance = '';
  DateTime? _relanceDateHeure;
  late TextEditingController _dateDisplayController;
  late TextEditingController _nomSocieteController;
  late TextEditingController _contactSocieteController;
  late TextEditingController _nomPersonneController;
  late TextEditingController _contactPersonneController;
  late TextEditingController _produitDemarcheController;
  late TextEditingController _commentaireController;

  @override
  void initState() {
    super.initState();
    final r = widget.reporting;
    _selectedDate = r?.reportDate ?? DateTime.now();
    _nature = r?.nature ?? '';
    _moyenContact = r?.moyenContact ?? '';
    _typeRelance = r?.typeRelance ?? '';
    _relanceDateHeure = r?.relanceDateHeure;
    _dateDisplayController = TextEditingController(text: _formatDate(_selectedDate));
    _nomSocieteController = TextEditingController(text: r?.nomSociete ?? '');
    _contactSocieteController = TextEditingController(text: r?.contactSociete ?? '');
    _nomPersonneController = TextEditingController(text: r?.nomPersonne ?? '');
    _contactPersonneController = TextEditingController(text: r?.contactPersonne ?? '');
    _produitDemarcheController = TextEditingController(text: r?.produitDemarche ?? '');
    _commentaireController = TextEditingController(text: r?.commentaire ?? '');
  }

  @override
  void dispose() {
    _dateDisplayController.dispose();
    _nomSocieteController.dispose();
    _contactSocieteController.dispose();
    _nomPersonneController.dispose();
    _contactPersonneController.dispose();
    _produitDemarcheController.dispose();
    _commentaireController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.reporting != null;

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    final notifier = ref.read(reportingProvider.notifier);
    final data = <String, dynamic>{
      'reportDate': _selectedDate,
      'nature': _nature,
      'nomSociete': _nomSocieteController.text.trim(),
      'contactSociete': _contactSocieteController.text.trim().isEmpty ? null : _contactSocieteController.text.trim(),
      'nomPersonne': _nomPersonneController.text.trim(),
      'contactPersonne': _contactPersonneController.text.trim().isEmpty ? null : _contactPersonneController.text.trim(),
      'moyenContact': _moyenContact,
      'produitDemarche': _produitDemarcheController.text.trim().isEmpty ? null : _produitDemarcheController.text.trim(),
      'commentaire': _commentaireController.text.trim().isEmpty ? null : _commentaireController.text.trim(),
      'typeRelance': _typeRelance.isEmpty ? null : _typeRelance,
      'relanceDateHeure': _relanceDateHeure,
    };
    try {
      if (_isEditing) {
        await notifier.updateReport(widget.reporting!.id, data);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rapport mis à jour avec succès')));
        rootGoRouter?.go('/reporting');
      } else {
        await notifier.createReport(data);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rapport créé avec succès')));
        rootGoRouter?.go('/reporting');
      }
    } catch (e) {
      if (!mounted) return;
      String msg = 'Erreur lors de la création du rapport';
      if (_isEditing) msg = 'Erreur lors de la mise à jour du rapport';
      if (e.toString().contains('Erreur de format') || e.toString().contains('format')) {
        msg = 'Erreur de format des données. Vérifiez que tous les champs sont correctement remplis.';
      } else if (e.toString().isNotEmpty) {
        msg = e.toString().replaceFirst('Exception: ', '');
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 5)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportingProvider);
    final userRole = ref.watch(authProvider).user?.role;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBarBackButton(fallbackRoute: '/reporting', iconColor: Colors.white),
        title: Text(_isEditing ? 'Modifier le rapport' : 'Nouveau Rapport'),
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
              _buildGeneralCard(),
              const SizedBox(height: 16),
              _buildNatureCard(userRole),
              const SizedBox(height: 16),
              _buildSocieteCard(),
              const SizedBox(height: 16),
              _buildPersonneCard(),
              const SizedBox(height: 16),
              _buildMoyenContactCard(),
              const SizedBox(height: 16),
              _buildDetailsCard(),
              const SizedBox(height: 16),
              _buildRelanceCard(userRole),
              const SizedBox(height: 24),
              _buildActions(state.isLoading),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informations Générales', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Date du rapport', border: OutlineInputBorder()),
              readOnly: true,
              controller: _dateDisplayController,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                    _dateDisplayController.text = _formatDate(_selectedDate);
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNatureCard(int? userRole) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nature du Reporting', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Nature', border: OutlineInputBorder()),
              value: _nature.isEmpty ? null : _nature,
              items: _getNatureOptions(userRole).map((o) => DropdownMenuItem(value: o['value']!, child: Text(o['label']!))).toList(),
              onChanged: (v) => setState(() => _nature = v ?? ''),
              validator: (v) => (v == null || v.isEmpty) ? 'Veuillez sélectionner une nature' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocieteCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informations Société', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nomSocieteController,
              decoration: const InputDecoration(labelText: 'Nom de la société', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.isEmpty) ? 'Veuillez saisir le nom de la société' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactSocieteController,
              decoration: const InputDecoration(labelText: 'Contact société', border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonneCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informations Personne', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nomPersonneController,
              decoration: const InputDecoration(labelText: 'Nom de la personne de l\'échange', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.isEmpty) ? 'Veuillez saisir le nom de la personne' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactPersonneController,
              decoration: const InputDecoration(labelText: 'Contact de la personne', border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoyenContactCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Moyen de Contact', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Moyen utilisé', border: OutlineInputBorder()),
              value: _moyenContact.isEmpty ? null : _moyenContact,
              items: const [
                DropdownMenuItem(value: 'mail', child: Text('Mail')),
                DropdownMenuItem(value: 'whatsapp', child: Text('WhatsApp')),
                DropdownMenuItem(value: 'linkedin', child: Text('LinkedIn')),
              ],
              onChanged: (v) => setState(() => _moyenContact = v ?? ''),
              validator: (v) => (v == null || v.isEmpty) ? 'Veuillez sélectionner un moyen de contact' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Détails', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _produitDemarcheController,
              decoration: const InputDecoration(labelText: 'Produit démarche', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _commentaireController,
              decoration: const InputDecoration(labelText: 'Commentaire', border: OutlineInputBorder()),
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelanceCard(int? userRole) {
    final label = _typeRelance.isEmpty
        ? null
        : _typeRelance == 'relance_rdv'
            ? 'Date et heure du RDV (rappel)'
            : _typeRelance == 'relance_telephonique'
                ? 'Date et heure de rappel (relance téléphonique)'
                : 'Date et heure de rappel (relance mail)';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userRole == Roles.TECHNICIEN ? 'Relance RDV (rappel)' : 'Relance',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: userRole == Roles.TECHNICIEN ? 'Relance par RDV (rappel)' : 'Type de relance',
                border: const OutlineInputBorder(),
              ),
              value: _typeRelance.isEmpty ? null : _typeRelance,
              items: _getRelanceOptions(userRole).map((o) => DropdownMenuItem(value: o['value']!, child: Text(o['label']!))).toList(),
              onChanged: (v) => setState(() => _typeRelance = v ?? ''),
            ),
            if (label != null) ...[
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
                readOnly: true,
                controller: TextEditingController(
                  text: _relanceDateHeure != null
                      ? '${_relanceDateHeure!.year}-${_relanceDateHeure!.month.toString().padLeft(2, '0')}-${_relanceDateHeure!.day.toString().padLeft(2, '0')} ${_relanceDateHeure!.hour.toString().padLeft(2, '0')}:${_relanceDateHeure!.minute.toString().padLeft(2, '0')}'
                      : '',
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                    if (time != null) setState(() => _relanceDateHeure = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActions(bool isLoading) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey, foregroundColor: Colors.white),
            child: const Text('Annuler'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
            child: isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(_isEditing ? 'Enregistrer' : 'Créer le Rapport'),
          ),
        ),
      ],
    );
  }

  List<Map<String, String>> _getNatureOptions(int? userRole) {
    if (userRole == Roles.COMMERCIAL) {
      return [
        {'value': 'echange_telephonique', 'label': 'Échange téléphonique'},
        {'value': 'visite', 'label': 'Visite'},
      ];
    }
    if (userRole == Roles.TECHNICIEN) {
      return [
        {'value': 'depannage_visite', 'label': 'Dépannage visite'},
        {'value': 'depannage_bureau', 'label': 'Dépannage bureau'},
        {'value': 'depannage_telephonique', 'label': 'Dépannage téléphonique'},
        {'value': 'programmation', 'label': 'Programmation'},
      ];
    }
    return [];
  }

  List<Map<String, String>> _getRelanceOptions(int? userRole) {
    if (userRole == Roles.TECHNICIEN) {
      return [{'value': 'relance_rdv', 'label': 'Relance par RDV (rappel)'}];
    }
    return [
      {'value': 'relance_telephonique', 'label': 'Relance téléphonique'},
      {'value': 'relance_mail', 'label': 'Relance par mail'},
      {'value': 'relance_rdv', 'label': 'Relance par RDV'},
    ];
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

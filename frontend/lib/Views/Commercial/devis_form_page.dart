import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/devis_notifier.dart';
import 'package:easyconnect/Models/devis_model.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';
import 'package:easyconnect/Views/Components/app_bar_back_button.dart';
import 'package:easyconnect/utils/tva_rates_ci.dart';

class DevisFormPage extends ConsumerStatefulWidget {
  final bool isEditing;
  final int? devisId;

  const DevisFormPage({super.key, this.isEditing = false, this.devisId});

  @override
  ConsumerState<DevisFormPage> createState() => _DevisFormPageState();
}

class _DevisFormPageState extends ConsumerState<DevisFormPage> {
  final formatCurrency = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA ');
  final formatDate = DateFormat('dd/MM/yyyy');

  late final TextEditingController referenceController;
  late final TextEditingController notesController;
  late final TextEditingController conditionsController;
  late final TextEditingController remiseGlobaleController;
  late final TextEditingController dateValiditeController;
  double _selectedTvaRate = tvaRateCiDefault;
  late final TextEditingController titreController;
  late final TextEditingController delaiLivraisonController;
  late final TextEditingController garantieController;

  @override
  void initState() {
    super.initState();
    referenceController = TextEditingController();
    notesController = TextEditingController();
    conditionsController = TextEditingController();
    remiseGlobaleController = TextEditingController();
    dateValiditeController = TextEditingController();
    titreController = TextEditingController();
    delaiLivraisonController = TextEditingController();
    garantieController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(devisProvider.notifier);
      notifier.loadValidatedClients();
      if (!widget.isEditing) {
        notifier.initializeGeneratedReference();
      }
      if (widget.isEditing && widget.devisId != null) {
        final devisList = ref.read(devisProvider).devis.where((d) => d.id == widget.devisId).toList();
        if (devisList.isNotEmpty) {
          final devis = devisList.first;
          referenceController.text = devis.reference;
          notesController.text = devis.notes ?? '';
          conditionsController.text = devis.conditions ?? '';
          remiseGlobaleController.text = devis.remiseGlobale?.toString() ?? '';
          _selectedTvaRate = clampTvaRateCi(devis.tva ?? tvaRateCiDefault);
          titreController.text = devis.titre ?? '';
          delaiLivraisonController.text = devis.delaiLivraison ?? '';
          garantieController.text = devis.garantie ?? '';
          if (devis.dateValidite != null) {
            dateValiditeController.text = formatDate.format(devis.dateValidite!);
          }
          notifier.clearItems();
          for (final item in devis.items) {
            notifier.addItem(item);
          }
          final clients = ref.read(devisProvider).clients;
          if (clients.isNotEmpty) {
            final clientList = clients.where((c) => c.id == devis.clientId).toList();
            if (clientList.isNotEmpty) notifier.selectClient(clientList.first);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    referenceController.dispose();
    notesController.dispose();
    conditionsController.dispose();
    remiseGlobaleController.dispose();
    dateValiditeController.dispose();
    titreController.dispose();
    delaiLivraisonController.dispose();
    garantieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBarBackButton(fallbackRoute: '/devis'),
        title: Text(widget.isEditing ? 'Modifier le devis' : 'Nouveau devis'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildClientSection(ref),
            const SizedBox(height: 16),
            _buildInformationsGenerales(ref),
            const SizedBox(height: 16),
            _buildArticlesSection(ref),
            const SizedBox(height: 16),
            _buildTotauxSection(ref),
            const SizedBox(height: 16),
            _buildNotesConditionsSection(),
            const SizedBox(height: 24),
            _buildSaveButton(ref),
          ],
        ),
      ),
    );
  }

  Widget _buildClientSection(WidgetRef ref) {
    final devisState = ref.watch(devisProvider);
    final devisNotifier = ref.read(devisProvider.notifier);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Client',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final selectedClient = devisState.selectedClient;
                if (selectedClient == null) {
                return ElevatedButton.icon(
                  icon: const Icon(Icons.person_add),
                  label: const Text('Sélectionner un client'),
                  onPressed: _showClientSearchDialog,
                );
              }
              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    (selectedClient.nomEntreprise?.isNotEmpty == true
                                ? selectedClient.nomEntreprise
                                : selectedClient.nom)
                            ?.substring(0, 1)
                            .toUpperCase() ??
                        '',
                  ),
                ),
                title: Text(
                  selectedClient.nomEntreprise?.isNotEmpty == true
                      ? selectedClient.nomEntreprise!
                      : selectedClient.nom ?? '',
                ),
                subtitle: Text(selectedClient.email ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: devisNotifier.clearSelectedClient,
                ),
              );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInformationsGenerales(WidgetRef ref) {
    final devisState = ref.watch(devisProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations générales',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final generatedRef = devisState.generatedReference;
                if (generatedRef.isNotEmpty &&
                    referenceController.text != generatedRef) {
                  referenceController.text = generatedRef;
                }
                return TextFormField(
                  controller: referenceController,
                  decoration: const InputDecoration(
                    labelText: 'Référence (générée automatiquement)',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey,
                    helperText: 'Référence générée automatiquement',
                  ),
                  readOnly: true,
                  enabled: false,
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: dateValiditeController,
              decoration: InputDecoration(
                labelText: 'Date de validité',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      dateValiditeController.text = formatDate.format(date);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: titreController,
              decoration: const InputDecoration(
                labelText: 'Titre du devis',
                border: OutlineInputBorder(),
                hintText: 'Ex: Devis pour installation système',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: delaiLivraisonController,
              decoration: const InputDecoration(
                labelText: 'Délai de livraison',
                border: OutlineInputBorder(),
                hintText: 'Ex: 15 jours ouvrables',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: garantieController,
              decoration: const InputDecoration(
                labelText: 'Garantie',
                border: OutlineInputBorder(),
                hintText: 'Ex: 1 an pièces et main d\'œuvre',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticlesSection(WidgetRef ref) {
    final devisState = ref.watch(devisProvider);
    final devisNotifier = ref.read(devisProvider.notifier);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Articles',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter un article'),
                  onPressed: () => _showItemDialog(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            devisState.items.isEmpty
                ? const Center(
                    child: Text(
                      'Aucun article ajouté',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: devisState.items.length,
                    itemBuilder: (context, index) {
                      final item = devisState.items[index];
                      return Card(
                        child: ListTile(
                          title: Text(item.designation),
                          subtitle: Text(
                            (item.reference != null && item.reference!.isNotEmpty
                                    ? '${item.reference!} • '
                                    : '') +
                                '${item.quantite} x ${formatCurrency.format(item.prixUnitaire)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                formatCurrency.format(item.total),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed:
                                    () => _showItemDialog(index: index, item: item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => devisNotifier.removeItem(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotauxSection(WidgetRef ref) {
    final devisState = ref.watch(devisProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Totaux',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: remiseGlobaleController,
                    decoration: const InputDecoration(
                      labelText: 'Remise globale (%)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<double>(
                    value: tvaRatesCiValues.contains(_selectedTvaRate)
                        ? _selectedTvaRate
                        : tvaRateCiDefault,
                    decoration: const InputDecoration(
                      labelText: 'TVA (Côte d\'Ivoire)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: tvaRatesCi
                        .map((e) => DropdownMenuItem<double>(
                              value: e.rate,
                              child: Text(e.label),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedTvaRate = value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final devis = Devis(
                  clientId: devisState.selectedClient?.id ?? 0,
                  reference: referenceController.text,
                  dateCreation: DateTime.now(),
                  items: devisState.items,
                  remiseGlobale:
                      double.tryParse(remiseGlobaleController.text) ?? 0,
                  tva: _selectedTvaRate,
                  commercialId: 0,
                );
                return Column(
                  children: [
                    _buildTotalRow('Sous-total', devis.sousTotal),
                    if (devis.remise > 0)
                      _buildTotalRow('Remise', -devis.remise, color: Colors.red),
                    _buildTotalRow('Total HT', devis.totalHT, bold: true),
                    if (devis.montantTVA > 0)
                      _buildTotalRow('TVA', devis.montantTVA),
                    _buildTotalRow(
                      'Total TTC',
                      devis.totalTTC,
                      bold: true,
                      large: true,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesConditionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notes et conditions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: conditionsController,
              decoration: const InputDecoration(
                labelText: 'Conditions',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    double montant, {
    bool bold = false,
    bool large = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: large ? 18 : 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            formatCurrency.format(montant),
            style: TextStyle(
              fontSize: large ? 18 : 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showClientSearchDialog() {
    final devisState = ref.read(devisProvider);
    final devisNotifier = ref.read(devisProvider.notifier);
    if (devisState.clients.isEmpty) {
      devisNotifier.loadValidatedClients();
    }
    final searchController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sélectionner un client'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Rechercher un client',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => devisNotifier.searchClients(value),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              width: double.maxFinite,
              child: Consumer(
                builder: (context, ref, _) {
                  final state = ref.watch(devisProvider);
                  if (state.isLoadingClients) {
                    return const SkeletonSearchResults(itemCount: 4);
                  }
                  if (state.clients.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Aucun client validé trouvé',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Veuillez d\'abord créer et valider des clients',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: state.clients.length,
                    itemBuilder: (context, index) {
                      final client = state.clients[index];
                      return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.shade100,
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.green.shade600,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        client.nomEntreprise?.isNotEmpty == true
                            ? client.nomEntreprise!
                            : client.nom ?? '',
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (client.nomEntreprise?.isNotEmpty == true &&
                              client.nom?.isNotEmpty == true)
                            Text(
                              'Contact: ${client.nom}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          Text(client.email ?? ''),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Validé',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        devisNotifier.selectClient(client);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                );
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/clients/new');
            },
            child: const Text('Nouveau client'),
          ),
        ],
      ),
    );
  }

  void _showItemDialog({int? index, DevisItem? item}) {
    final devisNotifier = ref.read(devisProvider.notifier);
    final referenceController = TextEditingController(
      text: item?.reference ?? '',
    );
    final designationController = TextEditingController(
      text: item?.designation ?? '',
    );
    final quantiteController = TextEditingController(
      text: item?.quantite.toString() ?? '',
    );
    final prixUnitaireController = TextEditingController(
      text: item?.prixUnitaire.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item == null ? 'Nouvel article' : 'Modifier l\'article'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: referenceController,
              decoration: const InputDecoration(
                labelText: 'Référence article',
                border: OutlineInputBorder(),
                hintText: 'Ex: REF-001',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: designationController,
              decoration: const InputDecoration(
                labelText: 'Désignation',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: quantiteController,
                    decoration: const InputDecoration(
                      labelText: 'Quantité',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: prixUnitaireController,
                    decoration: const InputDecoration(
                      labelText: 'Prix unitaire',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              final ref = referenceController.text.trim();
              final newItem = DevisItem(
                id: item?.id,
                reference: ref.isEmpty ? null : ref,
                designation: designationController.text,
                quantite: int.tryParse(quantiteController.text) ?? 0,
                prixUnitaire: double.tryParse(prixUnitaireController.text) ?? 0,
              );
              if (index != null) {
                devisNotifier.updateItem(index, newItem);
              } else {
                devisNotifier.addItem(newItem);
              }
              Navigator.of(context).pop();
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  /// Effacer tous les champs du formulaire
  void _clearForm() {
    referenceController.clear();
    notesController.clear();
    conditionsController.clear();
    remiseGlobaleController.clear();
    _selectedTvaRate = tvaRateCiDefault;
    dateValiditeController.clear();
    titreController.clear();
    delaiLivraisonController.clear();
    garantieController.clear();
    ref.read(devisProvider.notifier).clearForm();
  }

  Widget _buildSaveButton(WidgetRef ref) {
    final devisState = ref.watch(devisProvider);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: devisState.isLoading ? null : _saveDevis,
        icon: devisState.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.save),
        label: Text(
          devisState.isLoading ? 'Enregistrement...' : (widget.isEditing ? 'Modifier le devis' : 'Créer le devis'),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  void _saveDevis() async {
    final devisState = ref.read(devisProvider);
    final devisNotifier = ref.read(devisProvider.notifier);
    print('💾 [DEVIS FORM] Début de la sauvegarde du devis');
    print('💾 [DEVIS FORM] Mode édition: ${widget.isEditing}');
    print('💾 [DEVIS FORM] Devis ID: ${widget.devisId}');

    if (devisState.selectedClient == null) {
      print('❌ [DEVIS FORM] Aucun client sélectionné');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un client')),
      );
      return;
    }
    print(
      '✅ [DEVIS FORM] Client sélectionné: ${devisState.selectedClient?.id} - ${devisState.selectedClient?.nom}',
    );

    if (devisState.items.isEmpty) {
      print('❌ [DEVIS FORM] Aucun article ajouté');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez ajouter au moins un article')),
      );
      return;
    }
    print('✅ [DEVIS FORM] Nombre d\'articles: ${devisState.items.length}');

    // Utiliser la référence générée si disponible, sinon celle saisie
    final reference =
        devisState.generatedReference.isNotEmpty
            ? devisState.generatedReference
            : referenceController.text;

    print(
      '💾 [DEVIS FORM] Référence générée: ${devisState.generatedReference}',
    );
    print('💾 [DEVIS FORM] Référence saisie: ${referenceController.text}');
    print('💾 [DEVIS FORM] Référence finale: $reference');

    if (reference.isEmpty) {
      print('❌ [DEVIS FORM] Référence vide');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir une référence')),
      );
      return;
    }

    final data = {
      'reference': reference,
      'date_validite':
          dateValiditeController.text.isNotEmpty
              ? DateFormat('dd/MM/yyyy').parse(dateValiditeController.text)
              : null,
      'notes': notesController.text,
      'conditions': conditionsController.text,
      'remise_globale': double.tryParse(remiseGlobaleController.text),
      'tva': _selectedTvaRate,
      'titre': titreController.text,
      'delai_livraison': delaiLivraisonController.text,
      'garantie': garantieController.text,
    };

    print('💾 [DEVIS FORM] Données préparées:');
    print('💾 [DEVIS FORM] - reference: ${data['reference']}');
    print('💾 [DEVIS FORM] - date_validite: ${data['date_validite']}');
    print('💾 [DEVIS FORM] - notes: ${data['notes']}');
    print('💾 [DEVIS FORM] - conditions: ${data['conditions']}');
    print('💾 [DEVIS FORM] - remise_globale: ${data['remise_globale']}');
    print('💾 [DEVIS FORM] - tva: ${data['tva']}');

    if (widget.isEditing && widget.devisId != null) {
      print('💾 [DEVIS FORM] Mise à jour du devis ${widget.devisId}');
      final success = await devisNotifier.updateDevis(widget.devisId!, data);
      if (success) {
        print('✅ [DEVIS FORM] Devis mis à jour avec succès');
        _clearForm();
        context.go('/devis');
      } else {
        print('❌ [DEVIS FORM] Échec de la mise à jour');
      }
    } else {
      print('💾 [DEVIS FORM] Création d\'un nouveau devis');
      try {
        final success = await devisNotifier.createDevis(data);
        if (success) {
          print('✅ [DEVIS FORM] Devis créé avec succès');
          _clearForm();
          context.go('/devis');
        } else {
          print(
            '❌ [DEVIS FORM] Échec de la création - createDevis a retourné false',
          );
          // Le message d'erreur est déjà affiché par le contrôleur
        }
      } catch (e, stackTrace) {
        print('❌ [DEVIS FORM] Exception lors de la création: $e');
        print('❌ [DEVIS FORM] Stack trace: $stackTrace');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Une erreur inattendue s\'est produite: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}

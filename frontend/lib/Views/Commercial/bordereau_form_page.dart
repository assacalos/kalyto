import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/bordereau_notifier.dart';
import 'package:easyconnect/providers/bordereau_state.dart';
import 'package:easyconnect/Models/bordereau_model.dart';
import 'package:easyconnect/Views/Components/devis_selection_dialog.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';
import 'package:easyconnect/Views/Components/app_bar_back_button.dart';

class BordereauFormPage extends ConsumerStatefulWidget {
  final bool isEditing;
  final int? bordereauId;

  const BordereauFormPage({
    super.key,
    this.isEditing = false,
    this.bordereauId,
  });

  @override
  ConsumerState<BordereauFormPage> createState() => _BordereauFormPageState();
}

class _BordereauFormPageState extends ConsumerState<BordereauFormPage> {

  // Contrôleurs de formulaire
  late final TextEditingController referenceController;
  late final TextEditingController notesController;
  late final TextEditingController titreController;
  late final TextEditingController garantieController;
  String? _etatLivraison;
  DateTime? _dateLivraison;

  final formKey = GlobalKey<FormState>();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Toujours réinitialiser les contrôleurs pour avoir des champs vides
    referenceController = TextEditingController();
    notesController = TextEditingController();
    titreController = TextEditingController();
    garantieController = TextEditingController();

    if (!widget.isEditing) {
      ref.read(bordereauProvider.notifier).clearForm();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bordereauProvider.notifier).loadValidatedClients();
    });
  }

  @override
  void dispose() {
    referenceController.dispose();
    notesController.dispose();
    titreController.dispose();
    garantieController.dispose();
    super.dispose();
  }

  void _initializeFormIfNeeded() {
    if (!_isInitialized && widget.isEditing && widget.bordereauId != null) {
      final bordereaux = ref.read(bordereauProvider).bordereaux;
      final bordereauList = bordereaux.where((b) => b.id == widget.bordereauId).toList();
      if (bordereauList.isEmpty) return;
      final bordereau = bordereauList.first;
      referenceController.text = bordereau.reference;
      notesController.text = bordereau.notes ?? '';
      titreController.text = bordereau.titre ?? '';
      garantieController.text = bordereau.garantie ?? '';
      _etatLivraison = bordereau.etatLivraison;
      _dateLivraison = bordereau.dateLivraison;
      final notifier = ref.read(bordereauProvider.notifier);
      notifier.clearItems();
      for (final item in bordereau.items) {
        notifier.addItem(item);
      }
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    _initializeFormIfNeeded();
    final state = ref.watch(bordereauProvider);
    final notifier = ref.read(bordereauProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBarBackButton(fallbackRoute: '/bordereaux'),
        title: Text(
          widget.isEditing ? 'Modifier le bordereau' : 'Nouveau bordereau',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sélection du client
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Client',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green),
                            ),
                            child: const Text(
                              'Validés uniquement',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      state.selectedClient != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.selectedClient!.nomEntreprise?.isNotEmpty == true
                                      ? state.selectedClient!.nomEntreprise!
                                      : '${state.selectedClient!.nom ?? ''} ${state.selectedClient!.prenom ?? ''}'
                                          .trim()
                                          .isNotEmpty
                                      ? '${state.selectedClient!.nom ?? ''} ${state.selectedClient!.prenom ?? ''}'
                                          .trim()
                                      : 'Client #${state.selectedClient!.id}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (state.selectedClient!.nomEntreprise?.isNotEmpty == true &&
                                    '${state.selectedClient!.nom ?? ''} ${state.selectedClient!.prenom ?? ''}'
                                        .trim()
                                        .isNotEmpty)
                                  Text(
                                    'Contact: ${state.selectedClient!.nom ?? ''} ${state.selectedClient!.prenom ?? ''}'
                                        .trim(),
                                  ),
                                if (state.selectedClient!.email != null)
                                  Text(state.selectedClient!.email ?? ''),
                                if (state.selectedClient!.contact != null)
                                  Text(state.selectedClient!.contact ?? ''),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: notifier.clearSelectedClient,
                                  child: const Text('Changer de client'),
                                ),
                              ],
                            )
                          : ElevatedButton(
                              onPressed: () => _showClientSelection(context),
                              child: const Text('Sélectionner un client'),
                            ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Section Devis
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Devis',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue),
                            ),
                            child: const Text(
                              'Validés uniquement',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          state.selectedClient == null
                              ? const Text(
                                  'Sélectionnez d\'abord un client',
                                  style: TextStyle(color: Colors.grey),
                                )
                              : ElevatedButton.icon(
                                  onPressed:
                                      state.availableDevis.isEmpty
                                          ? null
                                          : () => _showDevisSelection(context),
                                  icon: const Icon(Icons.description, size: 16),
                                  label: const Text('Sélectionner'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      state.selectedDevis != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Devis ${state.selectedDevis!.reference + ' -B'}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Date: ${DateFormat('dd/MM/yyyy').format(state.selectedDevis!.dateCreation)}',
                                ),
                                Text('Articles: ${state.selectedDevis!.items.length}'),
                                Text(
                                  'Total HT: ${state.selectedDevis!.totalHT.toStringAsFixed(2)} FCFA',
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: notifier.clearSelectedDevis,
                                  child: const Text('Changer de devis'),
                                ),
                              ],
                            )
                          : const Text(
                              'Aucun devis sélectionné',
                              style: TextStyle(color: Colors.grey),
                            ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Informations générales
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informations générales',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      state.selectedDevis != null
                          ? Builder(
                              builder: (context) {
                                final genRef = state.generatedReference;
                                if (genRef.isNotEmpty && referenceController.text != genRef) {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    referenceController.text = genRef;
                                  });
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
                                  validator: (value) {
                                    final refValue =
                                        (value == null || value.isEmpty)
                                            ? state.generatedReference
                                            : value;
                                    if (refValue.isEmpty) return 'La référence est requise';
                                    return null;
                                  },
                                );
                              },
                            )
                          : TextFormField(
                              controller: referenceController,
                              decoration: const InputDecoration(
                                labelText: 'Référence',
                                border: OutlineInputBorder(),
                                helperText:
                                    'Saisissez une référence ou sélectionnez un devis',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'La référence est requise';
                                }
                                return null;
                              },
                            ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: titreController,
                        decoration: const InputDecoration(
                          labelText: 'Titre du bordereau',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _etatLivraison,
                        decoration: const InputDecoration(
                          labelText: 'État de livraison',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('-- Non renseigné --')),
                          DropdownMenuItem(value: 'en_attente', child: Text('En attente')),
                          DropdownMenuItem(value: 'en_cours', child: Text('En cours')),
                          DropdownMenuItem(value: 'livre', child: Text('Livré')),
                          DropdownMenuItem(value: 'partiel', child: Text('Partiel')),
                        ],
                        onChanged: (value) => setState(() => _etatLivraison = value),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: garantieController,
                        decoration: const InputDecoration(
                          labelText: 'Garantie',
                          border: OutlineInputBorder(),
                          hintText: 'Ex: 12 mois',
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Date de livraison'),
                        subtitle: Text(
                          _dateLivraison != null
                              ? DateFormat('dd/MM/yyyy').format(_dateLivraison!)
                              : 'Non renseignée',
                        ),
                        trailing: TextButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _dateLivraison ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) setState(() => _dateLivraison = picked);
                          },
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: Text(_dateLivraison == null ? 'Choisir' : 'Modifier'),
                        ),
                      ),
                      if (_dateLivraison != null)
                        TextButton(
                          onPressed: () => setState(() => _dateLivraison = null),
                          child: const Text('Effacer la date'),
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Liste des items
              Card(
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
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _showItemForm(context, notifier: notifier),
                            icon: const Icon(Icons.add),
                            label: const Text('Ajouter'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      state.items.isEmpty
                          ? const Center(
                              child: Text('Aucun article ajouté'),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: state.items.length,
                              itemBuilder: (context, index) {
                                final item = state.items[index];
                                return _buildItemCard(item, index, notifier);
                              },
                            ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildSaveButton(context, formKey, state, notifier),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context, GlobalKey<FormState> formKey, BordereauState state, BordereauNotifier notifier) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: state.isLoading
            ? null
            : () async {
          if (formKey.currentState!.validate()) {
            if (state.selectedClient == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Veuillez sélectionner un client validé'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            if (state.selectedClient!.status != 1) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Seuls les clients validés peuvent être sélectionnés'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            if (state.selectedDevis == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Veuillez sélectionner un devis validé'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            if (state.selectedDevis!.status != 2) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Seuls les devis validés peuvent être utilisés'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            if (state.items.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Veuillez ajouter au moins un article'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            final reference =
                state.generatedReference.isNotEmpty
                    ? state.generatedReference
                    : referenceController.text.trim();
            if (reference.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('La référence est requise'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            final data = {
              'reference': reference,
              'notes': notesController.text,
              'titre': titreController.text.trim().isEmpty ? null : titreController.text.trim(),
              'etat_livraison': _etatLivraison,
              'garantie': garantieController.text.trim().isEmpty ? null : garantieController.text.trim(),
              'date_livraison': _dateLivraison?.toIso8601String(),
            };
            if (widget.isEditing && widget.bordereauId != null) {
              try {
                final success = await notifier.updateBordereau(widget.bordereauId!, data);
                if (success && context.mounted) context.go('/bordereaux');
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            } else {
              try {
                final success = await notifier.createBordereau(data);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bordereau créé avec succès'), backgroundColor: Colors.green),
                  );
                  context.go('/bordereaux');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            }
          }
        },
        icon: state.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.save),
        label: Text(state.isLoading ? 'Enregistrement...' : (widget.isEditing ? 'Modifier le bordereau' : 'Enregistrer')),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildItemCard(BordereauItem item, int index, BordereauNotifier notifier) {
    return Card(
      child: ListTile(
        title: Text(item.designation),
        subtitle: Text(
          (item.reference != null && item.reference!.isNotEmpty
              ? '${item.reference!} • '
              : '') +
              '${item.quantite} ${item.unite}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed:
                  () => _showItemForm(context, item: item, index: index, notifier: notifier),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => notifier.removeItem(index),
            ),
          ],
        ),
      ),
    );
  }

  void _showClientSelection(BuildContext context) {
    final notifier = ref.read(bordereauProvider.notifier);
    if (ref.read(bordereauProvider).clients.isEmpty) {
      notifier.loadValidatedClients();
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(bordereauProvider);
          return AlertDialog(
            title: const Text('Sélectionner un client'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: state.isLoadingClients
                  ? const SkeletonSearchResults(itemCount: 4)
                  : state.clients.isEmpty
                      ? const Center(
                          child: Text('Aucun client validé disponible'),
                        )
                      : ListView.builder(
                          itemCount: state.clients.length,
                          itemBuilder: (context, index) {
                            final client = state.clients[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: client.statusColor,
                                  child: Icon(client.statusIcon, color: Colors.white),
                                ),
                                title: Text(
                                  client.nomEntreprise?.isNotEmpty == true
                                      ? client.nomEntreprise!
                                      : '${client.nom ?? ''} ${client.prenom ?? ''}'
                                          .trim()
                                          .isNotEmpty
                                      ? '${client.nom ?? ''} ${client.prenom ?? ''}'
                                          .trim()
                                      : 'Client #${client.id}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (client.nomEntreprise?.isNotEmpty == true &&
                                        '${client.nom ?? ''} ${client.prenom ?? ''}'
                                            .trim()
                                            .isNotEmpty)
                                      Text(
                                        'Contact: ${client.nom ?? ''} ${client.prenom ?? ''}'
                                            .trim(),
                                      ),
                                    if (client.email != null)
                                      Text('Email: ${client.email}'),
                                    if (client.contact != null)
                                      Text('Contact: ${client.contact}'),
                                    Text(
                                      'Statut: ${client.statusText}',
                                      style: TextStyle(
                                        color: client.statusColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  notifier.selectClient(client);
                                  Navigator.of(ctx).pop();
                                },
                              ),
                            );
                          },
                        ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Annuler'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showItemForm(BuildContext context, {BordereauItem? item, int? index, required BordereauNotifier notifier}) {
    final formKey = GlobalKey<FormState>();
    final referenceController = TextEditingController(
      text: item?.reference ?? '',
    );
    final designationController = TextEditingController(
      text: item?.designation,
    );
    final uniteController = TextEditingController(text: item?.unite);
    final quantiteController = TextEditingController(
      text: item?.quantite.toString(),
    );
    final descriptionController = TextEditingController(
      text: item?.description,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              item == null ? 'Ajouter un article' : 'Modifier l\'article',
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: referenceController,
                      decoration: const InputDecoration(
                        labelText: 'Référence article',
                        hintText: 'Ex: REF-001',
                      ),
                    ),
                    TextFormField(
                      controller: designationController,
                      decoration: const InputDecoration(
                        labelText: 'Désignation',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'La désignation est requise';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: uniteController,
                      decoration: const InputDecoration(labelText: 'Unité'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'L\'unité est requise';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: quantiteController,
                      decoration: const InputDecoration(labelText: 'Quantité'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'La quantité est requise';
                        }
                        if (int.tryParse(value) == null) {
                          return 'La quantité doit être un nombre';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    final ref = referenceController.text.trim();
                    final newItem = BordereauItem(
                      id: item?.id,
                      reference: ref.isEmpty ? null : ref,
                      designation: designationController.text,
                      unite: uniteController.text,
                      quantite: int.parse(quantiteController.text),
                      description: descriptionController.text.isEmpty ? null : descriptionController.text,
                    );
                    if (index != null) {
                      notifier.updateItem(index, newItem);
                    } else {
                      notifier.addItem(newItem);
                    }
                    Navigator.of(context).pop();
                  }
                },
                child: Text(item == null ? 'Ajouter' : 'Modifier'),
              ),
            ],
          ),
    );
  }

  void _showDevisSelection(BuildContext context) {
    final state = ref.read(bordereauProvider);
    showDialog<void>(
      context: context,
      builder: (ctx) => DevisSelectionDialog(
        devis: state.availableDevis,
        isLoading: state.isLoadingDevis,
        onDevisSelected: (devis) async {
          await ref.read(bordereauProvider.notifier).selectDevis(devis);
        },
      ),
    );
  }
}

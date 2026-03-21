import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/bon_de_commande_fournisseur_notifier.dart';
import 'package:easyconnect/Models/bon_de_commande_fournisseur_model.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';

class BonDeCommandeFournisseurFormPage extends ConsumerStatefulWidget {
  final bool isEditing;
  final int? bonDeCommandeId;

  const BonDeCommandeFournisseurFormPage({
    super.key,
    this.isEditing = false,
    this.bonDeCommandeId,
  });

  @override
  ConsumerState<BonDeCommandeFournisseurFormPage> createState() =>
      _BonDeCommandeFournisseurFormPageState();
}

class _BonDeCommandeFournisseurFormPageState
    extends ConsumerState<BonDeCommandeFournisseurFormPage> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController numeroCommandeController;
  late final TextEditingController descriptionController;
  late final TextEditingController commentaireController;
  late final TextEditingController conditionsPaiementController;
  late final TextEditingController delaiLivraisonController;

  @override
  void initState() {
    super.initState();
    numeroCommandeController = TextEditingController();
    descriptionController = TextEditingController();
    commentaireController = TextEditingController();
    conditionsPaiementController = TextEditingController();
    delaiLivraisonController = TextEditingController();

    if (!widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(bonDeCommandeFournisseurProvider.notifier).clearForm();
        ref
            .read(bonDeCommandeFournisseurProvider.notifier)
            .initializeGeneratedNumeroCommande();
      });
    }

    if (widget.isEditing && widget.bonDeCommandeId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(bonDeCommandeFournisseurProvider.notifier)
            .loadBonDeCommandes()
            .then((_) => _loadBonDeCommandeData());
      });
    }
  }

  void _loadBonDeCommandeData() {
    final state = ref.read(bonDeCommandeFournisseurProvider);
    final notifier = ref.read(bonDeCommandeFournisseurProvider.notifier);
    try {
      final bonDeCommande = state.bonDeCommandes
          .firstWhere((b) => b.id == widget.bonDeCommandeId);
      numeroCommandeController.text = bonDeCommande.numeroCommande;
      descriptionController.text = bonDeCommande.description ?? '';
      commentaireController.text = bonDeCommande.commentaire ?? '';
      conditionsPaiementController.text =
          bonDeCommande.conditionsPaiement ?? '';
      delaiLivraisonController.text =
          bonDeCommande.delaiLivraison?.toString() ?? '';
      notifier.setItems(bonDeCommande.items);
      notifier.selectSupplier(null);
    } catch (e) {
      // Le bon de commande n'est pas encore chargé
    }
  }

  @override
  void dispose() {
    numeroCommandeController.dispose();
    descriptionController.dispose();
    commentaireController.dispose();
    conditionsPaiementController.dispose();
    delaiLivraisonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bonDeCommandeFournisseurProvider);
    final notifier = ref.read(bonDeCommandeFournisseurProvider.notifier);

    // Sync generated number to field
    if (state.generatedNumeroCommande.isNotEmpty &&
        numeroCommandeController.text != state.generatedNumeroCommande) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            numeroCommandeController.text != state.generatedNumeroCommande) {
          numeroCommandeController.text = state.generatedNumeroCommande;
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing
              ? 'Modifier le bon de commande'
              : 'Nouveau bon de commande fournisseur',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sélection fournisseur
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fournisseur *',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      (() {
                        final selectedSupplier = state.selectedSupplier;
                        if (selectedSupplier != null) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Fournisseur: ${selectedSupplier.nom}'),
                              Text(selectedSupplier.email),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () => notifier.selectSupplier(null),
                                child: const Text('Changer'),
                              ),
                            ],
                          );
                        }
                        return ElevatedButton(
                          onPressed: () =>
                              _showSupplierSelection(context, notifier),
                          child: const Text('Sélectionner un fournisseur'),
                        );
                      })(),
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
                      TextFormField(
                        controller: numeroCommandeController,
                        decoration: const InputDecoration(
                          labelText:
                              'Numéro de commande (généré automatiquement) *',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey,
                          helperText: 'Numéro généré automatiquement',
                        ),
                        readOnly: true,
                        enabled: false,
                        validator: (value) {
                          final refValue = (value == null || value.isEmpty)
                              ? state.generatedNumeroCommande
                              : value;
                          if (refValue.isEmpty) {
                            return 'Le numéro de commande est requis';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: commentaireController,
                        decoration: const InputDecoration(
                          labelText: 'Commentaire',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: conditionsPaiementController,
                        decoration: const InputDecoration(
                          labelText: 'Conditions de paiement',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: delaiLivraisonController,
                        decoration: const InputDecoration(
                          labelText: 'Délai de livraison (jours)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
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
                            'Articles *',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _showItemForm(context, notifier),
                            icon: const Icon(Icons.add),
                            label: const Text('Ajouter'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (state.items.isEmpty)
                        const Center(
                          child: Text('Aucun article ajouté'),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.items.length,
                          itemBuilder: (context, index) {
                            final item = state.items[index];
                            return _buildItemCard(
                              context,
                              item,
                              index,
                              notifier,
                            );
                          },
                        ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Montant total:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              NumberFormat.currency(
                                locale: 'fr_FR',
                                symbol: 'fcfa',
                              ).format(state.items.fold(
                                0.0,
                                (sum, item) => sum + item.montantTotal,
                              )),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Bouton de soumission
              ElevatedButton(
                onPressed: state.isLoading
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          if (state.selectedSupplier == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Veuillez sélectionner un fournisseur',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          if (state.items.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Veuillez ajouter au moins un article',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          final data = {
                            'numero_commande': state
                                    .generatedNumeroCommande
                                    .isNotEmpty
                                ? state.generatedNumeroCommande
                                : numeroCommandeController.text,
                            'date_commande': DateTime.now(),
                            'description': descriptionController.text.isEmpty
                                ? null
                                : descriptionController.text,
                            'commentaire':
                                commentaireController.text.isEmpty
                                    ? null
                                    : commentaireController.text,
                            'conditions_paiement':
                                conditionsPaiementController.text.isEmpty
                                    ? null
                                    : conditionsPaiementController.text,
                            'delai_livraison':
                                delaiLivraisonController.text.isEmpty
                                    ? null
                                    : int.tryParse(
                                        delaiLivraisonController.text,
                                      ),
                          };
                          try {
                            if (widget.isEditing &&
                                widget.bonDeCommandeId != null) {
                              await notifier.updateBonDeCommande(
                                widget.bonDeCommandeId!,
                                data,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Bon de commande mis à jour avec succès',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                context.go('/bons-de-commande-fournisseur');
                              }
                            } else {
                              final success =
                                  await notifier.createBonDeCommande(data);
                              if (success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Bon de commande créé avec succès',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                context.go('/bons-de-commande-fournisseur');
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erreur: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: state.isLoading
                    ? const CircularProgressIndicator()
                    : Text(widget.isEditing ? 'Modifier' : 'Créer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    BonDeCommandeItem item,
    int index,
    BonDeCommandeFournisseurNotifier notifier,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(item.designation),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.ref != null && item.ref!.isNotEmpty)
              Text('Ref: ${item.ref}'),
            Text('Quantité: ${item.quantite}'),
            Text(
              'Prix unitaire: ${NumberFormat.currency(locale: 'fr_FR', symbol: 'fcfa').format(item.prixUnitaire)}',
            ),
            Text(
              'Total: ${NumberFormat.currency(locale: 'fr_FR', symbol: 'fcfa').format(item.montantTotal)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (item.description != null && item.description!.isNotEmpty)
              Text('Description: ${item.description}'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => notifier.removeItem(index),
        ),
        onTap: () => _showItemForm(context, notifier, index: index, item: item),
      ),
    );
  }

  void _showItemForm(
    BuildContext context,
    BonDeCommandeFournisseurNotifier notifier, {
    int? index,
    BonDeCommandeItem? item,
  }) {
    final refController = TextEditingController(text: item?.ref ?? '');
    final designationController = TextEditingController(
      text: item?.designation ?? '',
    );
    final quantiteController = TextEditingController(
      text: item?.quantite.toString() ?? '1',
    );
    final prixController = TextEditingController(
      text: item?.prixUnitaire.toString() ?? '0',
    );
    final descriptionItemController = TextEditingController(
      text: item?.description ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          item == null ? 'Ajouter un article' : 'Modifier l\'article',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: refController,
                decoration: const InputDecoration(
                  labelText: 'Référence',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: designationController,
                decoration: const InputDecoration(
                  labelText: 'Désignation *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La désignation est requise';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: quantiteController,
                decoration: const InputDecoration(
                  labelText: 'Quantité *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La quantité est requise';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Quantité invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: prixController,
                decoration: const InputDecoration(
                  labelText: 'Prix unitaire *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le prix unitaire est requis';
                  }
                  if (double.tryParse(value) == null ||
                      double.parse(value) <= 0) {
                    return 'Prix invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionItemController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (designationController.text.isEmpty ||
                  quantiteController.text.isEmpty ||
                  prixController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Veuillez remplir tous les champs obligatoires',
                    ),
                  ),
                );
                return;
              }

              final newItem = BonDeCommandeItem(
                id: item?.id,
                ref: refController.text.isEmpty ? null : refController.text,
                designation: designationController.text,
                quantite: int.parse(quantiteController.text),
                prixUnitaire: double.parse(prixController.text),
                description: descriptionItemController.text.isEmpty
                    ? null
                    : descriptionItemController.text,
              );

              if (index != null) {
                notifier.updateItem(index, newItem);
              } else {
                notifier.addItem(newItem);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showSupplierSelection(
    BuildContext context,
    BonDeCommandeFournisseurNotifier notifier,
  ) async {
    notifier.loadSuppliers();
    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final stateSuppliers =
              ref.watch(bonDeCommandeFournisseurProvider);
          if (stateSuppliers.isLoadingSuppliers) {
            return AlertDialog(
              title: const Text('Sélectionner un fournisseur'),
              content: const SkeletonSearchResults(itemCount: 4),
            );
          }
          if (stateSuppliers.suppliers.isEmpty) {
            return AlertDialog(
              title: const Text('Sélectionner un fournisseur'),
              content: const Text('Aucun fournisseur disponible'),
            );
          }
          return AlertDialog(
            title: const Text('Sélectionner un fournisseur'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: stateSuppliers.suppliers.length,
                itemBuilder: (context, index) {
                  final supplier = stateSuppliers.suppliers[index];
                  return ListTile(
                    title: Text(supplier.nom),
                    subtitle: Text(supplier.email),
                    onTap: () {
                      notifier.selectSupplier(supplier);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

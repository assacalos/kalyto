import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/supplier_notifier.dart';
import 'package:easyconnect/Models/supplier_model.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';
import 'package:easyconnect/utils/validation_helper.dart';

final _emailRegex = RegExp(
  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
);

class SupplierForm extends ConsumerStatefulWidget {
  final Supplier? supplier;

  const SupplierForm({super.key, this.supplier});

  @override
  ConsumerState<SupplierForm> createState() => _SupplierFormState();
}

class _SupplierFormState extends ConsumerState<SupplierForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController nomController;
  late final TextEditingController emailController;
  late final TextEditingController telephoneController;
  late final TextEditingController adresseController;
  late final TextEditingController villeController;
  late final TextEditingController paysController;
  late final TextEditingController descriptionController;
  late final TextEditingController commentairesController;
  late final TextEditingController nineaController;

  @override
  void initState() {
    super.initState();
    nomController = TextEditingController(text: widget.supplier?.nom ?? '');
    emailController = TextEditingController(text: widget.supplier?.email ?? '');
    telephoneController =
        TextEditingController(text: widget.supplier?.telephone ?? '');
    adresseController =
        TextEditingController(text: widget.supplier?.adresse ?? '');
    villeController = TextEditingController(text: widget.supplier?.ville ?? '');
    paysController = TextEditingController(text: widget.supplier?.pays ?? '');
    descriptionController =
        TextEditingController(text: widget.supplier?.description ?? '');
    commentairesController =
        TextEditingController(text: widget.supplier?.commentaires ?? '');
    nineaController =
        TextEditingController(text: widget.supplier?.ninea ?? '');
  }

  @override
  void dispose() {
    nomController.dispose();
    emailController.dispose();
    telephoneController.dispose();
    adresseController.dispose();
    villeController.dispose();
    paysController.dispose();
    descriptionController.dispose();
    commentairesController.dispose();
    nineaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.supplier == null
              ? 'Nouveau Fournisseur'
              : 'Modifier le Fournisseur',
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _saveSupplier(context),
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
                controller: nineaController,
                decoration: const InputDecoration(
                  labelText: 'NINEA',
                  hintText: '9 chiffres (numéro d\'identification ivoirien)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.fingerprint),
                ),
                keyboardType: TextInputType.number,
                maxLength: 9,
                validator: (value) =>
                    ValidationHelper.validateNinea(value, required: false),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom du fournisseur *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom est obligatoire';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'L\'email est obligatoire';
                  }
                  if (!_emailRegex.hasMatch(value)) {
                    return 'Format d\'email invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: telephoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le téléphone est obligatoire';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Adresse'),
              const SizedBox(height: 16),
              TextFormField(
                controller: adresseController,
                decoration: const InputDecoration(
                  labelText: 'Adresse *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'L\'adresse est obligatoire';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: villeController,
                      decoration: const InputDecoration(
                        labelText: 'Ville *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_city),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'La ville est obligatoire';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: paysController,
                      decoration: const InputDecoration(
                        labelText: 'Pays *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.public),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le pays est obligatoire';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Informations supplémentaires'),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  hintText: 'Description du fournisseur (optionnel)',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: commentairesController,
                decoration: const InputDecoration(
                  labelText: 'Commentaires',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.comment),
                  hintText: 'Commentaires internes (optionnel)',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              UniformFormButtons(
                onCancel: () => context.pop(),
                onSubmit: () => _saveSupplier(context),
                submitText: 'Soumettre',
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

  Future<void> _saveSupplier(BuildContext context) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final notifier = ref.read(supplierProvider.notifier);
    final nom = nomController.text.trim();
    final email = emailController.text.trim();
    final telephone = telephoneController.text.trim();
    final adresse = adresseController.text.trim();
    final ville = villeController.text.trim();
    final pays = paysController.text.trim();
    final description = descriptionController.text.trim();
    final commentaires = commentairesController.text.trim();
    final ninea = nineaController.text.replaceAll(RegExp(r'\s'), '').trim();
    final nineaOrNull = ninea.isEmpty ? null : ninea;

    try {
      bool success = false;
      if (widget.supplier == null) {
        final newSupplier = Supplier(
          nom: nom,
          email: email,
          telephone: telephone,
          adresse: adresse,
          ville: ville,
          pays: pays,
          description: description.isEmpty ? null : description,
          ninea: nineaOrNull,
          commentaires: commentaires.isEmpty ? null : commentaires,
          statut: 'en_attente',
        );
        success = await notifier.createSupplier(newSupplier);
      } else {
        final updated = widget.supplier!.copyWith(
          nom: nom,
          email: email,
          telephone: telephone,
          adresse: adresse,
          ville: ville,
          pays: pays,
          description: description.isEmpty ? null : description,
          ninea: nineaOrNull,
          commentaires: commentaires.isEmpty ? null : commentaires,
        );
        success = await notifier.updateSupplier(updated);
      }

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fournisseur enregistré avec succès'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/suppliers');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de l\'enregistrement'),
              backgroundColor: Colors.red,
            ),
          );
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
}

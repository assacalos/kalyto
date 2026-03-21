import 'package:easyconnect/providers/client_notifier.dart';
import 'package:easyconnect/Views/Components/app_bar_back_button.dart';
import 'package:easyconnect/utils/validation_helper_enhanced.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ClientFormPage extends ConsumerStatefulWidget {
  final bool isEditing;
  final int? clientId;

  const ClientFormPage({super.key, this.isEditing = false, this.clientId});

  @override
  ConsumerState<ClientFormPage> createState() => _ClientFormPageState();
}

class _ClientFormPageState extends ConsumerState<ClientFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController nomController;
  late final TextEditingController prenomController;
  late final TextEditingController nomEntrepriseController;
  late final TextEditingController situationGeographiqueController;
  late final TextEditingController emailController;
  late final TextEditingController telephoneController;
  late final TextEditingController adresseController;
  late final TextEditingController numeroContribuableController;
  late final TextEditingController nineaController;

  static bool _isEmail(String? value) {
    if (value == null || value.isEmpty) return false;
    return value.contains('@') && value.contains('.');
  }

  @override
  void initState() {
    super.initState();
    nomController = TextEditingController();
    prenomController = TextEditingController();
    nomEntrepriseController = TextEditingController();
    situationGeographiqueController = TextEditingController();
    emailController = TextEditingController();
    telephoneController = TextEditingController();
    adresseController = TextEditingController();
    numeroContribuableController = TextEditingController();
    nineaController = TextEditingController();

    if (widget.isEditing && widget.clientId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadClientData();
      });
    }
  }

  void _loadClientData() {
    final clients = ref.read(clientProvider).clients;
    try {
      final client = clients.firstWhere(
        (c) => c.id == widget.clientId,
      );
      nomController.text = client.nom?.toString() ?? '';
      prenomController.text = client.prenom?.toString() ?? '';
      nomEntrepriseController.text = client.nomEntreprise?.toString() ?? '';
      emailController.text = client.email?.toString() ?? '';
      telephoneController.text = client.contact?.toString() ?? '';
      adresseController.text = client.adresse?.toString() ?? '';
      situationGeographiqueController.text =
          client.situationGeographique?.toString() ?? '';
      numeroContribuableController.text =
          client.numeroContribuable?.toString() ?? '';
      nineaController.text = client.ninea?.toString() ?? '';
    } catch (e) {
      // Le client n'est pas encore chargé
    }
  }

  void _clearForm() {
    nomController.clear();
    prenomController.clear();
    nomEntrepriseController.clear();
    situationGeographiqueController.clear();
    emailController.clear();
    telephoneController.clear();
    adresseController.clear();
    numeroContribuableController.clear();
    nineaController.clear();
    _formKey.currentState?.reset();
  }

  @override
  void dispose() {
    nomController.dispose();
    prenomController.dispose();
    nomEntrepriseController.dispose();
    situationGeographiqueController.dispose();
    emailController.dispose();
    telephoneController.dispose();
    adresseController.dispose();
    numeroContribuableController.dispose();
    nineaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: const AppBarBackButton(fallbackRoute: '/clients'),
        title: Text(widget.isEditing ? "Modifier un Client" : "Nouveau Client"),
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Nom entreprise en premier
                TextFormField(
                  controller: nomEntrepriseController,
                  decoration: InputDecoration(labelText: "Nom Entreprise *"),
                  validator:
                      (value) =>
                          value!.isEmpty ? "Nom Entreprise requis" : null,
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: nomController,
                  decoration: InputDecoration(labelText: "Nom"),
                  validator: (value) => value!.isEmpty ? "Nom requis" : null,
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: prenomController,
                  decoration: InputDecoration(labelText: "Prénom"),
                  validator: (value) => value!.isEmpty ? "Prénom requis" : null,
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: "Email"),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value!.isEmpty) return "Email requis";
                    if (!_isEmail(value)) return "Email invalide";
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: telephoneController,
                  decoration: InputDecoration(labelText: "Contact"),
                  keyboardType: TextInputType.phone,
                  validator:
                      (value) => value!.isEmpty ? "Contact requis" : null,
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: adresseController,
                  decoration: InputDecoration(labelText: "Adresse"),
                  maxLines: 2,
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: situationGeographiqueController,
                  decoration: InputDecoration(
                    labelText: "Situation Géographique",
                  ),
                  validator:
                      (value) =>
                          value!.isEmpty
                              ? "Situation Géographique requise"
                              : null,
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: numeroContribuableController,
                  decoration: InputDecoration(
                    labelText: "Numéro Contribuable",
                    hintText: "Ex: CI-ABJ-2014-A-12345",
                  ),
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: nineaController,
                  decoration: InputDecoration(
                    labelText: "NINEA",
                    hintText: "9 chiffres (numéro d'identification ivoirien)",
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 9,
                  validator: (value) =>
                      ValidationHelperEnhanced.validateNinea(value, required: false),
                ),
                SizedBox(height: 20),
                Consumer(
                  builder: (context, ref, _) {
                    final isLoading = ref.watch(clientProvider).isLoading;
                    final notifier = ref.read(clientProvider.notifier);
                    return ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                final data = {
                                  "nom": nomController.text.trim(),
                                  "prenom": prenomController.text.trim(),
                                  "nom_entreprise":
                                      nomEntrepriseController.text.trim(),
                                  "situation_geographique":
                                      situationGeographiqueController.text.trim(),
                                  "email": emailController.text.trim(),
                                  "contact": telephoneController.text.trim(),
                                  "adresse": adresseController.text.trim(),
                                  "numero_contribuable":
                                      numeroContribuableController.text.trim(),
                                  "ninea": nineaController.text
                                      .replaceAll(RegExp(r'\s'), '')
                                      .trim(),
                                };

                                bool success = false;
                                try {
                                  if (widget.isEditing && widget.clientId != null) {
                                    success = await notifier.updateClient(data);
                                    if (success && mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Client mis à jour avec succès')),
                                      );
                                    }
                                  } else {
                                    success =
                                        await notifier.createClientFromMap(data);
                                    if (success && mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Client enregistré avec succès')),
                                      );
                                    }
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Erreur: ${e.toString()}')),
                                    );
                                  }
                                  return;
                                }

                                if (success && mounted) {
                                  _clearForm();
                                  await Future.delayed(
                                      const Duration(milliseconds: 500));
                                  context.go('/clients');
                                }
                              }
                            },
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              widget.isEditing ? "Modifier" : "Enregistrer",
                            ),
                    );
                  },
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:easyconnect/Models/user_model.dart';
import 'package:easyconnect/providers/user_management_notifier.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class UserForm extends ConsumerStatefulWidget {
  final UserModel? user;
  UserForm({super.key, this.user});

  @override
  ConsumerState<UserForm> createState() => _UserFormState();
}

class _UserFormState extends ConsumerState<UserForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController emailController;
  late TextEditingController passwordController;
  int role = 2;
  bool isActive = true;

  @override
  void initState() {
    super.initState();
    firstNameController = TextEditingController(text: widget.user?.nom ?? '');
    lastNameController = TextEditingController(text: widget.user?.prenom ?? '');
    emailController = TextEditingController(text: widget.user?.email ?? '');
    passwordController = TextEditingController();
    role = widget.user?.role ?? 2;
    isActive = widget.user?.isActive ?? true;
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(userManagementProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.user == null ? "Ajouter Utilisateur" : "Modifier Utilisateur",
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: firstNameController,
                decoration: InputDecoration(labelText: "Prénom"),
                validator: (v) => v!.isEmpty ? "Champ requis" : null,
              ),
              TextFormField(
                controller: lastNameController,
                decoration: InputDecoration(labelText: "Nom"),
                validator: (v) => v!.isEmpty ? "Champ requis" : null,
              ),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(labelText: "Email"),
                validator: (v) =>
                    (v == null || v.isEmpty || !v.contains('@'))
                        ? "Email invalide"
                        : null,
              ),
              if (widget.user == null)
                TextFormField(
                  controller: passwordController,
                  decoration: InputDecoration(labelText: "Mot de passe"),
                  obscureText: true,
                  validator:
                      (v) => (v == null || v.length < 6)
                          ? "Minimum 6 caractères"
                          : null,
                ),
              DropdownButtonFormField<int>(
                value: role,
                items:
                    [1, 2, 3]
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(r.toString()),
                          ),
                        )
                        .toList(),
                onChanged: (v) => setState(() => role = v!),
                decoration: InputDecoration(labelText: "Rôle"),
              ),
              SwitchListTile(
                title: Text("Actif"),
                value: isActive,
                onChanged: (v) => setState(() => isActive = v),
              ),
              SizedBox(height: 20),
              UniformFormButtons(
                onCancel: () => Navigator.pop(context),
                onSubmit: () async {
                  if (_formKey.currentState!.validate()) {
                    if (widget.user == null) {
                      final success = await notifier.createUser(
                        nom: lastNameController.text.trim(),
                        prenom: firstNameController.text.trim(),
                        email: emailController.text.trim(),
                        password: passwordController.text,
                        roleId: role,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? "Utilisateur créé avec succès"
                                : "Erreur lors de la création",
                          ),
                          backgroundColor:
                              success ? Colors.green : Colors.red,
                        ),
                      );
                      if (success) {
                        await Future.delayed(const Duration(milliseconds: 500));
                        context.go('/admin/users');
                      }
                    } else {
                      final user = UserModel(
                        id: widget.user!.id,
                        nom: firstNameController.text.trim(),
                        prenom: lastNameController.text.trim(),
                        email: emailController.text.trim(),
                        role: role,
                        isActive: isActive,
                      );
                      final success = await notifier.updateUser(user);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? "Utilisateur mis à jour"
                                : "Erreur lors de la mise à jour",
                          ),
                          backgroundColor:
                              success ? Colors.green : Colors.red,
                        ),
                      );
                      if (success) {
                        await Future.delayed(const Duration(milliseconds: 500));
                        context.go('/admin/users');
                      }
                    }
                  }
                },
                submitText: 'Soumettre',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/Models/company_model.dart';
import 'package:easyconnect/Models/user_model.dart';
import 'package:easyconnect/providers/user_management_notifier.dart';
import 'package:easyconnect/services/company_service.dart';
import 'package:easyconnect/services/user_service.dart';
import 'package:easyconnect/utils/roles.dart';

class UserFormPage extends ConsumerStatefulWidget {
  final bool isEditing;
  final int? userId;

  const UserFormPage({super.key, this.isEditing = false, this.userId});

  @override
  ConsumerState<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends ConsumerState<UserFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  int _selectedRoleId = 1;
  List<Company> _companies = [];
  int? _selectedCompanyId;
  bool _companiesLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
    if (widget.isEditing && widget.userId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadUser());
    }
  }

  Future<void> _loadCompanies() async {
    try {
      final list = await CompanyService.getCompanies();
      if (mounted) setState(() {
        _companies = list;
        _companiesLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _companiesLoading = false);
    }
  }

  Future<void> _loadUser() async {
    try {
      final user = await UserService().getUserById(widget.userId!);
      if (mounted) {
        _nomController.text = user.nom ?? '';
        _prenomController.text = user.prenom ?? '';
        _emailController.text = user.email ?? '';
        _selectedRoleId = user.role ?? 1;
        _selectedCompanyId = user.companyId;
        setState(() {});
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userManagementProvider);
    final notifier = ref.read(userManagementProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Modifier l\'utilisateur' : 'Nouvel utilisateur',
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (widget.isEditing && widget.userId != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Confirmer la suppression'),
                    content: const Text(
                      'Êtes-vous sûr de vouloir supprimer cet utilisateur ?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Annuler'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Supprimer'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  final ok = await notifier.deleteUser(widget.userId!);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok ? 'Utilisateur supprimé' : 'Erreur'),
                        backgroundColor: ok ? Colors.green : Colors.red,
                      ),
                    );
                    if (ok) context.go('/admin/users');
                  }
                }
              },
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple, Colors.deepPurple.shade300],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isEditing
                          ? 'Modifier l\'utilisateur'
                          : 'Créer un nouvel utilisateur',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.isEditing
                          ? 'Modifiez les informations de l\'utilisateur'
                          : 'Remplissez le formulaire pour créer un nouvel utilisateur',
                      style: const TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informations personnelles',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nomController,
                        decoration: const InputDecoration(
                          labelText: 'Nom *',
                          hintText: 'Entrez le nom',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Le nom est requis' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _prenomController,
                        decoration: const InputDecoration(
                          labelText: 'Prénom *',
                          hintText: 'Entrez le prénom',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Le prénom est requis' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email *',
                          hintText: 'Entrez l\'email',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'L\'email est requis';
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(v)) return 'Email valide requis';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      if (!widget.isEditing)
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Mot de passe *',
                            hintText: 'Entrez le mot de passe',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock),
                          ),
                          obscureText: true,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Le mot de passe est requis';
                            if (v.length < 6) return 'Au moins 6 caractères';
                            return null;
                          },
                        ),
                      if (!widget.isEditing) const SizedBox(height: 16),
                      const Text(
                        'Rôle *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _selectedRoleId,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.admin_panel_settings),
                        ),
                        items: Roles.getRolesList()
                            .map((r) => DropdownMenuItem<int>(
                                  value: r['id'] as int,
                                  child: Text(r['name'] as String),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() {
                            _selectedRoleId = v;
                            if (v == 1) _selectedCompanyId = null;
                          });
                        },
                      ),
                      if (_selectedRoleId != 1) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Société',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _companiesLoading
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : DropdownButtonFormField<int>(
                                value: _selectedCompanyId,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.business),
                                ),
                                hint: const Text('Aucune société'),
                                items: [
                                  const DropdownMenuItem<int>(
                                    value: null,
                                    child: Text('Aucune société'),
                                  ),
                                  ..._companies.map(
                                    (c) => DropdownMenuItem<int>(
                                      value: c.id,
                                      child: Text(c.name),
                                    ),
                                  ),
                                ],
                                onChanged: (v) => setState(() => _selectedCompanyId = v),
                              ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => context.go('/admin/users'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('Annuler'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: state.isCreating
                                  ? null
                                  : () => _submit(notifier),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: state.isCreating
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : Text(widget.isEditing ? 'Modifier' : 'Créer'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informations sur les rôles',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• Administrateur: Gère les utilisateurs et paramètres\n'
                        '• Patron: Valide les documents et prend les décisions\n'
                        '• Commercial: Gère les clients et ventes\n'
                        '• Comptable: Gère la comptabilité et finances\n'
                        '• RH: Gère les employés et ressources humaines\n'
                        '• Technicien: Gère les interventions techniques',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(UserManagementNotifier notifier) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final nom = _nomController.text.trim();
    final prenom = _prenomController.text.trim();
    final email = _emailController.text.trim();

    if (widget.isEditing && widget.userId != null) {
      final user = UserModel(
        id: widget.userId!,
        nom: nom,
        prenom: prenom,
        email: email,
        role: _selectedRoleId,
        companyId: _selectedRoleId == 1 ? null : _selectedCompanyId,
        isActive: true,
      );
      final ok = await notifier.updateUser(user);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Utilisateur mis à jour' : 'Erreur'),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
      if (ok) context.go('/admin/users');
    } else {
      final password = _passwordController.text;
      if (password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Le mot de passe est requis')),
        );
        return;
      }
      final ok = await notifier.createUser(
        nom: nom,
        prenom: prenom,
        email: email,
        password: password,
        roleId: _selectedRoleId,
        companyId: _selectedRoleId == 1 ? null : _selectedCompanyId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Utilisateur créé avec succès' : 'Erreur lors de la création'),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
      if (ok) context.go('/admin/users');
    }
  }
}

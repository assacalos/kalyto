import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/user_management_notifier.dart';
import 'package:easyconnect/providers/user_management_state.dart';
import 'package:easyconnect/Models/user_model.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';

class UserManagementPage extends ConsumerStatefulWidget {
  const UserManagementPage({super.key});

  @override
  ConsumerState<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends ConsumerState<UserManagementPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userManagementProvider.notifier).loadUsers();
      ref.read(userManagementProvider.notifier).loadUserStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userManagementProvider);
    final notifier = ref.read(userManagementProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des utilisateurs'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.loadUsers(),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/admin/users/new'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Total utilisateurs',
                    value: state.totalUsers.toString(),
                    icon: Icons.people,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    title: 'Utilisateurs actifs',
                    value: state.activeUsers.toString(),
                    icon: Icons.person,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    title: 'Nouveaux ce mois',
                    value: state.newUsersThisMonth.toString(),
                    icon: Icons.person_add,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) => notifier.setSearchQuery(value),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un utilisateur...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: state.selectedRole,
                  hint: const Text('Tous les rôles'),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Tous les rôles')),
                    DropdownMenuItem(value: 'admin', child: Text('Administrateur')),
                    DropdownMenuItem(value: 'patron', child: Text('Patron')),
                    DropdownMenuItem(value: 'commercial', child: Text('Commercial')),
                    DropdownMenuItem(value: 'comptable', child: Text('Comptable')),
                    DropdownMenuItem(value: 'rh', child: Text('RH')),
                    DropdownMenuItem(value: 'technicien', child: Text('Technicien')),
                  ],
                  onChanged: (value) {
                    if (value != null) notifier.setSelectedRole(value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildUserList(context, state, notifier),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(
    BuildContext context,
    UserManagementState state,
    UserManagementNotifier notifier,
  ) {
    if (state.isLoading) {
      return const SkeletonSearchResults(itemCount: 6);
    }
    final filteredUsers = notifier.getFilteredUsers();
    if (filteredUsers.isEmpty) {
      return const Center(
        child: Text('Aucun utilisateur trouvé', style: TextStyle(fontSize: 16)),
      );
    }
    return ListView.builder(
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        return _buildUserCard(context, user, notifier);
      },
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    UserModel user,
    UserManagementNotifier notifier,
  ) {
    final fullName = '${user.nom ?? ''} ${user.prenom ?? ''}'.trim();
    final roleName = UserManagementState.getRoleName(user.role);
    final roleColor = UserManagementState.getRoleColor(user.role);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: user.isActive ? Colors.green : Colors.grey,
          child: Text(
            fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(fullName.isNotEmpty ? fullName : 'Utilisateur sans nom'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email ?? 'Email non défini'),
            Text('Rôle: $roleName'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(
              label: Text(roleName),
              backgroundColor: roleColor.withOpacity(0.1),
              labelStyle: TextStyle(color: roleColor),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (value) async {
                switch (value) {
                  case 'edit':
                    context.go('/admin/users/${user.id}/edit');
                    break;
                  case 'toggle':
                    final ok = await notifier.toggleUserStatus(user.id, !user.isActive);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok
                              ? 'Statut modifié avec succès'
                              : 'Erreur lors de la modification'),
                          backgroundColor: ok ? Colors.green : Colors.red,
                        ),
                      );
                    }
                    break;
                  case 'delete':
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
                      final ok = await notifier.deleteUser(user.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ok
                                ? 'Utilisateur supprimé'
                                : 'Erreur lors de la suppression'),
                            backgroundColor: ok ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    }
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Modifier'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(user.isActive ? Icons.block : Icons.check_circle),
                      const SizedBox(width: 8),
                      Text(user.isActive ? 'Désactiver' : 'Activer'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Supprimer', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

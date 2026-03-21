import 'package:easyconnect/Models/user_model.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/providers/user_management_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum DashboardSection { dashboard, users, security, settings, logs }

class AdminDashboardFull extends ConsumerStatefulWidget {
  const AdminDashboardFull({super.key});

  @override
  ConsumerState<AdminDashboardFull> createState() => _AdminDashboardFullState();
}

class _AdminDashboardFullState extends ConsumerState<AdminDashboardFull> {
  DashboardSection currentSection = DashboardSection.dashboard;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userManagementProvider.notifier).loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Container(
          color: Colors.blueGrey.shade900,
          child: Column(
            children: [
              const SizedBox(height: 50),
              Text(
                'EasyConnect Admin',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              _buildSidebarButton(
                'Tableau de bord',
                Icons.dashboard,
                section: DashboardSection.dashboard,
              ),
              _buildSidebarButton(
                'Gestion des utilisateurs',
                Icons.people,
                section: DashboardSection.users,
              ),
              _buildSidebarButton(
                'Sécurité',
                Icons.security,
                section: DashboardSection.security,
              ),
              _buildSidebarButton(
                'Paramètres système',
                Icons.settings,
                section: DashboardSection.settings,
              ),
              _buildSidebarButton(
                'Logs d\'activité',
                Icons.list_alt,
                section: DashboardSection.logs,
              ),
              const Spacer(),
              _buildSidebarButton(
                'Déconnexion',
                Icons.logout,
                onTap: () {
                  ref.read(authProvider.notifier).logout();
                },
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade800,
        title: Text(_getSectionTitle(currentSection)),
        actions: [
          const Icon(Icons.notifications),
          const SizedBox(width: 20),
          CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: Colors.blueGrey.shade800),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildSectionContent(),
      ),
      floatingActionButton: currentSection == DashboardSection.users
          ? FloatingActionButton(
              onPressed: () => context.push('/admin/users/new'),
              child: const Icon(Icons.add),
              backgroundColor: Colors.blueGrey.shade800,
              tooltip: 'Ajouter Utilisateur',
            )
          : null,
    );
  }

  Widget _buildSidebarButton(
    String label,
    IconData icon, {
    DashboardSection? section,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      selected: section != null && section == currentSection,
      selectedTileColor: Colors.blueGrey.shade700,
      onTap: () {
        Navigator.pop(context);
        if (section != null) {
          setState(() => currentSection = section);
        } else if (onTap != null) {
          onTap();
        }
      },
    );
  }

  String _getSectionTitle(DashboardSection section) {
    switch (section) {
      case DashboardSection.dashboard:
        return 'Tableau de bord';
      case DashboardSection.users:
        return 'Gestion des utilisateurs';
      case DashboardSection.security:
        return 'Sécurité';
      case DashboardSection.settings:
        return 'Paramètres système';
      case DashboardSection.logs:
        return 'Logs d\'activité';
    }
  }

  Widget _buildSectionContent() {
    switch (currentSection) {
      case DashboardSection.dashboard:
        return _buildDashboardOverview();
      case DashboardSection.users:
        return _buildUsersSection();
      case DashboardSection.security:
        return _buildSecuritySection();
      case DashboardSection.settings:
        return _buildSettingsSection();
      case DashboardSection.logs:
        return _buildLogsSection();
    }
  }

  Widget _buildDashboardOverview() {
    return Center(
      child: Text(
        'Bienvenue dans le tableau de bord EasyConnect!\n\nRésumé des informations clés ici.',
        style: const TextStyle(fontSize: 20),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildUsersSection() {
    final state = ref.watch(userManagementProvider);

    if (state.isLoading && state.users.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          color: Colors.blueGrey,
          strokeWidth: 6,
        ),
      );
    }
    if (state.users.isEmpty) {
      return Center(
        child: Text(
          'Aucun utilisateur trouvé',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    final width = MediaQuery.of(context).size.width;
    final crossAxisCount =
        width >= 1200 ? 3 : width >= 800 ? 2 : 1;

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 3.2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: state.users.length,
      itemBuilder: (context, index) {
        final user = state.users[index];
        return _UserCard(
          user: user,
          onEdit: () => context.push('/admin/users/${user.id}/edit'),
          onDelete: () => _confirmDelete(context, user.id.toString()),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer'),
        content: const Text(
          'Voulez-vous vraiment supprimer cet utilisateur ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Oui'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final notifier = ref.read(userManagementProvider.notifier);
      final ok = await notifier.deleteUser(int.parse(id));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'Utilisateur supprimé' : 'Erreur'),
            backgroundColor: ok ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSecuritySection() {
    return const Center(
      child: Text(
        'Section Sécurité\n\nGestion des rôles, permissions et authentification.',
        style: TextStyle(fontSize: 18),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSettingsSection() {
    return const Center(
      child: Text(
        'Section Paramètres Système\n\nConfiguration générale de l\'application.',
        style: TextStyle(fontSize: 18),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildLogsSection() {
    return const Center(
      child: Text(
        'Section Logs d\'activité\n\nHistorique des actions effectuées par les utilisateurs.',
        style: TextStyle(fontSize: 18),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Colors.blueGrey.shade200,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${user.nom} ${user.prenom}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${user.email}',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: user.isActive
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    user.isActive ? 'Actif' : 'Inactif',
                    style: TextStyle(
                      color: user.isActive
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blueGrey),
                  onPressed: onEdit,
                  tooltip: 'Modifier',
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red.shade400),
                  onPressed: onDelete,
                  tooltip: 'Supprimer',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

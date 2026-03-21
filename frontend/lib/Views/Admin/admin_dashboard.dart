import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/auth_notifier.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final logout = ref.read(authProvider.notifier).logout;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord Administrateur'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de bienvenue
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
                    'Bienvenue, ${user?.nom ?? 'Administrateur'}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Gérez les utilisateurs et les paramètres de l\'application',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section gestion des utilisateurs
            const Text(
              'Gestion des utilisateurs',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildAdminCard(
                    title: 'Utilisateurs',
                    subtitle: 'Gérer tous les utilisateurs',
                    icon: Icons.people,
                    color: Colors.blue,
                    onTap: () {
                      context.go('/admin/users');
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAdminCard(
                    title: 'Nouvel utilisateur',
                    subtitle: 'Créer un utilisateur',
                    icon: Icons.person_add,
                    color: Colors.green,
                    onTap: () {
                      context.go('/admin/users/new');
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildAdminCard(
                    title: 'Rôles et permissions',
                    subtitle: 'Gérer les rôles',
                    icon: Icons.admin_panel_settings,
                    color: Colors.orange,
                    onTap: () {
                      context.go('/admin/roles');
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAdminCard(
                    title: 'Audit des connexions',
                    subtitle: 'Historique des connexions',
                    icon: Icons.history,
                    color: Colors.purple,
                    onTap: () {
                      context.go('/admin/audit');
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Section paramètres de l'application
            const Text(
              'Paramètres de l\'application',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildAdminCard(
                    title: 'Paramètres généraux',
                    subtitle: 'Configuration de l\'app',
                    icon: Icons.settings,
                    color: Colors.grey,
                    onTap: () {
                      context.go('/admin/settings');
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAdminCard(
                    title: 'Sauvegarde',
                    subtitle: 'Sauvegarder les données',
                    icon: Icons.backup,
                    color: Colors.teal,
                    onTap: () {
                      context.go('/admin/backup');
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildAdminCard(
                    title: 'Logs système',
                    subtitle: 'Consulter les logs',
                    icon: Icons.article,
                    color: Colors.red,
                    onTap: () {
                      context.go('/admin/logs');
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAdminCard(
                    title: 'Statistiques',
                    subtitle: 'Analyses et rapports',
                    icon: Icons.analytics,
                    color: Colors.indigo,
                    onTap: () {
                      context.go('/admin/statistics');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

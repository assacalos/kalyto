import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/utils/roles.dart';

/// Page de gestion des rôles (lecture seule) : liste des rôles et permissions
/// basées sur [Roles].
class RolesManagementPage extends StatelessWidget {
  const RolesManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final rolesList = Roles.getRolesList();
    final permissionsByRole = Roles.getRolePermissions();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des rôles'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/admin'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Rôles définis dans l\'application et leurs permissions (lecture seule).',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
          ),
          ...rolesList.map((roleMap) {
            final roleId = roleMap['id'] as int;
            final roleName = roleMap['name'] as String;
            final permissions = permissionsByRole[roleId] ?? <String>[];
            return _RoleCard(
              roleName: roleName,
              roleId: roleId,
              permissions: permissions,
            );
          }),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.roleName,
    required this.roleId,
    required this.permissions,
  });

  final String roleName;
  final int roleId;
  final List<String> permissions;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple.shade100,
          child: Icon(Icons.badge, color: Colors.deepPurple.shade700),
        ),
        title: Text(
          roleName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          'ID: $roleId · ${permissions.length} permission(s)',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Permissions',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                if (permissions.isEmpty)
                  Text(
                    'Aucune permission définie.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: permissions
                        .map((p) => Chip(
                              label: Text(
                                p,
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: Colors.grey.shade100,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ))
                        .toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

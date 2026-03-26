import 'package:easyconnect/providers/user_management_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecuritySection extends ConsumerWidget {
  const SecuritySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userManagementProvider);
    final notifier = ref.read(userManagementProvider.notifier);

    if (state.isLoading && state.users.isEmpty) {
      return Center(child: CircularProgressIndicator(color: Colors.blueGrey));
    }
    if (state.users.isEmpty) {
      return const Center(child: Text("Aucun utilisateur trouvé"));
    }

    return ListView.builder(
      itemCount: state.users.length,
      itemBuilder: (context, index) {
        final user = state.users[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            title: Text("${user.nom} ${user.prenom}"),
            subtitle: Text("${user.email} • Rôle: ${user.role}"),
            trailing: Switch(
              value: user.isActive,
              onChanged: (value) {
                notifier.toggleUserStatus(user.id, value);
              },
            ),
          ),
        );
      },
    );
  }
}

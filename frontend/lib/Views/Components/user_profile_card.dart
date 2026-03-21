import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easyconnect/Models/user_model.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/Views/Components/permission_list.dart';

class UserProfileCard extends ConsumerWidget {
  final bool showPermissions;
  final bool expanded;

  const UserProfileCard({
    super.key,
    this.showPermissions = true,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    if (user == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: _buildAvatar(user),
            title: Text(
              "${user.prenom ?? ''} ${user.nom ?? ''}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(user.email ?? ''),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    Roles.getRoleName(user.role),
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => ref.read(authProvider.notifier).logout(),
            ),
          ),
          if (showPermissions) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Permissions",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  PermissionList(
                    userRole: user.role,
                    showOnlyGranted: !expanded,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(dynamic user) {
    final String? photoUrl = user is UserModel
        ? user.photoUrl
        : (user.avatar != null &&
                user.avatar.toString().trim().isNotEmpty &&
                user.avatar.toString().startsWith('http')
            ? user.avatar
            : null);
    const double avatarSize = 72;
    return CircleAvatar(
      radius: avatarSize / 2,
      backgroundColor: Colors.blueGrey.shade100,
      child: photoUrl != null
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: photoUrl,
                width: avatarSize,
                height: avatarSize,
                fit: BoxFit.cover,
                placeholder: (_, __) => _avatarInitial(user),
                errorWidget: (_, __, ___) => _avatarInitial(user),
              ),
            )
          : _avatarInitial(user),
    );
  }

  Widget _avatarInitial(dynamic user) {
    return Text(
      (user.prenom?.isNotEmpty == true
              ? user.prenom![0]
              : user.nom?.isNotEmpty == true
                  ? user.nom![0]
                  : "?")
          .toUpperCase(),
      style: TextStyle(
        color: Colors.blueGrey.shade700,
        fontWeight: FontWeight.bold,
        fontSize: 28,
      ),
    );
  }
}

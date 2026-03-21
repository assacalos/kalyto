import 'package:flutter/material.dart';
import 'package:easyconnect/utils/permissions.dart';
import 'package:easyconnect/utils/roles.dart';

class PermissionList extends StatelessWidget {
  final int? userRole;
  final bool showOnlyGranted;
  final ScrollPhysics? physics;

  const PermissionList({
    super.key,
    required this.userRole,
    this.showOnlyGranted = true,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    final allPermissions = Permissions.getAllPermissions();
    final permissions =
        showOnlyGranted
            ? allPermissions
                .where(
                  (permission) => permission.allowedRoles.contains(userRole),
                )
                .toList()
            : allPermissions;

    return ListView.builder(
      shrinkWrap: true,
      physics: physics ?? const NeverScrollableScrollPhysics(),
      itemCount: permissions.length,
      itemBuilder: (context, index) {
        final permission = permissions[index];
        final hasPermission = permission.allowedRoles.contains(userRole);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: Icon(
              hasPermission ? Icons.check_circle : Icons.cancel,
              color: hasPermission ? Colors.green : Colors.red.shade200,
            ),
            title: Text(
              permission.description,
              style: TextStyle(
                color: hasPermission ? null : Colors.grey,
                fontWeight: hasPermission ? FontWeight.bold : null,
              ),
            ),
            subtitle: Text(
              'Code: ${permission.code}\nRôles autorisés: ${permission.allowedRoles.map((r) => Roles.getRoleName(r)).join(", ")}',
              style: TextStyle(
                fontSize: 12,
                color:
                    hasPermission ? Colors.grey.shade700 : Colors.grey.shade400,
              ),
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}

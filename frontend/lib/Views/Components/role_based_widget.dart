import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/utils/roles.dart';

class RoleBasedWidget extends ConsumerWidget {
  final Widget child;
  final List<int> allowedRoles;
  final Widget? fallback;
  final List<String>? requiredPermissions;

  const RoleBasedWidget({
    super.key,
    required this.child,
    required this.allowedRoles,
    this.fallback,
    this.requiredPermissions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRole = ref.watch(authProvider).user?.role;

    bool hasRole = allowedRoles.contains(userRole);

    bool hasPermissions = true;
    if (requiredPermissions != null && requiredPermissions!.isNotEmpty) {
      final rolePermissions = Roles.getRolePermissions()[userRole] ?? [];
      hasPermissions = requiredPermissions!.every(
        (permission) => rolePermissions.contains(permission),
      );
    }

    if (hasRole && hasPermissions) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}

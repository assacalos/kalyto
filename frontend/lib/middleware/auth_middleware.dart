import 'package:flutter/material.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/services/session_service.dart';

/// Helper de redirection pour l'authentification (utilisable dans go_router redirect).
/// Remplace l'ancien GetMiddleware.
class AuthMiddleware {
  /// Retourne la route de redirection si l'accès n'est pas autorisé, sinon null.
  static RouteSettings? redirect(String? route) {
    try {
      if (route == '/login' || route == '/splash') return null;

      final isValid = SessionService.isValidSession(allowLoginInProgress: true);
      if (!isValid) {
        if (!SessionService.isLoginInProgress()) {
          return const RouteSettings(name: '/login');
        }
        return null;
      }

      final userRole = SessionService.getUserRole();
      if (userRole == null) return const RouteSettings(name: '/login');
      if (userRole == Roles.ADMIN) return null;

      switch (route) {
        case '/rh':
          if (userRole != Roles.RH) return const RouteSettings(name: '/unauthorized');
          break;
        case '/commercial':
          if (userRole != Roles.COMMERCIAL) return const RouteSettings(name: '/unauthorized');
          break;
        case '/comptable':
          if (userRole != Roles.COMPTABLE) return const RouteSettings(name: '/unauthorized');
          break;
        case '/patron':
          if (userRole != Roles.PATRON) return const RouteSettings(name: '/unauthorized');
          break;
        case '/technicien':
          if (userRole != Roles.TECHNICIEN) return const RouteSettings(name: '/unauthorized');
          break;
        case '/admin/users':
          if (userRole != Roles.ADMIN && userRole != Roles.PATRON && userRole != Roles.RH) {
            return const RouteSettings(name: '/unauthorized');
          }
          break;
      }
      return null;
    } catch (e) {
      return const RouteSettings(name: '/login');
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/Views/Components/bottom_navigation.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/utils/roles.dart';

class DashboardWrapper extends ConsumerWidget {
  final Widget child;
  final int currentIndex;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;

  const DashboardWrapper({
    super.key,
    required this.child,
    required this.currentIndex,
    this.appBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final userRole = user?.role;

    return Scaffold(
      appBar: appBar,
      body: child,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar:
          userRole != null
              ? BottomNavigation(
                  currentIndex: currentIndex,
                  onTap: (index) => _handleNavigation(context, index, userRole),
                )
              : null,
    );
  }

  void _handleNavigation(BuildContext context, int index, int userRole) {
    switch (userRole) {
      case Roles.COMMERCIAL:
        _handleCommercialNavigation(context, index);
        break;
      case Roles.COMPTABLE:
        _handleComptableNavigation(context, index);
        break;
      case Roles.TECHNICIEN:
        _handleTechnicienNavigation(context, index);
        break;
      case Roles.RH:
        _handleRHNavigation(context, index);
        break;
      case Roles.PATRON:
        _handlePatronNavigation(context, index);
        break;
      default:
        break;
    }
  }

  void _handleCommercialNavigation(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/commercial');
        break;
      case 1:
        context.go('/clients-page');
        break;
      case 2:
        context.go('/devis-page');
        break;
      case 3:
        context.go('/attendance-punch');
        break;
      case 4:
        context.go('/media');
        break;
    }
  }

  void _handleComptableNavigation(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/comptable');
        break;
      case 1:
        context.go('/invoices');
        break;
      case 2:
        context.go('/payments');
        break;
      case 3:
        context.go('/attendance-punch');
        break;
      case 4:
        context.go('/media');
        break;
    }
  }

  void _handleTechnicienNavigation(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/technicien');
        break;
      case 1:
        context.go('/tickets');
        break;
      case 2:
        context.go('/interventions');
        break;
      case 3:
        context.go('/attendance-punch');
        break;
      case 4:
        context.go('/media');
        break;
    }
  }

  void _handleRHNavigation(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/rh');
        break;
      case 1:
        context.go('/employees');
        break;
      case 2:
        context.go('/leaves');
        break;
      case 3:
        context.go('/attendance-punch');
        break;
      case 4:
        context.go('/media');
        break;
    }
  }

  void _handlePatronNavigation(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/patron');
        break;
      case 1:
        context.go('/company');
        break;
      case 2:
        context.go('/approvals');
        break;
      case 3:
        context.go('/analytics');
        break;
      case 4:
        context.go('/media');
        break;
    }
  }
}

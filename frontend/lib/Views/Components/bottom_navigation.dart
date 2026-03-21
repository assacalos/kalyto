import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/utils/roles.dart';

class BottomNavigation extends ConsumerWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRole = ref.watch(authProvider).user?.role;
    if (userRole == null) return const SizedBox.shrink();

    return BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        onTap: onTap,
        selectedItemColor: _getPrimaryColor(userRole),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        items: _getNavigationItems(userRole),
      );
  }

  List<BottomNavigationBarItem> _getNavigationItems(int role) {
    switch (role) {
      case Roles.COMMERCIAL:
        return _getCommercialItems();
      case Roles.COMPTABLE:
        return _getComptableItems();
      case Roles.TECHNICIEN:
        return _getTechnicienItems();
      case Roles.RH:
        return _getRHItems();
      case Roles.PATRON:
        return _getPatronItems();
      default:
        return _getDefaultItems();
    }
  }

  List<BottomNavigationBarItem> _getCommercialItems() {
    return [
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      const BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clients'),
      const BottomNavigationBarItem(
        icon: Icon(Icons.description),
        label: 'Devis',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.access_time),
        label: 'Pointage',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.photo_library),
        label: 'Médias',
      ),
    ];
  }

  List<BottomNavigationBarItem> _getComptableItems() {
    return [
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.receipt_long),
        label: 'Factures',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.payment),
        label: 'Paiements',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.access_time),
        label: 'Pointage',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.photo_library),
        label: 'Médias',
      ),
    ];
  }

  List<BottomNavigationBarItem> _getTechnicienItems() {
    return [
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.report_problem),
        label: 'Tickets',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.build),
        label: 'Interventions',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.access_time),
        label: 'Pointage',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.photo_library),
        label: 'Médias',
      ),
    ];
  }

  List<BottomNavigationBarItem> _getRHItems() {
    return [
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.people),
        label: 'Employés',
      ),
      const BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Congés'),
      const BottomNavigationBarItem(
        icon: Icon(Icons.access_time),
        label: 'Présences',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.photo_library),
        label: 'Médias',
      ),
    ];
  }

  List<BottomNavigationBarItem> _getPatronItems() {
    return [
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.business),
        label: 'Entreprise',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.approval),
        label: 'Approbations',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.analytics),
        label: 'Analytics',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.photo_library),
        label: 'Médias',
      ),
    ];
  }

  List<BottomNavigationBarItem> _getDefaultItems() {
    return [
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
    ];
  }

  Color _getPrimaryColor(int role) {
    switch (role) {
      case Roles.COMMERCIAL:
        return Colors.blue;
      case Roles.COMPTABLE:
        return Colors.green;
      case Roles.TECHNICIEN:
        return Colors.indigo;
      case Roles.RH:
        return Colors.purple;
      case Roles.PATRON:
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }
}

class BottomNavigationController {
  final BuildContext context;
  BottomNavigationController(this.context);

  void onItemTapped(int index, List<String> routes) {
    if (index < routes.length) {
      context.go(routes[index]);
    }
  }
}

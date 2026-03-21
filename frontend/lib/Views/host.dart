import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/providers/host_provider.dart';
import 'package:easyconnect/Views/Components/bottomBar.dart';
import 'package:easyconnect/Views/Components/sideBar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class Host extends ConsumerWidget {
  const Host({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final currentIndex = ref.watch(hostIndexProvider);

    return Scaffold(
      appBar: AppBar(foregroundColor: Colors.black, title: const Text("EasyConnect")),
      drawer: SidebarWidget(
        customWidgets: [
          UserAccountsDrawerHeader(
            accountName: Text(user?.nom ?? 'Utilisateur'),
            accountEmail: Text(user?.email ?? 'Email'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.blueGrey.shade900),
            ),
            decoration: BoxDecoration(color: Colors.blueGrey.shade800),
          ),
          Visibility(
            visible: user?.role == 1,
            replacement: const SizedBox.shrink(),
            child: ListTile(
              leading: const Icon(Icons.people_alt_outlined, color: Colors.white),
              title: const Text("Gestion des utilisateurs", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                context.go('/admin/users');
              },
            ),
          ),
          Visibility(
            visible: user?.role == 1,
            replacement: const SizedBox.shrink(),
            child: ListTile(
              leading: const Icon(Icons.roller_shades_closed_outlined, color: Colors.white),
              title: const Text("Gestion des rôles", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                context.go('/admin/roles');
              },
            ),
          ),
          Visibility(
            visible: user?.role == 2,
            replacement: const SizedBox.shrink(),
            child: ListTile(
              leading: const Icon(Icons.people, color: Colors.white),
              title: const Text("Gestion des clients", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                context.go('/clients');
              },
            ),
          ),
          Visibility(
            visible: user?.role == 2,
            replacement: const SizedBox.shrink(),
            child: ListTile(
              leading: const Icon(Icons.request_quote, color: Colors.white),
              title: const Text("Gestion des proformas", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                context.go('/devis');
              },
            ),
          ),
          Visibility(
            visible: user?.role == 2,
            replacement: const SizedBox.shrink(),
            child: ListTile(
              leading: const Icon(Icons.insert_drive_file_outlined, color: Colors.white),
              title: const Text("Gestion des bordereaux", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                context.go('/bordereaux');
              },
            ),
          ),
          Visibility(
            visible: user?.role == 2,
            replacement: const SizedBox.shrink(),
            child: ListTile(
              leading: const Icon(Icons.book_online_rounded, color: Colors.white),
              title: const Text("Gestion des bons de commande", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                context.go('/bon-commandes');
              },
            ),
          ),
          Visibility(
            visible: user?.role == 3,
            replacement: const SizedBox.shrink(),
            child: ListTile(
              leading: const Icon(Icons.inventory_outlined, color: Colors.white),
              title: const Text("Gestion des factures", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                context.go('/invoices');
              },
            ),
          ),
          Visibility(
            visible: user?.role == 3,
            replacement: const SizedBox.shrink(),
            child: ListTile(
              leading: const Icon(Icons.paid, color: Colors.white),
              title: const Text("Gestion des paiements", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                context.go('/payments');
              },
            ),
          ),
          Visibility(
            visible: user?.role == 3,
            replacement: const SizedBox.shrink(),
            child: ListTile(
              leading: const Icon(Icons.table_view, color: Colors.white),
              title: const Text("Gestion des Taxes & Impôts", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                context.go('/taxes');
              },
            ),
          ),
          Visibility(
            visible: user?.role == 3,
            replacement: const SizedBox.shrink(),
            child: ListTile(
              leading: const Icon(Icons.fence_outlined, color: Colors.white),
              title: const Text("Gestion des fournisseurs", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                context.go('/suppliers');
              },
            ),
          ),
          Visibility(
            visible: user?.role == 4,
            replacement: const SizedBox.shrink(),
            child: ListTile(
              leading: const Icon(Icons.work, color: Colors.white),
              title: const Text("Gestion des employés", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                context.go('/employees');
              },
            ),
          ),
          Visibility(
            visible: user?.role == 4,
            replacement: const SizedBox.shrink(),
            child: ListTile(
              leading: const Icon(Icons.paid, color: Colors.white),
              title: const Text("Gestion des salaires", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                context.go('/salaries');
              },
            ),
          ),
          Visibility(
            visible: user?.role == 4,
            replacement: const SizedBox.shrink(),
            child: ListTile(
              leading: const Icon(Icons.receipt, color: Colors.white),
              title: const Text("Gestion des recrutements", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                context.go('/recruitment');
              },
            ),
          ),
          Visibility(
            visible: user?.role == 4,
            replacement: const SizedBox.shrink(),
            child: ListTile(
              leading: const Icon(Icons.holiday_village, color: Colors.white),
              title: const Text("Gestion des congés", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                context.go('/leaves');
              },
            ),
          ),
          Visibility(
            visible: user?.role == 5,
            replacement: const SizedBox.shrink(),
            child: ListTile(
              leading: const Icon(Icons.manage_accounts, color: Colors.white),
              title: const Text("Gestion des interventions", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                context.go('/interventions');
              },
            ),
          ),
          Visibility(
            visible: user?.role == 5,
            replacement: const SizedBox.shrink(),
            child: ListTile(
              leading: const Icon(Icons.precision_manufacturing_rounded, color: Colors.white),
              title: const Text("Gestion des equipements", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                context.go('/equipments');
              },
            ),
          ),
          Visibility(
            visible: user?.role == 6,
            replacement: const SizedBox.shrink(),
            child: ListTile(
              leading: const Icon(Icons.people, color: Colors.white),
              title: const Text("Validation Client", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                context.go('/clients/validation');
              },
            ),
          ),
          Visibility(
            visible: user?.role == 6,
            replacement: const SizedBox.shrink(),
            child: ListTile(
              leading: const Icon(Icons.request_quote, color: Colors.white),
              title: const Text("Validation Proforma", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                context.go('/devis/validation');
              },
            ),
          ),
          Visibility(
            visible: user?.role == 6,
            replacement: const SizedBox.shrink(),
            child: ListTile(
              leading: const Icon(Icons.insert_drive_file_outlined, color: Colors.white),
              title: const Text("Validation Bordereau", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                context.go('/bordereaux/validation');
              },
            ),
          ),
          Visibility(
            visible: user?.role == 6,
            replacement: const SizedBox.shrink(),
            child: ListTile(
              leading: const Icon(Icons.book_online_rounded, color: Colors.white),
              title: const Text("Validation Bon de commande", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                context.go('/bon-commandes/validation');
              },
            ),
          ),
          Visibility(
            visible: user?.role == 6,
            replacement: const SizedBox.shrink(),
            child: ListTile(
              leading: const Icon(Icons.inventory_outlined, color: Colors.white),
              title: const Text("Validation facture", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                context.go('/factures/validation');
              },
            ),
          ),
          Visibility(
            visible: user?.role == 6,
            replacement: const SizedBox.shrink(),
            child: ListTile(
              leading: const Icon(Icons.book_online_rounded, color: Colors.white),
              title: const Text("Validation Paiements", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                context.go('/paiements/validation');
              },
            ),
          ),
          Visibility(
            visible: user?.role == 6,
            replacement: const SizedBox.shrink(),
            child: ListTile(
              leading: const Icon(Icons.fence_outlined, color: Colors.white),
              title: const Text("Validation des fournisseurs", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                context.go('/suppliers/validation');
              },
            ),
          ),
          Visibility(
            visible: user?.role == 6,
            replacement: const SizedBox.shrink(),
            child: ListTile(
              leading: const Icon(Icons.paid, color: Colors.white),
              title: const Text("Validation des salaires", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                context.go('/salaires/validation');
              },
            ),
          ),
          Visibility(
            visible: user?.role == 6,
            replacement: const SizedBox.shrink(),
            child: ListTile(
              leading: const Icon(Icons.receipt, color: Colors.white),
              title: const Text("Validation des recrutements", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                context.go('/recrutement/validation');
              },
            ),
          ),
          Visibility(
            visible: user?.role == 6,
            replacement: const SizedBox.shrink(),
            child: ListTile(
              leading: const Icon(Icons.table_view, color: Colors.white),
              title: const Text("Validation des Taxes & Impôts", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                context.go('/taxes/validation');
              },
            ),
          ),
          Visibility(
            visible: user?.role == 6,
            replacement: const SizedBox.shrink(),
            child: ListTile(
              leading: const Icon(Icons.manage_accounts, color: Colors.white),
              title: const Text("Validation des interventions", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                context.go('/interventions/validation');
              },
            ),
          ),
          const ListTile(
            leading: Icon(Icons.present_to_all, color: Colors.white),
            title: Text("Pointage", style: TextStyle(color: Colors.white)),
          ),
          const ListTile(
            leading: Icon(Icons.report, color: Colors.white),
            title: Text("Rapports", style: TextStyle(color: Colors.white)),
          ),
          const ListTile(
            leading: Icon(Icons.note, color: Colors.white),
            title: Text("Bloc Notes", style: TextStyle(color: Colors.white)),
          ),
          if (user?.role == 1)
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.white),
              title: const Text("Paramètres", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                context.go('/admin/settings');
              },
            ),
          const ListTile(
            leading: Icon(Icons.person, color: Colors.white),
            title: Text("Profil", style: TextStyle(color: Colors.white)),
          ),
          const Divider(color: Colors.white54),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Déconnexion", style: TextStyle(color: Colors.red)),
            onTap: () {
              ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),

      bottomNavigationBar: BottomBarWidget(
        items: [
          BottomBarItem(icon: Icons.home, label: "Accueil"),
          BottomBarItem(icon: Icons.search, label: "Rechercher"),
          BottomBarItem(
            icon: Icons.notifications,
            label: "Notifications",
            showBadge: true,
          ),
          BottomBarItem(icon: Icons.message_rounded, label: "Chat"),
          BottomBarItem(icon: Icons.print, label: "Scanner"),
        ],
      ),
      body: _buildBodyForIndex(context, currentIndex),
    );
  }

  Widget _buildBodyForIndex(BuildContext context, int index) {
    switch (index) {
      case 0:
        return const Center(child: Text("Accueil"));
      case 1:
        return const Center(child: Text("Rechercher"));
      case 2:
        return const Center(child: Text("Notifications"));
      case 3:
        return const Center(child: Text("Chat"));
      case 4:
        return const Center(child: Text("Scanner"));
      default:
        return const Center(child: Text("Accueil"));
    }
  }
}

import 'package:flutter/material.dart';

/// Classe simple pour un item du menu
class SidebarItem {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  SidebarItem({required this.label, required this.icon, this.onTap});
}

class SidebarWidget extends StatelessWidget {
  final String title;
  final List<SidebarItem>? items; // version classique
  final List<Widget>? customWidgets; // version personnalisée

  const SidebarWidget({
    this.title = "EasyConnect",
    this.items,
    this.customWidgets,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.blueGrey.shade900,
        child: Column(
          children: [
            const SizedBox(height: 50),

            // Header du menu
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            // --- Si customWidgets est fourni, on l'affiche ---
            if (customWidgets != null)
              ...customWidgets!
            else if (items != null)
              // --- Sinon on affiche les items classiques ---
              ...items!.map(
                (item) => ListTile(
                  leading: Icon(item.icon, color: Colors.white),
                  title: Text(
                    item.label,
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    if (item.onTap != null) item.onTap!();
                  },
                ),
              ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}

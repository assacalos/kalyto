import 'package:flutter/material.dart';

class ComptableDashboard extends StatelessWidget {
  const ComptableDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard Comptable")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Bienvenue Comptable 📊",
              style: TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              child: const Text("Rapports Financiers"),
            ),
            ElevatedButton(
              onPressed: () {},
              child: const Text("Gestion des Factures"),
            ),
            ElevatedButton(
              onPressed: () {},
              child: const Text("Suivi des Paiements"),
            ),
          ],
        ),
      ),
    );
  }
}

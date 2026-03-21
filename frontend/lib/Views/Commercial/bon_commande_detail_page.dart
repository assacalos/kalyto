import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/providers/bon_commande_notifier.dart';
import 'package:easyconnect/Models/bon_commande_model.dart';
import 'package:easyconnect/Views/Components/app_bar_back_button.dart';

class BonCommandeDetailPage extends ConsumerWidget {
  final int bonCommandeId;

  const BonCommandeDetailPage({super.key, required this.bonCommandeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(bonCommandeProvider).bonCommandes.where((b) => b.id == bonCommandeId).toList();
    final bon = list.isEmpty ? null : list.first;

    if (bon == null) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBarBackButton(fallbackRoute: '/bon-commandes'),
          title: const Text('Détails du bon de commande'),
        ),
        body: const Center(child: Text('Bon de commande introuvable')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: const AppBarBackButton(fallbackRoute: '/bon-commandes'),
        title: Text('Bon de commande #${bon.id ?? 'N/A'}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(bon),
            const SizedBox(height: 16),
            _card('Informations', [
              _row(Icons.person, 'Client ID', bon.clientId.toString()),
              _row(Icons.person_outline, 'Commercial ID', bon.commercialId.toString()),
              _row(Icons.info, 'Statut', bon.statusText),
            ]),
            if (bon.fichiers.isNotEmpty) ...[
              const SizedBox(height: 16),
              _card('Fichiers scannés', [
                Text('Nombre de fichiers: ${bon.fichiers.length}'),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: bon.fichiers.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.attach_file, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(bon.fichiers[index])),
                        ],
                      ),
                    );
                  },
                ),
              ]),
            ],
            if (bon.status == 2) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _generatePdf(context, ref, bon.id!),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Générer PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _generatePdf(BuildContext context, WidgetRef ref, int id) async {
    try {
      await ref.read(bonCommandeProvider.notifier).generatePDF(id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF généré avec succès'), backgroundColor: Colors.green));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    }
  }

  Widget _header(BonCommande b) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey.shade100,
              child: const Icon(Icons.shopping_cart),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bon de commande #${b.id ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      b.statusText,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

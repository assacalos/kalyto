import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/providers/bordereau_notifier.dart';
import 'package:easyconnect/Models/bordereau_model.dart';

class BordereauDetailPage extends ConsumerWidget {
  final int bordereauId;

  const BordereauDetailPage({super.key, required this.bordereauId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bordereaux = ref.watch(bordereauProvider).bordereaux;
    final bordereau = bordereaux.where((b) => b.id == bordereauId).toList();
    final b = bordereau.isEmpty ? null : bordereau.first;
    final formatDate = DateFormat('dd/MM/yyyy');
    final nf = NumberFormat.currency(locale: 'fr_FR', symbol: 'fcfa');

    if (b == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détails du bordereau')),
        body: const Center(child: Text('Bordereau introuvable')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Bordereau ${b.reference}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(b, nf),
            const SizedBox(height: 16),
            _card('Informations', [
              if (b.titre != null && b.titre!.isNotEmpty)
                _row(Icons.title, 'Titre', b.titre!),
              _row(
                Icons.calendar_today,
                'Date de création',
                formatDate.format(b.dateCreation),
              ),
              if (b.dateValidation != null)
                _row(
                  Icons.event_available,
                  'Date de validation',
                  formatDate.format(b.dateValidation!),
                ),
              _row(Icons.info, 'Statut', b.statusText),
              if (b.etatLivraison != null && b.etatLivraison!.isNotEmpty)
                _row(Icons.local_shipping, 'État de livraison', _etatLivraisonLabel(b.etatLivraison!)),
              if (b.garantie != null && b.garantie!.isNotEmpty)
                _row(Icons.verified_user, 'Garantie', b.garantie!),
              if (b.dateLivraison != null)
                _row(
                  Icons.event,
                  'Date de livraison',
                  formatDate.format(b.dateLivraison!),
                ),
            ]),
            const SizedBox(height: 16),
            _card('Montants', [
              _row(
                Icons.summarize,
                'Montant HT',
                nf.format(b.montantHT),
              ),
              _row(Icons.percent, 'TVA', nf.format(b.montantTVA)),
              _row(
                Icons.calculate,
                'Montant TTC',
                nf.format(b.montantTTC),
                bold: true,
              ),
            ]),
            if (b.status == 3 &&
                b.commentaireRejet != null &&
                b.commentaireRejet!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _rejection('Motif du rejet', b.commentaireRejet!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _header(Bordereau b, NumberFormat nf) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey.shade100,
              child: const Icon(Icons.assignment),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.reference,
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
            Text(
              nf.format(b.montantTTC),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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

  String _etatLivraisonLabel(String value) {
    switch (value) {
      case 'en_attente':
        return 'En attente';
      case 'en_cours':
        return 'En cours';
      case 'livre':
        return 'Livré';
      case 'partiel':
        return 'Partiel';
      default:
        return value;
    }
  }

  Widget _rejection(String title, String reason) {
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.report, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reason,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


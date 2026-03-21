import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/providers/devis_notifier.dart';
import 'package:easyconnect/Models/devis_model.dart';
import 'package:easyconnect/Views/Components/app_bar_back_button.dart';

class DevisDetailPage extends ConsumerWidget {
  final int devisId;

  const DevisDetailPage({super.key, required this.devisId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devisList = ref.watch(devisProvider).devis.where((d) => d.id == devisId).toList();
    final devis = devisList.isEmpty ? null : devisList.first;
    final formatDate = DateFormat('dd/MM/yyyy');

    if (devis == null) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBarBackButton(fallbackRoute: '/devis'),
          title: const Text('Détails du devis'),
        ),
        body: const Center(child: Text('Devis introuvable')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: const AppBarBackButton(fallbackRoute: '/devis'),
        title: Text('Devis ${devis.reference}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(devis),
            const SizedBox(height: 16),

            _buildCard('Informations', [
              _row(
                Icons.calendar_today,
                'Date de création',
                formatDate.format(devis.dateCreation),
              ),
              if (devis.dateValidite != null)
                _row(
                  Icons.event,
                  'Date de validité',
                  formatDate.format(devis.dateValidite!),
                ),
              _row(Icons.info, 'Statut', devis.statusText),
            ]),

            const SizedBox(height: 16),
            _buildCard('Montants', [
              _row(
                Icons.summarize,
                'Sous-total',
                _formatCurrency(devis.sousTotal),
              ),
              _row(Icons.percent, 'Remise', _formatCurrency(devis.remise)),
              _row(
                Icons.account_balance,
                'TVA',
                _formatCurrency(devis.montantTVA),
              ),
              _row(
                Icons.calculate,
                'Total TTC',
                _formatCurrency(devis.totalTTC),
                bold: true,
              ),
            ]),

            if (devis.commentaire != null && devis.commentaire!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildCard('Commentaire', [
                _row(Icons.notes, 'Commentaire', devis.commentaire!),
              ]),
            ],

            if (devis.status == 3 &&
                devis.rejectionComment != null &&
                devis.rejectionComment!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildRejection('Motif du rejet', devis.rejectionComment!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Devis devis) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: devis.statusColor.withOpacity(0.1),
              child: Icon(devis.statusIcon, color: devis.statusColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    devis.reference,
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
                      color: devis.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      devis.statusText,
                      style: TextStyle(
                        color: devis.statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _formatCurrency(devis.totalTTC),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String title, List<Widget> children) {
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

  Widget _buildRejection(String title, String reason) {
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

  String _formatCurrency(double value) {
    final nf = NumberFormat.currency(locale: 'fr_FR', symbol: 'fcfa');
    return nf.format(value);
  }
}


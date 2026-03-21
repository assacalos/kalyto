import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/Models/invoice_model.dart';
import 'package:easyconnect/providers/invoice_notifier.dart';
import 'package:easyconnect/utils/tva_rates_ci.dart';

class InvoiceDetail extends ConsumerWidget {
  final InvoiceModel invoice;

  const InvoiceDetail({super.key, required this.invoice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(invoiceProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('Facture #${invoice.invoiceNumber}'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) =>
                _handleMenuAction(context, value, invoice, notifier),
            itemBuilder:
                (context) => [
                  if (invoice.status == 'en_attente' ||
                      invoice.status == 'draft' ||
                      invoice.status == 'pending_approval') ...[
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit, color: Colors.blue),
                        title: Text('Modifier'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'generate_pdf',
                      child: ListTile(
                        leading: Icon(Icons.picture_as_pdf),
                        title: Text('Générer PDF'),
                      ),
                    ),
                  ],
                  if (invoice.status == 'valide' ||
                      invoice.status == 'rejete' ||
                      invoice.status == 'rejetee' ||
                      invoice.status == 'sent' ||
                      invoice.status == 'paid')
                    const PopupMenuItem(
                      value: 'generate_pdf',
                      child: ListTile(
                        leading: Icon(Icons.picture_as_pdf),
                        title: Text('Générer PDF'),
                      ),
                    ),
                ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de la facture
            _buildInvoiceHeader(notifier),
            const SizedBox(height: 20),

            // Informations client
            _buildClientInfo(),
            const SizedBox(height: 20),

            // Articles
            _buildItemsList(),
            const SizedBox(height: 20),

            // Résumé financier
            _buildFinancialSummary(),
            const SizedBox(height: 20),

            // Notes et conditions
            if (invoice.notes != null || invoice.terms != null)
              _buildNotesSection(),

            // Informations de paiement
            if (invoice.paymentInfo != null) _buildPaymentInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceHeader(InvoiceNotifier notifier) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Facture #${invoice.invoiceNumber}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Commercial: ${invoice.commercialName}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: notifier
                        .getInvoiceStatusColor(invoice.status)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: notifier.getInvoiceStatusColor(invoice.status)),
                  ),
                  child: Text(
                    notifier.getInvoiceStatusText(invoice.status),
                    style: TextStyle(
                      color: notifier.getInvoiceStatusColor(invoice.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Date de facture',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      '${invoice.invoiceDate.day}/${invoice.invoiceDate.month}/${invoice.invoiceDate.year}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Date d\'échéance',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      '${invoice.dueDate.day}/${invoice.dueDate.month}/${invoice.dueDate.year}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientInfo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Informations client',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              invoice.clientName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              invoice.clientEmail,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(invoice.clientAddress, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.list, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Articles',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (invoice.items.isEmpty)
              const Center(
                child: Text(
                  'Aucun article',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: invoice.items.length,
                itemBuilder: (context, index) {
                  return _buildItemRow(invoice.items[index]);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(InvoiceItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (item.unit != null)
                  Text(
                    'Unité: ${item.unit}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${item.quantity} x ${item.unitPrice.toStringAsFixed(2)} ',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${item.totalPrice.toStringAsFixed(2)} fcfa',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calculate, color: Colors.teal),
                const SizedBox(width: 8),
                const Text(
                  'Résumé financier',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSummaryRow(
              'Sous-total',
              '${invoice.subtotal.toStringAsFixed(2)} FCFA',
            ),
            _buildSummaryRow(
              tvaRateLabelCi(invoice.taxRate),
              '${invoice.taxAmount.toStringAsFixed(2)} FCFA',
            ),
            const Divider(),
            _buildSummaryRow(
              'Total',
              '${invoice.totalAmount.toStringAsFixed(2)} FCFA',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: FontWeight.bold,
              color: isTotal ? Colors.green : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.note, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'Notes et conditions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (invoice.notes != null) ...[
              const Text(
                'Notes:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(invoice.notes!),
              const SizedBox(height: 12),
            ],
            if (invoice.terms != null) ...[
              const Text(
                'Conditions de paiement:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(invoice.terms!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfo() {
    final payment = invoice.paymentInfo!;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.payment, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Informations de paiement',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildPaymentRow('Méthode', _getPaymentMethodText(payment.method)),
            _buildPaymentRow(
              'Montant',
              '${payment.amount.toStringAsFixed(2)} fcfa',
            ),
            if (payment.reference != null)
              _buildPaymentRow('Référence', payment.reference!),
            if (payment.paymentDate != null)
              _buildPaymentRow(
                'Date de paiement',
                '${payment.paymentDate!.day}/${payment.paymentDate!.month}/${payment.paymentDate!.year}',
              ),
            if (payment.notes != null)
              _buildPaymentRow('Notes', payment.notes!),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _getPaymentMethodText(String method) {
    switch (method) {
      case 'bank_transfer':
        return 'Virement bancaire';
      case 'check':
        return 'Chèque';
      case 'cash':
        return 'Espèces';
      case 'card':
        return 'Carte bancaire';
      default:
        return method;
    }
  }

  void _handleMenuAction(
    BuildContext context,
    String action,
    InvoiceModel invoice,
    InvoiceNotifier notifier,
  ) {
    switch (action) {
      case 'edit':
        context.push('/invoices/edit', extra: invoice.id);
        break;
      case 'generate_pdf':
        notifier.generatePDF(invoice.id).then((_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('PDF généré avec succès'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }).catchError((e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
        break;
    }
  }
}

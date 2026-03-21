import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/Models/invoice_model.dart';
import 'package:easyconnect/providers/invoice_notifier.dart';
import 'package:easyconnect/Views/Components/client_selection_dialog.dart';
import 'package:easyconnect/providers/invoice_state.dart';
import 'package:easyconnect/utils/tva_rates_ci.dart';

class InvoiceForm extends ConsumerStatefulWidget {
  const InvoiceForm({super.key});

  @override
  ConsumerState<InvoiceForm> createState() => _InvoiceFormState();
}

class _InvoiceFormState extends ConsumerState<InvoiceForm> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _termsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final extra = GoRouterState.of(context).extra;
      final editId = extra is int ? extra : null;
      if (editId != null) {
        ref.read(invoiceProvider.notifier).loadInvoiceForEdit(editId);
      }
      final state = ref.read(invoiceProvider);
      _notesController.text = state.notes;
      _termsController.text = state.terms;
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(invoiceProvider);
    final notifier = ref.read(invoiceProvider.notifier);

    ref.listen<InvoiceState>(invoiceProvider, (prev, next) {
      if (prev?.isLoadingInvoiceForEdit == true &&
          next.isLoadingInvoiceForEdit == false &&
          next.editInvoiceId != null) {
        _notesController.text = next.notes;
        _termsController.text = next.terms;
      }
    });

    final isEdit = state.editInvoiceId != null;
    final isLoadingEdit = state.isLoadingInvoiceForEdit;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Modifier la facture' : 'Créer une facture'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: isLoadingEdit
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildClientSection(context, state, notifier),
                  const SizedBox(height: 20),
                  _buildItemsSection(context, state, notifier),
                  const SizedBox(height: 20),
                  _buildBillingSection(context, state, notifier),
                  const SizedBox(height: 20),
                  _buildNotesSection(state, notifier),
                  const SizedBox(height: 20),
                  _buildSummarySection(context, state, notifier),
                ],
              ),
            ),
    );
  }

  Widget _buildClientSection(
    BuildContext context,
    InvoiceState state,
    InvoiceNotifier notifier,
  ) {
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
                Expanded(
                  child: Row(
                    children: [
                      const Text(
                        'Informations client',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green),
                          ),
                          child: const Text(
                            'Validés uniquement',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showClientSelectionDialog(context, notifier),
                  icon: const Icon(Icons.search, size: 16),
                  label: const Text('Sélectionner'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildClientDisplay(state, notifier),
          ],
        ),
      ),
    );
  }

  Widget _buildClientDisplay(InvoiceState state, InvoiceNotifier notifier) {
    final client = state.selectedClient;
    if (client != null) {
      final name = client.nomEntreprise?.isNotEmpty == true
          ? client.nomEntreprise!
          : '${client.nom ?? ''} ${client.prenom ?? ''}'.trim();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name.isEmpty ? 'Client #${client.id}' : name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (client.nomEntreprise?.isNotEmpty == true &&
              '${client.nom ?? ''} ${client.prenom ?? ''}'.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Contact: ${client.nom ?? ''} ${client.prenom ?? ''}'.trim(),
            ),
            const SizedBox(height: 4),
          ] else
            const SizedBox(height: 8),
          if (client.email != null) ...[
            Text('Email: ${client.email}'),
            const SizedBox(height: 4),
          ],
          if (client.contact != null) ...[
            Text('Contact: ${client.contact}'),
            const SizedBox(height: 4),
          ],
          if (client.adresse != null) ...[
            Text('Adresse: ${client.adresse}'),
            const SizedBox(height: 4),
          ],
          Text(
            'Statut: ${client.statusText}',
            style: TextStyle(
              color: client.statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: notifier.clearSelectedClient,
            child: const Text('Changer de client'),
          ),
        ],
      );
    }
    if (state.selectedClientId != 0 &&
        (state.selectedClientName.isNotEmpty ||
            state.selectedClientEmail.isNotEmpty)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            state.selectedClientName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (state.selectedClientEmail.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Email: ${state.selectedClientEmail}'),
          ],
          if (state.selectedClientAddress.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Adresse: ${state.selectedClientAddress}'),
          ],
          const SizedBox(height: 12),
          TextButton(
            onPressed: notifier.clearSelectedClient,
            child: const Text('Changer de client'),
          ),
        ],
      );
    }
    return const Text(
      'Aucun client sélectionné',
      style: TextStyle(color: Colors.grey),
    );
  }

  Widget _buildItemsSection(
    BuildContext context,
    InvoiceState state,
    InvoiceNotifier notifier,
  ) {
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showAddItemDialog(context, notifier),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Ajouter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (state.invoiceItems.isEmpty)
              const Center(
                child: Text(
                  'Aucun article ajouté',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Column(
                children: state.invoiceItems.asMap().entries.map((entry) {
                  return _buildItemCard(
                    entry.key,
                    entry.value,
                    notifier,
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(
    int index,
    InvoiceItem item,
    InvoiceNotifier notifier,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                  Text(
                    '${item.quantity} x ${item.unitPrice.toStringAsFixed(2)} ',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
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
            IconButton(
              onPressed: () => notifier.removeInvoiceItem(index),
              icon: const Icon(Icons.delete, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillingSection(
    BuildContext context,
    InvoiceState state,
    InvoiceNotifier notifier,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Paramètres de facturation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Date de facture'),
                      TextButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: state.invoiceDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null) notifier.setInvoiceDate(date);
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          '${state.invoiceDate.day}/${state.invoiceDate.month}/${state.invoiceDate.year}',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Date d\'échéance'),
                      TextButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: state.dueDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null) notifier.setDueDate(date);
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          '${state.dueDate.day}/${state.dueDate.month}/${state.dueDate.year}',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Taux de TVA (Côte d\'Ivoire) :'),
            const SizedBox(height: 8),
            DropdownButtonFormField<double>(
              value: tvaRatesCiValues.contains(state.taxRate)
                  ? state.taxRate
                  : tvaRateCiDefault,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: tvaRatesCi
                  .map((e) => DropdownMenuItem<double>(
                        value: e.rate,
                        child: Text(e.label),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) notifier.setTaxRate(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection(
    InvoiceState state,
    InvoiceNotifier notifier,
  ) {
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: notifier.setNotes,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _termsController,
              decoration: const InputDecoration(
                labelText: 'Conditions de paiement',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: notifier.setTerms,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(
    BuildContext context,
    InvoiceState state,
    InvoiceNotifier notifier,
  ) {
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
                  'Résumé',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSummaryRow(
              'Sous-total',
              '${state.formSubtotal.toStringAsFixed(2)} FCFA',
            ),
            _buildSummaryRow(
              tvaRateLabelCi(state.taxRate),
              '${state.formTaxAmount.toStringAsFixed(2)} FCFA',
            ),
            const Divider(),
            _buildSummaryRow(
              'Total',
              '${state.formTotalAmount.toStringAsFixed(2)} FCFA',
              isTotal: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: state.isCreating
                    ? null
                    : () => _submitForm(context, state, notifier),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: state.isCreating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        state.editInvoiceId != null
                            ? 'Enregistrer les modifications'
                            : 'Enregistrer la facture',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
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

  Future<void> _submitForm(
    BuildContext context,
    InvoiceState state,
    InvoiceNotifier notifier,
  ) async {
    notifier.setNotes(_notesController.text);
    notifier.setTerms(_termsController.text);

    final currentState = ref.read(invoiceProvider);

    if (currentState.editInvoiceId != null) {
      try {
        await notifier.updateInvoiceFromForm();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Facture modifiée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/invoices');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      return;
    }

    if (currentState.selectedClientId == 0 &&
        currentState.selectedClientName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un client'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (currentState.invoiceItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez ajouter au moins un article'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final success = await notifier.createInvoice(
        clientId: currentState.selectedClientId,
        clientName: currentState.selectedClientName.isNotEmpty
            ? currentState.selectedClientName
            : 'Client #${currentState.selectedClientId}',
        clientEmail: currentState.selectedClientEmail,
        clientAddress: currentState.selectedClientAddress,
        invoiceDate: currentState.invoiceDate,
        dueDate: currentState.dueDate,
        items: currentState.invoiceItems,
        taxRate: currentState.taxRate,
        notes: currentState.notes.trim().isEmpty
            ? null
            : currentState.notes.trim(),
        terms: currentState.terms.trim().isEmpty
            ? null
            : currentState.terms.trim(),
      );
      if (success && context.mounted) {
        notifier.clearForm();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Facture créée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/invoices');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showClientSelectionDialog(
    BuildContext context,
    InvoiceNotifier notifier,
  ) {
    if (ref.read(invoiceProvider).availableClients.isEmpty) {
      notifier.loadValidatedClients().then((_) {
        if (context.mounted) _openClientDialog(context, notifier);
      }).catchError((_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible de charger les clients validés'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    } else {
      _openClientDialog(context, notifier);
    }
  }

  void _openClientDialog(BuildContext context, InvoiceNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => ClientSelectionDialog(
        onClientSelected: (client) {
          notifier.selectClientForInvoice(client);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showAddItemDialog(BuildContext context, InvoiceNotifier notifier) {
    final descriptionController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final unitPriceController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajouter un article'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantité',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: unitPriceController,
              decoration: const InputDecoration(
                labelText: 'Prix unitaire (fcfa)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (descriptionController.text.isNotEmpty &&
                  quantityController.text.isNotEmpty &&
                  unitPriceController.text.isNotEmpty) {
                notifier.addInvoiceItem(
                  description: descriptionController.text,
                  quantity: int.tryParse(quantityController.text) ?? 1,
                  unitPrice:
                      double.tryParse(unitPriceController.text) ?? 0.0,
                );
                Navigator.pop(ctx);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Veuillez remplir tous les champs obligatoires',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }
}

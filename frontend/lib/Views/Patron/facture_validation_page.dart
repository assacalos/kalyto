import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/providers/invoice_notifier.dart';
import 'package:easyconnect/Models/invoice_model.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';
import 'package:easyconnect/utils/tva_rates_ci.dart';

class FactureValidationPage extends ConsumerStatefulWidget {
  const FactureValidationPage({super.key});

  @override
  ConsumerState<FactureValidationPage> createState() =>
      _FactureValidationPageState();
}

class _FactureValidationPageState extends ConsumerState<FactureValidationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) _loadInvoices();
    });
    _loadInvoices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInvoices() async {
    final notifier = ref.read(invoiceProvider.notifier);
    notifier.filterInvoices(status: 'all', start: null, end: null, search: '');
    await notifier.loadInvoices(forceRefresh: true);
    await notifier.loadPendingInvoices();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(invoiceProvider);
    final notifier = ref.read(invoiceProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation des Factures'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInvoices,
            tooltip: 'Actualiser',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Tous', icon: Icon(Icons.list)),
            Tab(text: 'En attente', icon: Icon(Icons.pending)),
            Tab(text: 'Validés', icon: Icon(Icons.check_circle)),
            Tab(text: 'Rejetés', icon: Icon(Icons.cancel)),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par numéro, client...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const SkeletonSearchResults(itemCount: 6)
                : _buildInvoiceList(state.invoices, notifier),
          ),
        ],
      ),
    );
  }

  List<InvoiceModel> _filterByTabAndSearch(
      List<InvoiceModel> invoices, int tabIndex, String search) {
    List<InvoiceModel> filtered = invoices;
    if (tabIndex == 1) {
      filtered = filtered.where((inv) {
        final s = inv.status.toLowerCase().trim();
        return s == 'draft' ||
            s == 'en_attente' ||
            s == 'pending' ||
            s == 'en attente';
      }).toList();
    } else if (tabIndex == 2) {
      filtered = filtered.where((inv) {
        final s = inv.status.toLowerCase().trim();
        return s == 'valide' || s == 'validated' || s == 'approved';
      }).toList();
    } else if (tabIndex == 3) {
      filtered = filtered
          .where((inv) =>
              inv.status.toLowerCase().trim() == 'rejete' ||
              inv.status.toLowerCase().trim() == 'rejected')
          .toList();
    }
    if (search.isNotEmpty) {
      filtered = filtered.where((inv) {
        return inv.invoiceNumber.toLowerCase().contains(search.toLowerCase()) ||
            inv.clientName.toLowerCase().contains(search.toLowerCase());
      }).toList();
    }
    return filtered;
  }

  Widget _buildInvoiceList(
      List<InvoiceModel> invoices, InvoiceNotifier notifier) {
    final filtered =
        _filterByTabAndSearch(invoices, _tabController.index, _searchQuery);

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'Aucune facture trouvée'
                  : 'Aucune facture correspondant à "$_searchQuery"',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                icon: const Icon(Icons.clear),
                label: const Text('Effacer la recherche'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final invoice = filtered[index];
        return _buildInvoiceCard(context, invoice, notifier);
      },
    );
  }

  Widget _buildInvoiceCard(
      BuildContext context, InvoiceModel invoice, InvoiceNotifier notifier) {
    final formatDate = DateFormat('dd/MM/yyyy');
    final formatCurrency =
        NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA');
    final statusColor = notifier.getInvoiceStatusColor(invoice.status);
    final statusIcon = _getStatusIcon(invoice.status);
    final statusText = _getStatusText(invoice.status);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          invoice.invoiceNumber,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Client: ${invoice.clientName}'),
            Text('Date: ${formatDate.format(invoice.invoiceDate)}'),
            Text('Montant: ${formatCurrency.format(invoice.totalAmount)}'),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informations générales',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Numéro: ${invoice.invoiceNumber}'),
                      Text('Client: ${invoice.clientName}'),
                      Text('Email: ${invoice.clientEmail}'),
                      Text('Adresse: ${invoice.clientAddress}'),
                      Text('Commercial: ${invoice.commercialName}'),
                      Text(
                          'Date facture: ${formatDate.format(invoice.invoiceDate)}'),
                      Text(
                          'Date échéance: ${formatDate.format(invoice.dueDate)}'),
                      if (invoice.notes != null) Text('Notes: ${invoice.notes}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Détails des articles',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (invoice.items.isEmpty)
                  const Text('Aucun article')
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: invoice.items.length,
                    itemBuilder: (context, i) =>
                        _buildItemDetails(invoice.items[i], formatCurrency),
                  ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Sous-total:'),
                          Text(formatCurrency.format(invoice.subtotal)),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${tvaRateLabelCi(invoice.taxRate)}:'),
                          Text(formatCurrency.format(invoice.taxAmount)),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            formatCurrency.format(invoice.totalAmount),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildActionButtons(context, invoice, notifier),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemDetails(InvoiceItem item, NumberFormat formatCurrency) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(item.description,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text('${item.quantity}')),
          Expanded(child: Text(formatCurrency.format(item.unitPrice))),
          Expanded(
            child: Text(
              formatCurrency.format(item.quantity * item.unitPrice),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, InvoiceModel invoice, InvoiceNotifier notifier) {
    final s = invoice.status.toLowerCase().trim();
    final isPending =
        s == 'en_attente' || s == 'pending' || s == 'draft' || s == 'en attente';
    final isValidated =
        s == 'valide' || s == 'validated' || s == 'approved';
    final isRejected = s == 'rejete' || s == 'rejected';

    if (isPending) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: () => _showApproveConfirmation(context, invoice, notifier),
            icon: const Icon(Icons.check),
            label: const Text('Valider'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _showRejectDialog(context, invoice, notifier),
            icon: const Icon(Icons.close),
            label: const Text('Rejeter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      );
    }

    if (isValidated) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Facture validée',
                  style: TextStyle(
                      color: Colors.green[700], fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                await notifier.generatePDF(invoice.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('PDF généré avec succès'),
                        backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Erreur: $e'),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Générer PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      );
    }

    if (isRejected) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cancel, color: Colors.red),
            const SizedBox(width: 8),
            Text(
              'Facture rejetée',
              style: TextStyle(
                  color: Colors.red[700], fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.help, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            'Statut: ${invoice.status}',
            style: TextStyle(
                color: Colors.grey[600], fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'en_attente':
        return Icons.pending;
      case 'valide':
        return Icons.check_circle;
      case 'rejete':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'en_attente':
        return 'En attente';
      case 'valide':
        return 'Validé';
      case 'rejete':
        return 'Rejeté';
      default:
        return status;
    }
  }

  void _showApproveConfirmation(
      BuildContext context, InvoiceModel invoice, InvoiceNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Voulez-vous valider cette facture ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await notifier.approveInvoice(invoice.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Facture approuvée avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadInvoices();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Erreur: $e'),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(
      BuildContext context, InvoiceModel invoice, InvoiceNotifier notifier) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeter la facture'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Motif du rejet',
            hintText: 'Entrez le motif du rejet',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Veuillez entrer un motif de rejet')),
                );
                return;
              }
              Navigator.pop(ctx);
              try {
                await notifier.rejectInvoice(
                    invoice.id, reasonController.text.trim());
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Facture rejetée'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  _loadInvoices();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/Models/invoice_model.dart';
import 'package:easyconnect/providers/invoice_notifier.dart';
import 'package:easyconnect/Views/Comptable/invoice_detail.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';
import 'package:easyconnect/Views/Components/export_format_dialog.dart';
import 'package:easyconnect/services/export_service.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/utils/app_config.dart';

class InvoiceListPage extends ConsumerStatefulWidget {
  const InvoiceListPage({super.key});

  @override
  ConsumerState<InvoiceListPage> createState() => _InvoiceListPageState();
}

class _InvoiceListPageState extends ConsumerState<InvoiceListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      final status = _statusFromTab(_tabController.index);
      ref.read(invoiceProvider.notifier).filterInvoices(status: status);
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(invoiceProvider.notifier).filterInvoices(
        status: _statusFromTab(_tabController.index),
      );
      ref.read(invoiceProvider.notifier).loadInvoices(forceRefresh: true);
      _startAutoRefresh();
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  String _statusFromTab(int tabIndex) {
    switch (tabIndex) {
      case 1:
        return 'en_attente';
      case 2:
        return 'valide';
      case 3:
        return 'rejete';
      default:
        return 'all';
    }
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer =
        Timer.periodic(AppConfig.realtimeListRefreshInterval, (_) {
      if (!mounted) return;
      ref.read(invoiceProvider.notifier).loadInvoices(forceRefresh: true);
    });
  }

  List<InvoiceModel> _filteredInvoices(List<InvoiceModel> invoices) {
    List<InvoiceModel> filtered = invoices;

    switch (_tabController.index) {
      case 0:
        break;
      case 1:
        filtered = invoices.where((invoice) {
          final status = invoice.status.toLowerCase().trim();
          return status == 'en_attente' ||
              status == 'pending' ||
              status == 'draft' ||
              status == 'pending_approval';
        }).toList();
        break;
      case 2:
        filtered = invoices.where((invoice) {
          final status = invoice.status.toLowerCase().trim();
          return status == 'valide' ||
              status == 'validated' ||
              status == 'valid' ||
              status == 'sent' ||
              status == 'paid';
        }).toList();
        break;
      case 3:
        filtered = invoices.where((invoice) {
          final status = invoice.status.toLowerCase().trim();
          return status == 'rejete' ||
              status == 'rejetee' ||
              status == 'rejected' ||
              status == 'cancelled';
        }).toList();
        break;
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (invoice) =>
                invoice.invoiceNumber
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                invoice.clientName
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    return filtered;
  }

  Future<void> _exportInvoices(BuildContext context, List<InvoiceModel> list) async {
    final format = await showExportFormatDialog(context, title: 'Exporter les factures');
    if (format == null || !context.mounted) return;
    const headers = ['Id', 'N° facture', 'Client', 'Date', 'Échéance', 'Montant HT', 'TVA %', 'Total TTC', 'Statut', 'Créé le'];
    final rows = list.map((f) => [
      f.id,
      f.invoiceNumber,
      f.clientName,
      f.invoiceDate,
      f.dueDate,
      f.subtotal,
      f.taxRate,
      f.totalAmount,
      f.status,
      f.createdAt,
    ]).toList();
    final base = 'factures_${DateFormat('yyyy-MM-dd').format(DateTime.now())}';
    try {
      if (format == 'excel') {
        await ExportService.exportExcel(headers: headers, rows: rows, filenameBase: base, sheetName: 'Factures');
      } else {
        await ExportService.exportCsv(headers: headers, rows: rows, filenameBase: base);
      }
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export réussi')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(invoiceProvider);
    final notifier = ref.read(invoiceProvider.notifier);
    final invoices = state.invoices;
    final filtered = _filteredInvoices(invoices);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Factures'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Exporter',
            onPressed: invoices.isEmpty ? null : () => _exportInvoices(context, invoices),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(invoiceProvider.notifier).loadInvoices(forceRefresh: true),
            tooltip: 'Actualiser',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Toutes', icon: Icon(Icons.list)),
            Tab(text: 'En attente', icon: Icon(Icons.pending)),
            Tab(text: 'Validées', icon: Icon(Icons.check_circle)),
            Tab(text: 'Rejetées', icon: Icon(Icons.cancel)),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher par numéro ou client...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const SkeletonSearchResults(itemCount: 6)
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.inbox,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune facture trouvée',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            if (invoices.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Total: ${invoices.length} facture(s)',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final invoice = filtered[index];
                          return _buildInvoiceCard(
                            context,
                            invoice,
                            notifier,
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/invoices/new'),
        tooltip: 'Nouvelle facture',
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildInvoiceCard(
    BuildContext context,
    InvoiceModel invoice,
    InvoiceNotifier notifier,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InvoiceDetail(invoice: invoice),
          ),
        ),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      invoice.invoiceNumber,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: notifier
                          .getInvoiceStatusColor(invoice.status)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: notifier
                            .getInvoiceStatusColor(invoice.status)
                            .withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      notifier.getInvoiceStatusText(invoice.status),
                      style: TextStyle(
                        color: notifier.getInvoiceStatusColor(invoice.status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      invoice.clientName,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(invoice.invoiceDate),
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Text(
                    '${invoice.totalAmount.toStringAsFixed(0)} ${invoice.currency}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
              if (invoice.status == 'rejete' &&
                  (invoice.notes != null && invoice.notes!.isNotEmpty)) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.report, size: 16, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Raison: ${invoice.notes}',
                        style: TextStyle(
                            color: Colors.red[700], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (invoice.status == 'en_attente' ||
                      invoice.status == 'draft' ||
                      invoice.status == 'pending_approval')
                    TextButton.icon(
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Modifier'),
                      onPressed: () => context.push('/invoices/edit',
                          extra: invoice.id),
                    ),
                  if (invoice.status == 'en_attente' ||
                      invoice.status == 'draft' ||
                      invoice.status == 'pending_approval')
                    const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Détails'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InvoiceDetail(invoice: invoice),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.picture_as_pdf, size: 16),
                    label: const Text('PDF'),
                    onPressed: () => _generatePDF(context, invoice, notifier),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _generatePDF(
    BuildContext context,
    InvoiceModel invoice,
    InvoiceNotifier notifier,
  ) async {
    try {
      await notifier.generatePDF(invoice.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF généré avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de générer le PDF'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

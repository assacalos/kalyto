import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/payment_notifier.dart';
import 'package:easyconnect/providers/payment_state.dart';
import 'package:easyconnect/Models/payment_model.dart';
import 'package:easyconnect/Views/Components/role_based_widget.dart';
import 'package:easyconnect/Views/Components/paginated_list_view.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';
import 'package:easyconnect/Views/Components/export_format_dialog.dart';
import 'package:easyconnect/services/export_service.dart';
import 'package:easyconnect/Views/Components/app_bar_back_button.dart';
import 'package:intl/intl.dart';

class PaymentList extends ConsumerStatefulWidget {
  final int? clientId;

  const PaymentList({super.key, this.clientId});

  @override
  ConsumerState<PaymentList> createState() => _PaymentListState();
}

class _PaymentListState extends ConsumerState<PaymentList>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        ref.read(paymentProvider.notifier).loadByStatus(_tabController.index);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        ref.read(paymentProvider.notifier).loadByStatus(0, forceRefresh: true);
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _exportPayments(BuildContext context, List<PaymentModel> list) async {
    final format = await showExportFormatDialog(context, title: 'Exporter les paiements');
    if (format == null || !context.mounted) return;
    const headers = ['Id', 'Référence', 'Client', 'Date', 'Montant', 'Mode', 'Statut'];
    final rows = list.map((p) => [
      p.id,
      p.paymentNumber,
      p.clientName,
      p.paymentDate,
      p.amount,
      p.paymentMethod,
      p.status,
    ]).toList();
    final base = 'paiements_${DateFormat('yyyy-MM-dd').format(DateTime.now())}';
    try {
      if (format == 'excel') {
        await ExportService.exportExcel(headers: headers, rows: rows, filenameBase: base, sheetName: 'Paiements');
      } else {
        await ExportService.exportCsv(headers: headers, rows: rows, filenameBase: base);
      }
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export réussi')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  List<PaymentModel> _filteredPayments(PaymentState state) {
    List<PaymentModel> list = state.payments;
    if (_searchQuery.isEmpty) return list;
    return list
        .where(
          (payment) =>
              payment.paymentNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              payment.clientName.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentProvider);
    final notifier = ref.read(paymentProvider.notifier);
    final filtered = _filteredPayments(paymentState);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBarBackButton(fallbackRoute: '/comptable', iconColor: Colors.white),
        title: const Text('Paiements'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Exporter',
            onPressed: filtered.isEmpty ? null : () => _exportPayments(context, filtered),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.loadPayments(forceRefresh: true),
            tooltip: 'Actualiser',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
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
            child: paymentState.isLoading
                ? const SkeletonSearchResults(itemCount: 6)
                : filtered.isEmpty
                    ? const Center(child: Text('Aucun paiement trouvé'))
                    : PaginatedListView(
                        scrollController: _scrollController,
                        onLoadMore: notifier.loadMore,
                        hasNextPage: paymentState.hasNextPage,
                        isLoadingMore: paymentState.isLoadingMore,
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final payment = filtered[index];
                          return _buildPaymentCard(payment, notifier);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: RoleBasedWidget(
        allowedRoles: [Roles.ADMIN, Roles.COMPTABLE, Roles.PATRON],
        child: FloatingActionButton(
          onPressed: () => context.go('/payments/new'),
          tooltip: 'Nouveau paiement',
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildPaymentCard(PaymentModel payment, PaymentNotifier notifier) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: () => _showPaymentDetail(payment),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec numéro et statut
              Row(
                children: [
                  Expanded(
                    child: Text(
                      payment.paymentNumber,
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
                      color: _getStatusColor(payment).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(payment).withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      _getStatusLabel(payment),
                      style: TextStyle(
                        color: _getStatusColor(payment),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Client
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      payment.clientName,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Date
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(payment.paymentDate),
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Montant
              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Text(
                    '${payment.amount.toStringAsFixed(0)} ${payment.currency}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),

              // Raison du rejet si rejeté
              if (payment.isRejected &&
                  (payment.notes != null && payment.notes!.isNotEmpty)) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.report, size: 16, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Raison: ${payment.notes}',
                        style: TextStyle(color: Colors.red[700], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],

              // Actions
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (payment.status == 'draft' || payment.status == 'pending')
                    TextButton.icon(
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Modifier'),
                      onPressed: () => _editPayment(payment),
                    ),
                  TextButton.icon(
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Détails'),
                    onPressed: () => _showPaymentDetail(payment),
                  ),
                  // Bouton PDF seulement pour les paiements validés
                  if (payment.isApproved) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.picture_as_pdf, size: 16),
                      label: const Text('PDF'),
                      onPressed: () => notifier.generatePDF(payment.id),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(PaymentModel payment) {
    if (payment.isPending) return Colors.orange;
    if (payment.isApproved) return Colors.green;
    if (payment.isRejected) return Colors.red;
    return Colors.grey;
  }

  String _getStatusLabel(PaymentModel payment) {
    if (payment.isPending) return 'En attente';
    if (payment.isApproved) return 'Validé';
    if (payment.isRejected) return 'Rejeté';
    return 'Inconnu';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showPaymentDetail(PaymentModel payment) {
    context.push('/payments/detail', extra: payment.id);
  }

  void _editPayment(PaymentModel payment) {
    context.push('/payments/edit', extra: payment.id);
  }
}

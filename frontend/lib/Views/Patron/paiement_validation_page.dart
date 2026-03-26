import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/Models/payment_model.dart';
import 'package:easyconnect/providers/payment_notifier.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';
import 'package:easyconnect/utils/app_config.dart';

class PaiementValidationPage extends ConsumerStatefulWidget {
  const PaiementValidationPage({super.key});

  @override
  ConsumerState<PaiementValidationPage> createState() => _PaiementValidationPageState();
}

class _PaiementValidationPageState extends ConsumerState<PaiementValidationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPayments();
      _startAutoRefresh();
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      ref.read(paymentProvider.notifier).loadByStatus(
            _tabController.index,
            forceRefresh: true,
          );
    }
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer =
        Timer.periodic(AppConfig.realtimeListRefreshInterval, (_) {
      if (!mounted) return;
      ref
          .read(paymentProvider.notifier)
          .loadByStatus(_tabController.index, forceRefresh: true);
    });
  }

  Future<void> _loadPayments() async {
    final user = ref.read(authProvider).user;
    if (user != null) CacheHelper.clearByPrefix('payments_');
    ref.read(paymentProvider.notifier).loadByStatus(
          _tabController.index,
          forceRefresh: true,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentProvider);
    final notifier = ref.read(paymentProvider.notifier);

    List<PaymentModel> filteredPayments = state.payments;
    if (_tabController.index == 1) {
      filteredPayments = filteredPayments.where((p) => p.isPending).toList();
    } else if (_tabController.index == 2) {
      filteredPayments = filteredPayments.where((p) => p.isApproved).toList();
    } else if (_tabController.index == 3) {
      filteredPayments = filteredPayments.where((p) => p.isRejected).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filteredPayments = filteredPayments.where((p) {
        return (p.reference ?? '').toLowerCase().contains(q) ||
            p.clientName.toLowerCase().contains(q);
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation des Paiements'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPayments,
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
                hintText: 'Rechercher par référence, client...',
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
                : filteredPayments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.payment, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Aucun paiement trouvé'
                                  : 'Aucun paiement correspondant à "$_searchQuery"',
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
                      )
                    : ListView.builder(
                        itemCount: filteredPayments.length,
                        padding: const EdgeInsets.all(8),
                        itemBuilder: (context, index) {
                          return _buildPaymentCard(
                            context,
                            filteredPayments[index],
                            notifier,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(
    BuildContext context,
    PaymentModel payment,
    PaymentNotifier notifier,
  ) {
    final formatDate = DateFormat('dd/MM/yyyy');
    final formatCurrency = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA');
    final statusColor = _getStatusColor(payment.status);
    final statusIcon = _getStatusIcon(payment.status);
    final statusText = _getStatusText(payment.status);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(payment.paymentNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Client: ${payment.clientName}'),
            Text('Date: ${formatDate.format(payment.paymentDate)}'),
            Text('Montant: ${formatCurrency.format(payment.amount)}'),
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
                  fontSize: 12,
                ),
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
                      Text('Numéro: ${payment.paymentNumber}'),
                      Text('Type: ${_getPaymentTypeText(payment.type)}'),
                      Text('Client: ${payment.clientName}'),
                      Text('Email: ${payment.clientEmail}'),
                      Text('Adresse: ${payment.clientAddress}'),
                      Text('Comptable: ${payment.comptableName}'),
                      Text('Date paiement: ${formatDate.format(payment.paymentDate)}'),
                      if (payment.dueDate != null)
                        Text('Date échéance: ${formatDate.format(payment.dueDate!)}'),
                      Text('Méthode: ${_getPaymentMethodText(payment.paymentMethod)}'),
                      if (payment.reference != null) Text('Référence: ${payment.reference}'),
                      if (payment.description != null) Text('Description: ${payment.description}'),
                      if (payment.notes != null) Text('Notes: ${payment.notes}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Montant total:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(formatCurrency.format(payment.amount),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildActionButtons(context, payment, statusColor, notifier),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    PaymentModel payment,
    Color statusColor,
    PaymentNotifier notifier,
  ) {
    if (payment.isPending) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: () => _showApproveConfirmation(context, payment, notifier),
            icon: const Icon(Icons.check),
            label: const Text('Valider'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _showRejectDialog(context, payment, notifier),
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
    if (payment.isApproved) {
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
                  'Paiement validé',
                  style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => notifier.generatePDF(payment.id),
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
    if (payment.isRejected) {
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
              'Paiement rejeté',
              style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold),
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
            'Statut: ${PaymentNotifier.getPaymentStatusName(payment.status)}',
            style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'submitted': return Colors.orange;
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'submitted': return Icons.pending;
      case 'approved': return Icons.check_circle;
      case 'rejected': return Icons.cancel;
      default: return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'submitted': return 'En attente';
      case 'approved': return 'Validé';
      case 'rejected': return 'Rejeté';
      default: return status;
    }
  }

  String _getPaymentTypeText(String type) {
    switch (type) {
      case 'one_time': return 'Paiement unique';
      case 'monthly': return 'Paiement mensuel';
      default: return type;
    }
  }

  String _getPaymentMethodText(String method) {
    switch (method) {
      case 'bank_transfer': return 'Virement bancaire';
      case 'check': return 'Chèque';
      case 'cash': return 'Espèces';
      case 'card': return 'Carte';
      case 'direct_debit': return 'Prélèvement';
      default: return method;
    }
  }

  void _showApproveConfirmation(
    BuildContext context,
    PaymentModel payment,
    PaymentNotifier notifier,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Voulez-vous valider ce paiement ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await notifier.approvePayment(payment.id);
      if (mounted) _loadPayments();
    }
  }

  void _showRejectDialog(
    BuildContext context,
    PaymentModel payment,
    PaymentNotifier notifier,
  ) async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeter le paiement'),
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
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Veuillez entrer un motif de rejet')),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
    if (confirm == true && reasonController.text.trim().isNotEmpty) {
      await notifier.rejectPayment(payment.id, reason: reasonController.text.trim());
      if (mounted) _loadPayments();
    }
  }
}

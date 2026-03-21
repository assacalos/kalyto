import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/Models/payment_model.dart';
import 'package:easyconnect/providers/payment_state.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/services/payment_service.dart';
import 'package:easyconnect/services/pdf_service.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/utils/dashboard_refresh_helper.dart';
import 'package:easyconnect/utils/notification_helper.dart';
import 'package:easyconnect/utils/reference_generator.dart';
import 'package:easyconnect/utils/roles.dart';

final paymentProvider =
    NotifierProvider<PaymentNotifier, PaymentState>(PaymentNotifier.new);

class PaymentNotifier extends Notifier<PaymentState> {
  final PaymentService _paymentService = PaymentService();
  bool _isLoadingInProgress = false;
  String? _currentApprovalStatusFilter;

  bool get _isPatronOrAdmin {
    final role = ref.read(authProvider).user?.role;
    return role == Roles.ADMIN || role == Roles.PATRON;
  }

  @override
  PaymentState build() {
    return const PaymentState();
  }

  Future<String> generatePaymentReference() async {
    await loadPayments();
    final existing = state.payments
        .map((p) => p.reference)
        .where((r) => r != null && r.isNotEmpty)
        .map((r) => r!)
        .toList();
    final ref = ReferenceGenerator.generateReferenceWithIncrement('PAY', existing);
    state = state.copyWith(generatedReference: ref);
    return ref;
  }

  Future<void> loadPayments({
    String? approvalStatusFilter,
    int page = 1,
    bool forceRefresh = false,
  }) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    if (_isLoadingInProgress) return;

    _currentApprovalStatusFilter = approvalStatusFilter ??
        (state.selectedApprovalStatus == 'all' ? null : state.selectedApprovalStatus);
    final cacheKey = 'payments_${user.role}_${_currentApprovalStatusFilter ?? 'all'}';

    if (page == 1) {
      if (!forceRefresh) {
        final hiveList = PaymentService.getCachedPaiements();
        if (hiveList.isNotEmpty) {
          state = state.copyWith(payments: hiveList, isLoading: false);
          _isLoadingInProgress = false;
          Future.microtask(() => _refreshPaymentsFromApi(cacheKey));
          return;
        }
        final cached = CacheHelper.get<List<PaymentModel>>(cacheKey);
        if (cached != null && cached.isNotEmpty) {
          state = state.copyWith(payments: cached, isLoading: false);
          _isLoadingInProgress = false;
          Future.microtask(() => _refreshPaymentsFromApi(cacheKey));
          return;
        }
      }
      state = state.copyWith(payments: [], isLoading: true);
    } else {
      state = state.copyWith(isLoadingMore: true);
    }

    _isLoadingInProgress = true;
    try {
      final paginatedResponse = _isPatronOrAdmin
          ? await _paymentService.getAllPaymentsPaginated(
              startDate: state.startDate,
              endDate: state.endDate,
              status: null,
              type: null,
              page: page,
              perPage: state.perPage,
              search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
            )
          : await _paymentService.getComptablePaymentsPaginated(
              comptableId: user.id,
              startDate: state.startDate,
              endDate: state.endDate,
              status: state.selectedStatus != 'all' ? state.selectedStatus : null,
              type: state.selectedType != 'all' ? state.selectedType : null,
              page: page,
              perPage: state.perPage,
              search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
            );

      if (page == 1) {
        state = state.copyWith(
          payments: paginatedResponse.data,
          isLoading: false,
          currentPage: paginatedResponse.meta.currentPage,
          lastPage: paginatedResponse.meta.lastPage,
          totalItems: paginatedResponse.meta.total,
        );
        CacheHelper.set(cacheKey, paginatedResponse.data);
      } else {
        state = state.copyWith(
          payments: [...state.payments, ...paginatedResponse.data],
          isLoadingMore: false,
          currentPage: paginatedResponse.meta.currentPage,
          lastPage: paginatedResponse.meta.lastPage,
          totalItems: paginatedResponse.meta.total,
        );
      }
      loadPaymentStats().ignore();
    } catch (e) {
      if (page == 1) {
        final fallback = CacheHelper.get<List<PaymentModel>>(cacheKey);
        if (fallback != null && fallback.isNotEmpty) {
          state = state.copyWith(payments: fallback, isLoading: false);
        } else {
          final hiveList = PaymentService.getCachedPaiements();
          if (hiveList.isNotEmpty) {
            state = state.copyWith(payments: hiveList, isLoading: false);
          } else {
            state = state.copyWith(isLoading: false);
            rethrow;
          }
        }
      } else {
        state = state.copyWith(isLoadingMore: false);
        rethrow;
      }
    } finally {
      _isLoadingInProgress = false;
    }
  }

  Future<void> _refreshPaymentsFromApi(String cacheKey) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    if (_isLoadingInProgress) return;
    try {
      final paginatedResponse = _isPatronOrAdmin
          ? await _paymentService.getAllPaymentsPaginated(
              startDate: state.startDate,
              endDate: state.endDate,
              page: 1,
              perPage: state.perPage,
              search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
            )
          : await _paymentService.getComptablePaymentsPaginated(
              comptableId: user.id,
              startDate: state.startDate,
              endDate: state.endDate,
              status: state.selectedStatus != 'all' ? state.selectedStatus : null,
              type: state.selectedType != 'all' ? state.selectedType : null,
              page: 1,
              perPage: state.perPage,
              search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
            );
      state = state.copyWith(
        payments: paginatedResponse.data,
        currentPage: 1,
        lastPage: paginatedResponse.meta.lastPage,
        totalItems: paginatedResponse.meta.total,
      );
      CacheHelper.set(cacheKey, paginatedResponse.data);
      loadPaymentStats().ignore();
    } catch (_) {}
  }

  void loadMore() {
    if (state.hasNextPage && !state.isLoading && !state.isLoadingMore) {
      loadPayments(page: state.currentPage + 1);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setApprovalStatusFilter(String status) {
    state = state.copyWith(selectedApprovalStatus: status);
    loadPayments();
  }

  void loadByStatus(int index, {bool forceRefresh = false}) {
    const statuses = ['all', 'pending', 'approved', 'rejected'];
    state = state.copyWith(selectedApprovalStatus: statuses[index]);
    loadPayments(forceRefresh: forceRefresh);
  }

  Future<void> loadPaymentStats() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    try {
      final statsData = await _paymentService.getPaymentStats(
        startDate: state.startDate,
        endDate: state.endDate,
        type: state.selectedType != 'all' ? state.selectedType : null,
      );
      state = state.copyWith(paymentStats: PaymentStats.fromJson(statsData));
    } catch (_) {}
  }

  Future<bool> createPayment({
    required int clientId,
    required String clientName,
    required String clientEmail,
    required String clientAddress,
    required String type,
    required DateTime paymentDate,
    DateTime? dueDate,
    required double amount,
    required String paymentMethod,
    String? description,
    String? notes,
    String? reference,
    PaymentSchedule? schedule,
  }) async {
    final user = ref.read(authProvider).user;
    if (user == null) throw Exception('Utilisateur non connecté');

    state = state.copyWith(isCreating: true);
    try {
      final result = await _paymentService.createPayment(
        clientId: clientId,
        clientName: clientName,
        clientEmail: clientEmail,
        clientAddress: clientAddress,
        comptableId: user.id,
        comptableName: user.nom ?? 'Comptable',
        type: type,
        paymentDate: paymentDate,
        dueDate: dueDate,
        amount: amount,
        paymentMethod: paymentMethod,
        description: description,
        notes: notes,
        reference: reference,
        schedule: schedule,
      );

      final ok = result['success'] == true || result['success'] == 1;
      if (ok) {
        CacheHelper.clearByPrefix('payments_');
        CacheHelper.clearByPrefix('dashboard_comptable_pendingPaiements');
        DashboardRefreshHelper.refreshPatronCounter('payment');
        DashboardRefreshHelper.refreshComptablePending('paiement');
        if (result['data'] != null) {
          try {
            final data = result['data'];
            String idStr = '';
            if (data is Map) {
              idStr = data['id']?.toString() ?? '';
            }
            NotificationHelper.notifySubmission(
              entityType: 'payment',
              entityName: NotificationHelper.getEntityDisplayName('payment', data),
              entityId: idStr,
              route: NotificationHelper.getEntityRoute('payment', idStr),
            );
          } catch (_) {}
        }
        state = state.copyWith(isCreating: false);
        await loadPayments();
        return true;
      }
      state = state.copyWith(isCreating: false);
      throw Exception(result['message']?.toString() ?? 'Erreur lors de la création');
    } catch (e) {
      state = state.copyWith(isCreating: false);
      rethrow;
    }
  }

  Future<void> submitPaymentToPatron(int paymentId) async {
    final result = await _paymentService.submitPaymentToPatron(paymentId);
    if (result['success'] == true) {
      PaymentModel? payment;
      try {
        payment = state.payments.firstWhere((p) => p.id == paymentId);
      } catch (_) {}
      if (payment != null) {
        NotificationHelper.notifySubmission(
          entityType: 'payment',
          entityName: NotificationHelper.getEntityDisplayName('payment', payment),
          entityId: paymentId.toString(),
          route: NotificationHelper.getEntityRoute('payment', paymentId.toString()),
        );
      }
      await loadPayments();
    } else {
      throw Exception(result['message']?.toString() ?? 'Erreur lors de la soumission');
    }
  }

  Future<void> approvePayment(int paymentId, {String? comments}) async {
    CacheHelper.clearByPrefix('payments_');
    final result = await _paymentService.approvePayment(paymentId, comments: comments);
    if (result['success'] == true) {
      DashboardRefreshHelper.refreshPatronCounter('payment');
      if (result['data'] != null) {
        try {
          NotificationHelper.notifyValidation(
            entityType: 'payment',
            entityName: NotificationHelper.getEntityDisplayName('payment', result['data']),
            entityId: paymentId.toString(),
            route: NotificationHelper.getEntityRoute('payment', paymentId.toString()),
            entity: result['data'],
          );
        } catch (_) {}
      }
      await loadPayments(approvalStatusFilter: _currentApprovalStatusFilter);
    } else {
      throw Exception(result['message']?.toString() ?? 'Erreur');
    }
  }

  Future<void> rejectPayment(int paymentId, {required String reason}) async {
    CacheHelper.clearByPrefix('payments_');
    final result = await _paymentService.rejectPayment(paymentId, reason: reason);
    if (result['success'] == true) {
      DashboardRefreshHelper.refreshPatronCounter('payment');
      if (result['data'] != null) {
        try {
          NotificationHelper.notifyRejection(
            entityType: 'payment',
            entityName: NotificationHelper.getEntityDisplayName('payment', result['data']),
            entityId: paymentId.toString(),
            reason: reason,
            route: NotificationHelper.getEntityRoute('payment', paymentId.toString()),
            entity: result['data'],
          );
        } catch (_) {}
      }
      await loadPayments(approvalStatusFilter: _currentApprovalStatusFilter);
    } else {
      throw Exception(result['message']?.toString() ?? 'Erreur');
    }
  }

  Future<void> markAsPaid(int paymentId, {String? paymentReference, String? notes}) async {
    final result = await _paymentService.markAsPaid(
      paymentId,
      paymentReference: paymentReference,
      notes: notes,
    );
    if (result['success'] == true) {
      await loadPayments();
    } else {
      throw Exception(result['message']?.toString() ?? 'Erreur');
    }
  }

  Future<void> generatePDF(int paymentId) async {
    PaymentModel payment;
    try {
      payment = state.payments.firstWhere((p) => p.id == paymentId);
    } catch (_) {
      payment = await _paymentService.getPaymentById(paymentId);
    }
    await PdfService().generatePaiementPdf(
      paiement: {
        'reference': payment.reference ?? payment.paymentNumber,
        'montant': payment.amount,
        'mode_paiement': payment.paymentMethod,
        'date_paiement': payment.paymentDate,
      },
      facture: {'reference': payment.paymentNumber},
      client: {
        'nom': payment.clientName,
        'prenom': '',
        'nom_entreprise': payment.clientName,
        'email': payment.clientEmail,
        'contact': '',
        'adresse': payment.clientAddress,
      },
    );
  }

  Future<PaymentModel> getPaymentById(int id) async {
    return _paymentService.getPaymentById(id);
  }

  bool get canApprovePayments => _isPatronOrAdmin;
  bool get canSubmitPayments {
    final role = ref.read(authProvider).user?.role;
    return role == Roles.COMPTABLE;
  }

  // Helpers pour l'UI (même logique que PaymentController)
  static Color getPaymentStatusColor(String status) {
    final s = status.toLowerCase().trim();
    if (s == 'draft' || s == 'drafts') return Colors.grey;
    if (s == 'submitted' || s == 'soumis') return Colors.orange;
    if (s == 'approved' || s == 'approuve' || s == 'approuvé' || s == 'valide') return Colors.blue;
    if (s == 'rejected' || s == 'rejete' || s == 'rejeté') return Colors.red;
    if (s == 'paid' || s == 'paye' || s == 'payé') return Colors.green;
    if (s == 'overdue' || s == 'en_retard') return Colors.red;
    if (s == 'pending' || s == 'en_attente') return Colors.orange;
    return Colors.grey;
  }

  static String getPaymentStatusName(String status) {
    final s = status.toLowerCase().trim();
    if (s == 'draft' || s == 'drafts') return 'Brouillon';
    if (s == 'submitted' || s == 'soumis') return 'Soumis';
    if (s == 'approved' || s == 'approuve' || s == 'approuvé' || s == 'valide') return 'Approuvé';
    if (s == 'rejected' || s == 'rejete' || s == 'rejeté') return 'Rejeté';
    if (s == 'paid' || s == 'paye' || s == 'payé') return 'Payé';
    if (s == 'overdue' || s == 'en_retard') return 'En retard';
    if (s == 'pending' || s == 'en_attente') return 'En attente';
    return status.replaceAll('_', ' ').split(' ').map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1).toLowerCase()).join(' ');
  }

  static String getPaymentTypeName(String type) {
    if (type == 'one_time') return 'Ponctuel';
    if (type == 'monthly') return 'Mensuel';
    return type;
  }

  static String getPaymentMethodName(String method) {
    if (method == 'bank_transfer') return 'Virement bancaire';
    if (method == 'check') return 'Chèque';
    if (method == 'cash') return 'Espèces';
    if (method == 'card') return 'Carte bancaire';
    if (method == 'direct_debit') return 'Prélèvement';
    return method;
  }
}

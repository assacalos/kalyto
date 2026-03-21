import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/Models/invoice_model.dart';
import 'package:easyconnect/Models/client_model.dart';
import 'package:easyconnect/providers/invoice_state.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/services/invoice_service.dart';
import 'package:easyconnect/services/client_service.dart';
import 'package:easyconnect/services/pdf_service.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/utils/notification_helper.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/utils/dashboard_refresh_helper.dart';
import 'package:easyconnect/utils/reference_generator.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/tva_rates_ci.dart';

final invoiceProvider =
    NotifierProvider<InvoiceNotifier, InvoiceState>(InvoiceNotifier.new);

class InvoiceNotifier extends Notifier<InvoiceState> {
  final InvoiceService _invoiceService = InvoiceService();
  final ClientService _clientService = ClientService();
  bool _isLoadingInProgress = false;

  int? get _userRole => ref.read(authProvider).user?.role;
  bool get _isPatronOrAdmin =>
      _userRole == Roles.ADMIN || _userRole == Roles.PATRON;

  @override
  InvoiceState build() {
    return InvoiceState();
  }

  InvoiceModel? _findInvoice(int id) {
    for (final i in state.invoices) {
      if (i.id == id) return i;
    }
    for (final i in state.pendingInvoices) {
      if (i.id == id) return i;
    }
    return null;
  }

  Future<void> loadInvoices({int page = 1, bool forceRefresh = false}) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    if (_isLoadingInProgress) return;
    _isLoadingInProgress = true;

    final statusParam =
        state.selectedStatus != 'all' ? state.selectedStatus : null;
    final commercialIdParam =
        _isPatronOrAdmin ? null : user.id;
    final cacheKey = 'invoices_${user.role}_${state.selectedStatus}';

    if (page == 1) {
      state = state.copyWith(isLoading: true);
      if (!forceRefresh) {
        final hiveList = InvoiceService.getCachedFactures(
            statusParam, commercialIdParam);
        if (hiveList.isNotEmpty) {
          state = state.copyWith(
              invoices: hiveList, isLoading: false);
          _isLoadingInProgress = false;
          Future.microtask(() =>
              _refreshInvoicesFromApi(cacheKey, statusParam, commercialIdParam));
          return;
        }
        final cached = CacheHelper.get<List<InvoiceModel>>(cacheKey);
        if (cached != null && cached.isNotEmpty) {
          state = state.copyWith(invoices: cached, isLoading: false);
          _isLoadingInProgress = false;
          Future.microtask(() =>
              _refreshInvoicesFromApi(cacheKey, statusParam, commercialIdParam));
          return;
        }
      }
      state = state.copyWith(invoices: []);
    } else {
      state = state.copyWith(isLoadingMore: true);
    }

    try {
      final res = await _invoiceService.getInvoicesPaginated(
        startDate: state.startDate,
        endDate: state.endDate,
        status: statusParam,
        commercialId: commercialIdParam,
        page: page,
        perPage: state.perPage,
        search:
            state.searchQuery.isNotEmpty ? state.searchQuery : null,
      );

      if (page == 1) {
        state = state.copyWith(
          invoices: res.data,
          isLoading: false,
          currentPage: res.meta.currentPage,
          lastPage: res.meta.lastPage,
          totalItems: res.meta.total,
        );
        CacheHelper.set(cacheKey, res.data);
      } else {
        state = state.copyWith(
          invoices: [...state.invoices, ...res.data],
          isLoadingMore: false,
          currentPage: res.meta.currentPage,
          lastPage: res.meta.lastPage,
          totalItems: res.meta.total,
        );
      }
      loadInvoiceStats().ignore();
    } catch (e) {
      try {
        final loaded = await _invoiceService.getAllInvoices(
          startDate: state.startDate,
          endDate: state.endDate,
          status: statusParam,
          commercialId: commercialIdParam,
        );
        final limited = loaded.take(1000).toList();
        if (page == 1) {
          state = state.copyWith(
            invoices: limited,
            isLoading: false,
            totalItems: limited.length,
            lastPage: 1,
          );
          CacheHelper.set(cacheKey, limited);
        } else {
          state = state.copyWith(
            invoices: [...state.invoices, ...limited],
            isLoadingMore: false,
          );
        }
        loadInvoiceStats().ignore();
      } catch (_) {
        if (page == 1) {
          final hive = InvoiceService.getCachedFactures();
          if (hive.isNotEmpty) {
            state = state.copyWith(invoices: hive, isLoading: false);
          } else {
            final fallback =
                CacheHelper.get<List<InvoiceModel>>('invoices_all');
            if (fallback != null && fallback.isNotEmpty) {
              state = state.copyWith(invoices: fallback, isLoading: false);
            } else {
              state = state.copyWith(isLoading: false);
              rethrow;
            }
          }
        } else {
          state = state.copyWith(isLoadingMore: false);
        }
      }
    } finally {
      _isLoadingInProgress = false;
    }
  }

  Future<void> _refreshInvoicesFromApi(
    String cacheKey,
    String? statusParam,
    int? commercialIdParam,
  ) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    if (_isLoadingInProgress) return;
    final currentStatus =
        state.selectedStatus != 'all' ? state.selectedStatus : null;
    final currentCommercial = _isPatronOrAdmin ? null : user.id;
    if (currentStatus != statusParam || currentCommercial != commercialIdParam) {
      return;
    }
    try {
      final res = await _invoiceService.getInvoicesPaginated(
        startDate: state.startDate,
        endDate: state.endDate,
        status: statusParam,
        commercialId: commercialIdParam,
        page: 1,
        perPage: state.perPage,
        search:
            state.searchQuery.isNotEmpty ? state.searchQuery : null,
      );
      if ((state.selectedStatus != 'all' ? state.selectedStatus : null) !=
              statusParam ||
          (_isPatronOrAdmin ? null : user.id) != commercialIdParam) return;
      state = state.copyWith(
        invoices: res.data,
        currentPage: 1,
        lastPage: res.meta.lastPage,
        totalItems: res.meta.total,
      );
      CacheHelper.set(cacheKey, res.data);
      loadInvoiceStats().ignore();
    } catch (_) {}
  }

  void loadMore() {
    if (state.hasNextPage && !state.isLoading && !state.isLoadingMore) {
      loadInvoices(page: state.currentPage + 1);
    }
  }

  void filterInvoices({
    String? status,
    DateTime? start,
    DateTime? end,
    String? search,
  }) {
    state = state.copyWith(
      selectedStatus: status ?? 'all',
      startDate: start ?? state.startDate,
      endDate: end ?? state.endDate,
      searchQuery: search ?? state.searchQuery,
    );
    loadInvoices();
  }

  Future<void> loadPendingInvoices() async {
    if (!_isPatronOrAdmin) return;
    try {
      final list = await _invoiceService.getPendingInvoices();
      state = state.copyWith(pendingInvoices: list);
    } catch (_) {}
  }

  Future<void> loadInvoiceStats() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    try {
      final stats = await _invoiceService.getInvoiceStats(
        startDate: state.startDate,
        endDate: state.endDate,
        commercialId: _isPatronOrAdmin ? null : user.id,
      );
      state = state.copyWith(invoiceStats: stats);
    } catch (_) {}
  }

  Future<void> loadTemplates() async {
    try {
      final list = await _invoiceService.getInvoiceTemplates();
      state = state.copyWith(templates: list);
    } catch (_) {}
  }

  Future<void> loadValidatedClients() async {
    state = state.copyWith(isLoadingClients: true);
    try {
      final cached = ClientService.getCachedClients(1);
      if (cached.isNotEmpty) {
        state = state.copyWith(availableClients: cached);
      } else {
        state = state.copyWith(availableClients: []);
      }
      final clients = await _clientService.getClients(status: 1);
      state = state.copyWith(
          availableClients: clients, isLoadingClients: false);
    } catch (e) {
      if (state.availableClients.isEmpty) {
        final fallback = ClientService.getCachedClients(1);
        if (fallback.isNotEmpty) {
          state = state.copyWith(availableClients: fallback);
        }
      }
      state = state.copyWith(isLoadingClients: false);
      rethrow;
    } finally {
      state = state.copyWith(isLoadingClients: false);
    }
  }

  void selectClientForInvoice(Client client) {
    final name = client.nomEntreprise?.isNotEmpty == true
        ? client.nomEntreprise!
        : '${client.nom ?? ''} ${client.prenom ?? ''}'.trim();
    state = state.copyWith(
      selectedClient: client,
      selectedClientId: client.id ?? 0,
      selectedClientName: name.isEmpty ? 'Client #${client.id}' : name,
      selectedClientEmail: client.email ?? '',
      selectedClientAddress: client.adresse ?? '',
    );
  }

  void clearSelectedClient() {
    state = state.copyWith(
      selectedClient: null,
      selectedClientId: 0,
      selectedClientName: '',
      selectedClientEmail: '',
      selectedClientAddress: '',
    );
  }

  void addInvoiceItem({
    required String description,
    required int quantity,
    required double unitPrice,
    String? unit,
  }) {
    final totalPrice = quantity * unitPrice;
    final item = InvoiceItem(
      id: 0,
      description: description,
      quantity: quantity,
      unitPrice: unitPrice,
      totalPrice: totalPrice,
      unit: unit,
    );
    state = state.copyWith(
        invoiceItems: [...state.invoiceItems, item]);
  }

  void removeInvoiceItem(int index) {
    final items = List<InvoiceItem>.from(state.invoiceItems);
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
      state = state.copyWith(invoiceItems: items);
    }
  }

  void setInvoiceDate(DateTime date) {
    state = state.copyWith(invoiceDate: date);
  }

  void setDueDate(DateTime date) {
    state = state.copyWith(dueDate: date);
  }

  void setTaxRate(double value) {
    state = state.copyWith(taxRate: value);
  }

  void setNotes(String value) {
    state = state.copyWith(notes: value);
  }

  void setTerms(String value) {
    state = state.copyWith(terms: value);
  }

  Future<void> loadInvoiceForEdit(int invoiceId) async {
    state = state.copyWith(
        editInvoiceId: invoiceId, isLoadingInvoiceForEdit: true);
    try {
      if (state.availableClients.isEmpty) {
        await loadValidatedClients();
      }
      final invoice = await _invoiceService.getInvoiceById(invoiceId);
      Client? clientFromList;
      try {
        clientFromList = state.availableClients
            .firstWhere((c) => c.id == invoice.clientId);
      } catch (_) {
        clientFromList = null;
      }
      state = state.copyWith(
        editInvoiceId: invoiceId,
        isLoadingInvoiceForEdit: false,
        selectedClient: clientFromList,
        selectedClientId: invoice.clientId,
        selectedClientName: invoice.clientName,
        selectedClientEmail: invoice.clientEmail,
        selectedClientAddress: invoice.clientAddress,
        invoiceItems: invoice.items,
        invoiceDate: invoice.invoiceDate,
        dueDate: invoice.dueDate,
        taxRate: clampTvaRateCi(invoice.taxRate),
        notes: invoice.notes ?? '',
        terms: invoice.terms ?? '',
      );
    } catch (e) {
      state = state.copyWith(isLoadingInvoiceForEdit: false);
      rethrow;
    }
  }

  void clearForm() {
    state = state.copyWith(
      selectedClient: null,
      selectedClientId: 0,
      selectedClientName: '',
      selectedClientEmail: '',
      selectedClientAddress: '',
      invoiceItems: const [],
      invoiceDate: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 30)),
      taxRate: tvaRateCiDefault,
      notes: '',
      terms: '',
      editInvoiceId: null,
    );
    setGeneratedInvoiceNumber('');
  }

  Future<String> generateInvoiceNumber() async {
    await loadInvoices();
    final existing = state.invoices
        .map((i) => i.invoiceNumber)
        .where((n) => n.isNotEmpty)
        .toList();
    final number = ReferenceGenerator.generateReferenceWithIncrement(
        'FACT', existing);
    state = state.copyWith(generatedInvoiceNumber: number);
    return number;
  }

  Future<bool> createInvoice({
    required int clientId,
    required String clientName,
    required String clientEmail,
    required String clientAddress,
    required DateTime invoiceDate,
    required DateTime dueDate,
    required List<InvoiceItem> items,
    required double taxRate,
    String? notes,
    String? terms,
  }) async {
    final user = ref.read(authProvider).user;
    if (user == null) throw Exception('Utilisateur non connecté');
    if (items.isEmpty) throw Exception('Veuillez ajouter au moins un article');
    state = state.copyWith(isCreating: true);
    try {
      final result = await _invoiceService.createInvoice(
        clientId: clientId,
        clientName: clientName,
        clientEmail: clientEmail,
        clientAddress: clientAddress,
        commercialId: user.id,
        commercialName: user.nom ?? 'Comptable',
        invoiceDate: invoiceDate,
        dueDate: dueDate,
        items: items,
        taxRate: taxRate,
        notes: notes,
        terms: terms,
      );
      final ok = result['success'] == true ||
          result['success'] == 1 ||
          result['success'] == 'true' ||
          (result['success'] == null && result['data'] != null);
      if (ok) {
        CacheHelper.clearByPrefix('invoices_');
        DashboardRefreshHelper.refreshPatronCounter('invoice');
        state = state.copyWith(isCreating: false);
        await loadInvoices();
        await generateInvoiceNumber();
        return true;
      }
      state = state.copyWith(isCreating: false);
      throw Exception(
          result['message']?.toString() ?? 'Erreur lors de la création');
    } catch (e) {
      state = state.copyWith(isCreating: false);
      rethrow;
    }
  }

  Future<void> updateInvoice(int invoiceId, Map<String, dynamic> data) async {
    state = state.copyWith(isCreating: true);
    try {
      final result = await _invoiceService.updateInvoice(
          invoiceId: invoiceId, data: data);
      if (result['success'] == true) {
        await loadInvoices();
      } else {
        throw Exception(result['message']?.toString() ?? 'Erreur');
      }
    } finally {
      state = state.copyWith(isCreating: false);
    }
  }

  Future<bool> updateInvoiceFromForm() async {
    final id = state.editInvoiceId;
    if (id == null) return false;
    if (state.invoiceItems.isEmpty) {
      throw Exception('Veuillez ajouter au moins un article');
    }
    final subtotal = state.formSubtotal;
    final taxAmount = state.formTaxAmount;
    final totalAmount = state.formTotalAmount;
    await updateInvoice(id, {
      'date_facture': state.invoiceDate.toIso8601String().split('T')[0],
      'date_echeance': state.dueDate.toIso8601String().split('T')[0],
      'subtotal': subtotal,
      'tax_rate': state.taxRate,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
      'notes': state.notes.trim().isEmpty ? null : state.notes.trim(),
      'terms': state.terms.trim().isEmpty ? null : state.terms.trim(),
      'items': state.invoiceItems.map((item) => item.toJson()).toList(),
    });
    state = state.copyWith(editInvoiceId: null);
    return true;
  }

  Future<void> submitInvoiceToPatron(int invoiceId) async {
    state = state.copyWith(isSubmitting: true);
    try {
      final result =
          await _invoiceService.submitInvoiceToPatron(invoiceId);
      if (result['success'] == true) {
        final invoice = _findInvoice(invoiceId);
        if (invoice != null) {
          NotificationHelper.notifySubmission(
            entityType: 'facture',
            entityName:
                NotificationHelper.getEntityDisplayName('facture', invoice),
            entityId: invoiceId.toString(),
            route:
                NotificationHelper.getEntityRoute('facture', invoiceId.toString()),
          );
        }
        await loadInvoices();
        await loadPendingInvoices();
      } else {
        throw Exception(
            result['message']?.toString() ?? 'Erreur lors de la soumission');
      }
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }

  Future<void> approveInvoice(int invoiceId, {String? comments}) async {
    state = state.copyWith(isLoading: true);
    try {
      CacheHelper.clearByPrefix('invoices_');
      CacheHelper.clearByPrefix('factures_');
      final pendingIndex =
          state.pendingInvoices.indexWhere((i) => i.id == invoiceId);
      InvoiceModel? original;
      List<InvoiceModel> newPending = List.from(state.pendingInvoices);
      if (pendingIndex != -1) {
        original = newPending[pendingIndex];
        newPending.removeAt(pendingIndex);
      }
      List<InvoiceModel> newInvoices = List.from(state.invoices);
      final mainIndex = newInvoices.indexWhere((i) => i.id == invoiceId);
      if (mainIndex != -1) {
        original ??= newInvoices[mainIndex];
        final o = newInvoices[mainIndex];
        newInvoices[mainIndex] = InvoiceModel(
          id: o.id,
          invoiceNumber: o.invoiceNumber,
          clientId: o.clientId,
          clientName: o.clientName,
          clientEmail: o.clientEmail,
          clientAddress: o.clientAddress,
          commercialId: o.commercialId,
          commercialName: o.commercialName,
          invoiceDate: o.invoiceDate,
          dueDate: o.dueDate,
          subtotal: o.subtotal,
          taxRate: o.taxRate,
          taxAmount: o.taxAmount,
          totalAmount: o.totalAmount,
          currency: o.currency,
          status: 'valide',
          items: o.items,
          notes: o.notes,
          terms: o.terms,
          paymentInfo: o.paymentInfo,
          createdAt: o.createdAt,
          updatedAt: DateTime.now(),
          sentAt: o.sentAt,
          paidAt: o.paidAt,
        );
      }
      state = state.copyWith(
          invoices: newInvoices, pendingInvoices: newPending);

      final result = await _invoiceService.approveInvoice(
          invoiceId: invoiceId, comments: comments);
      final ok = result['success'] == true ||
          result['success'] == 1 ||
          result['success'] == 'true';
      if (ok) {
        DashboardRefreshHelper.refreshPatronCounter('invoice');
        if (original != null) {
          NotificationHelper.notifyValidation(
            entityType: 'facture',
            entityName:
                NotificationHelper.getEntityDisplayName('facture', original),
            entityId: invoiceId.toString(),
            route: NotificationHelper.getEntityRoute(
                'facture', invoiceId.toString()),
            entity: original,
          );
        }
        Future.delayed(const Duration(milliseconds: 500), () {
          loadInvoices();
          loadPendingInvoices();
        });
      } else {
        await loadInvoices();
        await loadPendingInvoices();
        throw Exception('La validation a peut-être réussi. Vérifiez.');
      }
    } catch (e) {
      await loadInvoices();
      await loadPendingInvoices();
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> rejectInvoice(int invoiceId, String reason) async {
    state = state.copyWith(isLoading: true);
    try {
      final pendingIndex =
          state.pendingInvoices.indexWhere((i) => i.id == invoiceId);
      InvoiceModel? original;
      List<InvoiceModel> newPending = List.from(state.pendingInvoices);
      if (pendingIndex != -1) {
        original = newPending[pendingIndex];
        newPending.removeAt(pendingIndex);
      }
      List<InvoiceModel> newInvoices = List.from(state.invoices);
      final mainIndex = newInvoices.indexWhere((i) => i.id == invoiceId);
      if (mainIndex != -1) {
        final o = newInvoices[mainIndex];
        original ??= o;
        newInvoices[mainIndex] = InvoiceModel(
          id: o.id,
          invoiceNumber: o.invoiceNumber,
          clientId: o.clientId,
          clientName: o.clientName,
          clientEmail: o.clientEmail,
          clientAddress: o.clientAddress,
          commercialId: o.commercialId,
          commercialName: o.commercialName,
          invoiceDate: o.invoiceDate,
          dueDate: o.dueDate,
          subtotal: o.subtotal,
          taxRate: o.taxRate,
          taxAmount: o.taxAmount,
          totalAmount: o.totalAmount,
          currency: o.currency,
          status: 'rejetee',
          items: o.items,
          notes: o.notes,
          terms: o.terms,
          paymentInfo: o.paymentInfo,
          createdAt: o.createdAt,
          updatedAt: DateTime.now(),
          sentAt: o.sentAt,
          paidAt: o.paidAt,
        );
      }
      state = state.copyWith(
          invoices: newInvoices, pendingInvoices: newPending);

      final result =
          await _invoiceService.rejectInvoice(invoiceId: invoiceId, reason: reason);
      if (result['success'] == true) {
        final inv = _findInvoice(invoiceId) ?? original;
        if (inv != null) {
          NotificationHelper.notifyRejection(
            entityType: 'facture',
            entityName:
                NotificationHelper.getEntityDisplayName('facture', inv),
            entityId: invoiceId.toString(),
            reason: reason,
            route: NotificationHelper.getEntityRoute(
                'facture', invoiceId.toString()),
            entity: inv,
          );
        }
        loadInvoices().ignore();
        loadPendingInvoices().ignore();
      } else {
        throw Exception(result['message']?.toString() ?? 'Erreur');
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> generatePDF(int invoiceId) async {
    state = state.copyWith(isLoading: true);
    try {
      InvoiceModel invoice;
      try {
        invoice = state.invoices.firstWhere((i) => i.id == invoiceId);
      } catch (_) {
        invoice = await _invoiceService.getInvoiceById(invoiceId);
      }
      if (invoice.items.isEmpty) {
        throw Exception(
            'Impossible de générer le PDF: la facture n\'a pas d\'articles');
      }
      final items = invoice.items
          .map((item) => {
                'designation': item.description,
                'unite': item.unit ?? 'unité',
                'quantite': item.quantity,
                'prix_unitaire': item.unitPrice,
                'montant_total': item.totalPrice,
              })
          .toList();
      await PdfService().generateFacturePdf(
        facture: {
          'reference': invoice.invoiceNumber,
          'date_creation': invoice.invoiceDate,
          'date_echeance': invoice.dueDate,
          'montant_ht': invoice.subtotal,
          'tva': invoice.taxRate,
          'montant_tva': invoice.taxAmount,
          'total_ttc': invoice.totalAmount,
        },
        items: items,
        client: {
          'nom': invoice.clientName.isNotEmpty
              ? (invoice.clientName.split(' ').isNotEmpty
                  ? invoice.clientName.split(' ').first
                  : '')
              : '',
          'prenom': invoice.clientName.isNotEmpty &&
                  invoice.clientName.split(' ').length > 1
              ? invoice.clientName.split(' ').sublist(1).join(' ')
              : '',
          'nom_entreprise': invoice.clientName,
          'email': invoice.clientEmail,
          'contact': '',
          'adresse': invoice.clientAddress,
          'ninea': invoice.clientNinea?.trim() ?? '',
        },
        commercial: {
          'nom': invoice.commercialName.isNotEmpty
              ? (invoice.commercialName.split(' ').isNotEmpty
                  ? invoice.commercialName.split(' ').first
                  : 'Commercial')
              : 'Commercial',
          'prenom': invoice.commercialName.isNotEmpty &&
                  invoice.commercialName.split(' ').length > 1
              ? invoice.commercialName.split(' ').sublist(1).join(' ')
              : '',
          'email': '',
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error(
          'Erreur génération PDF: $e', tag: 'INVOICE_NOTIFIER', error: e, stackTrace: stackTrace);
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void setGeneratedInvoiceNumber(String value) {
    state = state.copyWith(generatedInvoiceNumber: value);
  }

  Color getInvoiceStatusColor(String status) {
    switch (status) {
      case 'en_attente':
      case 'draft':
      case 'pending_approval':
        return Colors.orange;
      case 'valide':
      case 'sent':
      case 'paid':
        return Colors.green;
      case 'rejetee':
      case 'rejete':
        return Colors.red;
      case 'overdue':
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  String getInvoiceStatusText(String status) {
    switch (status) {
      case 'en_attente':
      case 'pending_approval':
        return 'En attente';
      case 'draft':
        return 'Brouillon';
      case 'valide':
        return 'Validée';
      case 'sent':
        return 'Envoyée';
      case 'paid':
        return 'Payée';
      case 'rejetee':
      case 'rejete':
        return 'Rejetée';
      case 'overdue':
        return 'En retard';
      default:
        return status;
    }
  }
}

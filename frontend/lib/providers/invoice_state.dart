import 'package:flutter/foundation.dart';
import 'package:easyconnect/Models/invoice_model.dart';
import 'package:easyconnect/Models/client_model.dart';

@immutable
class InvoiceState {
  final List<InvoiceModel> invoices;
  final List<InvoiceModel> pendingInvoices;
  final InvoiceStats? invoiceStats;
  final List<InvoiceTemplate> templates;
  final List<Client> availableClients;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isCreating;
  final bool isSubmitting;
  final bool isLoadingClients;
  final String selectedStatus;
  final DateTime? startDate;
  final DateTime? endDate;
  final String searchQuery;
  final int currentPage;
  final int lastPage;
  final int totalItems;
  final int perPage;
  final String generatedInvoiceNumber;
  // Formulaire facture
  final Client? selectedClient;
  final int selectedClientId;
  final String selectedClientName;
  final String selectedClientEmail;
  final String selectedClientAddress;
  final List<InvoiceItem> invoiceItems;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final double taxRate;
  final String notes;
  final String terms;
  final int? editInvoiceId;
  final bool isLoadingInvoiceForEdit;

  InvoiceState({
    this.invoices = const [],
    this.pendingInvoices = const [],
    this.invoiceStats,
    this.templates = const [],
    this.availableClients = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isCreating = false,
    this.isSubmitting = false,
    this.isLoadingClients = false,
    this.selectedStatus = 'all',
    this.startDate,
    this.endDate,
    this.searchQuery = '',
    this.currentPage = 1,
    this.lastPage = 1,
    this.totalItems = 0,
    this.perPage = 15,
    this.generatedInvoiceNumber = '',
    this.selectedClient,
    this.selectedClientId = 0,
    this.selectedClientName = '',
    this.selectedClientEmail = '',
    this.selectedClientAddress = '',
    this.invoiceItems = const [],
    DateTime? invoiceDate,
    DateTime? dueDate,
    this.taxRate = 18.0,
    this.notes = '',
    this.terms = '',
    this.editInvoiceId,
    this.isLoadingInvoiceForEdit = false,
  })  : invoiceDate = invoiceDate ?? DateTime.now(),
        dueDate = dueDate ?? DateTime.now().add(const Duration(days: 30));

  InvoiceState copyWith({
    List<InvoiceModel>? invoices,
    List<InvoiceModel>? pendingInvoices,
    InvoiceStats? invoiceStats,
    List<InvoiceTemplate>? templates,
    List<Client>? availableClients,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isCreating,
    bool? isSubmitting,
    bool? isLoadingClients,
    String? selectedStatus,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    int? currentPage,
    int? lastPage,
    int? totalItems,
    int? perPage,
    String? generatedInvoiceNumber,
    Object? selectedClient = _sentinel,
    int? selectedClientId,
    String? selectedClientName,
    String? selectedClientEmail,
    String? selectedClientAddress,
    List<InvoiceItem>? invoiceItems,
    DateTime? invoiceDate,
    DateTime? dueDate,
    double? taxRate,
    String? notes,
    String? terms,
    Object? editInvoiceId = _sentinel,
    bool? isLoadingInvoiceForEdit,
  }) {
    return InvoiceState(
      invoices: invoices ?? this.invoices,
      pendingInvoices: pendingInvoices ?? this.pendingInvoices,
      invoiceStats: invoiceStats ?? this.invoiceStats,
      templates: templates ?? this.templates,
      availableClients: availableClients ?? this.availableClients,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isCreating: isCreating ?? this.isCreating,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isLoadingClients: isLoadingClients ?? this.isLoadingClients,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      totalItems: totalItems ?? this.totalItems,
      perPage: perPage ?? this.perPage,
      generatedInvoiceNumber:
          generatedInvoiceNumber ?? this.generatedInvoiceNumber,
      selectedClient: identical(selectedClient, _sentinel)
          ? this.selectedClient
          : selectedClient as Client?,
      selectedClientId: selectedClientId ?? this.selectedClientId,
      selectedClientName: selectedClientName ?? this.selectedClientName,
      selectedClientEmail: selectedClientEmail ?? this.selectedClientEmail,
      selectedClientAddress: selectedClientAddress ?? this.selectedClientAddress,
      invoiceItems: invoiceItems ?? this.invoiceItems,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: dueDate ?? this.dueDate,
      taxRate: taxRate ?? this.taxRate,
      notes: notes ?? this.notes,
      terms: terms ?? this.terms,
      editInvoiceId: identical(editInvoiceId, _sentinel)
          ? this.editInvoiceId
          : editInvoiceId as int?,
      isLoadingInvoiceForEdit:
          isLoadingInvoiceForEdit ?? this.isLoadingInvoiceForEdit,
    );
  }

  static const _sentinel = Object();

  double get formSubtotal =>
      invoiceItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get formTaxAmount => formSubtotal * (taxRate / 100);
  double get formTotalAmount => formSubtotal + formTaxAmount;

  bool get hasNextPage => currentPage < lastPage;
  bool get hasPreviousPage => currentPage > 1;
}

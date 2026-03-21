import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/providers/global_search_state.dart';
import 'package:easyconnect/services/client_service.dart';
import 'package:easyconnect/services/employee_service.dart';
import 'package:easyconnect/services/invoice_service.dart';
import 'package:easyconnect/services/payment_service.dart';
import 'package:easyconnect/services/stock_service.dart';
import 'package:easyconnect/services/supplier_service.dart';

final globalSearchProvider =
    NotifierProvider<GlobalSearchNotifier, GlobalSearchState>(
        GlobalSearchNotifier.new);

class GlobalSearchNotifier extends Notifier<GlobalSearchState> {
  final ClientService _clientService = ClientService();
  final InvoiceService _invoiceService = InvoiceService();
  final PaymentService _paymentService = PaymentService();
  final EmployeeService _employeeService = EmployeeService();
  final SupplierService _supplierService = SupplierService();
  final StockService _stockService = StockService();

  @override
  GlobalSearchState build() => const GlobalSearchState();

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> performSearch(String query) async {
    if (query.trim().isEmpty) {
      clearResults();
      return;
    }
    state = state.copyWith(isSearching: true, hasNoResults: false);
    try {
      await Future.wait([
        _searchClients(query),
        _searchInvoices(query),
        _searchPayments(query),
        _searchEmployees(query),
        _searchSuppliers(query),
        _searchStocks(query),
      ]);
      final total =
          state.clientsResults.length +
          state.invoicesResults.length +
          state.paymentsResults.length +
          state.employeesResults.length +
          state.suppliersResults.length +
          state.stocksResults.length;
      state = state.copyWith(isSearching: false, hasNoResults: total == 0);
    } catch (_) {
      state = state.copyWith(isSearching: false);
    }
  }

  Future<void> _searchClients(String query) async {
    try {
      final clients = await _clientService.getClients();
      final q = query.toLowerCase();
      final list = clients
          .where((c) {
            final ne = (c.nomEntreprise ?? '').toLowerCase();
            final n = (c.nom ?? '').toLowerCase();
            final p = (c.prenom ?? '').toLowerCase();
            final e = (c.email ?? '').toLowerCase();
            final co = (c.contact ?? '').toLowerCase();
            return ne.contains(q) || n.contains(q) || p.contains(q) ||
                e.contains(q) || co.contains(q);
          })
          .take(10)
          .toList();
      state = state.copyWith(clientsResults: list);
    } catch (_) {
      state = state.copyWith(clientsResults: []);
    }
  }

  Future<void> _searchInvoices(String query) async {
    try {
      final invoices = await _invoiceService.getAllInvoices();
      final q = query.toLowerCase();
      final list = invoices
          .where((i) =>
              i.invoiceNumber.toLowerCase().contains(q) ||
              i.clientName.toLowerCase().contains(q))
          .take(10)
          .toList();
      state = state.copyWith(invoicesResults: list);
    } catch (_) {
      state = state.copyWith(invoicesResults: []);
    }
  }

  Future<void> _searchPayments(String query) async {
    try {
      final payments = await _paymentService.getAllPayments();
      final q = query.toLowerCase();
      final list = payments
          .where((p) =>
              (p.reference?.toLowerCase() ?? '').contains(q) ||
              p.clientName.toLowerCase().contains(q))
          .take(10)
          .toList();
      state = state.copyWith(paymentsResults: list);
    } catch (_) {
      state = state.copyWith(paymentsResults: []);
    }
  }

  Future<void> _searchEmployees(String query) async {
    try {
      final employees = await _employeeService.getEmployees();
      final q = query.toLowerCase();
      final list = employees
          .where((e) {
            final fn = e.firstName.toLowerCase();
            final ln = e.lastName.toLowerCase();
            final em = e.email.toLowerCase();
            return '$fn $ln'.contains(q) || em.contains(q);
          })
          .take(10)
          .toList();
      state = state.copyWith(employeesResults: list);
    } catch (_) {
      state = state.copyWith(employeesResults: []);
    }
  }

  Future<void> _searchSuppliers(String query) async {
    try {
      final suppliers = await _supplierService.getSuppliers();
      final q = query.toLowerCase();
      final list = suppliers
          .where((s) =>
              s.nom.toLowerCase().contains(q) ||
              s.email.toLowerCase().contains(q) ||
              s.telephone.toLowerCase().contains(q))
          .take(10)
          .toList();
      state = state.copyWith(suppliersResults: list);
    } catch (_) {
      state = state.copyWith(suppliersResults: []);
    }
  }

  Future<void> _searchStocks(String query) async {
    try {
      final stocks = await _stockService.getStocks();
      final q = query.toLowerCase();
      final list = stocks
          .where((s) =>
              s.name.toLowerCase().contains(q) ||
              s.sku.toLowerCase().contains(q) ||
              s.category.toLowerCase().contains(q))
          .take(10)
          .toList();
      state = state.copyWith(stocksResults: list);
    } catch (_) {
      state = state.copyWith(stocksResults: []);
    }
  }

  void clearResults() {
    state = state.copyWith(
      clientsResults: [],
      invoicesResults: [],
      paymentsResults: [],
      employeesResults: [],
      suppliersResults: [],
      stocksResults: [],
      hasNoResults: false,
    );
  }
}

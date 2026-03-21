import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/providers/patron_reports_state.dart';
import 'package:easyconnect/services/devis_service.dart';
import 'package:easyconnect/services/bordereau_service.dart';
import 'package:easyconnect/services/invoice_service.dart';
import 'package:easyconnect/services/payment_service.dart';
import 'package:easyconnect/services/expense_service.dart';
import 'package:easyconnect/services/salary_service.dart';

final patronReportsProvider =
    NotifierProvider<PatronReportsNotifier, PatronReportsState>(
        PatronReportsNotifier.new);

class PatronReportsNotifier extends Notifier<PatronReportsState> {
  final DevisService _devisService = DevisService();
  final BordereauService _bordereauService = BordereauService();
  final InvoiceService _invoiceService = InvoiceService();
  final PaymentService _paymentService = PaymentService();
  final ExpenseService _expenseService = ExpenseService();
  final SalaryService _salaryService = SalaryService();
  bool _isLoadingData = false;

  @override
  PatronReportsState build() {
    final now = DateTime.now();
    return PatronReportsState(
      startDate: now.subtract(const Duration(days: 30)),
      endDate: now,
    );
  }

  Future<void> updateDateRange(DateTime start, DateTime end) async {
    state = state.copyWith(startDate: start, endDate: end);
    await loadReports();
  }

  Future<void> loadReports() async {
    if (_isLoadingData || state.isLoading) return;
    _isLoadingData = true;
    state = state.copyWith(isLoading: true);

    try {
      await Future.wait([
        _loadDevisStats(),
        _loadBordereauxStats(),
        _loadFacturesStats(),
        _loadPaiementsStats(),
        _loadDepensesStats(),
        _loadSalairesStats(),
        _loadCreances(),
      ], eagerError: false);

      final beneficeNet = (state.facturesTotal + state.paiementsTotal) -
          (state.depensesTotal + state.salairesTotal);
      state = state.copyWith(beneficeNet: beneficeNet);
    } catch (_) {}
    finally {
      state = state.copyWith(isLoading: false);
      _isLoadingData = false;
    }
  }

  Future<void> _loadDevisStats() async {
    try {
      int page = 1;
      const perPage = 100;
      int totalCount = 0;
      double totalAmount = 0.0;
      const maxPages = 50;
      final start = state.startDate;
      final end = state.endDate;

      while (page <= maxPages) {
        try {
          final paginated = await _devisService.getDevisPaginated(
            page: page,
            perPage: perPage,
          );
          final filtered = paginated.data.where((d) {
            final date = d.dateCreation;
            return date.isAfter(start.subtract(const Duration(days: 1))) &&
                date.isBefore(end.add(const Duration(days: 1)));
          }).toList();
          totalCount += filtered.length;
          totalAmount += filtered.fold<double>(
              0.0, (double sum, d) => sum + d.totalTTC);
          if (!paginated.hasNextPage) break;
          page++;
        } catch (e) {
          if (page == 1) {
            final devis = await _devisService.getDevis();
            final filtered = devis.where((d) {
              final date = d.dateCreation;
              return date.isAfter(start.subtract(const Duration(days: 1))) &&
                  date.isBefore(end.add(const Duration(days: 1)));
            }).toList();
            state = state.copyWith(
              devisCount: filtered.length,
              devisTotal: filtered.fold<double>(
                  0.0, (double sum, d) => sum + d.totalTTC),
            );
            return;
          }
          break;
        }
      }
      state = state.copyWith(devisCount: totalCount, devisTotal: totalAmount);
    } catch (_) {
      state = state.copyWith(devisCount: 0, devisTotal: 0.0);
    }
  }

  Future<void> _loadBordereauxStats() async {
    try {
      int page = 1;
      const perPage = 100;
      int totalCount = 0;
      double totalAmount = 0.0;
      const maxPages = 50;
      final start = state.startDate;
      final end = state.endDate;

      while (page <= maxPages) {
        try {
          final paginated = await _bordereauService.getBordereauxPaginated(
            page: page,
            perPage: perPage,
          );
          final filtered = paginated.data.where((b) {
            final date = b.dateCreation;
            return date.isAfter(start.subtract(const Duration(days: 1))) &&
                date.isBefore(end.add(const Duration(days: 1)));
          }).toList();
          totalCount += filtered.length;
          totalAmount += filtered.fold<double>(
              0.0, (double sum, b) => sum + b.montantTTC);
          if (!paginated.hasNextPage) break;
          page++;
        } catch (e) {
          if (page == 1) {
            final bordereaux = await _bordereauService.getBordereaux();
            final filtered = bordereaux.where((b) {
              final date = b.dateCreation;
              return date.isAfter(start.subtract(const Duration(days: 1))) &&
                  date.isBefore(end.add(const Duration(days: 1)));
            }).toList();
            state = state.copyWith(
              bordereauxCount: filtered.length,
              bordereauxTotal: filtered.fold<double>(
                  0.0, (double sum, b) => sum + b.montantTTC),
            );
            return;
          }
          break;
        }
      }
      state = state.copyWith(
          bordereauxCount: totalCount, bordereauxTotal: totalAmount);
    } catch (_) {
      state = state.copyWith(bordereauxCount: 0, bordereauxTotal: 0.0);
    }
  }

  Future<void> _loadFacturesStats() async {
    try {
      int page = 1;
      const perPage = 100;
      int totalCount = 0;
      double totalAmount = 0.0;
      const maxPages = 50;
      final start = state.startDate;
      final end = state.endDate;

      while (page <= maxPages) {
        try {
          final paginated = await _invoiceService.getInvoicesPaginated(
            startDate: start,
            endDate: end,
            page: page,
            perPage: perPage,
          );
          totalCount += paginated.data.length;
          totalAmount +=
              paginated.data.fold<double>(
                  0.0, (double sum, f) => sum + f.totalAmount);
          if (!paginated.hasNextPage) break;
          page++;
        } catch (e) {
          if (page == 1) {
            final factures = await _invoiceService.getAllInvoices(
              startDate: start,
              endDate: end,
            );
            state = state.copyWith(
              facturesCount: factures.length,
              facturesTotal: factures.fold<double>(
                  0.0, (double sum, f) => sum + f.totalAmount),
            );
            return;
          }
          break;
        }
      }
      state = state.copyWith(
          facturesCount: totalCount, facturesTotal: totalAmount);
    } catch (_) {
      state = state.copyWith(facturesCount: 0, facturesTotal: 0.0);
    }
  }

  Future<void> _loadPaiementsStats() async {
    try {
      int page = 1;
      const perPage = 100;
      int totalCount = 0;
      double totalAmount = 0.0;
      const maxPages = 50;
      final start = state.startDate;
      final end = state.endDate;

      while (page <= maxPages) {
        try {
          final paginated = await _paymentService.getAllPaymentsPaginated(
            startDate: start,
            endDate: end,
            page: page,
            perPage: perPage,
          );
          totalCount += paginated.data.length;
          totalAmount += paginated.data.fold<double>(
              0.0, (double sum, p) => sum + p.amount);
          if (!paginated.hasNextPage) break;
          page++;
        } catch (e) {
          if (page == 1) {
            final paiements = await _paymentService.getAllPayments(
              startDate: start,
              endDate: end,
            );
            state = state.copyWith(
              paiementsCount: paiements.length,
              paiementsTotal: paiements.fold<double>(
                  0.0, (double sum, p) => sum + p.amount),
            );
            return;
          }
          break;
        }
      }
      state = state.copyWith(
          paiementsCount: totalCount, paiementsTotal: totalAmount);
    } catch (_) {
      state = state.copyWith(paiementsCount: 0, paiementsTotal: 0.0);
    }
  }

  Future<void> _loadDepensesStats() async {
    try {
      int page = 1;
      const perPage = 100;
      int totalCount = 0;
      double totalAmount = 0.0;
      const maxPages = 50;
      final start = state.startDate;
      final end = state.endDate;

      while (page <= maxPages) {
        try {
          final paginated = await _expenseService.getExpensesPaginated(
            page: page,
            perPage: perPage,
          );
          final filtered = paginated.data.where((d) {
            final date = d.expenseDate;
            return date.isAfter(start.subtract(const Duration(days: 1))) &&
                date.isBefore(end.add(const Duration(days: 1)));
          }).toList();
          totalCount += filtered.length;
          totalAmount += filtered.fold<double>(
              0.0, (double sum, d) => sum + d.amount);
          if (!paginated.hasNextPage) break;
          page++;
        } catch (e) {
          if (page == 1) {
            final depenses = await _expenseService.getExpenses();
            final filtered = depenses.where((d) {
              final date = d.expenseDate;
              return date.isAfter(start.subtract(const Duration(days: 1))) &&
                  date.isBefore(end.add(const Duration(days: 1)));
            }).toList();
            state = state.copyWith(
              depensesCount: filtered.length,
              depensesTotal: filtered.fold<double>(
                  0.0, (double sum, d) => sum + d.amount),
            );
            return;
          }
          break;
        }
      }
      state = state.copyWith(
          depensesCount: totalCount, depensesTotal: totalAmount);
    } catch (_) {
      state = state.copyWith(depensesCount: 0, depensesTotal: 0.0);
    }
  }

  Future<void> _loadSalairesStats() async {
    try {
      int page = 1;
      const perPage = 100;
      int totalCount = 0;
      double totalAmount = 0.0;
      const maxPages = 50;
      final start = state.startDate;
      final end = state.endDate;

      while (page <= maxPages) {
        try {
          final paginated = await _salaryService.getSalariesPaginated(
            page: page,
            perPage: perPage,
          );
          final filtered = paginated.data.where((s) {
            final date = s.createdAt ?? DateTime.now();
            return date.isAfter(start.subtract(const Duration(days: 1))) &&
                date.isBefore(end.add(const Duration(days: 1)));
          }).toList();
          totalCount += filtered.length;
          totalAmount +=
              filtered.fold<double>(
                  0.0, (double sum, s) => sum + s.netSalary);
          if (!paginated.hasNextPage) break;
          page++;
        } catch (e) {
          if (page == 1) {
            final salaires = await _salaryService.getSalaries();
            final filtered = salaires.where((s) {
              final date = s.createdAt ?? DateTime.now();
              return date.isAfter(start.subtract(const Duration(days: 1))) &&
                  date.isBefore(end.add(const Duration(days: 1)));
            }).toList();
            state = state.copyWith(
              salairesCount: filtered.length,
              salairesTotal: filtered.fold<double>(
                  0.0, (double sum, s) => sum + s.netSalary),
            );
            return;
          }
          break;
        }
      }
      state = state.copyWith(
          salairesCount: totalCount, salairesTotal: totalAmount);
    } catch (_) {
      state = state.copyWith(salairesCount: 0, salairesTotal: 0.0);
    }
  }

  /// Charge les créances (factures non soldées) par tranche d'âge.
  Future<void> _loadCreances() async {
    try {
      int page = 1;
      const perPage = 100;
      const maxPages = 50;
      double c0_30 = 0.0, c31_60 = 0.0, c61_90 = 0.0, c90Plus = 0.0;
      final now = DateTime.now();

      while (page <= maxPages) {
        final paginated = await _invoiceService.getInvoicesPaginated(
          page: page,
          perPage: perPage,
        );
        for (final inv in paginated.data) {
          if (inv.status == 'paid' || inv.status == 'cancelled') continue;
          final paid = inv.paymentInfo?.amount ?? 0.0;
          final due = (inv.totalAmount - paid).clamp(0.0, double.infinity);
          if (due <= 0) continue;
          final daysOverdue = now.difference(inv.dueDate).inDays;
          if (daysOverdue <= 30) {
            c0_30 += due;
          } else if (daysOverdue <= 60) {
            c31_60 += due;
          } else if (daysOverdue <= 90) {
            c61_90 += due;
          } else {
            c90Plus += due;
          }
        }
        if (!paginated.hasNextPage) break;
        page++;
      }
      state = state.copyWith(
        creances0_30: c0_30,
        creances31_60: c31_60,
        creances61_90: c61_90,
        creances90Plus: c90Plus,
      );
    } catch (_) {
      state = state.copyWith(
        creances0_30: 0.0,
        creances31_60: 0.0,
        creances61_90: 0.0,
        creances90Plus: 0.0,
      );
    }
  }
}

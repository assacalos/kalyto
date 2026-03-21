import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/providers/comptable_dashboard_state.dart';
import 'package:easyconnect/providers/services_providers.dart';
import 'package:easyconnect/services/session_service.dart';
import 'package:easyconnect/utils/cache_helper.dart';

/// Notifier Riverpod pour le dashboard comptable.
class ComptableDashboardNotifier
    extends AsyncNotifier<ComptableDashboardState> {
  Timer? _refreshTimer;

  @override
  Future<ComptableDashboardState> build() async {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      refresh(silent: true);
    });
    ref.onDispose(() => _refreshTimer?.cancel());
    try {
      await _waitForTokenAndLoad().timeout(const Duration(seconds: 15));
    } catch (_) {}
    return state.valueOrNull ?? const ComptableDashboardState();
  }

  Future<void> _waitForTokenAndLoad() async {
    for (int i = 0; i < 30; i++) {
      final token = SessionService.getTokenSync();
      final user = ref.read(authProvider).user;
      if (token != null && token.isNotEmpty && user != null) {
        await refresh();
        return;
      }
      if (i > 0) return;
      await Future.delayed(const Duration(milliseconds: 100));
    }
    await refresh();
  }

  Future<void> refresh({bool silent = false}) async {
    final token = SessionService.getTokenSync();
    if (token == null || token.isEmpty) return;

    final previous = state.valueOrNull ?? const ComptableDashboardState();
    if (!silent) {
      state = AsyncValue.data(previous.copyWith(isLoading: true));
    }
    try {
      final newState = await _loadAll(previous);
      state = AsyncValue.data(newState);
    } catch (e) {
      state = AsyncValue.data(previous.copyWith(isLoading: false));
    }
  }

  Future<ComptableDashboardState> _loadAll(
    ComptableDashboardState current,
  ) async {
    ComptableDashboardState s = current.copyWith(
      isLoading: true,
      pendingFactures:
          CacheHelper.get<int>('dashboard_comptable_pendingFactures') ??
          current.pendingFactures,
      pendingPaiements:
          CacheHelper.get<int>('dashboard_comptable_pendingPaiements') ??
          current.pendingPaiements,
      totalRevenue:
          CacheHelper.get<double>('dashboard_comptable_totalRevenue') ??
          current.totalRevenue,
    );

    try {
      final invoiceService = ref.read(invoiceServiceProvider);
      final paymentService = ref.read(paymentServiceProvider);
      final expenseService = ref.read(expenseServiceProvider);
      final salaryService = ref.read(salaryServiceProvider);
      final taskService = ref.read(taskServiceProvider);

      final results = await Future.wait([
        invoiceService.getAllInvoices(),
        paymentService.getAllPayments(),
        expenseService.getExpenses(),
        salaryService.getSalaries(),
      ]);

      final factures = results[0] as List;
      final statusLower = (String status) => status.toLowerCase().trim();
      int pendingFactures =
          factures.where((f) {
            final status = statusLower(f.status);
            return status == 'draft' || status == 'en_attente';
          }).length;
      final paiements = results[1] as List;
      int pendingPaiements = paiements.where((p) => p.isPending).length;
      final depenses = results[2] as List;
      int pendingDepenses = depenses.where((d) => d.status == 'pending').length;
      final salaires = results[3] as List;
      int pendingSalaires = salaires.where((s) => s.status == 'pending').length;

      final taskResult = await taskService.getTasks(
        status: 'pending',
        page: 1,
        perPage: 1,
      );
      int pendingTasks = 0;
      if (taskResult['success'] == true) {
        final pagination =
            taskResult['pagination'] as Map<String, dynamic>? ?? {};
        pendingTasks = pagination['total'] as int? ?? 0;
      }

      CacheHelper.set('dashboard_comptable_pendingFactures', pendingFactures);
      CacheHelper.set('dashboard_comptable_pendingPaiements', pendingPaiements);
      CacheHelper.set('dashboard_comptable_pendingDepenses', pendingDepenses);
      CacheHelper.set('dashboard_comptable_pendingSalaires', pendingSalaires);

      int validatedFactures = factures.length - pendingFactures;
      int validatedPaiements = paiements.length - pendingPaiements;
      int validatedDepenses = depenses.length - pendingDepenses;
      int validatedSalaires = salaires.length - pendingSalaires;

      double totalRevenue = factures
          .where((f) {
            final status = statusLower(f.status);
            return status == 'valide' ||
                status == 'validated' ||
                status == 'approved';
          })
          .fold(0.0, (sum, f) => sum + f.totalAmount);
      double totalPayments = paiements.fold(
        0.0,
        (sum, p) => sum + (p.amount ?? 0.0),
      );
      double totalExpenses = depenses.fold(
        0.0,
        (sum, d) => sum + (d.amount ?? 0.0),
      );
      double totalSalaries = salaires.fold(0.0, (sum, s) => sum + s.netSalary);
      double netProfit = totalRevenue - totalExpenses - totalSalaries;

      CacheHelper.set('dashboard_comptable_totalRevenue', totalRevenue);

      s = s.copyWith(
        isLoading: false,
        pendingFactures: pendingFactures,
        pendingPaiements: pendingPaiements,
        pendingDepenses: pendingDepenses,
        pendingSalaires: pendingSalaires,
        pendingTasks: pendingTasks,
        validatedFactures: validatedFactures,
        validatedPaiements: validatedPaiements,
        validatedDepenses: validatedDepenses,
        validatedSalaires: validatedSalaires,
        totalRevenue: totalRevenue,
        totalPayments: totalPayments,
        totalExpenses: totalExpenses,
        totalSalaries: totalSalaries,
        netProfit: netProfit,
      );
    } catch (_) {
      s = s.copyWith(isLoading: false);
    }
    return s;
  }

}

final comptableDashboardProvider =
    AsyncNotifierProvider<ComptableDashboardNotifier, ComptableDashboardState>(
      ComptableDashboardNotifier.new,
    );

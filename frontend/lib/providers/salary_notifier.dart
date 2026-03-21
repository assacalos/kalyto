import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/Models/salary_model.dart';
import 'package:easyconnect/providers/salary_state.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/services/salary_service.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/utils/notification_helper.dart';
import 'package:easyconnect/utils/logger.dart';

final salaryProvider =
    NotifierProvider<SalaryNotifier, SalaryState>(SalaryNotifier.new);

class SalaryNotifier extends Notifier<SalaryState> {
  final SalaryService _salaryService = SalaryService();
  bool _loadingInProgress = false;

  @override
  SalaryState build() {
    return SalaryState(
      selectedYear: DateTime.now().year,
    );
  }

  Future<void> loadSalaries({
    String? statusFilter,
    int page = 1,
    bool forceRefresh = false,
  }) async {
    if (_loadingInProgress) return;
    final user = ref.read(authProvider).user;
    if (user == null) return;

    final statusParam = statusFilter ?? (state.selectedStatus == 'all' ? null : state.selectedStatus);
    final monthParam = state.selectedMonth == 'all' ? null : state.selectedMonth;
    final year = state.selectedYear == 0 ? DateTime.now().year : state.selectedYear;
    final cacheKey = 'salaries_${statusParam ?? 'all'}';

    if (page == 1) {
      if (!forceRefresh) {
        final hiveList = SalaryService.getCachedSalaires();
        if (hiveList.isNotEmpty) {
          state = state.copyWith(
            salaries: hiveList,
            isLoading: false,
            currentPage: 1,
          );
          Future.microtask(() => _refreshFromApi(cacheKey, statusParam, monthParam, year));
          return;
        }
        final cached = CacheHelper.get<List<Salary>>(cacheKey);
        if (cached != null && cached.isNotEmpty) {
          state = state.copyWith(
            salaries: cached,
            isLoading: false,
            currentPage: 1,
          );
          Future.microtask(() => _refreshFromApi(cacheKey, statusParam, monthParam, year));
          return;
        }
      }
      state = state.copyWith(salaries: [], isLoading: true);
    } else {
      state = state.copyWith(isLoadingMore: true);
    }

    _loadingInProgress = true;
    try {
      final res = await _salaryService.getSalariesPaginated(
        status: statusParam,
        month: monthParam,
        year: year,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        page: page,
        perPage: state.perPage,
      );

      if (page == 1) {
        state = state.copyWith(
          salaries: res.data,
          isLoading: false,
          currentPage: res.meta.currentPage,
          totalPages: res.meta.lastPage,
          totalItems: res.meta.total,
        );
        CacheHelper.set(cacheKey, res.data);
      } else {
        state = state.copyWith(
          salaries: [...state.salaries, ...res.data],
          isLoadingMore: false,
          currentPage: res.meta.currentPage,
          totalPages: res.meta.lastPage,
          totalItems: res.meta.total,
        );
      }
      loadSalaryStats();
    } catch (e) {
      AppLogger.error('Erreur chargement salaires: $e', tag: 'SALARY_NOTIFIER');
      if (state.salaries.isEmpty) {
        final fallback = CacheHelper.get<List<Salary>>(cacheKey);
        if (fallback != null && fallback.isNotEmpty) {
          state = state.copyWith(salaries: fallback, isLoading: false);
        } else {
          state = state.copyWith(isLoading: false, isLoadingMore: false);
        }
      } else {
        state = state.copyWith(isLoading: false, isLoadingMore: false);
      }
    } finally {
      _loadingInProgress = false;
    }
  }

  Future<void> _refreshFromApi(
    String cacheKey,
    String? statusParam,
    String? monthParam,
    int year,
  ) async {
    try {
      final res = await _salaryService.getSalariesPaginated(
        status: statusParam,
        month: monthParam,
        year: year,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        page: 1,
        perPage: state.perPage,
      );
      state = state.copyWith(
        salaries: res.data,
        currentPage: 1,
        totalPages: res.meta.lastPage,
        totalItems: res.meta.total,
      );
      CacheHelper.set(cacheKey, res.data);
      loadSalaryStats();
    } catch (_) {}
    state = state.copyWith(isLoading: false);
  }

  void loadMore() {
    if (state.hasNextPage && !state.isLoading && !state.isLoadingMore) {
      loadSalaries(
        statusFilter: state.selectedStatus == 'all' ? null : state.selectedStatus,
        page: state.currentPage + 1,
      );
    }
  }

  void filterByStatus(String status) {
    state = state.copyWith(selectedStatus: status);
    loadSalaries(statusFilter: status == 'all' ? null : status);
  }

  void filterByMonth(String month) {
    state = state.copyWith(selectedMonth: month);
    loadSalaries();
  }

  void filterByYear(int year) {
    state = state.copyWith(selectedYear: year);
    loadSalaries();
  }

  void searchSalaries(String query) {
    state = state.copyWith(searchQuery: query);
    loadSalaries();
  }

  Future<void> loadPendingSalaries() async {
    try {
      final pending = await _salaryService.getPendingSalaries();
      state = state.copyWith(pendingSalaries: pending);
    } catch (_) {}
  }

  Future<void> loadEmployees() async {
    try {
      final list = await _salaryService.getEmployees();
      state = state.copyWith(employees: list);
    } catch (_) {
      state = state.copyWith(employees: []);
    }
  }

  Future<void> loadSalaryComponents() async {
    try {
      final components = await _salaryService.getSalaryComponents();
      state = state.copyWith(salaryComponents: components);
    } catch (_) {
      state = state.copyWith(salaryComponents: []);
    }
  }

  Future<void> loadSalaryStats() async {
    try {
      final stats = await _salaryService.getSalaryStats();
      state = state.copyWith(salaryStats: stats);
    } catch (_) {}
  }

  Future<Salary?> createSalary(Salary salary) async {
    state = state.copyWith(isLoading: true);
    try {
      final created = await _salaryService.createSalary(salary);
      CacheHelper.clearByPrefix('salaries_');
      await loadSalaries(forceRefresh: true);
      await loadSalaryStats();
      await loadPendingSalaries();
      if (created.id != null) {
        NotificationHelper.notifySubmission(
          entityType: 'salary',
          entityName: NotificationHelper.getEntityDisplayName('salary', created),
          entityId: created.id.toString(),
          route: NotificationHelper.getEntityRoute('salary', created.id.toString()),
        );
      }
      return created;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> updateSalary(Salary salary) async {
    state = state.copyWith(isLoading: true);
    try {
      await _salaryService.updateSalary(salary);
      CacheHelper.clearByPrefix('salaries_');
      await loadSalaries(forceRefresh: true);
      await loadSalaryStats();
      await loadPendingSalaries();
      return true;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> approveSalary(Salary salary, {String? notes}) async {
    state = state.copyWith(isLoading: true);
    try {
      final success = await _salaryService.approveSalary(salary.id!, notes: notes);
      if (success) {
        NotificationHelper.notifyValidation(
          entityType: 'salary',
          entityName: NotificationHelper.getEntityDisplayName('salary', salary),
          entityId: salary.id.toString(),
          route: NotificationHelper.getEntityRoute('salary', salary.id.toString()),
          entity: salary,
        );
        await loadSalaries(forceRefresh: true);
        await loadSalaryStats();
        await loadPendingSalaries();
      } else {
        throw Exception('Erreur lors de l\'approbation');
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> rejectSalary(Salary salary, String reason) async {
    state = state.copyWith(isLoading: true);
    try {
      final success = await _salaryService.rejectSalary(salary.id!, reason: reason);
      if (success) {
        NotificationHelper.notifyRejection(
          entityType: 'salary',
          entityName: NotificationHelper.getEntityDisplayName('salary', salary),
          entityId: salary.id.toString(),
          reason: reason,
          route: NotificationHelper.getEntityRoute('salary', salary.id.toString()),
          entity: salary,
        );
        await loadSalaries(forceRefresh: true);
        await loadSalaryStats();
        await loadPendingSalaries();
      } else {
        throw Exception('Erreur lors du rejet');
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> markSalaryAsPaid(Salary salary, {String? notes}) async {
    state = state.copyWith(isLoading: true);
    try {
      final success = await _salaryService.markSalaryAsPaid(salary.id!, notes: notes);
      if (success) {
        await loadSalaries(forceRefresh: true);
        await loadSalaryStats();
        await loadPendingSalaries();
      } else {
        throw Exception('Erreur lors du paiement');
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> deleteSalary(Salary salary) async {
    state = state.copyWith(isLoading: true);
    try {
      final success = await _salaryService.deleteSalary(salary.id!);
      if (success) {
        state = state.copyWith(
          salaries: state.salaries.where((s) => s.id != salary.id).toList(),
        );
        await loadSalaryStats();
      } else {
        throw Exception('Erreur lors de la suppression');
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

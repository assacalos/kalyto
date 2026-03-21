import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/Models/expense_model.dart';
import 'package:easyconnect/providers/expense_state.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/services/expense_service.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/utils/notification_helper.dart';
import 'package:easyconnect/utils/logger.dart';

final expenseProvider =
    NotifierProvider<ExpenseNotifier, ExpenseState>(ExpenseNotifier.new);

class ExpenseNotifier extends Notifier<ExpenseState> {
  final ExpenseService _expenseService = ExpenseService();
  bool _loadingInProgress = false;

  @override
  ExpenseState build() {
    return const ExpenseState();
  }

  Future<void> loadExpenses({
    int page = 1,
    bool forceRefresh = false,
  }) async {
    if (_loadingInProgress) return;
    final user = ref.read(authProvider).user;
    if (user == null) return;

    final statusParam =
        state.selectedStatus == 'all' ? null : state.selectedStatus;
    final categoryParam =
        state.selectedCategory == 'all' ? null : state.selectedCategory;
    final cacheKey = 'expenses_${state.selectedStatus}_${state.selectedCategory}';

    if (page == 1) {
      if (!forceRefresh) {
        final hiveList = ExpenseService.getCachedDepenses(
          statusParam,
          categoryParam,
        );
        if (hiveList.isNotEmpty) {
          state = state.copyWith(
            expenses: hiveList,
            isLoading: false,
            currentPage: 1,
          );
          Future.microtask(() =>
              _refreshExpensesFromApi(cacheKey, statusParam, categoryParam));
          return;
        }
        final cached = CacheHelper.get<List<Expense>>(cacheKey);
        if (cached != null && cached.isNotEmpty) {
          state = state.copyWith(
            expenses: cached,
            isLoading: false,
            currentPage: 1,
          );
          Future.microtask(() =>
              _refreshExpensesFromApi(cacheKey, statusParam, categoryParam));
          return;
        }
      }
      state = state.copyWith(expenses: [], isLoading: true);
    } else {
      state = state.copyWith(isLoadingMore: true);
    }

    _loadingInProgress = true;
    try {
      final res = await _expenseService.getExpensesPaginated(
        status: statusParam,
        category: categoryParam,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        page: page,
        perPage: state.perPage,
      );

      if (page == 1) {
        state = state.copyWith(
          expenses: res.data,
          isLoading: false,
          currentPage: res.meta.currentPage,
          totalPages: res.meta.lastPage,
          totalItems: res.meta.total,
        );
        CacheHelper.set(cacheKey, res.data);
      } else {
        state = state.copyWith(
          expenses: [...state.expenses, ...res.data],
          isLoadingMore: false,
          currentPage: res.meta.currentPage,
          totalPages: res.meta.lastPage,
          totalItems: res.meta.total,
        );
      }
      loadExpenseStats();
    } catch (e) {
      AppLogger.error('Erreur chargement dépenses: $e', tag: 'EXPENSE_NOTIFIER');
      if (state.expenses.isEmpty) {
        final fallback = CacheHelper.get<List<Expense>>(cacheKey);
        if (fallback != null && fallback.isNotEmpty) {
          state = state.copyWith(expenses: fallback, isLoading: false);
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

  Future<void> _refreshExpensesFromApi(
    String cacheKey,
    String? statusParam,
    String? categoryParam,
  ) async {
    try {
      final res = await _expenseService.getExpensesPaginated(
        status: statusParam,
        category: categoryParam,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        page: 1,
        perPage: state.perPage,
      );
      if ((statusParam == null && state.selectedStatus == 'all') ||
          (statusParam == state.selectedStatus)) {
        if ((categoryParam == null && state.selectedCategory == 'all') ||
            (categoryParam == state.selectedCategory)) {
          state = state.copyWith(
            expenses: res.data,
            currentPage: 1,
            totalPages: res.meta.lastPage,
            totalItems: res.meta.total,
          );
          CacheHelper.set(cacheKey, res.data);
        }
      }
      loadExpenseStats();
    } catch (_) {}
    state = state.copyWith(isLoading: false);
  }

  void loadMore() {
    if (state.hasNextPage && !state.isLoading && !state.isLoadingMore) {
      loadExpenses(page: state.currentPage + 1);
    }
  }

  void filterByStatus(String status) {
    state = state.copyWith(selectedStatus: status);
    loadExpenses();
  }

  void filterByCategory(String category) {
    state = state.copyWith(selectedCategory: category);
    loadExpenses();
  }

  void searchExpenses(String query) {
    state = state.copyWith(searchQuery: query);
    loadExpenses();
  }

  Future<void> loadPendingExpenses() async {
    try {
      final pending = await _expenseService.getPendingExpenses();
      state = state.copyWith(pendingExpenses: pending);
    } catch (_) {}
  }

  Future<void> loadExpenseCategories() async {
    try {
      final categories = await _expenseService.getExpenseCategories();
      state = state.copyWith(expenseCategories: categories);
    } catch (_) {}
  }

  Future<void> loadExpenseStats() async {
    try {
      final stats = await _expenseService.getExpenseStats();
      state = state.copyWith(expenseStats: stats);
    } catch (_) {}
  }

  Future<void> approveExpense(Expense expense, {String? notes}) async {
    state = state.copyWith(isLoading: true);
    try {
      final success = await _expenseService.approveExpense(
        expense.id!,
        notes: notes,
      );
      if (success) {
        NotificationHelper.notifyValidation(
          entityType: 'expense',
          entityName: NotificationHelper.getEntityDisplayName('expense', expense),
          entityId: expense.id.toString(),
          route: NotificationHelper.getEntityRoute('expense', expense.id.toString()),
          entity: expense,
        );
        await loadExpenses();
        await loadExpenseStats();
        await loadPendingExpenses();
      } else {
        throw Exception('Erreur lors de l\'approbation');
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> rejectExpense(Expense expense, String reason) async {
    state = state.copyWith(isLoading: true);
    try {
      final success = await _expenseService.rejectExpense(expense.id!, reason: reason);
      if (success) {
        NotificationHelper.notifyRejection(
          entityType: 'expense',
          entityName: NotificationHelper.getEntityDisplayName('expense', expense),
          entityId: expense.id.toString(),
          reason: reason,
          route: NotificationHelper.getEntityRoute('expense', expense.id.toString()),
          entity: expense,
        );
        await loadExpenses();
        await loadExpenseStats();
        await loadPendingExpenses();
      } else {
        throw Exception('Erreur lors du rejet');
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> submitExpense(Expense expense) async {
    state = state.copyWith(isLoading: true);
    try {
      final success = await _expenseService.submitExpense(expense.id!);
      if (success) {
        NotificationHelper.notifySubmission(
          entityType: 'expense',
          entityName: NotificationHelper.getEntityDisplayName('expense', expense),
          entityId: expense.id.toString(),
          route: NotificationHelper.getEntityRoute('expense', expense.id.toString()),
        );
        await loadExpenses();
        await loadExpenseStats();
        await loadPendingExpenses();
      } else {
        throw Exception('Erreur lors de la soumission');
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<Expense?> createExpense(Map<String, dynamic> expenseData) async {
    state = state.copyWith(isLoading: true);
    try {
      final created = await _expenseService.createExpense(expenseData);
      await loadExpenses();
      await loadExpenseStats();
      await loadPendingExpenses();
      return created;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> updateExpense(int id, Map<String, dynamic> expenseData) async {
    state = state.copyWith(isLoading: true);
    try {
      await _expenseService.updateExpense(id, expenseData);
      await loadExpenses();
      await loadExpenseStats();
      await loadPendingExpenses();
      return true;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> deleteExpense(Expense expense) async {
    state = state.copyWith(isLoading: true);
    try {
      final success = await _expenseService.deleteExpense(expense.id!);
      if (success) {
        state = state.copyWith(
          expenses: state.expenses.where((e) => e.id != expense.id).toList(),
        );
        await loadExpenseStats();
      } else {
        throw Exception('Erreur lors de la suppression');
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  List<Expense> get filteredExpenses {
    List<Expense> filtered = state.expenses;
    if (state.selectedStatus != 'all') {
      filtered = filtered.where((e) => e.status == state.selectedStatus).toList();
    }
    if (state.selectedCategory != 'all') {
      filtered = filtered.where((e) => e.category == state.selectedCategory).toList();
    }
    if (state.searchQuery.isNotEmpty) {
      final q = state.searchQuery.toLowerCase();
      filtered = filtered
          .where((e) =>
              e.title.toLowerCase().contains(q) ||
              e.description.toLowerCase().contains(q))
          .toList();
    }
    return filtered;
  }
}

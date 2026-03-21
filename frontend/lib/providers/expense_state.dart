import 'package:easyconnect/Models/expense_model.dart';

/// État du provider des dépenses (Riverpod).
class ExpenseState {
  final List<Expense> expenses;
  final List<Expense> pendingExpenses;
  final List<ExpenseCategory> expenseCategories;
  final bool isLoading;
  final bool isLoadingMore;
  final ExpenseStats? expenseStats;
  final String selectedStatus;
  final String selectedCategory;
  final String searchQuery;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int perPage;

  const ExpenseState({
    this.expenses = const [],
    this.pendingExpenses = const [],
    this.expenseCategories = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.expenseStats,
    this.selectedStatus = 'all',
    this.selectedCategory = 'all',
    this.searchQuery = '',
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalItems = 0,
    this.perPage = 15,
  });

  bool get hasNextPage => currentPage < totalPages;
  bool get hasPreviousPage => currentPage > 1;

  ExpenseState copyWith({
    List<Expense>? expenses,
    List<Expense>? pendingExpenses,
    List<ExpenseCategory>? expenseCategories,
    bool? isLoading,
    bool? isLoadingMore,
    ExpenseStats? expenseStats,
    String? selectedStatus,
    String? selectedCategory,
    String? searchQuery,
    int? currentPage,
    int? totalPages,
    int? totalItems,
    int? perPage,
  }) {
    return ExpenseState(
      expenses: expenses ?? this.expenses,
      pendingExpenses: pendingExpenses ?? this.pendingExpenses,
      expenseCategories: expenseCategories ?? this.expenseCategories,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      expenseStats: expenseStats ?? this.expenseStats,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalItems: totalItems ?? this.totalItems,
      perPage: perPage ?? this.perPage,
    );
  }
}

import 'package:easyconnect/Models/salary_model.dart';

/// État du provider des salaires (Riverpod).
class SalaryState {
  final List<Salary> salaries;
  final List<Salary> pendingSalaries;
  final List<Map<String, dynamic>> employees;
  final List<SalaryComponent> salaryComponents;
  final bool isLoading;
  final bool isLoadingMore;
  final SalaryStats? salaryStats;
  final String selectedStatus;
  final String selectedMonth;
  final int selectedYear;
  final String searchQuery;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int perPage;

  const SalaryState({
    this.salaries = const [],
    this.pendingSalaries = const [],
    this.employees = const [],
    this.salaryComponents = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.salaryStats,
    this.selectedStatus = 'all',
    this.selectedMonth = 'all',
    this.selectedYear = 0,
    this.searchQuery = '',
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalItems = 0,
    this.perPage = 15,
  });

  bool get hasNextPage => currentPage < totalPages;

  SalaryState copyWith({
    List<Salary>? salaries,
    List<Salary>? pendingSalaries,
    List<Map<String, dynamic>>? employees,
    List<SalaryComponent>? salaryComponents,
    bool? isLoading,
    bool? isLoadingMore,
    SalaryStats? salaryStats,
    String? selectedStatus,
    String? selectedMonth,
    int? selectedYear,
    String? searchQuery,
    int? currentPage,
    int? totalPages,
    int? totalItems,
    int? perPage,
  }) {
    return SalaryState(
      salaries: salaries ?? this.salaries,
      pendingSalaries: pendingSalaries ?? this.pendingSalaries,
      employees: employees ?? this.employees,
      salaryComponents: salaryComponents ?? this.salaryComponents,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      salaryStats: salaryStats ?? this.salaryStats,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedYear: selectedYear ?? this.selectedYear,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalItems: totalItems ?? this.totalItems,
      perPage: perPage ?? this.perPage,
    );
  }
}

import 'package:easyconnect/Models/employee_model.dart';

class EmployeeState {
  final List<Employee> employees;
  final bool isLoading;
  final bool isLoadingMore;
  final EmployeeStats? employeeStats;
  final List<String> departments;
  final List<String> positions;
  final String searchQuery;
  final String selectedDepartment;
  final String selectedPosition;
  final String selectedStatus;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final int perPage;

  const EmployeeState({
    this.employees = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.employeeStats,
    this.departments = const [],
    this.positions = const [],
    this.searchQuery = '',
    this.selectedDepartment = 'all',
    this.selectedPosition = 'all',
    this.selectedStatus = 'active',
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalItems = 0,
    this.hasNextPage = false,
    this.hasPreviousPage = false,
    this.perPage = 15,
  });

  EmployeeState copyWith({
    List<Employee>? employees,
    bool? isLoading,
    bool? isLoadingMore,
    EmployeeStats? employeeStats,
    List<String>? departments,
    List<String>? positions,
    String? searchQuery,
    String? selectedDepartment,
    String? selectedPosition,
    String? selectedStatus,
    int? currentPage,
    int? totalPages,
    int? totalItems,
    bool? hasNextPage,
    bool? hasPreviousPage,
    int? perPage,
  }) {
    return EmployeeState(
      employees: employees ?? this.employees,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      employeeStats: employeeStats ?? this.employeeStats,
      departments: departments ?? this.departments,
      positions: positions ?? this.positions,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedDepartment: selectedDepartment ?? this.selectedDepartment,
      selectedPosition: selectedPosition ?? this.selectedPosition,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalItems: totalItems ?? this.totalItems,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      hasPreviousPage: hasPreviousPage ?? this.hasPreviousPage,
      perPage: perPage ?? this.perPage,
    );
  }
}

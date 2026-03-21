import 'package:easyconnect/Models/leave_model.dart';

class LeaveState {
  final List<LeaveRequest> leaveRequests;
  final bool isLoading;
  final bool isLoadingMore;
  final LeaveStats? leaveStats;
  final List<LeaveType> leaveTypes;
  final List<Map<String, dynamic>> employees;
  final String searchQuery;
  final String selectedStatus;
  final String selectedLeaveType;
  final String selectedEmployee;
  final DateTime? selectedStartDate;
  final DateTime? selectedEndDate;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final int perPage;
  final bool canManageLeaves;
  final bool canApproveLeaves;
  final bool canViewAllLeaves;

  const LeaveState({
    this.leaveRequests = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.leaveStats,
    this.leaveTypes = const [],
    this.employees = const [],
    this.searchQuery = '',
    this.selectedStatus = 'all',
    this.selectedLeaveType = 'all',
    this.selectedEmployee = 'all',
    this.selectedStartDate,
    this.selectedEndDate,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalItems = 0,
    this.hasNextPage = false,
    this.hasPreviousPage = false,
    this.perPage = 15,
    this.canManageLeaves = true,
    this.canApproveLeaves = true,
    this.canViewAllLeaves = true,
  });

  LeaveState copyWith({
    List<LeaveRequest>? leaveRequests,
    bool? isLoading,
    bool? isLoadingMore,
    LeaveStats? leaveStats,
    List<LeaveType>? leaveTypes,
    List<Map<String, dynamic>>? employees,
    String? searchQuery,
    String? selectedStatus,
    String? selectedLeaveType,
    String? selectedEmployee,
    DateTime? selectedStartDate,
    DateTime? selectedEndDate,
    int? currentPage,
    int? totalPages,
    int? totalItems,
    bool? hasNextPage,
    bool? hasPreviousPage,
    int? perPage,
    bool? canManageLeaves,
    bool? canApproveLeaves,
    bool? canViewAllLeaves,
  }) {
    return LeaveState(
      leaveRequests: leaveRequests ?? this.leaveRequests,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      leaveStats: leaveStats ?? this.leaveStats,
      leaveTypes: leaveTypes ?? this.leaveTypes,
      employees: employees ?? this.employees,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      selectedLeaveType: selectedLeaveType ?? this.selectedLeaveType,
      selectedEmployee: selectedEmployee ?? this.selectedEmployee,
      selectedStartDate: selectedStartDate ?? this.selectedStartDate,
      selectedEndDate: selectedEndDate ?? this.selectedEndDate,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalItems: totalItems ?? this.totalItems,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      hasPreviousPage: hasPreviousPage ?? this.hasPreviousPage,
      perPage: perPage ?? this.perPage,
      canManageLeaves: canManageLeaves ?? this.canManageLeaves,
      canApproveLeaves: canApproveLeaves ?? this.canApproveLeaves,
      canViewAllLeaves: canViewAllLeaves ?? this.canViewAllLeaves,
    );
  }
}

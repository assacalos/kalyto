import 'package:easyconnect/Models/recruitment_model.dart';

class RecruitmentState {
  final List<RecruitmentRequest> recruitmentRequests;
  final bool isLoading;
  final RecruitmentStats? recruitmentStats;
  final List<String> departments;
  final List<String> positions;
  final String searchQuery;
  final String selectedStatus;
  final String selectedDepartment;
  final String selectedPosition;
  final DateTime? selectedStartDate;
  final DateTime? selectedEndDate;
  final bool canManageRecruitment;
  final bool canApproveRecruitment;
  final bool canViewAllRecruitment;

  const RecruitmentState({
    this.recruitmentRequests = const [],
    this.isLoading = false,
    this.recruitmentStats,
    this.departments = const [],
    this.positions = const [],
    this.searchQuery = '',
    this.selectedStatus = 'all',
    this.selectedDepartment = 'all',
    this.selectedPosition = 'all',
    this.selectedStartDate,
    this.selectedEndDate,
    this.canManageRecruitment = true,
    this.canApproveRecruitment = true,
    this.canViewAllRecruitment = true,
  });

  RecruitmentState copyWith({
    List<RecruitmentRequest>? recruitmentRequests,
    bool? isLoading,
    RecruitmentStats? recruitmentStats,
    List<String>? departments,
    List<String>? positions,
    String? searchQuery,
    String? selectedStatus,
    String? selectedDepartment,
    String? selectedPosition,
    DateTime? selectedStartDate,
    DateTime? selectedEndDate,
    bool? canManageRecruitment,
    bool? canApproveRecruitment,
    bool? canViewAllRecruitment,
  }) {
    return RecruitmentState(
      recruitmentRequests: recruitmentRequests ?? this.recruitmentRequests,
      isLoading: isLoading ?? this.isLoading,
      recruitmentStats: recruitmentStats ?? this.recruitmentStats,
      departments: departments ?? this.departments,
      positions: positions ?? this.positions,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      selectedDepartment: selectedDepartment ?? this.selectedDepartment,
      selectedPosition: selectedPosition ?? this.selectedPosition,
      selectedStartDate: selectedStartDate ?? this.selectedStartDate,
      selectedEndDate: selectedEndDate ?? this.selectedEndDate,
      canManageRecruitment: canManageRecruitment ?? this.canManageRecruitment,
      canApproveRecruitment: canApproveRecruitment ?? this.canApproveRecruitment,
      canViewAllRecruitment: canViewAllRecruitment ?? this.canViewAllRecruitment,
    );
  }
}

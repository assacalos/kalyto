import 'package:flutter/foundation.dart';
import 'package:easyconnect/Models/reporting_model.dart';

@immutable
class ReportingState {
  final List<ReportingModel> reports;
  final DateTime startDate;
  final DateTime endDate;
  final String? selectedUserRole;
  final bool isLoading;
  final bool isLoadingMore;
  final int currentPage;
  final int lastPage;
  final int totalItems;
  final int perPage;

  ReportingState({
    this.reports = const [],
    DateTime? startDate,
    DateTime? endDate,
    this.selectedUserRole,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.currentPage = 1,
    this.lastPage = 1,
    this.totalItems = 0,
    this.perPage = 10,
  })  : startDate = startDate ?? DateTime.now().subtract(const Duration(days: 30)),
        endDate = endDate ?? DateTime.now();

  ReportingState copyWith({
    List<ReportingModel>? reports,
    DateTime? startDate,
    DateTime? endDate,
    String? selectedUserRole,
    bool? isLoading,
    bool? isLoadingMore,
    int? currentPage,
    int? lastPage,
    int? totalItems,
    int? perPage,
  }) {
    return ReportingState(
      reports: reports ?? this.reports,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedUserRole: selectedUserRole ?? this.selectedUserRole,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      totalItems: totalItems ?? this.totalItems,
      perPage: perPage ?? this.perPage,
    );
  }

  bool get hasNextPage => currentPage < lastPage;
  bool get hasPreviousPage => currentPage > 1;
}

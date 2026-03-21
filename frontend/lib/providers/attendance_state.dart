import 'package:flutter/foundation.dart';
import 'package:easyconnect/Models/attendance_punch_model.dart';

@immutable
class AttendanceState {
  final List<AttendancePunchModel> attendanceHistory;
  final bool isLoading;
  final bool isLoadingMore;
  final int currentPage;
  final int lastPage;
  final int totalItems;
  final int perPage;
  final String searchQuery;

  const AttendanceState({
    this.attendanceHistory = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.currentPage = 1,
    this.lastPage = 1,
    this.totalItems = 0,
    this.perPage = 15,
    this.searchQuery = '',
  });

  AttendanceState copyWith({
    List<AttendancePunchModel>? attendanceHistory,
    bool? isLoading,
    bool? isLoadingMore,
    int? currentPage,
    int? lastPage,
    int? totalItems,
    int? perPage,
    String? searchQuery,
  }) {
    return AttendanceState(
      attendanceHistory: attendanceHistory ?? this.attendanceHistory,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      totalItems: totalItems ?? this.totalItems,
      perPage: perPage ?? this.perPage,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  bool get hasNextPage => currentPage < lastPage;
  bool get hasPreviousPage => currentPage > 1;
}

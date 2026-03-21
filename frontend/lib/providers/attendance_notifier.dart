import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/providers/attendance_state.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/services/attendance_punch_service.dart';
import 'package:easyconnect/utils/roles.dart';

final attendanceProvider =
    NotifierProvider<AttendanceNotifier, AttendanceState>(AttendanceNotifier.new);

class AttendanceNotifier extends Notifier<AttendanceState> {
  final AttendancePunchService _attendanceService = AttendancePunchService();
  bool _isLoadingInProgress = false;

  int? get _userId => ref.read(authProvider).user?.id;
  int? get _userRole => ref.read(authProvider).user?.role;

  @override
  AttendanceState build() {
    return const AttendanceState();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> loadAttendanceData({int page = 1}) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    if (_isLoadingInProgress) return;
    _isLoadingInProgress = true;

    if (page == 1) {
      state = state.copyWith(isLoading: true);
      final cached = AttendancePunchService.getCachedAttendances();
      if (cached.isNotEmpty) {
        state = state.copyWith(attendanceHistory: cached, isLoading: false);
        _isLoadingInProgress = false;
        Future.microtask(() => _refreshFromApi());
        return;
      }
      state = state.copyWith(attendanceHistory: []);
    } else {
      state = state.copyWith(isLoadingMore: true);
    }

    try {
      final paginatedResponse = await _attendanceService.getAttendancesPaginated(
        userId: _userRole == Roles.PATRON ? null : _userId,
        page: page,
        perPage: state.perPage,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
      );

      if (page == 1) {
        state = state.copyWith(
          attendanceHistory: paginatedResponse.data,
          isLoading: false,
          currentPage: paginatedResponse.meta.currentPage,
          lastPage: paginatedResponse.meta.lastPage,
          totalItems: paginatedResponse.meta.total,
        );
      } else {
        state = state.copyWith(
          attendanceHistory: [...state.attendanceHistory, ...paginatedResponse.data],
          isLoadingMore: false,
          currentPage: paginatedResponse.meta.currentPage,
          lastPage: paginatedResponse.meta.lastPage,
          totalItems: paginatedResponse.meta.total,
        );
      }
    } catch (e) {
      try {
        final history = _userRole == Roles.PATRON
            ? await _attendanceService.getAttendances()
            : await _attendanceService.getAttendances(userId: _userId);
        if (page == 1) {
          state = state.copyWith(
            attendanceHistory: history,
            isLoading: false,
            totalItems: history.length,
            lastPage: 1,
          );
        } else {
          state = state.copyWith(
            attendanceHistory: [...state.attendanceHistory, ...history],
            isLoadingMore: false,
          );
        }
      } catch (_) {
        if (state.attendanceHistory.isEmpty) {
          final fallback = AttendancePunchService.getCachedAttendances();
          if (fallback.isNotEmpty) {
            state = state.copyWith(attendanceHistory: fallback, isLoading: false);
          } else {
            state = state.copyWith(isLoading: false);
          }
        } else {
          state = state.copyWith(isLoading: false, isLoadingMore: false);
        }
      }
    } finally {
      _isLoadingInProgress = false;
    }
  }

  Future<void> _refreshFromApi() async {
    if (_isLoadingInProgress) return;
    final user = ref.read(authProvider).user;
    if (user == null) return;
    _isLoadingInProgress = true;
    try {
      final paginatedResponse = await _attendanceService.getAttendancesPaginated(
        userId: _userRole == Roles.PATRON ? null : _userId,
        page: 1,
        perPage: state.perPage,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
      );
      state = state.copyWith(
        attendanceHistory: paginatedResponse.data,
        currentPage: paginatedResponse.meta.currentPage,
        lastPage: paginatedResponse.meta.lastPage,
        totalItems: paginatedResponse.meta.total,
      );
    } catch (_) {}
    _isLoadingInProgress = false;
  }

  void loadMore() {
    if (state.hasNextPage && !state.isLoading && !state.isLoadingMore) {
      loadAttendanceData(page: state.currentPage + 1);
    }
  }
}

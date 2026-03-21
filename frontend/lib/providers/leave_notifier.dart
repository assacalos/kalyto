import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/Models/leave_model.dart';
import 'package:easyconnect/providers/leave_state.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/services/leave_service.dart';
import 'package:easyconnect/services/employee_service.dart';
import 'package:easyconnect/utils/notification_helper.dart';
import 'package:easyconnect/utils/dashboard_refresh_helper.dart';

final leaveProvider =
    NotifierProvider<LeaveNotifier, LeaveState>(LeaveNotifier.new);

class LeaveNotifier extends Notifier<LeaveState> {
  final LeaveService _leaveService = LeaveService();
  final EmployeeService _employeeService = EmployeeService();
  bool _loadingInProgress = false;

  @override
  LeaveState build() {
    return const LeaveState();
  }

  Future<void> loadLeaveTypes() async {
    try {
      final types = await _leaveService.getLeaveTypes();
      state = state.copyWith(leaveTypes: types);
    } catch (_) {}
  }

  Future<void> loadEmployees() async {
    try {
      final employeesList = await _employeeService.getEmployees(
        limit: 50,
        page: 1,
      );
      final list = employeesList
          .map((e) => {
                'id': e.id,
                'name': '${e.firstName} ${e.lastName}',
                'email': e.email,
              })
          .toList();
      state = state.copyWith(employees: list);
    } catch (_) {
      state = state.copyWith(employees: []);
    }
  }

  Future<void> loadLeaveRequests({int page = 1, bool forceRefresh = false}) async {
    if (_loadingInProgress) return;
    final user = ref.read(authProvider).user;
    if (user == null) return;

    if (page == 1) {
      if (!forceRefresh) {
        final cached = LeaveService.getCachedLeaves();
        if (cached.isNotEmpty) {
          state = state.copyWith(
            leaveRequests: cached,
            isLoading: false,
            currentPage: 1,
          );
          Future.microtask(() => _refreshLeavesFromApi());
          return;
        }
      }
      state = state.copyWith(isLoading: true);
    } else {
      state = state.copyWith(isLoadingMore: true);
    }

    _loadingInProgress = true;
    try {
      final res = await _leaveService.getLeaveRequestsPaginated(
        startDate: state.selectedStartDate,
        endDate: state.selectedEndDate,
        status: state.selectedStatus != 'all' ? state.selectedStatus : null,
        leaveType:
            state.selectedLeaveType != 'all' ? state.selectedLeaveType : null,
        employeeId: state.canViewAllLeaves ? null : user.id,
        page: page,
        perPage: state.perPage,
        search:
            state.searchQuery.isNotEmpty ? state.searchQuery : null,
      );

      final list = res.data;
      if (page == 1) {
        state = state.copyWith(
          leaveRequests: list,
          isLoading: false,
          isLoadingMore: false,
          currentPage: res.meta.currentPage,
          totalPages: res.meta.lastPage,
          totalItems: res.meta.total,
          hasNextPage: res.hasNextPage,
          hasPreviousPage: res.hasPreviousPage,
        );
      } else {
        final existingIds = state.leaveRequests.map((l) => l.id).toSet();
        final newList = List<LeaveRequest>.from(state.leaveRequests)
          ..addAll(
            list.where((l) => l.id != null && !existingIds.contains(l.id)),
          );
        state = state.copyWith(
          leaveRequests: newList,
          isLoadingMore: false,
          currentPage: res.meta.currentPage,
          totalPages: res.meta.lastPage,
          totalItems: res.meta.total,
          hasNextPage: res.hasNextPage,
          hasPreviousPage: res.hasPreviousPage,
        );
      }
    } catch (e) {
      if (page == 1 && state.leaveRequests.isEmpty) {
        final cached = LeaveService.getCachedLeaves();
        if (cached.isNotEmpty) {
          state = state.copyWith(leaveRequests: cached, isLoading: false);
        } else {
          state = state.copyWith(isLoading: false);
        }
      } else {
        state = state.copyWith(isLoading: false, isLoadingMore: false);
      }
    } finally {
      _loadingInProgress = false;
    }
  }

  Future<void> _refreshLeavesFromApi() async {
    try {
      final user = ref.read(authProvider).user;
      if (user == null) return;
      final res = await _leaveService.getLeaveRequestsPaginated(
        startDate: state.selectedStartDate,
        endDate: state.selectedEndDate,
        status: state.selectedStatus != 'all' ? state.selectedStatus : null,
        leaveType:
            state.selectedLeaveType != 'all' ? state.selectedLeaveType : null,
        employeeId: state.canViewAllLeaves ? null : user.id,
        page: 1,
        perPage: state.perPage,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
      );
      state = state.copyWith(
        leaveRequests: res.data,
        currentPage: res.meta.currentPage,
        totalPages: res.meta.lastPage,
        totalItems: res.meta.total,
        hasNextPage: res.hasNextPage,
        hasPreviousPage: res.hasPreviousPage,
      );
    } catch (_) {}
  }

  void loadMore() {
    if (state.hasNextPage && !state.isLoading && !state.isLoadingMore) {
      loadLeaveRequests(page: state.currentPage + 1);
    }
  }

  Future<void> loadLeaveStats() async {
    try {
      final stats = await _leaveService.getLeaveStats(
        startDate: state.selectedStartDate,
        endDate: state.selectedEndDate,
      );
      state = state.copyWith(leaveStats: stats);
    } catch (_) {}
  }

  void searchLeaves(String query) {
    state = state.copyWith(searchQuery: query);
    loadLeaveRequests();
  }

  void filterByStatus(String status) {
    state = state.copyWith(selectedStatus: status);
    loadLeaveRequests();
  }

  void filterByLeaveType(String leaveType) {
    state = state.copyWith(selectedLeaveType: leaveType);
    loadLeaveRequests();
  }

  void filterByEmployee(String employeeId) {
    state = state.copyWith(selectedEmployee: employeeId);
    loadLeaveRequests();
  }

  Future<void> approveLeaveRequest(LeaveRequest request, {String? comments}) async {
    if (request.id == null) return;
    try {
      final result = await _leaveService.approveLeaveRequest(
        request.id!,
        comments: comments,
      );
      if (result['success'] == true) {
        NotificationHelper.notifyValidation(
          entityType: 'leave',
          entityName: NotificationHelper.getEntityDisplayName('leave', request),
          entityId: request.id.toString(),
          route: NotificationHelper.getEntityRoute(
            'leave',
            request.id.toString(),
          ),
          entity: request,
        );
        DashboardRefreshHelper.refreshPatronCounter('leave');
        DashboardRefreshHelper.refreshRhDashboard();
        await loadLeaveRequests();
        await loadLeaveStats();
      } else {
        throw Exception(result['message'] ?? 'Erreur lors de l\'approbation');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> rejectLeaveRequest(LeaveRequest request, String rejectionReason) async {
    if (request.id == null) return;
    try {
      final result = await _leaveService.rejectLeaveRequest(
        request.id!,
        rejectionReason: rejectionReason,
      );
      if (result['success'] == true) {
        NotificationHelper.notifyRejection(
          entityType: 'leave',
          entityName: NotificationHelper.getEntityDisplayName('leave', request),
          entityId: request.id.toString(),
          reason: rejectionReason,
          route: NotificationHelper.getEntityRoute(
            'leave',
            request.id.toString(),
          ),
          entity: request,
        );
        DashboardRefreshHelper.refreshPatronCounter('leave');
        DashboardRefreshHelper.refreshRhDashboard();
        await loadLeaveRequests();
        await loadLeaveStats();
      } else {
        throw Exception(result['message'] ?? 'Erreur lors du rejet');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> cancelLeaveRequest(LeaveRequest request) async {
    if (request.id == null) return;
    try {
      final result = await _leaveService.cancelLeaveRequest(request.id!);
      if (result['success'] == true) {
        DashboardRefreshHelper.refreshPatronCounter('leave');
        DashboardRefreshHelper.refreshRhDashboard();
        await loadLeaveRequests();
        await loadLeaveStats();
      } else {
        throw Exception(result['message'] ?? 'Erreur lors de l\'annulation');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteLeaveRequest(LeaveRequest request) async {
    if (request.id == null) return;
    try {
      final result = await _leaveService.deleteLeaveRequest(request.id!);
      if (result['success'] == true) {
        DashboardRefreshHelper.refreshPatronCounter('leave');
        DashboardRefreshHelper.refreshRhDashboard();
        await loadLeaveRequests();
        await loadLeaveStats();
      } else {
        throw Exception(result['message'] ?? 'Erreur lors de la suppression');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Crée une demande de congé. Utilisé par le formulaire (Riverpod).
  Future<bool> createLeaveRequest({
    required int employeeId,
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    String? comments,
    List<String>? attachmentPaths,
  }) async {
    try {
      final result = await _leaveService.createLeaveRequest(
        employeeId: employeeId,
        leaveType: leaveType,
        startDate: startDate,
        endDate: endDate,
        reason: reason,
        comments: comments,
        attachmentPaths: attachmentPaths,
      );
      if (result['success'] == true) {
        DashboardRefreshHelper.refreshPatronCounter('leave');
        DashboardRefreshHelper.refreshRhDashboard();
        await loadLeaveRequests(forceRefresh: true);
        await loadLeaveStats();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

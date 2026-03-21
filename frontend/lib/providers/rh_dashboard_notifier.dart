import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/providers/rh_dashboard_state.dart';
import 'package:easyconnect/providers/services_providers.dart';
import 'package:easyconnect/services/session_service.dart';

/// Notifier Riverpod pour le dashboard RH.
class RhDashboardNotifier extends AsyncNotifier<RhDashboardState> {
  Timer? _refreshTimer;

  @override
  Future<RhDashboardState> build() async {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      refresh(silent: true);
    });
    ref.onDispose(() => _refreshTimer?.cancel());
    try {
      await _waitForTokenAndLoad().timeout(const Duration(seconds: 15));
    } catch (_) {}
    return state.valueOrNull ?? const RhDashboardState();
  }

  Future<void> _waitForTokenAndLoad() async {
    for (int i = 0; i < 30; i++) {
      final token = SessionService.getTokenSync();
      final user = ref.read(authProvider).user;
      if (token != null && token.isNotEmpty && user != null) {
        await refresh();
        return;
      }
      if (i > 0) return;
      await Future.delayed(const Duration(milliseconds: 100));
    }
    await refresh();
  }

  Future<void> refresh({bool silent = false}) async {
    final token = SessionService.getTokenSync();
    if (token == null || token.isEmpty) return;

    final previous = state.valueOrNull ?? const RhDashboardState();
    if (!silent) {
      state = AsyncValue.data(previous.copyWith(isLoading: true));
    }
    try {
      final newState = await _loadAll(previous);
      state = AsyncValue.data(newState);
    } catch (e) {
      state = AsyncValue.data(previous.copyWith(isLoading: false));
    }
  }

  Future<RhDashboardState> _loadAll(RhDashboardState current) async {
    RhDashboardState s = current.copyWith(isLoading: true);

    try {
      final leaveService = ref.read(leaveServiceProvider);
      final recruitmentService = ref.read(recruitmentServiceProvider);
      final attendanceService = ref.read(attendancePunchServiceProvider);
      final contractService = ref.read(contractServiceProvider);
      final employeeService = ref.read(employeeServiceProvider);
      final taskService = ref.read(taskServiceProvider);

      final results = await Future.wait([
        leaveService.getAllLeaveRequests(),
        recruitmentService.getAllRecruitmentRequests(),
        attendanceService.getAttendances(),
        contractService.getAllContracts(),
      ]);

      final leaves = results[0] as List;
      int pendingLeaves =
          leaves.where((l) => (l as dynamic).status == 'pending').length;
      final recruitments = results[1] as List;
      int pendingRecruitments =
          recruitments
              .where((r) => (r as dynamic).status == 'published')
              .length;
      final attendances = results[2] as List;
      int pendingAttendance =
          attendances
              .where((a) => (a as dynamic).status.toLowerCase() == 'pending')
              .length;
      final contracts = results[3] as List;
      int pendingContracts =
          contracts.where((c) => (c as dynamic).status == 'pending').length;

      int pendingSalaries = 0;
      int pendingTasks = 0;
      try {
        final taskResult = await taskService.getTasks(
          status: 'pending',
          page: 1,
          perPage: 1,
        );
        if (taskResult['success'] == true) {
          final pagination =
              taskResult['pagination'] as Map<String, dynamic>? ?? {};
          pendingTasks = pagination['total'] as int? ?? 0;
        }
      } catch (_) {}

      final employees = await employeeService.getEmployees();
      int activeEmployees = employees.length;
      int approvedLeaves =
          leaves.where((l) => (l as dynamic).status == 'approved').length;
      int completedRecruitments = recruitments.length - pendingRecruitments;
      int approvedContracts =
          contracts.where((c) => (c as dynamic).status == 'active').length;
      int paidSalaries = 0;

      s = s.copyWith(
        isLoading: false,
        pendingLeaves: pendingLeaves,
        pendingRecruitments: pendingRecruitments,
        pendingAttendance: pendingAttendance,
        pendingSalaries: pendingSalaries,
        pendingContracts: pendingContracts,
        pendingTasks: pendingTasks,
        activeEmployees: activeEmployees,
        approvedLeaves: approvedLeaves,
        completedRecruitments: completedRecruitments,
        paidSalaries: paidSalaries,
        approvedContracts: approvedContracts,
      );
    } catch (_) {
      s = s.copyWith(isLoading: false);
    }
    return s;
  }
}

final rhDashboardProvider =
    AsyncNotifierProvider<RhDashboardNotifier, RhDashboardState>(
      RhDashboardNotifier.new,
    );

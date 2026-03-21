import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/providers/technicien_dashboard_state.dart';
import 'package:easyconnect/providers/services_providers.dart';
import 'package:easyconnect/services/session_service.dart';

/// Notifier Riverpod pour le dashboard technicien.
class TechnicienDashboardNotifier
    extends AsyncNotifier<TechnicienDashboardState> {
  Timer? _refreshTimer;

  @override
  Future<TechnicienDashboardState> build() async {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      refresh(silent: true);
    });
    ref.onDispose(() => _refreshTimer?.cancel());
    try {
      await _waitForTokenAndLoad().timeout(const Duration(seconds: 15));
    } catch (_) {}
    return state.valueOrNull ?? const TechnicienDashboardState();
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

    final previous = state.valueOrNull ?? const TechnicienDashboardState();
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

  Future<TechnicienDashboardState> _loadAll(
    TechnicienDashboardState current,
  ) async {
    TechnicienDashboardState s = current.copyWith(isLoading: true);

    try {
      final interventionService = ref.read(interventionServiceProvider);
      final reportingService = ref.read(reportingServiceProvider);
      final equipmentService = ref.read(equipmentServiceProvider);
      final taskService = ref.read(taskServiceProvider);

      final results = await Future.wait([
        interventionService.getInterventions(),
        reportingService.getAllReports(),
        equipmentService.getEquipments(),
      ]);

      final interventions = results[0] as List;
      int pendingInterventions =
          interventions
              .where((i) => (i as dynamic).status.toLowerCase() == 'pending')
              .length;
      int pendingMaintenance = 0;
      final reports = results[1] as List;
      int pendingReports =
          reports.where((r) {
            final status = (r as dynamic).status;
            return status == 'pending' || status == 'submitted';
          }).length;
      final equipments = results[2] as List;
      int pendingEquipments =
          equipments.where((e) {
            final status =
                (e as dynamic).status?.toString().toLowerCase() ?? '';
            return status == 'pending' ||
                status == 'en_attente' ||
                status == 'maintenance' ||
                status == 'broken' ||
                (e as dynamic).needsMaintenance == true;
          }).length;

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

      int completedInterventions =
          interventions.where((i) {
            final status = (i as dynamic).status.toLowerCase();
            return status == 'completed' ||
                status == 'approved' ||
                status == 'validated';
          }).length;
      int completedMaintenance = 0;
      int validatedReports =
          reports
              .where(
                (r) =>
                    (r as dynamic).status == 'validated' ||
                    (r as dynamic).status == 'done',
              )
              .length;
      int operationalEquipments =
          equipments
              .where((e) => (e as dynamic).status.toLowerCase() == 'active')
              .length;

      double interventionCost = interventions.fold(
        0.0,
        (sum, i) => sum + ((i as dynamic).cost ?? 0.0),
      );
      double equipmentValue = equipments.fold(
        0.0,
        (sum, e) => sum + ((e as dynamic).currentValue ?? 0.0),
      );

      s = s.copyWith(
        isLoading: false,
        pendingInterventions: pendingInterventions,
        pendingMaintenance: pendingMaintenance,
        pendingReports: pendingReports,
        pendingEquipments: pendingEquipments,
        pendingTasks: pendingTasks,
        completedInterventions: completedInterventions,
        completedMaintenance: completedMaintenance,
        validatedReports: validatedReports,
        operationalEquipments: operationalEquipments,
        interventionCost: interventionCost,
        maintenanceCost: 0.0,
        equipmentValue: equipmentValue,
        savings: 0.0,
      );
    } catch (_) {
      s = s.copyWith(isLoading: false);
    }
    return s;
  }
}

final technicienDashboardProvider = AsyncNotifierProvider<
  TechnicienDashboardNotifier,
  TechnicienDashboardState
>(TechnicienDashboardNotifier.new);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/Models/intervention_model.dart';
import 'package:easyconnect/providers/intervention_state.dart';
import 'package:easyconnect/services/intervention_service.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/utils/notification_helper.dart';
import 'package:easyconnect/utils/dashboard_refresh_helper.dart';

final interventionProvider =
    NotifierProvider<InterventionNotifier, InterventionState>(
        InterventionNotifier.new);

class InterventionNotifier extends Notifier<InterventionState> {
  final InterventionService _service = InterventionService();
  final GetStorage _storage = GetStorage();
  bool _loadingInProgress = false;
  String? _currentStatusFilter;

  @override
  InterventionState build() {
    final role = _storage.read<int>('userRole');
    final canManage = role == 1 || role == 6;
    final canApprove = role == 1 || role == 4;
    return InterventionState(
      canManageInterventions: canManage,
      canApproveInterventions: canApprove,
      canViewInterventions: true,
    );
  }

  Future<void> loadInterventions({
    String? statusFilter,
    int page = 1,
    bool forceRefresh = false,
  }) async {
    if (_loadingInProgress) return;
    _loadingInProgress = true;
    _currentStatusFilter =
        statusFilter ?? (state.selectedStatus == 'all' ? null : state.selectedStatus);

    if (!forceRefresh && page == 1) {
      final cached = InterventionService.getCachedInterventions();
      if (cached.isNotEmpty) {
        state = state.copyWith(
            interventions: cached, isLoading: false);
        _loadingInProgress = false;
        Future.microtask(() => _refreshInterventionsFromApi());
        return;
      }
    }

    if (page == 1) {
      state = state.copyWith(isLoading: true);
    } else {
      state = state.copyWith(isLoadingMore: true);
    }

    try {
      final response = await _service.getInterventionsPaginated(
        status: _currentStatusFilter,
        type: state.selectedType == 'all' ? null : state.selectedType,
        priority:
            state.selectedPriority == 'all' ? null : state.selectedPriority,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        page: page,
        perPage: state.perPage,
      );

      state = state.copyWith(
        interventions: page == 1
            ? response.data
            : [...state.interventions, ...response.data],
        currentPage: response.meta.currentPage,
        totalPages: response.meta.lastPage,
        totalItems: response.meta.total,
        hasNextPage: response.hasNextPage,
        hasPreviousPage: response.hasPreviousPage,
        isLoading: false,
        isLoadingMore: false,
      );
    } catch (_) {
      try {
        final list = await _service.getInterventions(
          status: _currentStatusFilter,
          type: state.selectedType == 'all' ? null : state.selectedType,
          priority:
              state.selectedPriority == 'all' ? null : state.selectedPriority,
          search: state.searchQuery.isEmpty ? null : state.searchQuery,
        );
        state = state.copyWith(
          interventions: list,
          isLoading: false,
          isLoadingMore: false,
        );
      } catch (e) {
        if (page == 1 && state.interventions.isEmpty) {
          final cached = InterventionService.getCachedInterventions();
          state = state.copyWith(
            interventions: cached,
            isLoading: false,
            isLoadingMore: false,
          );
        } else {
          state = state.copyWith(isLoading: false, isLoadingMore: false);
        }
      }
    } finally {
      _loadingInProgress = false;
    }
  }

  Future<void> _refreshInterventionsFromApi() async {
    try {
      final response = await _service.getInterventionsPaginated(
        status: _currentStatusFilter,
        type: state.selectedType == 'all' ? null : state.selectedType,
        priority:
            state.selectedPriority == 'all' ? null : state.selectedPriority,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        page: 1,
        perPage: state.perPage,
      );
      state = state.copyWith(
        interventions: response.data,
        currentPage: 1,
        totalPages: response.meta.lastPage,
        totalItems: response.meta.total,
        hasNextPage: response.hasNextPage,
        hasPreviousPage: response.hasPreviousPage,
      );
      loadInterventionStats();
    } catch (_) {}
  }

  void loadMore() {
    if (state.hasNextPage && !state.isLoading && !state.isLoadingMore) {
      loadInterventions(
        statusFilter: _currentStatusFilter,
        page: state.currentPage + 1,
      );
    }
  }

  Future<void> loadPendingInterventions() async {
    try {
      final pending = await _service.getPendingInterventions();
      state = state.copyWith(pendingInterventions: pending);
    } catch (_) {}
  }

  Future<void> loadInterventionStats() async {
    try {
      final stats = await _service.getInterventionStats();
      state = state.copyWith(interventionStats: stats);
    } catch (_) {}
  }

  void filterByStatus(String status) {
    state = state.copyWith(selectedStatus: status);
    loadInterventions();
  }

  void filterByType(String type) {
    state = state.copyWith(selectedType: type);
    loadInterventions();
  }

  void filterByPriority(String priority) {
    state = state.copyWith(selectedPriority: priority);
    loadInterventions();
  }

  void searchInterventions(String query) {
    state = state.copyWith(searchQuery: query);
    loadInterventions();
  }

  Future<void> approveIntervention(Intervention intervention, {String? notes}) async {
    if (intervention.id == null) return;
    CacheHelper.clearByPrefix('interventions_');
    try {
      final success = await _service.approveIntervention(intervention.id!, notes: notes);
      if (success) {
        DashboardRefreshHelper.refreshPatronCounter('intervention');
        DashboardRefreshHelper.refreshTechnicienPending('intervention');
        NotificationHelper.notifyValidation(
          entityType: 'intervention',
          entityName: NotificationHelper.getEntityDisplayName('intervention', intervention),
          entityId: intervention.id.toString(),
          route: NotificationHelper.getEntityRoute('intervention', intervention.id.toString()),
          entity: intervention,
        );
        await loadInterventions(statusFilter: _currentStatusFilter);
        await loadInterventionStats();
        await loadPendingInterventions();
      } else {
        throw Exception('Échec de l\'approbation');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> rejectIntervention(Intervention intervention, String reason) async {
    if (intervention.id == null) return;
    CacheHelper.clearByPrefix('interventions_');
    try {
      final success = await _service.rejectIntervention(intervention.id!, reason: reason);
      if (success) {
        DashboardRefreshHelper.refreshPatronCounter('intervention');
        DashboardRefreshHelper.refreshTechnicienPending('intervention');
        NotificationHelper.notifyRejection(
          entityType: 'intervention',
          entityName: NotificationHelper.getEntityDisplayName('intervention', intervention),
          entityId: intervention.id.toString(),
          reason: reason,
          route: NotificationHelper.getEntityRoute('intervention', intervention.id.toString()),
          entity: intervention,
        );
        await loadInterventions(statusFilter: _currentStatusFilter);
        await loadInterventionStats();
        await loadPendingInterventions();
      } else {
        throw Exception('Échec du rejet');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> startIntervention(Intervention intervention, {String? notes}) async {
    if (intervention.id == null) return;
    try {
      final success = await _service.startIntervention(intervention.id!, notes: notes);
      if (success) {
        DashboardRefreshHelper.refreshTechnicienPending('intervention');
        await loadInterventions();
        await loadInterventionStats();
      } else {
        throw Exception('Échec du démarrage');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> completeIntervention(
    Intervention intervention, {
    required String solution,
    String? completionNotes,
    double? actualDuration,
    double? cost,
  }) async {
    if (intervention.id == null) return;
    try {
      final success = await _service.completeIntervention(
        intervention.id!,
        solution: solution,
        completionNotes: completionNotes,
        actualDuration: actualDuration,
        cost: cost,
      );
      if (success) {
        DashboardRefreshHelper.refreshTechnicienPending('intervention');
        await loadInterventions();
        await loadInterventionStats();
      } else {
        throw Exception('Échec de la finalisation');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteIntervention(Intervention intervention) async {
    if (intervention.id == null) return;
    try {
      final success = await _service.deleteIntervention(intervention.id!);
      if (success) {
        state = state.copyWith(
          interventions: state.interventions
              .where((i) => i.id != intervention.id)
              .toList(),
        );
        await loadInterventionStats();
      } else {
        throw Exception('Échec de la suppression');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Crée une intervention. Utilisé par le formulaire (Riverpod).
  Future<bool> createIntervention(Intervention intervention) async {
    try {
      final created = await _service.createIntervention(intervention);
      CacheHelper.clearByPrefix('interventions_');
      if (created.id != null) {
        NotificationHelper.notifySubmission(
          entityType: 'intervention',
          entityName: NotificationHelper.getEntityDisplayName('intervention', created),
          entityId: created.id.toString(),
          route: NotificationHelper.getEntityRoute('intervention', created.id.toString()),
        );
      }
      await loadInterventions(forceRefresh: true);
      await loadInterventionStats();
      await loadPendingInterventions();
      DashboardRefreshHelper.refreshTechnicienPending('intervention');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Met à jour une intervention. Utilisé par le formulaire (Riverpod).
  Future<bool> updateIntervention(Intervention intervention) async {
    if (intervention.id == null) return false;
    try {
      await _service.updateIntervention(intervention);
      CacheHelper.clearByPrefix('interventions_');
      await loadInterventions(forceRefresh: true);
      await loadInterventionStats();
      await loadPendingInterventions();
      DashboardRefreshHelper.refreshTechnicienPending('intervention');
      return true;
    } catch (_) {
      return false;
    }
  }
}

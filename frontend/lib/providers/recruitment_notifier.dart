import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/Models/recruitment_model.dart';
import 'package:easyconnect/providers/recruitment_state.dart';
import 'package:easyconnect/services/recruitment_service.dart';
import 'package:easyconnect/utils/notification_helper.dart';
import 'package:easyconnect/utils/dashboard_refresh_helper.dart';

final recruitmentProvider =
    NotifierProvider<RecruitmentNotifier, RecruitmentState>(RecruitmentNotifier.new);

class RecruitmentNotifier extends Notifier<RecruitmentState> {
  final RecruitmentService _service = RecruitmentService();
  bool _loadingInProgress = false;

  @override
  RecruitmentState build() {
    return const RecruitmentState();
  }

  Future<void> loadDepartments() async {
    try {
      final depts = await _service.getDepartments();
      state = state.copyWith(departments: depts);
    } catch (_) {}
  }

  Future<void> loadPositions() async {
    try {
      final pos = await _service.getPositions();
      state = state.copyWith(positions: pos);
    } catch (_) {}
  }

  Future<void> loadRecruitmentRequests({bool forceRefresh = false}) async {
    if (_loadingInProgress) return;
    _loadingInProgress = true;

    if (!forceRefresh) {
      final cached = RecruitmentService.getCachedRecruitments();
      if (cached.isNotEmpty) {
        state = state.copyWith(recruitmentRequests: cached, isLoading: false);
        _loadingInProgress = false;
        Future.microtask(() => _refreshFromApi());
        return;
      }
    }

    state = state.copyWith(isLoading: true);
    try {
      final requests = await _service.getAllRecruitmentRequests(
        status: state.selectedStatus != 'all' ? state.selectedStatus : null,
        department: state.selectedDepartment != 'all' ? state.selectedDepartment : null,
        position: state.selectedPosition != 'all' ? state.selectedPosition : null,
      );
      state = state.copyWith(recruitmentRequests: requests, isLoading: false);
    } catch (e) {
      if (state.recruitmentRequests.isEmpty) {
        final cached = RecruitmentService.getCachedRecruitments();
        if (cached.isNotEmpty) {
          state = state.copyWith(recruitmentRequests: cached, isLoading: false);
        } else {
          state = state.copyWith(isLoading: false);
        }
      } else {
        state = state.copyWith(isLoading: false);
      }
    } finally {
      _loadingInProgress = false;
    }
  }

  Future<void> _refreshFromApi() async {
    try {
      final requests = await _service.getAllRecruitmentRequests(
        status: state.selectedStatus != 'all' ? state.selectedStatus : null,
        department: state.selectedDepartment != 'all' ? state.selectedDepartment : null,
        position: state.selectedPosition != 'all' ? state.selectedPosition : null,
      );
      state = state.copyWith(recruitmentRequests: requests);
    } catch (_) {}
  }

  Future<void> loadRecruitmentStats() async {
    try {
      final stats = await _service.getRecruitmentStats(
        startDate: state.selectedStartDate,
        endDate: state.selectedEndDate,
        department: state.selectedDepartment != 'all' ? state.selectedDepartment : null,
      );
      state = state.copyWith(recruitmentStats: stats);
    } catch (_) {}
  }

  void filterByStatus(String status) {
    state = state.copyWith(selectedStatus: status);
    loadRecruitmentRequests();
  }

  void filterByDepartment(String department) {
    state = state.copyWith(selectedDepartment: department);
    loadRecruitmentRequests();
  }

  void filterByPosition(String position) {
    state = state.copyWith(selectedPosition: position);
    loadRecruitmentRequests();
  }

  void searchRecruitments(String query) {
    state = state.copyWith(searchQuery: query);
    loadRecruitmentRequests();
  }

  Future<void> publishRecruitmentRequest(RecruitmentRequest request) async {
    if (request.id == null) return;
    try {
      final result = await _service.publishRecruitmentRequest(request.id!);
      if (result['success'] == true) {
        DashboardRefreshHelper.refreshPatronCounter('recruitment');
        DashboardRefreshHelper.refreshRhDashboard();
        await loadRecruitmentRequests();
        await loadRecruitmentStats();
      } else {
        throw Exception(result['message'] ?? 'Erreur lors de la publication');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> approveRecruitmentRequest(RecruitmentRequest request) async {
    if (request.id == null) return;
    try {
      final result = await _service.approveRecruitmentRequest(request.id!);
      if (result['success'] == true) {
        NotificationHelper.notifyValidation(
          entityType: 'recruitment',
          entityName: NotificationHelper.getEntityDisplayName('recruitment', request),
          entityId: request.id.toString(),
          route: NotificationHelper.getEntityRoute('recruitment', request.id.toString()),
          entity: request,
        );
        DashboardRefreshHelper.refreshPatronCounter('recruitment');
        DashboardRefreshHelper.refreshRhDashboard();
        state = state.copyWith(selectedStatus: 'all');
        await loadRecruitmentRequests();
        await loadRecruitmentStats();
      } else {
        throw Exception(result['message'] ?? 'Erreur lors de l\'approbation');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> rejectRecruitmentRequest(RecruitmentRequest request, String reason) async {
    if (request.id == null) return;
    try {
      final result = await _service.rejectRecruitmentRequest(request.id!, rejectionReason: reason);
      if (result['success'] == true) {
        NotificationHelper.notifyRejection(
          entityType: 'recruitment',
          entityName: NotificationHelper.getEntityDisplayName('recruitment', request),
          entityId: request.id.toString(),
          reason: reason,
          route: NotificationHelper.getEntityRoute('recruitment', request.id.toString()),
          entity: request,
        );
        DashboardRefreshHelper.refreshPatronCounter('recruitment');
        DashboardRefreshHelper.refreshRhDashboard();
        state = state.copyWith(selectedStatus: 'all');
        await loadRecruitmentRequests();
        await loadRecruitmentStats();
      } else {
        throw Exception(result['message'] ?? 'Erreur lors du rejet');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> closeRecruitmentRequest(RecruitmentRequest request) async {
    if (request.id == null) return;
    try {
      final result = await _service.closeRecruitmentRequest(request.id!);
      if (result['success'] == true) {
        DashboardRefreshHelper.refreshPatronCounter('recruitment');
        DashboardRefreshHelper.refreshRhDashboard();
        await loadRecruitmentRequests();
        await loadRecruitmentStats();
      } else {
        throw Exception(result['message'] ?? 'Erreur lors de la fermeture');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> cancelRecruitmentRequest(RecruitmentRequest request) async {
    if (request.id == null) return;
    try {
      final result = await _service.cancelRecruitmentRequest(request.id!);
      if (result['success'] == true) {
        DashboardRefreshHelper.refreshPatronCounter('recruitment');
        DashboardRefreshHelper.refreshRhDashboard();
        await loadRecruitmentRequests();
        await loadRecruitmentStats();
      } else {
        throw Exception(result['message'] ?? 'Erreur lors de l\'annulation');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteRecruitmentRequest(RecruitmentRequest request) async {
    if (request.id == null) return;
    try {
      final result = await _service.deleteRecruitmentRequest(request.id!);
      if (result['success'] == true) {
        DashboardRefreshHelper.refreshPatronCounter('recruitment');
        DashboardRefreshHelper.refreshRhDashboard();
        await loadRecruitmentRequests();
        await loadRecruitmentStats();
      } else {
        throw Exception(result['message'] ?? 'Erreur lors de la suppression');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Crée une demande de recrutement (formulaire Riverpod).
  Future<bool> createRecruitmentRequest({
    required String title,
    required List<String> departments,
    required List<String> positions,
    required String description,
    required String requirements,
    required String responsibilities,
    required int numberOfPositions,
    required String employmentType,
    required String experienceLevel,
    required String salaryRange,
    required String location,
    required DateTime applicationDeadline,
  }) async {
    try {
      final departmentString = departments.join(', ');
      final positionString = positions.join(', ');
      final result = await _service.createRecruitmentRequest(
        title: title,
        department: departmentString,
        position: positionString,
        description: description,
        requirements: requirements,
        responsibilities: responsibilities,
        numberOfPositions: numberOfPositions,
        employmentType: employmentType,
        experienceLevel: experienceLevel,
        salaryRange: salaryRange,
        location: location,
        applicationDeadline: applicationDeadline,
      );
      if (result['success'] == true && result['data'] != null && result['data']['id'] != null) {
        await loadRecruitmentRequests(forceRefresh: true);
        await loadRecruitmentStats();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

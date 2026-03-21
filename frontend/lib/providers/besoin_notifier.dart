import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/providers/besoin_state.dart';
import 'package:easyconnect/services/besoin_service.dart';
import 'package:easyconnect/utils/dashboard_refresh_helper.dart';

final besoinProvider =
    NotifierProvider<BesoinNotifier, BesoinState>(BesoinNotifier.new);

class BesoinNotifier extends Notifier<BesoinState> {
  final BesoinService _service = BesoinService();
  final GetStorage _storage = GetStorage();
  bool _loadingInProgress = false;

  @override
  BesoinState build() {
    final role = _storage.read<int>('userRole');
    final isTechnicien = role == 5; // Roles.TECHNICIEN
    final canMarkTreated = role == 1 || role == 6; // ADMIN, PATRON
    return BesoinState(
      isTechnicien: isTechnicien,
      canMarkTreated: canMarkTreated,
    );
  }

  Future<void> loadBesoins({bool forceRefresh = false}) async {
    if (_loadingInProgress && !forceRefresh) return;
    _loadingInProgress = true;
    final status =
        state.selectedStatus == 'all' ? null : state.selectedStatus;

    if (!forceRefresh) {
      final cached = BesoinService.getCachedBesoins(status);
      if (cached.isNotEmpty) {
        state = state.copyWith(besoins: cached, isLoading: false);
        _loadingInProgress = false;
        Future.microtask(() => _refreshFromApi(status));
        return;
      }
    }

    state = state.copyWith(isLoading: true);
    try {
      final list = await _service.getBesoins(status: status);
      state = state.copyWith(besoins: list, isLoading: false);
    } catch (e) {
      if (state.besoins.isEmpty) {
        state = state.copyWith(isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } finally {
      _loadingInProgress = false;
    }
  }

  Future<void> _refreshFromApi(String? status) async {
    try {
      final list = await _service.getBesoins(status: status);
      final sameFilter = (status == null && state.selectedStatus == 'all') ||
          (status != null && state.selectedStatus == status);
      if (sameFilter) {
        state = state.copyWith(besoins: list);
      }
    } catch (_) {}
  }

  void filterByStatus(String status) {
    state = state.copyWith(selectedStatus: status);
    loadBesoins(forceRefresh: true);
  }

  Future<bool> createBesoin({
    required String title,
    String? description,
    required String reminderFrequency,
  }) async {
    if (title.trim().isEmpty) return false;
    state = state.copyWith(isLoading: true);
    try {
      await _service.createBesoin(
        title: title.trim(),
        description: description?.trim().isEmpty == true ? null : description?.trim(),
        reminderFrequency: reminderFrequency,
      );
      await loadBesoins(forceRefresh: true);
      return true;
    } catch (_) {
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> markTreated(int id, {String? note}) async {
    state = state.copyWith(isLoading: true);
    try {
      await _service.markTreated(id, treatedNote: note);
      DashboardRefreshHelper.refreshTechnicienPending('besoin');
      await loadBesoins(forceRefresh: true);
    } catch (e) {
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

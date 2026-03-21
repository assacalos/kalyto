import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/Models/equipment_model.dart';
import 'package:easyconnect/providers/equipment_state.dart';
import 'package:easyconnect/services/equipment_service.dart';
import 'package:easyconnect/utils/dashboard_refresh_helper.dart';

final equipmentProvider =
    NotifierProvider<EquipmentNotifier, EquipmentState>(EquipmentNotifier.new);

class EquipmentNotifier extends Notifier<EquipmentState> {
  final EquipmentService _service = EquipmentService();
  bool _loadingInProgress = false;

  @override
  EquipmentState build() {
    return const EquipmentState();
  }

  Future<void> loadEquipments({bool forceRefresh = false}) async {
    if (_loadingInProgress) return;
    _loadingInProgress = true;

    if (!forceRefresh) {
      final cached = EquipmentService.getCachedEquipments();
      if (cached.isNotEmpty) {
        state = state.copyWith(equipments: cached, isLoading: false);
        _loadingInProgress = false;
        Future.microtask(() => _refreshFromApi());
        return;
      }
    }

    state = state.copyWith(isLoading: true);
    try {
      final list = await _service.getEquipments(
        status: state.selectedStatus != 'all' ? state.selectedStatus : null,
        category: state.selectedCategory != 'all' ? state.selectedCategory : null,
        condition:
            state.selectedCondition != 'all' ? state.selectedCondition : null,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
      );
      state = state.copyWith(equipments: list, isLoading: false);
    } catch (e) {
      if (state.equipments.isEmpty) {
        final cached = EquipmentService.getCachedEquipments();
        if (cached.isNotEmpty) {
          state = state.copyWith(equipments: cached, isLoading: false);
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
      final list = await _service.getEquipments(
        status: state.selectedStatus != 'all' ? state.selectedStatus : null,
        category: state.selectedCategory != 'all' ? state.selectedCategory : null,
        condition:
            state.selectedCondition != 'all' ? state.selectedCondition : null,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
      );
      state = state.copyWith(equipments: list);
    } catch (_) {}
  }

  Future<void> loadEquipmentStats() async {
    try {
      final stats = await _service.getEquipmentStats();
      state = state.copyWith(equipmentStats: stats);
    } catch (_) {}
  }

  Future<void> loadEquipmentCategories() async {
    try {
      final categories = await _service.getEquipmentCategories();
      state = state.copyWith(equipmentCategories: categories);
    } catch (_) {}
  }

  Future<void> loadEquipmentsNeedingMaintenance() async {
    try {
      final list = await _service.getEquipmentsNeedingMaintenance();
      state = state.copyWith(equipmentsNeedingMaintenance: list);
    } catch (_) {}
  }

  Future<void> loadEquipmentsWithExpiredWarranty() async {
    try {
      final list = await _service.getEquipmentsWithExpiredWarranty();
      state = state.copyWith(equipmentsWithExpiredWarranty: list);
    } catch (_) {}
  }

  void filterByStatus(String status) {
    state = state.copyWith(selectedStatus: status);
    loadEquipments();
  }

  void filterByCategory(String category) {
    state = state.copyWith(selectedCategory: category);
    loadEquipments();
  }

  void filterByCondition(String condition) {
    state = state.copyWith(selectedCondition: condition);
    loadEquipments();
  }

  void searchEquipments(String query) {
    state = state.copyWith(searchQuery: query);
    loadEquipments();
  }

  Future<void> updateEquipmentStatus(Equipment equipment, String status) async {
    if (equipment.id == null) return;
    try {
      final success = await _service.updateEquipmentStatus(equipment.id!, status);
      if (success) {
        DashboardRefreshHelper.refreshTechnicienPending('equipment');
        await loadEquipments();
        await loadEquipmentStats();
      } else {
        throw Exception('Erreur lors de la mise à jour du statut');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateEquipmentCondition(
      Equipment equipment, String condition) async {
    if (equipment.id == null) return;
    try {
      final success = await _service.updateEquipmentCondition(
          equipment.id!, condition);
      if (success) {
        DashboardRefreshHelper.refreshTechnicienPending('equipment');
        await loadEquipments();
        await loadEquipmentStats();
      } else {
        throw Exception('Erreur lors de la mise à jour de l\'état');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteEquipment(Equipment equipment) async {
    if (equipment.id == null) return;
    try {
      final success = await _service.deleteEquipment(equipment.id!);
      if (success) {
        DashboardRefreshHelper.refreshTechnicienPending('equipment');
        await loadEquipments();
        await loadEquipmentStats();
      } else {
        throw Exception('Erreur lors de la suppression');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Crée un équipement. Utilisé par le formulaire (Riverpod).
  Future<bool> createEquipment(Equipment equipment) async {
    try {
      await _service.createEquipment(equipment);
      DashboardRefreshHelper.refreshTechnicienPending('equipment');
      await loadEquipments(forceRefresh: true);
      await loadEquipmentStats();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Met à jour un équipement. Utilisé par le formulaire (Riverpod).
  Future<bool> updateEquipment(Equipment equipment) async {
    if (equipment.id == null) return false;
    try {
      await _service.updateEquipment(equipment);
      DashboardRefreshHelper.refreshTechnicienPending('equipment');
      await loadEquipments(forceRefresh: true);
      await loadEquipmentStats();
      return true;
    } catch (_) {
      return false;
    }
  }
}

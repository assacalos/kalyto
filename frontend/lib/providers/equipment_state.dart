import 'package:easyconnect/Models/equipment_model.dart';

class EquipmentState {
  final List<Equipment> equipments;
  final bool isLoading;
  final EquipmentStats? equipmentStats;
  final List<EquipmentCategory> equipmentCategories;
  final List<Equipment> equipmentsNeedingMaintenance;
  final List<Equipment> equipmentsWithExpiredWarranty;
  final String searchQuery;
  final String selectedStatus;
  final String selectedCategory;
  final String selectedCondition;
  final bool canManageEquipments;
  final bool canViewEquipments;

  const EquipmentState({
    this.equipments = const [],
    this.isLoading = false,
    this.equipmentStats,
    this.equipmentCategories = const [],
    this.equipmentsNeedingMaintenance = const [],
    this.equipmentsWithExpiredWarranty = const [],
    this.searchQuery = '',
    this.selectedStatus = 'all',
    this.selectedCategory = 'all',
    this.selectedCondition = 'all',
    this.canManageEquipments = true,
    this.canViewEquipments = true,
  });

  EquipmentState copyWith({
    List<Equipment>? equipments,
    bool? isLoading,
    EquipmentStats? equipmentStats,
    List<EquipmentCategory>? equipmentCategories,
    List<Equipment>? equipmentsNeedingMaintenance,
    List<Equipment>? equipmentsWithExpiredWarranty,
    String? searchQuery,
    String? selectedStatus,
    String? selectedCategory,
    String? selectedCondition,
    bool? canManageEquipments,
    bool? canViewEquipments,
  }) {
    return EquipmentState(
      equipments: equipments ?? this.equipments,
      isLoading: isLoading ?? this.isLoading,
      equipmentStats: equipmentStats ?? this.equipmentStats,
      equipmentCategories: equipmentCategories ?? this.equipmentCategories,
      equipmentsNeedingMaintenance:
          equipmentsNeedingMaintenance ?? this.equipmentsNeedingMaintenance,
      equipmentsWithExpiredWarranty:
          equipmentsWithExpiredWarranty ?? this.equipmentsWithExpiredWarranty,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedCondition: selectedCondition ?? this.selectedCondition,
      canManageEquipments: canManageEquipments ?? this.canManageEquipments,
      canViewEquipments: canViewEquipments ?? this.canViewEquipments,
    );
  }
}

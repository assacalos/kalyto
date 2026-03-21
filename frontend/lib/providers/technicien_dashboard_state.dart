import 'package:flutter/material.dart';
import 'package:easyconnect/Views/Components/stats_grid.dart';
import 'package:easyconnect/utils/permissions.dart';

/// État immutable du dashboard technicien.
@immutable
class TechnicienDashboardState {
  final bool isLoading;
  final int pendingInterventions;
  final int pendingMaintenance;
  final int pendingReports;
  final int pendingEquipments;
  final int pendingTasks;
  final int completedInterventions;
  final int completedMaintenance;
  final int validatedReports;
  final int operationalEquipments;
  final double interventionCost;
  final double maintenanceCost;
  final double equipmentValue;
  final double savings;

  const TechnicienDashboardState({
    this.isLoading = false,
    this.pendingInterventions = 0,
    this.pendingMaintenance = 0,
    this.pendingReports = 0,
    this.pendingEquipments = 0,
    this.pendingTasks = 0,
    this.completedInterventions = 0,
    this.completedMaintenance = 0,
    this.validatedReports = 0,
    this.operationalEquipments = 0,
    this.interventionCost = 0.0,
    this.maintenanceCost = 0.0,
    this.equipmentValue = 0.0,
    this.savings = 0.0,
  });

  TechnicienDashboardState copyWith({
    bool? isLoading,
    int? pendingInterventions,
    int? pendingMaintenance,
    int? pendingReports,
    int? pendingEquipments,
    int? pendingTasks,
    int? completedInterventions,
    int? completedMaintenance,
    int? validatedReports,
    int? operationalEquipments,
    double? interventionCost,
    double? maintenanceCost,
    double? equipmentValue,
    double? savings,
  }) {
    return TechnicienDashboardState(
      isLoading: isLoading ?? this.isLoading,
      pendingInterventions: pendingInterventions ?? this.pendingInterventions,
      pendingMaintenance: pendingMaintenance ?? this.pendingMaintenance,
      pendingReports: pendingReports ?? this.pendingReports,
      pendingEquipments: pendingEquipments ?? this.pendingEquipments,
      pendingTasks: pendingTasks ?? this.pendingTasks,
      completedInterventions: completedInterventions ?? this.completedInterventions,
      completedMaintenance: completedMaintenance ?? this.completedMaintenance,
      validatedReports: validatedReports ?? this.validatedReports,
      operationalEquipments: operationalEquipments ?? this.operationalEquipments,
      interventionCost: interventionCost ?? this.interventionCost,
      maintenanceCost: maintenanceCost ?? this.maintenanceCost,
      equipmentValue: equipmentValue ?? this.equipmentValue,
      savings: savings ?? this.savings,
    );
  }

  List<StatCard> get enhancedStats => [
        StatCard(
          title: "Interventions en attente",
          value: pendingInterventions.toString(),
          icon: Icons.build,
          color: Colors.orange,
          requiredPermission: Permissions.MANAGE_INTERVENTIONS,
        ),
        StatCard(
          title: "Maintenance en attente",
          value: pendingMaintenance.toString(),
          icon: Icons.engineering,
          color: Colors.blue,
          requiredPermission: Permissions.MANAGE_EQUIPMENT,
        ),
        StatCard(
          title: "Rapports en attente",
          value: pendingReports.toString(),
          icon: Icons.analytics,
          color: Colors.green,
          requiredPermission: Permissions.VIEW_REPORTS,
        ),
        StatCard(
          title: "Équipements en attente",
          value: pendingEquipments.toString(),
          icon: Icons.settings,
          color: Colors.purple,
          requiredPermission: Permissions.MANAGE_EQUIPMENT,
        ),
      ];
}

import 'package:flutter/material.dart';
import 'package:easyconnect/Views/Components/stats_grid.dart';
import 'package:easyconnect/utils/permissions.dart';

/// État immutable du dashboard RH.
@immutable
class RhDashboardState {
  final bool isLoading;
  final int pendingLeaves;
  final int pendingRecruitments;
  final int pendingAttendance;
  final int pendingSalaries;
  final int pendingContracts;
  final int pendingTasks;
  final int activeEmployees;
  final int approvedLeaves;
  final int completedRecruitments;
  final int paidSalaries;
  final int approvedContracts;
  final double totalSalaryMass;
  final double totalBonuses;
  final double recruitmentCost;
  final double trainingCost;

  const RhDashboardState({
    this.isLoading = false,
    this.pendingLeaves = 0,
    this.pendingRecruitments = 0,
    this.pendingAttendance = 0,
    this.pendingSalaries = 0,
    this.pendingContracts = 0,
    this.pendingTasks = 0,
    this.activeEmployees = 0,
    this.approvedLeaves = 0,
    this.completedRecruitments = 0,
    this.paidSalaries = 0,
    this.approvedContracts = 0,
    this.totalSalaryMass = 0.0,
    this.totalBonuses = 0.0,
    this.recruitmentCost = 0.0,
    this.trainingCost = 0.0,
  });

  RhDashboardState copyWith({
    bool? isLoading,
    int? pendingLeaves,
    int? pendingRecruitments,
    int? pendingAttendance,
    int? pendingSalaries,
    int? pendingContracts,
    int? pendingTasks,
    int? activeEmployees,
    int? approvedLeaves,
    int? completedRecruitments,
    int? paidSalaries,
    int? approvedContracts,
    double? totalSalaryMass,
    double? totalBonuses,
    double? recruitmentCost,
    double? trainingCost,
  }) {
    return RhDashboardState(
      isLoading: isLoading ?? this.isLoading,
      pendingLeaves: pendingLeaves ?? this.pendingLeaves,
      pendingRecruitments: pendingRecruitments ?? this.pendingRecruitments,
      pendingAttendance: pendingAttendance ?? this.pendingAttendance,
      pendingSalaries: pendingSalaries ?? this.pendingSalaries,
      pendingContracts: pendingContracts ?? this.pendingContracts,
      pendingTasks: pendingTasks ?? this.pendingTasks,
      activeEmployees: activeEmployees ?? this.activeEmployees,
      approvedLeaves: approvedLeaves ?? this.approvedLeaves,
      completedRecruitments: completedRecruitments ?? this.completedRecruitments,
      paidSalaries: paidSalaries ?? this.paidSalaries,
      approvedContracts: approvedContracts ?? this.approvedContracts,
      totalSalaryMass: totalSalaryMass ?? this.totalSalaryMass,
      totalBonuses: totalBonuses ?? this.totalBonuses,
      recruitmentCost: recruitmentCost ?? this.recruitmentCost,
      trainingCost: trainingCost ?? this.trainingCost,
    );
  }

  List<StatCard> get enhancedStats => [
        StatCard(
          title: "Congés en attente",
          value: pendingLeaves.toString(),
          icon: Icons.beach_access,
          color: Colors.blue,
          requiredPermission: Permissions.MANAGE_LEAVES,
        ),
        StatCard(
          title: "Recrutements en attente",
          value: pendingRecruitments.toString(),
          icon: Icons.person_add,
          color: Colors.green,
          requiredPermission: Permissions.MANAGE_RECRUITMENT,
        ),
        StatCard(
          title: "Pointages en attente",
          value: pendingAttendance.toString(),
          icon: Icons.access_time,
          color: Colors.orange,
          requiredPermission: Permissions.VIEW_ATTENDANCE,
        ),
      ];
}

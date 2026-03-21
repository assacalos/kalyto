import 'package:flutter/material.dart';
import 'package:easyconnect/Views/Components/stats_grid.dart';
import 'package:easyconnect/utils/permissions.dart';

/// État immutable du dashboard comptable.
@immutable
class ComptableDashboardState {
  final bool isLoading;
  final int pendingFactures;
  final int pendingPaiements;
  final int pendingDepenses;
  final int pendingSalaires;
  final int pendingTasks;
  final int validatedFactures;
  final int validatedPaiements;
  final int validatedDepenses;
  final int validatedSalaires;
  final double totalRevenue;
  final double totalPayments;
  final double totalExpenses;
  final double totalSalaries;
  final double netProfit;

  const ComptableDashboardState({
    this.isLoading = false,
    this.pendingFactures = 0,
    this.pendingPaiements = 0,
    this.pendingDepenses = 0,
    this.pendingSalaires = 0,
    this.pendingTasks = 0,
    this.validatedFactures = 0,
    this.validatedPaiements = 0,
    this.validatedDepenses = 0,
    this.validatedSalaires = 0,
    this.totalRevenue = 0.0,
    this.totalPayments = 0.0,
    this.totalExpenses = 0.0,
    this.totalSalaries = 0.0,
    this.netProfit = 0.0,
  });

  ComptableDashboardState copyWith({
    bool? isLoading,
    int? pendingFactures,
    int? pendingPaiements,
    int? pendingDepenses,
    int? pendingSalaires,
    int? pendingTasks,
    int? validatedFactures,
    int? validatedPaiements,
    int? validatedDepenses,
    int? validatedSalaires,
    double? totalRevenue,
    double? totalPayments,
    double? totalExpenses,
    double? totalSalaries,
    double? netProfit,
  }) {
    return ComptableDashboardState(
      isLoading: isLoading ?? this.isLoading,
      pendingFactures: pendingFactures ?? this.pendingFactures,
      pendingPaiements: pendingPaiements ?? this.pendingPaiements,
      pendingDepenses: pendingDepenses ?? this.pendingDepenses,
      pendingSalaires: pendingSalaires ?? this.pendingSalaires,
      pendingTasks: pendingTasks ?? this.pendingTasks,
      validatedFactures: validatedFactures ?? this.validatedFactures,
      validatedPaiements: validatedPaiements ?? this.validatedPaiements,
      validatedDepenses: validatedDepenses ?? this.validatedDepenses,
      validatedSalaires: validatedSalaires ?? this.validatedSalaires,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalPayments: totalPayments ?? this.totalPayments,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      totalSalaries: totalSalaries ?? this.totalSalaries,
      netProfit: netProfit ?? this.netProfit,
    );
  }

  List<StatCard> get enhancedStats => [
        StatCard(
          title: "Factures en attente",
          value: pendingFactures.toString(),
          icon: Icons.receipt,
          color: Colors.red,
          requiredPermission: Permissions.VIEW_FINANCES,
        ),
        StatCard(
          title: "Paiements en attente",
          value: pendingPaiements.toString(),
          icon: Icons.payment,
          color: Colors.teal,
          requiredPermission: Permissions.VIEW_FINANCES,
        ),
        StatCard(
          title: "Dépenses en attente",
          value: pendingDepenses.toString(),
          icon: Icons.money_off,
          color: Colors.orange,
          requiredPermission: Permissions.VIEW_FINANCES,
        ),
        StatCard(
          title: "Salaires en attente",
          value: pendingSalaires.toString(),
          icon: Icons.account_balance_wallet,
          color: Colors.purple,
          requiredPermission: Permissions.VIEW_FINANCES,
        ),
      ];
}

import 'package:flutter/material.dart';
import 'package:easyconnect/Views/Components/data_chart.dart';
import 'package:easyconnect/Views/Components/stats_grid.dart';
import 'package:easyconnect/utils/permissions.dart';

/// État immutable du dashboard commercial (compteurs, montants, chargement).
/// Tous les écrans et onglets écoutent le même provider pour une synchronisation instantanée.
@immutable
class CommercialDashboardState {
  final bool isLoading;
  final int pendingClients;
  final int pendingDevis;
  final int pendingBordereaux;
  final int pendingBonCommandes;
  final int pendingBonCommandesFournisseur;
  final int pendingTasks;
  final int validatedClients;
  final int validatedDevis;
  final int validatedBordereaux;
  final int validatedBonCommandes;
  final double totalRevenue;
  final double pendingDevisAmount;
  final double paidBordereauxAmount;
  final List<ChartData> revenueData;
  final List<ChartData> clientData;
  final List<ChartData> devisData;
  final List<ChartData> bordereauData;

  const CommercialDashboardState({
    this.isLoading = false,
    this.pendingClients = 0,
    this.pendingDevis = 0,
    this.pendingBordereaux = 0,
    this.pendingBonCommandes = 0,
    this.pendingBonCommandesFournisseur = 0,
    this.pendingTasks = 0,
    this.validatedClients = 0,
    this.validatedDevis = 0,
    this.validatedBordereaux = 0,
    this.validatedBonCommandes = 0,
    this.totalRevenue = 0.0,
    this.pendingDevisAmount = 0.0,
    this.paidBordereauxAmount = 0.0,
    this.revenueData = const [],
    this.clientData = const [],
    this.devisData = const [],
    this.bordereauData = const [],
  });

  CommercialDashboardState copyWith({
    bool? isLoading,
    int? pendingClients,
    int? pendingDevis,
    int? pendingBordereaux,
    int? pendingBonCommandes,
    int? pendingBonCommandesFournisseur,
    int? pendingTasks,
    int? validatedClients,
    int? validatedDevis,
    int? validatedBordereaux,
    int? validatedBonCommandes,
    double? totalRevenue,
    double? pendingDevisAmount,
    double? paidBordereauxAmount,
    List<ChartData>? revenueData,
    List<ChartData>? clientData,
    List<ChartData>? devisData,
    List<ChartData>? bordereauData,
  }) {
    return CommercialDashboardState(
      isLoading: isLoading ?? this.isLoading,
      pendingClients: pendingClients ?? this.pendingClients,
      pendingDevis: pendingDevis ?? this.pendingDevis,
      pendingBordereaux: pendingBordereaux ?? this.pendingBordereaux,
      pendingBonCommandes: pendingBonCommandes ?? this.pendingBonCommandes,
      pendingBonCommandesFournisseur:
          pendingBonCommandesFournisseur ?? this.pendingBonCommandesFournisseur,
      pendingTasks: pendingTasks ?? this.pendingTasks,
      validatedClients: validatedClients ?? this.validatedClients,
      validatedDevis: validatedDevis ?? this.validatedDevis,
      validatedBordereaux: validatedBordereaux ?? this.validatedBordereaux,
      validatedBonCommandes:
          validatedBonCommandes ?? this.validatedBonCommandes,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      pendingDevisAmount: pendingDevisAmount ?? this.pendingDevisAmount,
      paidBordereauxAmount: paidBordereauxAmount ?? this.paidBordereauxAmount,
      revenueData: revenueData ?? this.revenueData,
      clientData: clientData ?? this.clientData,
      devisData: devisData ?? this.devisData,
      bordereauData: bordereauData ?? this.bordereauData,
    );
  }

  List<StatCard> get enhancedStats => [
        StatCard(
          title: "Clients en attente",
          value: pendingClients.toString(),
          icon: Icons.people,
          color: Colors.blue,
          requiredPermission: Permissions.MANAGE_CLIENTS,
        ),
        StatCard(
          title: "Devis en attente",
          value: pendingDevis.toString(),
          icon: Icons.description,
          color: Colors.green,
          requiredPermission: Permissions.MANAGE_DEVIS,
        ),
        StatCard(
          title: "Bordereaux en attente",
          value: pendingBordereaux.toString(),
          icon: Icons.assignment_turned_in,
          color: Colors.orange,
          requiredPermission: Permissions.MANAGE_BORDEREAUX,
        ),
        StatCard(
          title: "Bons en attente",
          value: pendingBonCommandes.toString(),
          icon: Icons.shopping_cart,
          color: Colors.purple,
          requiredPermission: Permissions.MANAGE_BON_COMMANDES,
        ),
      ];
}

import 'package:flutter/material.dart';
import 'package:easyconnect/Views/Components/stats_grid.dart';
import 'package:easyconnect/utils/permissions.dart';
import 'package:easyconnect/providers/patron_validation_item.dart';

/// État immutable du dashboard patron (compteurs en attente, métriques, KPIs, file validations).
@immutable
class PatronDashboardState {
  final bool isLoading;
  final int pendingClients;
  final int pendingDevis;
  final int pendingBordereaux;
  final int pendingBonCommandes;
  final int pendingFactures;
  final int pendingPaiements;
  final int pendingDepenses;
  final int pendingSalaires;
  final int pendingReporting;
  final int pendingPointages;
  final int pendingInterventions;
  final int pendingTaxes;
  final int pendingRecruitments;
  final int pendingContracts;
  final int pendingLeaves;
  final int pendingSuppliers;
  final int pendingStocks;
  final int pendingRegistrations;
  final int pendingTasks;
  final int validatedClients;
  final int totalEmployees;
  final int totalSuppliers;
  final double totalRevenue;

  /// Période affichée pour les KPIs : 'day' | 'week' | 'month'
  final String kpiPeriod;

  /// KPIs par période (toujours calculés pour les 3)
  final double kpiCaJour;
  final double kpiCaSemaine;
  final double kpiCaMois;
  final double kpiEncaissable;
  final double kpiDepensesJour;
  final double kpiDepensesSemaine;
  final double kpiDepensesMois;
  final double kpiMargeJour;
  final double kpiMargeSemaine;
  final double kpiMargeBrute;

  /// Rappels / alertes pour inciter à l'action (validations en attente, stock, retard)
  final List<String> rappels;

  /// File "Urgence & Validations" : éléments cliquables / swipe
  final List<PatronValidationItem> validationQueue;

  /// Opérations en cours : dernières factures (clientName, totalAmount, id)
  final List<Map<String, dynamic>> lastInvoices;
  /// Nombre d'alertes stock (rupture ou sous seuil)
  final int stockAlertsCount;
  /// Répartition interventions pour PieChart: { 'pending': n, 'in_progress': n, 'completed': n, 'rejected': n }
  final Map<String, int> interventionPie;

  const PatronDashboardState({
    this.isLoading = false,
    this.pendingClients = 0,
    this.pendingDevis = 0,
    this.pendingBordereaux = 0,
    this.pendingBonCommandes = 0,
    this.pendingFactures = 0,
    this.pendingPaiements = 0,
    this.pendingDepenses = 0,
    this.pendingSalaires = 0,
    this.pendingReporting = 0,
    this.pendingPointages = 0,
    this.pendingInterventions = 0,
    this.pendingTaxes = 0,
    this.pendingRecruitments = 0,
    this.pendingContracts = 0,
    this.pendingLeaves = 0,
    this.pendingSuppliers = 0,
    this.pendingStocks = 0,
    this.pendingRegistrations = 0,
    this.pendingTasks = 0,
    this.validatedClients = 0,
    this.totalEmployees = 0,
    this.totalSuppliers = 0,
    this.totalRevenue = 0.0,
    this.kpiPeriod = 'month',
    this.kpiCaJour = 0.0,
    this.kpiCaSemaine = 0.0,
    this.kpiCaMois = 0.0,
    this.kpiEncaissable = 0.0,
    this.kpiDepensesJour = 0.0,
    this.kpiDepensesSemaine = 0.0,
    this.kpiDepensesMois = 0.0,
    this.kpiMargeJour = 0.0,
    this.kpiMargeSemaine = 0.0,
    this.kpiMargeBrute = 0.0,
    this.rappels = const [],
    this.validationQueue = const [],
    this.lastInvoices = const [],
    this.stockAlertsCount = 0,
    this.interventionPie = const {},
  });

  PatronDashboardState copyWith({
    bool? isLoading,
    int? pendingClients,
    int? pendingDevis,
    int? pendingBordereaux,
    int? pendingBonCommandes,
    int? pendingFactures,
    int? pendingPaiements,
    int? pendingDepenses,
    int? pendingSalaires,
    int? pendingReporting,
    int? pendingPointages,
    int? pendingInterventions,
    int? pendingTaxes,
    int? pendingRecruitments,
    int? pendingContracts,
    int? pendingLeaves,
    int? pendingSuppliers,
    int? pendingStocks,
    int? pendingRegistrations,
    int? pendingTasks,
    int? validatedClients,
    int? totalEmployees,
    int? totalSuppliers,
    double? totalRevenue,
    String? kpiPeriod,
    double? kpiCaJour,
    double? kpiCaSemaine,
    double? kpiCaMois,
    double? kpiEncaissable,
    double? kpiDepensesJour,
    double? kpiDepensesSemaine,
    double? kpiDepensesMois,
    double? kpiMargeJour,
    double? kpiMargeSemaine,
    double? kpiMargeBrute,
    List<String>? rappels,
    List<PatronValidationItem>? validationQueue,
    List<Map<String, dynamic>>? lastInvoices,
    int? stockAlertsCount,
    Map<String, int>? interventionPie,
  }) {
    return PatronDashboardState(
      isLoading: isLoading ?? this.isLoading,
      pendingClients: pendingClients ?? this.pendingClients,
      pendingDevis: pendingDevis ?? this.pendingDevis,
      pendingBordereaux: pendingBordereaux ?? this.pendingBordereaux,
      pendingBonCommandes: pendingBonCommandes ?? this.pendingBonCommandes,
      pendingFactures: pendingFactures ?? this.pendingFactures,
      pendingPaiements: pendingPaiements ?? this.pendingPaiements,
      pendingDepenses: pendingDepenses ?? this.pendingDepenses,
      pendingSalaires: pendingSalaires ?? this.pendingSalaires,
      pendingReporting: pendingReporting ?? this.pendingReporting,
      pendingPointages: pendingPointages ?? this.pendingPointages,
      pendingInterventions: pendingInterventions ?? this.pendingInterventions,
      pendingTaxes: pendingTaxes ?? this.pendingTaxes,
      pendingRecruitments: pendingRecruitments ?? this.pendingRecruitments,
      pendingContracts: pendingContracts ?? this.pendingContracts,
      pendingLeaves: pendingLeaves ?? this.pendingLeaves,
      pendingSuppliers: pendingSuppliers ?? this.pendingSuppliers,
      pendingStocks: pendingStocks ?? this.pendingStocks,
      pendingRegistrations: pendingRegistrations ?? this.pendingRegistrations,
      pendingTasks: pendingTasks ?? this.pendingTasks,
      validatedClients: validatedClients ?? this.validatedClients,
      totalEmployees: totalEmployees ?? this.totalEmployees,
      totalSuppliers: totalSuppliers ?? this.totalSuppliers,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      kpiPeriod: kpiPeriod ?? this.kpiPeriod,
      kpiCaJour: kpiCaJour ?? this.kpiCaJour,
      kpiCaSemaine: kpiCaSemaine ?? this.kpiCaSemaine,
      kpiCaMois: kpiCaMois ?? this.kpiCaMois,
      kpiEncaissable: kpiEncaissable ?? this.kpiEncaissable,
      kpiDepensesJour: kpiDepensesJour ?? this.kpiDepensesJour,
      kpiDepensesSemaine: kpiDepensesSemaine ?? this.kpiDepensesSemaine,
      kpiDepensesMois: kpiDepensesMois ?? this.kpiDepensesMois,
      kpiMargeJour: kpiMargeJour ?? this.kpiMargeJour,
      kpiMargeSemaine: kpiMargeSemaine ?? this.kpiMargeSemaine,
      kpiMargeBrute: kpiMargeBrute ?? this.kpiMargeBrute,
      rappels: rappels ?? this.rappels,
      validationQueue: validationQueue ?? this.validationQueue,
      lastInvoices: lastInvoices ?? this.lastInvoices,
      stockAlertsCount: stockAlertsCount ?? this.stockAlertsCount,
      interventionPie: interventionPie ?? this.interventionPie,
    );
  }

  int get totalPendingValidations =>
      pendingClients +
      pendingDevis +
      pendingBordereaux +
      pendingBonCommandes +
      pendingFactures +
      pendingPaiements +
      pendingDepenses +
      pendingSalaires +
      pendingReporting +
      pendingPointages +
      pendingInterventions +
      pendingLeaves +
      pendingTasks;

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
          requiredPermission: Permissions.VIEW_DEVIS,
        ),
        StatCard(
          title: "Bordereaux en attente",
          value: pendingBordereaux.toString(),
          icon: Icons.assignment_turned_in,
          color: Colors.orange,
          requiredPermission: Permissions.VIEW_SALES,
        ),
        StatCard(
          title: "Bons de commande en attente",
          value: pendingBonCommandes.toString(),
          icon: Icons.shopping_cart,
          color: Colors.purple,
          requiredPermission: Permissions.VIEW_SALES,
        ),
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
          color: Colors.indigo,
          requiredPermission: Permissions.VIEW_FINANCES,
        ),
        StatCard(
          title: "Salaires en attente",
          value: pendingSalaires.toString(),
          icon: Icons.account_balance_wallet,
          color: Colors.amber,
          requiredPermission: Permissions.MANAGE_EMPLOYEES,
        ),
        StatCard(
          title: "Rapports en attente",
          value: pendingReporting.toString(),
          icon: Icons.analytics,
          color: Colors.cyan,
          requiredPermission: Permissions.VIEW_REPORTS,
        ),
        StatCard(
          title: "Pointages en attente",
          value: pendingPointages.toString(),
          icon: Icons.access_time,
          color: Colors.brown,
          requiredPermission: Permissions.MANAGE_EMPLOYEES,
        ),
        StatCard(
          title: "Interventions en attente",
          value: pendingInterventions.toString(),
          icon: Icons.build,
          color: Colors.deepOrange,
          requiredPermission: Permissions.MANAGE_INTERVENTIONS,
        ),
        StatCard(
          title: "Taxes en attente",
          value: pendingTaxes.toString(),
          icon: Icons.account_balance,
          color: Colors.pink,
          requiredPermission: Permissions.VIEW_FINANCES,
        ),
        StatCard(
          title: "Recrutements en attente",
          value: pendingRecruitments.toString(),
          icon: Icons.person_add,
          color: Colors.lightBlue,
          requiredPermission: Permissions.MANAGE_EMPLOYEES,
        ),
        StatCard(
          title: "Fournisseurs en attente",
          value: pendingSuppliers.toString(),
          icon: Icons.business,
          color: Colors.grey,
          requiredPermission: Permissions.MANAGE_SUPPLIERS,
        ),
        StatCard(
          title: "Stocks en attente",
          value: pendingStocks.toString(),
          icon: Icons.inventory,
          color: Colors.deepPurple,
          requiredPermission: Permissions.MANAGE_STOCKS,
        ),
      ];
}

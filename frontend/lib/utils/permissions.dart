import 'package:easyconnect/utils/roles.dart';

class Permission {
  final String code;
  final String description;
  final List<int> allowedRoles;

  const Permission({
    required this.code,
    required this.description,
    required this.allowedRoles,
  });
}

class Permissions {
  // Permissions générales
  static const VIEW_DASHBOARD = Permission(
    code: 'view_dashboard',
    description: 'Accéder au tableau de bord',
    allowedRoles: [
      Roles.ADMIN,
      Roles.PATRON,
      Roles.COMMERCIAL,
      Roles.COMPTABLE,
      Roles.RH,
      Roles.TECHNICIEN,
    ],
  );

  static const MANAGE_SETTINGS = Permission(
    code: 'manage_settings',
    description: 'Gérer les paramètres système',
    allowedRoles: [Roles.ADMIN],
  );

  // Permissions Clients/Commercial
  static const MANAGE_CLIENTS = Permission(
    code: 'manage_clients',
    description: 'Gérer les clients',
    allowedRoles: [Roles.ADMIN, Roles.COMMERCIAL],
  );
  static const VIEW_CLIENTS = Permission(
    code: 'view_clients',
    description: 'Voir les clients',
    allowedRoles: [
      Roles.ADMIN,
      Roles.COMMERCIAL,
      Roles.COMPTABLE,
      Roles.TECHNICIEN,
    ],
  );
  static const CREATE_CLIENTS = Permission(
    code: 'create_clients',
    description: 'Créer les clients',
    allowedRoles: [Roles.ADMIN, Roles.COMMERCIAL],
  );
  static const UPDATE_CLIENTS = Permission(
    code: 'update_clients',
    description: 'Mettre à jour les clients',
    allowedRoles: [Roles.ADMIN, Roles.COMMERCIAL],
  );
  static const DELETE_CLIENTS = Permission(
    code: 'delete_clients',
    description: 'Supprimer les clients',
    allowedRoles: [Roles.ADMIN, Roles.COMMERCIAL],
  );

  static const VIEW_SALES = Permission(
    code: 'view_sales',
    description: 'Voir les ventes',
    allowedRoles: [
      Roles.ADMIN,
      Roles.COMMERCIAL,
      Roles.PATRON,
      Roles.COMPTABLE,
    ],
  );

  // Permissions Comptabilité
  /*  static const MANAGE_INVOICES = Permission(
    code: 'manage_invoices',
    description: 'Gérer les factures',
    allowedRoles: [Roles.ADMIN, Roles.COMPTABLE],
  ); */

  static const VIEW_FINANCES = Permission(
    code: 'view_finances',
    description: 'Voir les données financières',
    allowedRoles: [Roles.ADMIN, Roles.COMPTABLE, Roles.PATRON],
  );

  static const MANAGE_EXPENSES = Permission(
    code: 'manage_expenses',
    description: 'Gérer les dépenses',
    allowedRoles: [Roles.ADMIN, Roles.COMPTABLE, Roles.PATRON],
  );

  // Permissions RH
  static const MANAGE_EMPLOYEES = Permission(
    code: 'manage_employees',
    description: 'Gérer les employés',
    allowedRoles: [Roles.ADMIN, Roles.COMPTABLE, Roles.RH, Roles.PATRON],
  );

  static const MANAGE_LEAVES = Permission(
    code: 'manage_leaves',
    description: 'Gérer les congés',
    allowedRoles: [Roles.ADMIN, Roles.RH, Roles.PATRON],
  );

  static const VIEW_ATTENDANCE = Permission(
    code: 'view_attendance',
    description: 'Voir les présences',
    allowedRoles: [
      Roles.ADMIN,
      Roles.RH,
      Roles.PATRON,
      Roles.COMPTABLE,
      Roles.COMMERCIAL,
      Roles.TECHNICIEN,
    ],
  );

  static const MANAGE_ATTENDANCE = Permission(
    code: 'Gerer_attendance',
    description: 'Gerer les présences',
    allowedRoles: [
      Roles.ADMIN,
      Roles.RH,
      Roles.PATRON,
      Roles.COMMERCIAL,
      Roles.TECHNICIEN,
    ],
  );

  // Permissions Facturation
  static const MANAGE_INVOICES = Permission(
    code: 'manage_invoices',
    description: 'Gérer les factures',
    allowedRoles: [Roles.ADMIN, Roles.COMPTABLE, Roles.PATRON],
  );

  static const VIEW_INVOICES = Permission(
    code: 'view_invoices',
    description: 'Voir les factures',
    allowedRoles: [
      Roles.ADMIN,
      Roles.COMMERCIAL,
      Roles.COMPTABLE,
      Roles.PATRON,
    ],
  );

  static const APPROVE_INVOICES = Permission(
    code: 'approve_invoices',
    description: 'Approuver les factures',
    allowedRoles: [Roles.ADMIN, Roles.PATRON],
  );

  // Permissions Paiements
  static const MANAGE_PAYMENTS = Permission(
    code: 'manage_payments',
    description: 'Gérer les paiements',
    allowedRoles: [Roles.ADMIN, Roles.COMPTABLE, Roles.PATRON],
  );

  static const VIEW_PAYMENTS = Permission(
    code: 'view_payments',
    description: 'Voir les paiements',
    allowedRoles: [
      Roles.ADMIN,
      Roles.COMMERCIAL,
      Roles.COMPTABLE,
      Roles.PATRON,
    ],
  );

  static const APPROVE_PAYMENTS = Permission(
    code: 'approve_payments',
    description: 'Approuver les paiements',
    allowedRoles: [Roles.ADMIN, Roles.PATRON],
  );

  // Permissions Fournisseurs
  static const MANAGE_SUPPLIERS = Permission(
    code: 'manage_suppliers',
    description: 'Gérer les fournisseurs',
    allowedRoles: [Roles.ADMIN, Roles.COMPTABLE, Roles.PATRON],
  );

  static const VIEW_SUPPLIERS = Permission(
    code: 'view_suppliers',
    description: 'Voir les fournisseurs',
    allowedRoles: [Roles.ADMIN, Roles.COMPTABLE, Roles.PATRON],
  );

  static const APPROVE_SUPPLIERS = Permission(
    code: 'approve_suppliers',
    description: 'Approuver les fournisseurs',
    allowedRoles: [Roles.ADMIN, Roles.PATRON],
  );

  // Permissions Impôts et Taxes
  static const MANAGE_TAXES = Permission(
    code: 'manage_taxes',
    description: 'Gérer les impôts et taxes',
    allowedRoles: [Roles.ADMIN, Roles.COMPTABLE, Roles.PATRON],
  );

  static const VIEW_TAXES = Permission(
    code: 'view_taxes',
    description: 'Voir les impôts et taxes',
    allowedRoles: [Roles.ADMIN, Roles.COMPTABLE, Roles.PATRON],
  );

  static const PAY_TAXES = Permission(
    code: 'pay_taxes',
    description: 'Marquer les impôts comme payés',
    allowedRoles: [Roles.ADMIN, Roles.COMPTABLE],
  );

  // Permissions Salaires
  static const MANAGE_SALARIES = Permission(
    code: 'manage_salaries',
    description: 'Gérer les salaires',
    allowedRoles: [Roles.ADMIN, Roles.COMPTABLE, Roles.PATRON],
  );

  static const VIEW_SALARIES = Permission(
    code: 'view_salaries',
    description: 'Voir les salaires',
    allowedRoles: [Roles.ADMIN, Roles.COMPTABLE, Roles.PATRON],
  );

  static const APPROVE_SALARIES = Permission(
    code: 'approve_salaries',
    description: 'Approuver les salaires',
    allowedRoles: [Roles.ADMIN, Roles.PATRON],
  );

  // Permissions Interventions
  static const MANAGE_INTERVENTIONS = Permission(
    code: 'manage_interventions',
    description: 'Gérer les interventions',
    allowedRoles: [Roles.ADMIN, Roles.TECHNICIEN, Roles.PATRON],
  );

  static const VIEW_INTERVENTIONS = Permission(
    code: 'view_interventions',
    description: 'Voir les interventions',
    allowedRoles: [
      Roles.ADMIN,
      Roles.COMMERCIAL,
      Roles.TECHNICIEN,
      Roles.PATRON,
    ],
  );

  static const APPROVE_INTERVENTIONS = Permission(
    code: 'approve_interventions',
    description: 'Approuver les interventions',
    allowedRoles: [Roles.ADMIN, Roles.PATRON],
  );

  // Permissions Équipements
  static const MANAGE_EQUIPMENTS = Permission(
    code: 'manage_equipments',
    description: 'Gérer les équipements',
    allowedRoles: [Roles.ADMIN, Roles.TECHNICIEN, Roles.PATRON],
  );

  static const VIEW_EQUIPMENTS = Permission(
    code: 'view_equipments',
    description: 'Voir les équipements',
    allowedRoles: [Roles.ADMIN, Roles.TECHNICIEN, Roles.PATRON],
  );

  // Permissions Stock
  static const MANAGE_STOCKS = Permission(
    code: 'manage_stocks',
    description: 'Gérer le stock',
    allowedRoles: [Roles.ADMIN, Roles.COMPTABLE, Roles.PATRON],
  );

  static const VIEW_STOCKS = Permission(
    code: 'view_stocks',
    description: 'Voir le stock',
    allowedRoles: [Roles.ADMIN, Roles.COMPTABLE, Roles.PATRON],
  );

  static const MANAGE_STOCK_MOVEMENTS = Permission(
    code: 'manage_stock_movements',
    description: 'Gérer les mouvements de stock',
    allowedRoles: [Roles.ADMIN, Roles.COMPTABLE],
  );

  static const VIEW_EMPLOYEES = Permission(
    code: 'view_employees',
    description: 'Voir les employés',
    allowedRoles: [Roles.ADMIN, Roles.COMPTABLE, Roles.RH, Roles.PATRON],
  );

  static const APPROVE_EMPLOYEES = Permission(
    code: 'approve_employees',
    description: 'Approuver les employés',
    allowedRoles: [Roles.ADMIN, Roles.PATRON, Roles.RH],
  );

  static const VIEW_LEAVES = Permission(
    code: 'view_leaves',
    description: 'Voir les congés',
    allowedRoles: [Roles.ADMIN, Roles.RH, Roles.PATRON],
  );

  static const APPROVE_LEAVES = Permission(
    code: 'approve_leaves',
    description: 'Approuver les congés',
    allowedRoles: [Roles.ADMIN, Roles.PATRON, Roles.RH],
  );

  static const REQUEST_LEAVES = Permission(
    code: 'request_leaves',
    description: 'Demander des congés',
    allowedRoles: [
      Roles.ADMIN,
      Roles.RH,
      Roles.COMMERCIAL,
      Roles.COMPTABLE,
      Roles.TECHNICIEN,
    ],
  );

  static const MANAGE_RECRUITMENT = Permission(
    code: 'manage_recruitment',
    description: 'Gérer le recrutement',
    allowedRoles: [Roles.ADMIN, Roles.RH],
  );

  static const VIEW_RECRUITMENT = Permission(
    code: 'view_recruitment',
    description: 'Voir les recrutements',
    allowedRoles: [Roles.ADMIN, Roles.RH, Roles.PATRON],
  );

  static const APPROVE_RECRUITMENT = Permission(
    code: 'approve_recruitment',
    description: 'Approuver les recrutements',
    allowedRoles: [Roles.ADMIN, Roles.PATRON],
  );

  static const PUBLISH_RECRUITMENT = Permission(
    code: 'publish_recruitment',
    description: 'Publier les recrutements',
    allowedRoles: [Roles.ADMIN, Roles.RH],
  );

  // Permissions Contrats
  static const MANAGE_CONTRACTS = Permission(
    code: 'manage_contracts',
    description: 'Gérer les contrats',
    allowedRoles: [Roles.ADMIN, Roles.RH],
  );

  static const VIEW_CONTRACTS = Permission(
    code: 'view_contracts',
    description: 'Voir les contrats',
    allowedRoles: [Roles.ADMIN, Roles.RH, Roles.PATRON],
  );

  static const APPROVE_CONTRACTS = Permission(
    code: 'approve_contracts',
    description: 'Approuver les contrats',
    allowedRoles: [Roles.ADMIN, Roles.PATRON],
  );

  static const SUBMIT_CONTRACTS = Permission(
    code: 'submit_contracts',
    description: 'Soumettre les contrats',
    allowedRoles: [Roles.ADMIN, Roles.RH],
  );

  // Permissions Technicien
  static const MANAGE_TICKETS = Permission(
    code: 'manage_tickets',
    description: 'Gérer les tickets',
    allowedRoles: [Roles.ADMIN, Roles.TECHNICIEN],
  );

  static const MANAGE_EQUIPMENT = Permission(
    code: 'manage_equipment',
    description: 'Gérer le matériel',
    allowedRoles: [Roles.ADMIN, Roles.TECHNICIEN],
  );

  // Permissions Patron
  static const APPROVE_DECISIONS = Permission(
    code: 'approve_decisions',
    description: 'Approuver les décisions importantes',
    allowedRoles: [Roles.ADMIN, Roles.PATRON],
  );

  static const VIEW_ANALYTICS = Permission(
    code: 'view_analytics',
    description: 'Voir les analyses globales',
    allowedRoles: [Roles.ADMIN, Roles.PATRON],
  );
  static const VIEW_DEVIS = Permission(
    code: 'view_devis',
    description: 'Voir les devis',
    allowedRoles: [Roles.ADMIN, Roles.COMMERCIAL, Roles.PATRON],
  );
  static const CREATE_DEVIS = Permission(
    code: 'create_devis',
    description: 'Créer les devis',
    allowedRoles: [Roles.ADMIN, Roles.COMMERCIAL],
  );
  static const UPDATE_DEVIS = Permission(
    code: 'update_devis',
    description: 'Mettre à jour les devis',
    allowedRoles: [Roles.ADMIN, Roles.COMMERCIAL],
  );
  static const DELETE_DEVIS = Permission(
    code: 'delete_devis',
    description: 'Supprimer les devis',
    allowedRoles: [Roles.ADMIN, Roles.COMMERCIAL],
  );
  static const MANAGE_DEVIS = Permission(
    code: 'manage_devis',
    description: 'Gérer le devis',
    allowedRoles: [Roles.ADMIN, Roles.COMMERCIAL, Roles.PATRON],
  );
  static const MANAGE_BORDEREAUX = Permission(
    code: 'manage_bordereaux',
    description: 'Gérer les bordereaux',
    allowedRoles: [Roles.ADMIN, Roles.COMMERCIAL, Roles.PATRON],
  );
  static const VIEW_BORDEREAUX = Permission(
    code: 'view_bordereaux',
    description: 'Voir les bordereaux',
    allowedRoles: [Roles.ADMIN, Roles.COMMERCIAL, Roles.PATRON],
  );
  static const APPROVE_BORDEREAUX = Permission(
    code: 'approve_bordereaux',
    description: 'Approuver les bordereaux',
    allowedRoles: [Roles.ADMIN, Roles.COMMERCIAL, Roles.PATRON],
  );

  static const MANAGE_BON_COMMANDES = Permission(
    code: 'manage_bon_commandes',
    description: 'Gérer les bons de commande',
    allowedRoles: [Roles.ADMIN, Roles.COMMERCIAL, Roles.PATRON],
  );
  static const VIEW_BON_COMMANDES = Permission(
    code: 'view_bon_commandes',
    description: 'Voir les bons de commande',
    allowedRoles: [Roles.ADMIN, Roles.COMMERCIAL, Roles.PATRON],
  );
  static const APPROVE_BON_COMMANDES = Permission(
    code: 'approve_bon_commandes',
    description: 'Approuver les bons de commande',
    allowedRoles: [Roles.ADMIN, Roles.COMMERCIAL, Roles.PATRON],
  );
  static const VIEW_STATS = Permission(
    code: 'view_stats',
    description: 'Voir les statistiques',
    allowedRoles: [Roles.ADMIN, Roles.COMMERCIAL],
  );

  // Permissions Reporting
  static const VIEW_REPORTS = Permission(
    code: 'view_reports',
    description: 'Voir les rapports',
    allowedRoles: [
      Roles.ADMIN,
      Roles.PATRON,
      Roles.COMMERCIAL,
      Roles.COMPTABLE,
      Roles.RH,
      Roles.TECHNICIEN,
    ],
  );
  // Chat et Communication
  static const USE_CHAT = Permission(
    code: 'use_chat',
    description: 'Utiliser le chat interne',
    allowedRoles: [
      Roles.ADMIN,
      Roles.PATRON,
      Roles.COMMERCIAL,
      Roles.COMPTABLE,
      Roles.RH,
      Roles.TECHNICIEN,
    ],
  );

  // Méthodes utilitaires
  static List<Permission> getAllPermissions() {
    return [
      VIEW_DASHBOARD,
      MANAGE_SETTINGS,
      MANAGE_CLIENTS,
      VIEW_CLIENTS,
      CREATE_CLIENTS,
      UPDATE_CLIENTS,
      DELETE_CLIENTS,
      MANAGE_DEVIS,
      MANAGE_BORDEREAUX,
      MANAGE_BON_COMMANDES,
      VIEW_SALES,
      MANAGE_INVOICES,
      VIEW_FINANCES,
      MANAGE_EXPENSES,
      MANAGE_EMPLOYEES,
      MANAGE_LEAVES,
      MANAGE_ATTENDANCE,
      VIEW_ATTENDANCE,
      MANAGE_INVOICES,
      VIEW_INVOICES,
      APPROVE_INVOICES,
      MANAGE_PAYMENTS,
      VIEW_PAYMENTS,
      APPROVE_PAYMENTS,
      MANAGE_SUPPLIERS,
      VIEW_SUPPLIERS,
      APPROVE_SUPPLIERS,
      MANAGE_TAXES,
      VIEW_TAXES,
      PAY_TAXES,
      MANAGE_RECRUITMENT,
      MANAGE_CONTRACTS,
      VIEW_CONTRACTS,
      APPROVE_CONTRACTS,
      SUBMIT_CONTRACTS,
      MANAGE_TICKETS,
      MANAGE_EQUIPMENT,
      APPROVE_DECISIONS,
      VIEW_ANALYTICS,
      VIEW_REPORTS,
      USE_CHAT,
    ];
  }

  static List<Permission> getPermissionsForRole(int role) {
    return getAllPermissions()
        .where((permission) => permission.allowedRoles.contains(role))
        .toList();
  }

  static bool hasPermission(int? role, Permission permission) {
    if (role == null) return false;
    return permission.allowedRoles.contains(role);
  }

  static bool hasAnyPermission(int? role, List<Permission> permissions) {
    if (role == null) return false;
    return permissions.any(
      (permission) => permission.allowedRoles.contains(role),
    );
  }

  static bool hasAllPermissions(int? role, List<Permission> permissions) {
    if (role == null) return false;
    return permissions.every(
      (permission) => permission.allowedRoles.contains(role),
    );
  }
}

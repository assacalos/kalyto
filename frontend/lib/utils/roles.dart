class Roles {
  static const int ADMIN = 1;
  static const int COMMERCIAL = 2;
  static const int COMPTABLE = 3;
  static const int RH = 4;
  static const int TECHNICIEN = 5;
  static const int PATRON = 6;

  static String getRoleName(int? role) {
    switch (role) {
      case ADMIN:
        return 'Administrateur';
      case COMMERCIAL:
        return 'Commercial';
      case COMPTABLE:
        return 'Comptable';
      case RH:
        return 'Ressources Humaines';
      case TECHNICIEN:
        return 'Technicien';
      case PATRON:
        return 'Patron';
      default:
        return 'Utilisateur';
    }
  }

  static List<Map<String, dynamic>> getRolesList() {
    return [
      {'id': ADMIN, 'name': 'Administrateur'},
      {'id': COMMERCIAL, 'name': 'Commercial'},
      {'id': COMPTABLE, 'name': 'Comptable'},
      {'id': RH, 'name': 'Ressources Humaines'},
      {'id': TECHNICIEN, 'name': 'Technicien'},
      {'id': PATRON, 'name': 'Patron'},
    ];
  }

  static Map<int, List<String>> getRolePermissions() {
    return {
      ADMIN: [
        'manage_users',
        'manage_roles',
        'view_all_data',
        'manage_settings',
      ],
      COMMERCIAL: [
        'manage_clients',
        'view_sales',
        'create_quotes',
        'manage_opportunities',
      ],
      COMPTABLE: [
        'manage_invoices',
        'view_finances',
        'manage_expenses',
        'generate_reports',
      ],

      RH: [
        'manage_employees',
        'manage_leaves',
        'manage_recruitment',
        'view_employee_data',
      ],
      TECHNICIEN: [
        'manage_tickets',
        'view_technical_data',
        'manage_maintenance',
        'update_status',
      ],
      PATRON: [
        'view_all_data',
        'manage_settings',
        'view_analytics',
        'approve_major_decisions',
      ],
    };
  }
}

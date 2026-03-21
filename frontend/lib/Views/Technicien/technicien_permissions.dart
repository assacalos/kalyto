import 'package:easyconnect/utils/roles.dart';

class TechnicianPermissions {
  static const String VIEW_DASHBOARD = 'view_technical_data';
  static const String MANAGE_TICKETS = 'manage_tickets';
  static const String MANAGE_INTERVENTIONS = 'manage_maintenance';
  static const String MANAGE_EQUIPMENT = 'manage_equipment';
  static const String VIEW_REPORTS = 'view_technical_reports';
  static const String USE_CHAT = 'use_tech_chat';
  static const String MANAGE_SETTINGS = 'manage_settings';
  static const String UPDATE_STATUS = 'update_status';

  static List<int> getAllowedRoles(String permission) {
    switch (permission) {
      case MANAGE_TICKETS:
      case MANAGE_INTERVENTIONS:
      case UPDATE_STATUS:
        return [Roles.ADMIN, Roles.TECHNICIEN];
      case MANAGE_EQUIPMENT:
        return [Roles.ADMIN, Roles.TECHNICIEN, Roles.PATRON];
      case VIEW_REPORTS:
        return [Roles.ADMIN, Roles.TECHNICIEN, Roles.PATRON];
      case USE_CHAT:
        return [
          Roles.ADMIN,
          Roles.TECHNICIEN,
          Roles.PATRON,
          Roles.COMMERCIAL,
          Roles.COMPTABLE,
          Roles.RH,
        ];
      case MANAGE_SETTINGS:
        return [Roles.ADMIN];
      default:
        return [Roles.ADMIN, Roles.TECHNICIEN];
    }
  }

  static List<String> getRequiredPermissions(TechnicianSection section) {
    switch (section) {
      case TechnicianSection.dashboard:
        return [VIEW_DASHBOARD];
      case TechnicianSection.tickets:
        return [MANAGE_TICKETS];
      case TechnicianSection.interventions:
        return [MANAGE_INTERVENTIONS];
      case TechnicianSection.equipment:
        return [MANAGE_EQUIPMENT];
      case TechnicianSection.reporting:
        return [VIEW_REPORTS];
      case TechnicianSection.chat:
        return [USE_CHAT];
      case TechnicianSection.profile:
        return [MANAGE_SETTINGS];
      default:
        return [VIEW_DASHBOARD];
    }
  }
}

enum TechnicianSection {
  dashboard,
  tickets,
  interventions,
  equipment,
  reporting,
  chat,
  profile,
}

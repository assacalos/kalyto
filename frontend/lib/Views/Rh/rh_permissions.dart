import 'package:easyconnect/utils/roles.dart';

class RhPermissions {
  static const String VIEW_DASHBOARD = 'view_employee_data';
  static const String MANAGE_STAFF = 'manage_employees';
  static const String MANAGE_ATTENDANCE = 'manage_attendance';
  static const String MANAGE_LEAVES = 'manage_leaves';
  static const String MANAGE_RECRUITMENT = 'manage_recruitment';
  static const String VIEW_REPORTS = 'view_hr_reports';
  static const String USE_CHAT = 'use_hr_chat';
  static const String MANAGE_SETTINGS = 'manage_settings';

  static List<int> getAllowedRoles(String permission) {
    switch (permission) {
      case MANAGE_STAFF:
      case MANAGE_RECRUITMENT:
        return [Roles.ADMIN, Roles.RH];
      case MANAGE_ATTENDANCE:
      case MANAGE_LEAVES:
        return [Roles.ADMIN, Roles.RH, Roles.PATRON];
      case VIEW_REPORTS:
        return [Roles.ADMIN, Roles.RH, Roles.PATRON];
      case USE_CHAT:
        return [
          Roles.ADMIN,
          Roles.RH,
          Roles.PATRON,
          Roles.COMMERCIAL,
          Roles.COMPTABLE,
          Roles.TECHNICIEN,
        ];
      case MANAGE_SETTINGS:
        return [Roles.ADMIN];
      default:
        return [Roles.ADMIN, Roles.RH];
    }
  }

  static List<String> getRequiredPermissions(RhSection section) {
    switch (section) {
      case RhSection.dashboard:
        return [VIEW_DASHBOARD];
      case RhSection.staff:
        return [MANAGE_STAFF];
      case RhSection.attendance:
        return [MANAGE_ATTENDANCE];
      case RhSection.leaves:
        return [MANAGE_LEAVES];
      case RhSection.recruitment:
        return [MANAGE_RECRUITMENT];
      case RhSection.reporting:
        return [VIEW_REPORTS];
      case RhSection.chat:
        return [USE_CHAT];
      case RhSection.profile:
        return [MANAGE_SETTINGS];
      default:
        return [VIEW_DASHBOARD];
    }
  }
}

enum RhSection {
  dashboard,
  staff,
  attendance,
  leaves,
  recruitment,
  reporting,
  chat,
  profile,
}

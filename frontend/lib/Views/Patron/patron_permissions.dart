import 'package:easyconnect/utils/roles.dart';

class PatronPermissions {
  static const String VIEW_DASHBOARD = 'view_all_data';
  static const String MANAGE_EMPLOYEES = 'manage_employees';
  static const String MANAGE_LEAVES = 'manage_leaves';
  static const String VIEW_ATTENDANCE = 'view_attendance';
  static const String MANAGE_PAYROLL = 'manage_payroll';
  static const String MANAGE_TRAINING = 'manage_training';
  static const String VIEW_REPORTS = 'view_analytics';
  static const String USE_CHAT = 'use_patron_chat';
  static const String APPROVE_DECISIONS = 'approve_major_decisions';

  static List<int> getAllowedRoles(String permission) {
    switch (permission) {
      case MANAGE_EMPLOYEES:
      case MANAGE_LEAVES:
        return [Roles.ADMIN, Roles.PATRON, Roles.RH];
      case VIEW_ATTENDANCE:
      case VIEW_REPORTS:
        return [Roles.ADMIN, Roles.PATRON, Roles.RH, Roles.COMPTABLE];
      case MANAGE_PAYROLL:
        return [Roles.ADMIN, Roles.PATRON, Roles.COMPTABLE];
      case MANAGE_TRAINING:
        return [Roles.ADMIN, Roles.PATRON, Roles.RH];
      case USE_CHAT:
        return [
          Roles.ADMIN,
          Roles.PATRON,
          Roles.RH,
          Roles.COMMERCIAL,
          Roles.COMPTABLE,
          Roles.TECHNICIEN,
        ];
      case APPROVE_DECISIONS:
        return [Roles.ADMIN, Roles.PATRON];
      default:
        return [Roles.ADMIN, Roles.PATRON];
    }
  }

  static List<String> getRequiredPermissions(PatronSection section) {
    switch (section) {
      case PatronSection.dashboard:
        return [VIEW_DASHBOARD];
      case PatronSection.employees:
        return [MANAGE_EMPLOYEES];
      case PatronSection.leaves:
        return [MANAGE_LEAVES];
      case PatronSection.attendance:
        return [VIEW_ATTENDANCE];
      case PatronSection.payroll:
        return [MANAGE_PAYROLL];
      case PatronSection.training:
        return [MANAGE_TRAINING];
      case PatronSection.reports:
        return [VIEW_REPORTS];
      case PatronSection.approvals:
        return [APPROVE_DECISIONS];
      case PatronSection.chat:
        return [USE_CHAT];
      default:
        return [VIEW_DASHBOARD];
    }
  }
}

enum PatronSection {
  dashboard,
  employees,
  leaves,
  attendance,
  payroll,
  training,
  reports,
  approvals,
  chat,
}

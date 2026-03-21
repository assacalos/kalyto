import 'package:easyconnect/utils/roles.dart';

class AccountantPermissions {
  static const String VIEW_DASHBOARD = 'view_finances';
  static const String MANAGE_INVOICES = 'manage_invoices';
  static const String MANAGE_PAYMENTS = 'manage_payments';
  static const String MANAGE_EXPENSES = 'manage_expenses';
  static const String VIEW_REPORTS = 'view_finances';
  static const String USE_CHAT = 'use_accountant_chat';
  static const String MANAGE_SETTINGS = 'manage_settings';
  static const String MANAGE_SUPPLIERS = 'manage_suppliers';
  static const String MANAGE_TAXES = 'manage_taxes';
  static const String VIEW_TAXES = 'view_taxes';
  static const String PAY_TAXES = 'pay_taxes';
  static const String MANAGE_SALARIES = 'manage_salaries';

  static List<int> getAllowedRoles(String permission) {
    switch (permission) {
      case MANAGE_INVOICES:
      case MANAGE_SUPPLIERS:
      case MANAGE_TAXES:
      case VIEW_TAXES:
      case PAY_TAXES:
      case MANAGE_SALARIES:
      case MANAGE_PAYMENTS:
      case MANAGE_EXPENSES:
        return [Roles.ADMIN, Roles.COMPTABLE];
      case VIEW_REPORTS:
        return [Roles.ADMIN, Roles.COMPTABLE, Roles.PATRON];
      case USE_CHAT:
        return [
          Roles.ADMIN,
          Roles.COMPTABLE,
          Roles.PATRON,
          Roles.COMMERCIAL,
          Roles.RH,
        ];
      case MANAGE_SETTINGS:
        return [Roles.ADMIN];
      default:
        return [Roles.ADMIN, Roles.COMPTABLE];
    }
  }

  static List<String> getRequiredPermissions(AccountantSection section) {
    switch (section) {
      case AccountantSection.dashboard:
        return [VIEW_DASHBOARD];
      case AccountantSection.invoices:
        return [MANAGE_INVOICES];
      case AccountantSection.payments:
        return [MANAGE_PAYMENTS];
      case AccountantSection.expenses:
        return [MANAGE_EXPENSES];
      case AccountantSection.suppliers:
        return [MANAGE_SUPPLIERS];
      case AccountantSection.taxes:
        return [MANAGE_TAXES];
      case AccountantSection.salaries:
        return [MANAGE_SALARIES];

      case AccountantSection.reporting:
        return [VIEW_REPORTS];
      case AccountantSection.chat:
        return [USE_CHAT];
      case AccountantSection.profile:
        return [MANAGE_SETTINGS];
      default:
        return [VIEW_DASHBOARD];
    }
  }
}

enum AccountantSection {
  dashboard,
  invoices,
  payments,
  expenses,
  reporting,
  suppliers,
  taxes,
  salaries,
  chat,
  profile,
}

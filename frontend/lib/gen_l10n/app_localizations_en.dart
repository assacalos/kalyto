// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Kalyto';

  @override
  String get appTagline => 'Your integrated ERP solution';

  @override
  String get login => 'Log in';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'Enter your email';

  @override
  String get emailRequired => 'Please enter your email';

  @override
  String get emailInvalid => 'Please enter a valid email';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get passwordRequired => 'Please enter your password';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String welcomeUser(String name) {
    return 'Welcome $name!';
  }

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get refresh => 'Refresh';

  @override
  String get export => 'Export';

  @override
  String get search => 'Search';

  @override
  String get close => 'Close';

  @override
  String get confirm => 'Confirm';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get submit => 'Submit';

  @override
  String get validate => 'Validate';

  @override
  String get reject => 'Reject';

  @override
  String get settings => 'Settings';

  @override
  String get settingsTitle => 'Application settings';

  @override
  String get currentCompany => 'Current company';

  @override
  String get currentCompanyHint => 'Choose the company for displayed data (clients, invoices, journal, etc.)';

  @override
  String get noCompanySelected => 'No company selected';

  @override
  String get allCompaniesMono => 'All (single company mode)';

  @override
  String get companyUpdated => 'Company updated';

  @override
  String get companyAll => 'Company: all';

  @override
  String get companyDataSection => 'Company data';

  @override
  String get nineaLabel => 'NINEA (Ivorian company identification number)';

  @override
  String get nineaField => 'Company NINEA';

  @override
  String get nineaHint => '9 digits';

  @override
  String get nineaHelp => 'Exactly 9 digits. Stored locally until linked with the API.';

  @override
  String get apiConfigSection => 'API configuration';

  @override
  String get apiUrl => 'API URL';

  @override
  String get resetApiUrl => 'Reset URL';

  @override
  String get resetApiUrlSubtitle => 'Restore default URL';

  @override
  String get generalSection => 'General';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsSubtitle => 'Receive push notifications';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select language';

  @override
  String get languageFrench => 'French';

  @override
  String get languageEnglish => 'English';

  @override
  String get theme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get selectTheme => 'Select theme';

  @override
  String get testsSection => 'Tests and development';

  @override
  String get testPushNotifications => 'Test Push Notifications';

  @override
  String get testPushSubtitle => 'Test Firebase and FCM configuration';

  @override
  String get securitySection => 'Security';

  @override
  String get changePassword => 'Change password';

  @override
  String get changePasswordSubtitle => 'Update your password';

  @override
  String get activeSessions => 'Active sessions';

  @override
  String get activeSessionsSubtitle => 'Manage open sessions';

  @override
  String get menuInvoices => 'Invoices';

  @override
  String get menuPayments => 'Payments';

  @override
  String get menuExpenses => 'Expenses';

  @override
  String get menuSalaries => 'Salaries';

  @override
  String get menuJournal => 'Journal';

  @override
  String get menuGrandLivre => 'General ledger';

  @override
  String get menuBalance => 'Balance';

  @override
  String get menuTaxes => 'Taxes';

  @override
  String get menuStock => 'Stock';

  @override
  String get menuInventory => 'Physical inventory';

  @override
  String get menuSuppliers => 'Suppliers';

  @override
  String get menuAttendance => 'Attendance';

  @override
  String get menuMyTasks => 'My tasks';

  @override
  String roleLabel(String role) {
    return 'Role: $role';
  }

  @override
  String get dashboardComptable => 'Accounting';

  @override
  String get home => 'Home';

  @override
  String get profile => 'Profile';

  @override
  String get saveSettings => 'Save settings';

  @override
  String get allCompaniesMonoShort => 'All (single company)';

  @override
  String get dashboardLoadError => 'Unable to load dashboard.';

  @override
  String get retry => 'Retry';
}

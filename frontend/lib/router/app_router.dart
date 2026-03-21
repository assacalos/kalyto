import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/Views/Auth/login_page.dart';
import 'package:easyconnect/Views/Auth/welcome_page.dart';
import 'package:easyconnect/Views/Auth/register_page.dart';
import 'package:easyconnect/Views/Auth/unauthorized_page.dart';
import 'package:easyconnect/Views/Components/splash_screen.dart';
import 'package:easyconnect/Views/Commercial/commercial_dashboard_enhanced.dart';
import 'package:easyconnect/Views/Comptable/comptable_dashboard_enhanced.dart';
import 'package:easyconnect/Views/Patron/patron_dashboard_enhanced.dart';
import 'package:easyconnect/Views/Rh/rh_dashboard_enhanced.dart';
import 'package:easyconnect/Views/Technicien/technicien_dashboard_enhanced.dart';
import 'package:easyconnect/Views/Admin/admin_dashboard.dart';
import 'package:easyconnect/Views/Patron/finances_page.dart';
import 'package:easyconnect/Views/Patron/patron_reports_page.dart';
import 'package:easyconnect/Views/Commercial/client_list_page.dart';
import 'package:easyconnect/Views/Commercial/client_form_page.dart';
import 'package:easyconnect/Views/Commercial/client_details_page.dart';
import 'package:easyconnect/Views/Patron/client_validation_page.dart';
import 'package:easyconnect/Views/Commercial/devis_list_page.dart';
import 'package:easyconnect/Views/Commercial/devis_form_page.dart';
import 'package:easyconnect/Views/Commercial/devis_detail_page.dart';
import 'package:easyconnect/Views/Patron/devis_validation_page.dart';
import 'package:easyconnect/Views/Commercial/bordereau_list_page.dart';
import 'package:easyconnect/Views/Commercial/bordereau_form_page.dart';
import 'package:easyconnect/Views/Commercial/bordereau_detail_page.dart';
import 'package:easyconnect/Views/Patron/bordereau_validation_page.dart';
import 'package:easyconnect/Views/Commercial/bon_commande_list_page.dart';
import 'package:easyconnect/Views/Commercial/bon_commande_form_page.dart';
import 'package:easyconnect/Views/Commercial/bon_commande_detail_page.dart';
import 'package:easyconnect/Views/Patron/bon_commande_validation_page.dart';
import 'package:easyconnect/Views/Commercial/bon_de_commande_fournisseur_list_page.dart';
import 'package:easyconnect/Views/Commercial/bon_de_commande_fournisseur_form_page.dart';
import 'package:easyconnect/Views/Commercial/bon_de_commande_fournisseur_detail_page.dart';
import 'package:easyconnect/Views/Patron/bon_de_commande_fournisseur_validation_page.dart';
import 'package:easyconnect/Views/Components/task_list_page.dart';
import 'package:easyconnect/Views/Components/task_form_page.dart';
import 'package:easyconnect/Views/Components/task_detail_page.dart';
import 'package:easyconnect/Views/Admin/user_management_page.dart';
import 'package:easyconnect/Views/Admin/user_form_page.dart';
import 'package:easyconnect/Views/Admin/app_settings_page.dart';
import 'package:easyconnect/Views/Admin/push_notification_test_page.dart';
import 'package:easyconnect/Views/Admin/roles_management_page.dart';
import 'package:easyconnect/Views/Patron/facture_validation_page.dart';
import 'package:easyconnect/Views/Patron/paiement_validation_page.dart';
import 'package:easyconnect/Views/Patron/depense_validation_page.dart';
import 'package:easyconnect/Views/Patron/salaire_validation_page.dart';
import 'package:easyconnect/Views/Patron/pointage_validation_page.dart';
import 'package:easyconnect/Views/Patron/presence_summary_page.dart';
import 'package:easyconnect/Views/Rh/pointage_detail.dart';
import 'package:easyconnect/Models/attendance_punch_model.dart';
import 'package:easyconnect/Views/Patron/stock_validation_page.dart';
import 'package:easyconnect/Views/Patron/intervention_validation_page.dart';
import 'package:easyconnect/Views/Patron/recruitment_validation_page.dart';
import 'package:easyconnect/Views/Patron/contract_validation_page.dart';
import 'package:easyconnect/Views/Patron/leave_validation_page.dart';
import 'package:easyconnect/Views/Patron/taxe_validation_page.dart';
import 'package:easyconnect/Views/Patron/reporting_validation_page.dart';
import 'package:easyconnect/Views/Patron/supplier_validation_page.dart';
import 'package:easyconnect/Views/Patron/employee_validation_page.dart';
import 'package:easyconnect/Views/Patron/registration_validation_page.dart';
import 'package:easyconnect/Views/Components/reporting_list.dart';
import 'package:easyconnect/Views/Components/reporting_form.dart';
import 'package:easyconnect/Views/Components/reporting_detail.dart';
import 'package:easyconnect/Models/reporting_model.dart';
import 'package:easyconnect/Models/supplier_model.dart';
import 'package:easyconnect/Models/tax_model.dart';
import 'package:easyconnect/Models/expense_model.dart';
import 'package:easyconnect/Models/salary_model.dart';
import 'package:easyconnect/Models/intervention_model.dart';
import 'package:easyconnect/Models/equipment_model.dart';
import 'package:easyconnect/Models/stock_model.dart';
import 'package:easyconnect/Models/employee_model.dart';
import 'package:easyconnect/Models/leave_model.dart';
import 'package:easyconnect/Models/recruitment_model.dart';
import 'package:easyconnect/Models/contract_model.dart';
import 'package:easyconnect/Views/Components/attendance_punch_page.dart';
import 'package:easyconnect/Views/Components/attendance_validation_page.dart';
import 'package:easyconnect/Views/Comptable/invoice_list_page.dart';
import 'package:easyconnect/Views/Comptable/invoice_form.dart';
import 'package:easyconnect/Views/Comptable/payment_list.dart';
import 'package:easyconnect/Views/Comptable/payment_form.dart';
import 'package:easyconnect/Views/Comptable/payment_detail.dart';
import 'package:easyconnect/Views/Comptable/supplier_list.dart';
import 'package:easyconnect/Views/Comptable/supplier_form.dart';
import 'package:easyconnect/Views/Comptable/supplier_detail.dart';
import 'package:easyconnect/Views/Comptable/tax_list.dart';
import 'package:easyconnect/Views/Comptable/tax_form.dart';
import 'package:easyconnect/Views/Comptable/tax_detail.dart';
import 'package:easyconnect/Views/Comptable/expense_list.dart';
import 'package:easyconnect/Views/Comptable/expense_form.dart';
import 'package:easyconnect/Views/Comptable/expense_detail.dart';
import 'package:easyconnect/Views/Comptable/salary_list.dart';
import 'package:easyconnect/Views/Comptable/salary_form.dart';
import 'package:easyconnect/Views/Comptable/salary_detail.dart';
import 'package:easyconnect/Views/Technicien/intervention_list.dart';
import 'package:easyconnect/Views/Technicien/intervention_form.dart';
import 'package:easyconnect/Views/Technicien/intervention_detail.dart';
import 'package:easyconnect/Views/Technicien/besoin_list_page.dart';
import 'package:easyconnect/Views/Technicien/besoin_form_page.dart';
import 'package:easyconnect/Views/Technicien/equipment_list.dart';
import 'package:easyconnect/Views/Technicien/equipment_form.dart';
import 'package:easyconnect/Views/Technicien/equipment_detail.dart';
import 'package:easyconnect/Views/Comptable/stock_list.dart';
import 'package:easyconnect/Views/Comptable/stock_form.dart';
import 'package:easyconnect/Views/Comptable/stock_detail.dart';
import 'package:easyconnect/Views/Comptable/inventory_session_list_page.dart';
import 'package:easyconnect/Views/Comptable/inventory_session_detail_page.dart';
import 'package:easyconnect/Models/inventory_session_model.dart';
import 'package:easyconnect/Views/Rh/employee_list.dart';
import 'package:easyconnect/Views/Rh/employee_form.dart';
import 'package:easyconnect/Views/Rh/employee_detail.dart';
import 'package:easyconnect/Views/Rh/leave_list.dart';
import 'package:easyconnect/Views/Rh/leave_form.dart';
import 'package:easyconnect/Views/Rh/leave_detail.dart';
import 'package:easyconnect/Views/Rh/recruitment_list.dart';
import 'package:easyconnect/Views/Rh/recruitment_form.dart';
import 'package:easyconnect/Views/Rh/recruitment_detail.dart';
import 'package:easyconnect/Views/Rh/contract_list.dart';
import 'package:easyconnect/Views/Rh/contract_form.dart';
import 'package:easyconnect/Views/Rh/contract_detail.dart';
import 'package:easyconnect/Views/Components/journal_list_page.dart';
import 'package:easyconnect/Views/Components/journal_detail_page.dart';
import 'package:easyconnect/Views/Components/journal_form_page.dart';
import 'package:easyconnect/Views/Comptable/grand_livre_page.dart';
import 'package:easyconnect/Views/Comptable/balance_page.dart';
import 'package:easyconnect/Views/Components/global_search_page.dart';
import 'package:easyconnect/Views/Components/profile_page.dart';
import 'package:easyconnect/Views/Components/notifications_page.dart';
import 'package:easyconnect/Views/Components/media_page.dart';

bool _isPublicRoute(String loc) {
  const public = ['/splash', '/login', '/welcome', '/register', '/unauthorized'];
  return public.any((r) => loc == r || loc.startsWith('$r/'));
}

GoRouter? rootGoRouter;

/// Dernière route connue (mise à jour dans redirect), pour AuthErrorHandler.currentRouteCallback.
String get currentRouterLocation => _currentRouterLocation;
String _currentRouterLocation = '/splash';

GoRouter createAppRouter() {
  rootGoRouter = GoRouter(
    initialLocation: '/splash',
    refreshListenable: authRefreshNotifier,
    redirect: (BuildContext context, GoRouterState state) {
      _currentRouterLocation = state.matchedLocation;
      final user = currentAuthState?.user;
      final loc = state.matchedLocation;

      if (user != null && (loc == '/splash' || loc == '/login')) {
        return initialRouteForRole(user.role);
      }
      if (user == null && !_isPublicRoute(loc)) {
        return '/splash';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomePage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
      GoRoute(path: '/unauthorized', builder: (_, __) => UnauthorizedPage()),
      GoRoute(path: '/commercial', builder: (_, __) => CommercialDashboardEnhanced()),
      GoRoute(path: '/comptable', builder: (_, __) => ComptableDashboardEnhanced()),
      GoRoute(path: '/comptable/grand-livre', builder: (_, __) => const GrandLivrePage()),
      GoRoute(path: '/comptable/balance', builder: (_, __) => const BalancePage()),
      GoRoute(path: '/patron', builder: (_, __) => PatronDashboardEnhanced()),
      GoRoute(path: '/rh', builder: (_, __) => RhDashboardEnhanced()),
      GoRoute(path: '/technicien', builder: (_, __) => TechnicienDashboardEnhanced()),
      GoRoute(path: '/patron/finances', builder: (_, __) => const FinancesPage()),
      GoRoute(path: '/patron/reports', builder: (_, __) => const PatronReportsPage()),
      GoRoute(path: '/admin', builder: (_, __) => const AdminDashboard()),
      GoRoute(path: '/admin/users', builder: (_, __) => const UserManagementPage()),
      GoRoute(path: '/admin/users/new', builder: (_, __) => const UserFormPage()),
      GoRoute(
        path: '/admin/users/:id/edit',
        builder: (c, s) => UserFormPage(
          isEditing: true,
          userId: int.tryParse(s.pathParameters['id'] ?? '0') ?? 0,
        ),
      ),
      GoRoute(path: '/admin/settings', builder: (_, __) => const AppSettingsPage()),
      GoRoute(path: '/admin/push-test', builder: (_, __) => const PushNotificationTestPage()),
      GoRoute(path: '/admin/roles', builder: (_, __) => const RolesManagementPage()),
      GoRoute(path: '/clients', builder: (_, __) => ClientsPage()),
      GoRoute(path: '/clients/new', builder: (_, __) => ClientFormPage()),
      GoRoute(path: '/clients/validation', builder: (_, __) => ClientValidationPage()),
      GoRoute(
        path: '/clients/:id',
        builder: (_, s) => ClientDetailsPage(
          clientId: int.tryParse(s.pathParameters['id'] ?? '0') ?? 0,
        ),
      ),
      GoRoute(
        path: '/clients/:id/edit',
        builder: (_, s) => ClientFormPage(
          isEditing: true,
          clientId: int.tryParse(s.pathParameters['id'] ?? '0'),
        ),
      ),
      GoRoute(path: '/clients-page', builder: (_, __) => ClientsPage()),
      GoRoute(path: '/devis', builder: (_, __) => DevisListPage()),
      GoRoute(path: '/devis/new', builder: (_, __) => DevisFormPage()),
      GoRoute(path: '/devis/validation', builder: (_, __) => const DevisValidationPage()),
      GoRoute(
        path: '/devis/:id/edit',
        builder: (_, s) => DevisFormPage(
          isEditing: true,
          devisId: int.tryParse(s.pathParameters['id'] ?? '0') ?? 0,
        ),
      ),
      GoRoute(
        path: '/devis/:id',
        builder: (_, s) => DevisDetailPage(
          devisId: int.tryParse(s.pathParameters['id'] ?? '0') ?? 0,
        ),
      ),
      GoRoute(path: '/devis-page', builder: (_, __) => DevisListPage()),
      GoRoute(path: '/bordereaux', builder: (_, __) => BordereauListPage()),
      GoRoute(path: '/bordereaux/new', builder: (_, __) => BordereauFormPage()),
      GoRoute(path: '/bordereaux/validation', builder: (_, __) => const BordereauValidationPage()),
      GoRoute(
        path: '/bordereaux/:id/edit',
        builder: (_, s) => BordereauFormPage(
          isEditing: true,
          bordereauId: int.tryParse(s.pathParameters['id'] ?? '0') ?? 0,
        ),
      ),
      GoRoute(
        path: '/bordereaux/:id',
        builder: (_, s) => BordereauDetailPage(
          bordereauId: int.tryParse(s.pathParameters['id'] ?? '0') ?? 0,
        ),
      ),
      GoRoute(path: '/bon-commandes', builder: (_, __) => BonCommandeListPage()),
      GoRoute(path: '/bon-commandes/new', builder: (_, __) => BonCommandeFormPage()),
      GoRoute(path: '/bon-commandes/validation', builder: (_, __) => const BonCommandeValidationPage()),
      GoRoute(
        path: '/bon-commandes/:id/edit',
        builder: (_, s) => BonCommandeFormPage(
          isEditing: true,
          bonCommandeId: int.tryParse(s.pathParameters['id'] ?? '0') ?? 0,
        ),
      ),
      GoRoute(
        path: '/bon-commandes/:id',
        builder: (_, s) => BonCommandeDetailPage(
          bonCommandeId: int.tryParse(s.pathParameters['id'] ?? '0') ?? 0,
        ),
      ),
      GoRoute(path: '/bons-de-commande-fournisseur', builder: (_, __) => BonDeCommandeFournisseurListPage()),
      GoRoute(path: '/bons-de-commande-fournisseur/new', builder: (_, __) => BonDeCommandeFournisseurFormPage()),
      GoRoute(path: '/bons-de-commande-fournisseur/validation', builder: (_, __) => const BonDeCommandeFournisseurValidationPage()),
      GoRoute(
        path: '/bons-de-commande-fournisseur/:id/edit',
        builder: (_, s) => BonDeCommandeFournisseurFormPage(
          isEditing: true,
          bonDeCommandeId: int.tryParse(s.pathParameters['id'] ?? '0') ?? 0,
        ),
      ),
      GoRoute(
        path: '/bons-de-commande-fournisseur/:id',
        builder: (_, s) => BonDeCommandeFournisseurDetailPage(
          bonDeCommandeId: int.tryParse(s.pathParameters['id'] ?? '0') ?? 0,
        ),
      ),
      GoRoute(path: '/tasks', builder: (_, __) => const TaskListPage()),
      GoRoute(path: '/tasks/new', builder: (_, __) => const TaskFormPage()),
      GoRoute(
        path: '/tasks/:id',
        builder: (_, s) => TaskDetailPage(
          taskId: int.tryParse(s.pathParameters['id'] ?? '0') ?? 0,
        ),
      ),
      GoRoute(path: '/factures/validation', builder: (_, __) => const FactureValidationPage()),
      GoRoute(path: '/paiements/validation', builder: (_, __) => const PaiementValidationPage()),
      GoRoute(path: '/depenses/validation', builder: (_, __) => const DepenseValidationPage()),
      GoRoute(path: '/stock/validation', builder: (_, __) => const StockValidationPage()),
      GoRoute(path: '/interventions/validation', builder: (_, __) => const InterventionValidationPage()),
      GoRoute(path: '/salaires/validation', builder: (_, __) => const SalaireValidationPage()),
      GoRoute(path: '/recrutement/validation', builder: (_, __) => const RecruitmentValidationPage()),
      GoRoute(path: '/contrats/validation', builder: (_, __) => const ContractValidationPage()),
      GoRoute(path: '/conges/validation', builder: (_, __) => const LeaveValidationPage()),
      GoRoute(path: '/pointage/validation', builder: (_, __) => const PointageValidationPage()),
      GoRoute(
        path: '/pointage/detail',
        builder: (_, s) {
          final pointage = s.extra;
          if (pointage is! AttendancePunchModel) {
            return Scaffold(
              appBar: AppBar(title: const Text('Pointage')),
              body: const Center(child: Text('Données du pointage non fournies')),
            );
          }
          return PointageDetail(pointage: pointage);
        },
      ),
      GoRoute(path: '/pointage/presence-summary', builder: (_, __) => const PresenceSummaryPage()),
      GoRoute(path: '/taxes/validation', builder: (_, __) => const TaxeValidationPage()),
      GoRoute(path: '/reporting/validation', builder: (_, __) => const ReportingValidationPage()),
      GoRoute(path: '/employees/validation', builder: (_, __) => const EmployeeValidationPage()),
      GoRoute(path: '/patron/registrations/validation', builder: (_, __) => const RegistrationValidationPage()),
      GoRoute(path: '/reporting', builder: (_, __) => const ReportingList()),
      GoRoute(
        path: '/reporting/new',
        builder: (_, s) => ReportingForm(reporting: s.extra as ReportingModel?),
      ),
      GoRoute(
        path: '/user-reportings/:id',
        builder: (c, s) {
          final reporting = s.extra;
          if (reporting is! ReportingModel) {
            return Scaffold(
              appBar: AppBar(title: const Text('Reporting')),
              body: const Center(child: Text('Données du reporting non fournies')),
            );
          }
          return ReportingDetail(reporting: reporting);
        },
      ),
      GoRoute(path: '/attendance-punch', builder: (_, __) => const AttendancePunchPage()),
      GoRoute(path: '/attendance-validation', builder: (_, __) => const AttendanceValidationPage()),
      GoRoute(path: '/invoices', builder: (_, __) => const InvoiceListPage()),
      GoRoute(path: '/invoices/new', builder: (_, __) => const InvoiceForm()),
      GoRoute(path: '/payments', builder: (_, __) => const PaymentList()),
      GoRoute(path: '/payments/new', builder: (_, __) => const PaymentForm()),
      GoRoute(
        path: '/payments/detail',
        builder: (_, s) => PaymentDetail(paymentId: s.extra as int),
      ),
      GoRoute(
        path: '/payments/edit',
        builder: (_, s) => PaymentForm(paymentId: s.extra as int?),
      ),
      GoRoute(path: '/suppliers', builder: (_, __) => const SupplierList()),
      GoRoute(path: '/suppliers/validation', builder: (_, __) => const SupplierValidationPage()),
      GoRoute(path: '/suppliers/new', builder: (_, __) => const SupplierForm()),
      GoRoute(
        path: '/suppliers/:id/edit',
        builder: (_, s) => SupplierForm(supplier: s.extra as Supplier?),
      ),
      GoRoute(
        path: '/suppliers/:id',
        builder: (_, s) => SupplierDetail(supplier: s.extra as Supplier),
      ),
      GoRoute(path: '/taxes', builder: (_, __) => const TaxList()),
      GoRoute(path: '/taxes/new', builder: (_, __) => const TaxForm()),
      GoRoute(
        path: '/taxes/:id/edit',
        builder: (_, s) => TaxForm(tax: s.extra as Tax?),
      ),
      GoRoute(
        path: '/taxes/:id',
        builder: (_, s) => TaxDetail(tax: s.extra as Tax),
      ),
      GoRoute(path: '/expenses', builder: (_, __) => const ExpenseList()),
      GoRoute(path: '/expenses/new', builder: (_, __) => const ExpenseForm()),
      GoRoute(
        path: '/expenses/:id/edit',
        builder: (_, s) => ExpenseForm(expense: s.extra as Expense?),
      ),
      GoRoute(
        path: '/expenses/:id',
        builder: (_, s) => ExpenseDetail(expense: s.extra as Expense),
      ),
      GoRoute(path: '/journal', builder: (_, __) => const JournalListPage()),
      GoRoute(
        path: '/journal/form',
        builder: (_, s) => JournalFormPage(entryId: s.extra as int?),
      ),
      GoRoute(
        path: '/journal/:id',
        builder: (_, s) => JournalDetailPage(
          entryId: int.tryParse(s.pathParameters['id'] ?? '0') ?? 0,
        ),
      ),
      GoRoute(path: '/salaries', builder: (_, __) => const SalaryList()),
      GoRoute(path: '/salaries/new', builder: (_, __) => const SalaryForm()),
      GoRoute(
        path: '/salaries/:id/edit',
        builder: (_, s) => SalaryForm(salary: s.extra as Salary?),
      ),
      GoRoute(
        path: '/salaries/:id',
        builder: (_, s) => SalaryDetail(salary: s.extra as Salary),
      ),
      GoRoute(path: '/interventions', builder: (_, __) => const InterventionList()),
      GoRoute(path: '/interventions/new', builder: (_, __) => const InterventionForm()),
      GoRoute(
        path: '/interventions/:id/edit',
        builder: (_, s) => InterventionForm(intervention: s.extra as Intervention?),
      ),
      GoRoute(
        path: '/interventions/:id',
        builder: (_, s) => InterventionDetail(intervention: s.extra as Intervention),
      ),
      GoRoute(path: '/besoins', builder: (_, __) => const BesoinListPage()),
      GoRoute(path: '/besoins/new', builder: (_, __) => const BesoinFormPage()),
      GoRoute(path: '/equipments', builder: (_, __) => const EquipmentList()),
      GoRoute(path: '/equipments/new', builder: (_, __) => const EquipmentForm()),
      GoRoute(
        path: '/equipments/:id/edit',
        builder: (_, s) => EquipmentForm(equipment: s.extra as Equipment?),
      ),
      GoRoute(
        path: '/equipments/:id',
        builder: (_, s) => EquipmentDetail(equipment: s.extra as Equipment),
      ),
      GoRoute(path: '/stocks', builder: (_, __) => const StockList()),
      GoRoute(path: '/stock/inventaire', builder: (_, __) => const InventorySessionListPage()),
      GoRoute(
        path: '/stock/inventaire/:id',
        builder: (c, s) {
          final id = int.tryParse(s.pathParameters['id'] ?? '0') ?? 0;
          final session = s.extra as InventorySession?;
          return InventorySessionDetailPage(sessionId: id, session: session);
        },
      ),
      GoRoute(path: '/stocks/new', builder: (_, __) => const StockForm()),
      GoRoute(
        path: '/stocks/:id/edit',
        builder: (_, s) => StockForm(stock: s.extra as Stock?),
      ),
      GoRoute(
        path: '/stocks/:id',
        builder: (_, s) => StockDetail(stock: s.extra as Stock),
      ),
      GoRoute(path: '/employees', builder: (_, __) => const EmployeeList()),
      GoRoute(path: '/employees/new', builder: (_, __) => const EmployeeForm()),
      GoRoute(
        path: '/employees/:id/edit',
        builder: (_, s) => EmployeeForm(employee: s.extra as Employee?),
      ),
      GoRoute(
        path: '/employees/:id',
        builder: (_, s) => EmployeeDetail(employee: s.extra as Employee),
      ),
      GoRoute(path: '/leaves', builder: (_, __) => const LeaveList()),
      GoRoute(path: '/leaves/new', builder: (_, __) => const LeaveForm()),
      GoRoute(
        path: '/leaves/:id/edit',
        builder: (_, s) => LeaveForm(request: s.extra as LeaveRequest?),
      ),
      GoRoute(
        path: '/leaves/:id',
        builder: (_, s) => LeaveDetail(request: s.extra as LeaveRequest),
      ),
      GoRoute(path: '/recruitment', builder: (_, __) => const RecruitmentList()),
      GoRoute(path: '/recruitment/new', builder: (_, __) => const RecruitmentForm()),
      GoRoute(
        path: '/recruitment/:id/edit',
        builder: (_, s) => RecruitmentForm(request: s.extra as RecruitmentRequest?),
      ),
      GoRoute(
        path: '/recruitment/:id',
        builder: (_, s) => RecruitmentDetail(request: s.extra as RecruitmentRequest),
      ),
      GoRoute(path: '/contracts', builder: (_, __) => const ContractList()),
      GoRoute(path: '/contracts/new', builder: (_, __) => const ContractForm()),
      GoRoute(
        path: '/contracts/:id/edit',
        builder: (_, s) => ContractForm(contract: s.extra as Contract?),
      ),
      GoRoute(
        path: '/contracts/:id',
        builder: (_, s) => ContractDetail(contract: s.extra as Contract),
      ),
      GoRoute(path: '/search', builder: (_, __) => const GlobalSearchPage()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationsPage()),
      GoRoute(path: '/media', builder: (_, __) => const MediaPage()),
    ],
  );
  return rootGoRouter!;
}

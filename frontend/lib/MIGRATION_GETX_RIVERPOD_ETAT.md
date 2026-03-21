# État de la migration GetX → Riverpod

## Entités entièrement migrées (vues + provider, plus de GetX dans le flux)

| Entité | Provider | Vues migrées | GetX retiré |
|--------|----------|--------------|-------------|
| **Invoice** | `invoiceProvider` | invoice_list, invoice_list_page, invoice_detail, invoice_form | Oui – bindings sans InvoiceController |
| **Journal** | `journalProvider` | journal_list_page, journal_detail_page, journal_form_page | Oui – plus de JournalController |
| **Recherche globale** | `globalSearchProvider` | global_search_page | Oui |
| **Gestion utilisateurs (Admin)** | `userManagementProvider` | user_management_page, user_form_page | Oui |
| **Auth** (partiel) | `authProvider` | admin_dashboard, attendance_validation_page | Les deux vues utilisent authProvider ; AuthController encore utilisé ailleurs |

---

## Entités avec provider Riverpod mais vues encore en GetX

Les **providers** existent déjà, mais les **écrans** utilisent encore `Get.put`, `Get.find`, `Obx`, `Get.to`, `Get.back`, `Get.snackbar` :

| Entité | Provider | Fichiers vues encore GetX |
|--------|----------|---------------------------|
| **Intervention** | intervention_notifier | intervention_form.dart (Get.put, Obx, Get.back) |
| **Equipment** | equipment_notifier | equipment_form.dart (Get.put, Obx, Get.back) |
| **Recruitment** | recruitment_notifier | recruitment_form.dart (Get.put, Obx, Get.snackbar) |
| **Leave** | leave_notifier | leave_form.dart (Get.put, Obx, Get.snackbar) |
| **Employee** | employee_notifier | employee_form.dart (Get.put, Obx, Get.back) |
| **Contract** | contract_notifier | contract_form.dart (Get.put, Obx) |
| **Salary** | salary_notifier | salary_form.dart (Get.put, Obx) |
| **Stock** | stock_notifier | stock_form.dart (Get.put, Obx) |
| **Reporting** | reporting_notifier | reporting_controller + vues (GetxController, Get.snackbar) |
| **Tax** | tax_notifier | tax_detail.dart (Get.dialog, Get.back) |
| **Payment** | payment_notifier | Bindings Get.put(PaymentController) ; vues à vérifier |
| **Devis** | devis_notifier | DevisController (GetxController) ; vues commercial à vérifier |
| **Client** | client_notifier | ClientController (GetxController) ; vues commercial à vérifier |
| **Bordereau** | bordereau_notifier | BordereauxController (GetxController) |
| **Bon commande** | bon_commande_notifier | BonCommandeController (GetxController) |
| **Bon commande fournisseur** | bon_de_commande_fournisseur_notifier | BonDeCommandeFournisseurController (GetxController) |
| **Expense** | expense_notifier | ExpenseController (GetxController) |
| **Task** | task_notifier | TaskController (GetxController) |
| **Attendance** | attendance_notifier | attendance_punch_page.dart (Get.snackbar, Get.dialog, Get.back) |
| **Auth** | auth_notifier | auth_controller + nombreux Get.find<AuthController> dans controllers et notifiers |

---

## Autres usages GetX (hors entités métier)

| Fichier / zone | Usage GetX |
|----------------|-----------|
| **host.dart** | Get.find(HostController), Get.find(AuthController), Get.to(UserPage) partout |
| **base_dashboard.dart** | Get.find<AuthController>, Obx |
| **favorites_bar.dart** | Get.find<FavoritesService>, Obx |
| **app_settings_page.dart** | Get.snackbar |
| **patron/dashboard_content.dart** | Obx |
| **patron/devis_validation_page.dart** | Obx |
| **patron/finances_page.dart** | Get.put(ComptableDashboardController) |
| **Users/user_form.dart** | Get.find(UserController) |
| **Bindings** (app, auth, comptable, commercial, patron, rh, technicien, task) | Get.put(Controllers et Services) |
| **Dashboard notifiers** (patron, comptable, commercial, rh, technicien) | Get.find<AuthController>, Get.find<*Service> pour charger les données |
| **dashboard_refresh_helper.dart** | Get.find(PatronDashboardController, ComptableDashboardController, TechnicienDashboardController) |
| **Controllers** (tous les GetxController restants) | Get.find<AuthController>, Get.find<*Service> |
| **Services** (employee, leave, supplier, invoice, reporting, notification, contract, stock, payment) | `static get to => Get.find()` |

---

## Contrôleurs GetX encore enregistrés dans les bindings

- **AuthController** (app_bindings, auth_binding, patron_binding, task_binding)
- **PaymentController** (app_bindings, comptable_binding, commercial_binding, patron_binding)
- **EmployeeController** (comptable_binding, rh_binding)
- **InterventionController** (technicien_binding)
- **EquipmentController** (technicien_binding)
- **RecruitmentController** (rh_binding)
- **LeaveController** (rh_binding)
- **ContractController** (rh_binding)

*(InvoiceController et JournalController ne sont plus enregistrés.)*

---

## Synthèse

- **Entités 100 % migrées (vues + provider, pas de GetX)** : Invoice, Journal, Recherche globale, Gestion utilisateurs (Admin). Auth partiel (2 vues).
- **Entités avec provider mais vues encore GetX** : Intervention, Equipment, Recruitment, Leave, Employee, Contract, Salary, Stock, Reporting, Tax, Payment, Devis, Client, Bordereau, Bon commande, Bon commande fournisseur, Expense, Task, Attendance, Auth (reste de l’app).
- **Infra / divers encore GetX** : host.dart, base_dashboard, favorites_bar, app_settings, dashboards (contenus + refresh helper), tous les bindings, services avec `Get.find`, et la majorité des contrôleurs GetxController.

Pour « tout migrer », il faudrait, par entité concernée :
1. Brancher les vues sur le provider (ref.watch / ref.read) et supprimer Get.put / Get.find / Obx.
2. Remplacer Get.to / Get.back / Get.dialog / Get.snackbar par `context.push` / `context.pop` / `showDialog` / `ScaffoldMessenger`.
3. À terme : retirer les contrôleurs GetX des bindings et, si besoin, faire passer les notifiers Riverpod par des services injectés ou fournis (plutôt que Get.find<*Service>).

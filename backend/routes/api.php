<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\API\BordereauController;
use App\Http\Controllers\API\BonDeCommandeController;
use App\Http\Controllers\API\CommandeEntrepriseController;
use App\Http\Controllers\API\DevisController;
use App\Http\Controllers\API\FournisseurController;
use App\Http\Controllers\API\TaxController;
use App\Http\Controllers\API\StockController;
use App\Http\Controllers\API\ExpenseController;
use App\Http\Controllers\API\EmployeeController;
use App\Http\Controllers\API\RecruitmentController;
use App\Http\Controllers\API\RecruitmentApplicationController;
use App\Http\Controllers\API\RecruitmentDocumentController;
use App\Http\Controllers\API\RecruitmentInterviewController;
use App\Http\Controllers\API\ContractController;
use App\Http\Controllers\API\ReportingController;
use App\Http\Controllers\API\UserReportingController;
use App\Http\Controllers\API\NotificationController;
use App\Http\Controllers\API\EvaluationController;
use App\Http\Controllers\API\ClientController;
use App\Http\Controllers\API\CompanyController;
use App\Http\Controllers\API\FactureController;
use App\Http\Controllers\API\PaiementController;
use App\Http\Controllers\API\PaymentScheduleController;
use App\Http\Controllers\API\JournalController;
use App\Http\Controllers\API\BalanceController;
use App\Http\Controllers\API\InventorySessionController;
use App\Http\Controllers\API\TaskController;
use App\Http\Controllers\API\AttendanceController;
use App\Http\Controllers\API\UserController;
use App\Http\Controllers\API\InterventionController;
use App\Http\Controllers\API\BesoinController;
use App\Http\Controllers\API\EquipmentController;
use App\Http\Controllers\API\SalaryController;
use App\Http\Controllers\API\LeaveRequestController;
use App\Http\Controllers\API\LeaveBalanceController;
use App\Http\Controllers\API\DeviceTokenController;

/* -------------------------------------------------------------- */
/* ROUTES PUBLIQUES (SANS AUTHENTIFICATION) */
/* -------------------------------------------------------------- */

Route::post('/login', [UserController::class, 'login'])->middleware('throttle:login');
Route::post('/register', [UserController::class, 'register'])->middleware('throttle:5,1');

/* -------------------------------------------------------------- */
/* ROUTES PROTÉGÉES PAR AUTHENTIFICATION */
/* -------------------------------------------------------------- */

Route::middleware(['auth:sanctum'])->group(function () {
    
    // Routes d'authentification
    Route::post('/logout', [UserController::class, 'logout']);
    Route::get('/me', [UserController::class, 'me']);
    Route::put('/user-profile', [UserController::class, 'updateProfile']);
    Route::post('/user-profile-photo', [UserController::class, 'updateProfilePhoto']);
    Route::post('/refresh', [UserController::class, 'refresh']);
    
    // Routes de liste (accessibles à tous les utilisateurs authentifiés)
    Route::get('/companies', [CompanyController::class, 'index']);
    Route::get('/companies/{id}/logo', [CompanyController::class, 'showLogo']);
    Route::get('/companies/{id}/signature', [CompanyController::class, 'showSignature']);
    Route::post('/companies/{id}/logo', [CompanyController::class, 'uploadLogo']);
    Route::post('/companies/{id}/signature', [CompanyController::class, 'uploadSignature']);
    Route::get('/clients-list', [ClientController::class, 'index']);
    Route::get('/fournisseurs-list', [FournisseurController::class, 'index']);
    Route::get('/users-list', [UserController::class, 'index']);
    Route::get('/factures-list', [FactureController::class, 'index']);
    Route::get('/factures/count', [FactureController::class, 'count']);
    Route::get('/factures/stats', [FactureController::class, 'stats']);
    Route::get('/bons-de-commande-list', [BonDeCommandeController::class, 'index']);
    Route::get('/commandes-entreprise-list', [CommandeEntrepriseController::class, 'index']);
    Route::get('/devis', [DevisController::class, 'index']);
    Route::get('/devis-list', [DevisController::class, 'index']);
    Route::get('/devis-debug', [DevisController::class, 'debug']);
    Route::get('/devis/count', [DevisController::class, 'count']);
    Route::get('/devis/stats', [DevisController::class, 'stats']);
    Route::get('/bordereaux-list', [BordereauController::class, 'index']);
    Route::get('/bordereaux', [BordereauController::class, 'index']);
    Route::get('/bordereaux/count', [BordereauController::class, 'count']);
    Route::get('/bordereaux/stats', [BordereauController::class, 'stats']);
    Route::get('/paiements-list', [PaiementController::class, 'index']);
    Route::get('/payments', [PaiementController::class, 'index']);
    Route::get('/payments/count', [PaiementController::class, 'count']);
    Route::get('/payments/stats', [PaiementController::class, 'stats']);
    Route::get('/paiements/count', [PaiementController::class, 'count']);
    Route::get('/paiements/stats', [PaiementController::class, 'stats']);
    Route::get('/journal', [JournalController::class, 'index']);
    Route::get('/journal-list', [JournalController::class, 'list']);
    Route::get('/balance', [BalanceController::class, 'index']);
    Route::get('/inventory-sessions', [InventorySessionController::class, 'index']);
    Route::post('/inventory-sessions', [InventorySessionController::class, 'store']);
    Route::get('/inventory-sessions/{id}', [InventorySessionController::class, 'show']);
    Route::get('/inventory-sessions/{id}/lines', [InventorySessionController::class, 'lines']);
    Route::post('/inventory-sessions/{id}/lines', [InventorySessionController::class, 'addLines']);
    Route::patch('/inventory-sessions/{sessionId}/lines/{lineId}', [InventorySessionController::class, 'updateLine']);
    Route::post('/inventory-sessions/{id}/close', [InventorySessionController::class, 'close']);
    Route::get('/tasks-list', [TaskController::class, 'index']);
    Route::get('/tasks-show/{id}', [TaskController::class, 'show']);
    Route::get('/payment-schedules', [PaymentScheduleController::class, 'index']);
    Route::get('/taxes-list', [TaxController::class, 'index']);
    Route::get('/salaires-list', [SalaryController::class, 'index']);
    Route::get('/salaries-list', [SalaryController::class, 'index']);
    Route::get('/salaries/count', [SalaryController::class, 'count']);
    Route::get('/salaries/stats', [SalaryController::class, 'stats']);
    Route::get('/depenses-list', [ExpenseController::class, 'index']);
    Route::get('/expenses-list', [ExpenseController::class, 'index']);
    Route::get('/expenses/count', [ExpenseController::class, 'count']);
    Route::get('/expenses/stats', [ExpenseController::class, 'stats']);
    Route::get('/stocks', [StockController::class, 'index']);
    Route::get('/stocks-list', [StockController::class, 'index']);
    Route::get('/interventions', [InterventionController::class, 'index']);
    Route::get('/interventions-list', [InterventionController::class, 'index']);
    Route::get('/besoins-list', [BesoinController::class, 'index']);
    Route::get('/besoins-show/{id}', [BesoinController::class, 'show']);
    Route::get('/equipment-list', [EquipmentController::class, 'index']);
    Route::get('/employees', [EmployeeController::class, 'index']);
    Route::get('/employees-list', [EmployeeController::class, 'index']);
    Route::get('/recruitment-requests', [RecruitmentController::class, 'index']);
    Route::get('/recruitment-applications', [RecruitmentApplicationController::class, 'index']);
    Route::get('/recruitment-documents', [RecruitmentDocumentController::class, 'index']);
    Route::get('/recruitment-interviews', [RecruitmentInterviewController::class, 'index']);
    Route::get('/contracts', [ContractController::class, 'index']);
    Route::get('/leave-requests', [LeaveRequestController::class, 'index']);
    
    // Routes pour les notifications (tous les utilisateurs)
    // Nouvelles routes selon la documentation
    Route::prefix('notifications')->group(function () {
        Route::get('/', [NotificationController::class, 'index']);
        Route::put('/{id}/read', [NotificationController::class, 'markAsRead']);
        Route::put('/read-all', [NotificationController::class, 'markAllAsRead']);
        Route::delete('/{id}', [NotificationController::class, 'destroy']);
    });

    // Routes pour les tokens d'appareil (tous les utilisateurs authentifiés)
    Route::prefix('device-tokens')->group(function () {
        Route::get('/', [DeviceTokenController::class, 'index']);
        Route::post('/', [DeviceTokenController::class, 'store']);
        Route::delete('/{id}', [DeviceTokenController::class, 'destroy']);
        Route::delete('/', [DeviceTokenController::class, 'destroyAll']);
    });
    
    // Routes existantes pour compatibilité
    Route::get('/notifications/{id}', [NotificationController::class, 'show']);
    Route::post('/notifications/{id}/mark-read', [NotificationController::class, 'markAsRead']);
    Route::post('/notifications/mark-all-read', [NotificationController::class, 'markAllAsRead']);
    Route::post('/notifications/{id}/archive', [NotificationController::class, 'archive']);
    Route::post('/notifications/archive-all-read', [NotificationController::class, 'archiveAllRead']);
    Route::get('/notifications/unread', [NotificationController::class, 'unread']);
    Route::get('/notifications/urgent', [NotificationController::class, 'urgent']);
    Route::get('/notifications-statistics', [NotificationController::class, 'statistics']);

    // Routes pour les Reportings (tous les utilisateurs)
    Route::get('/user-reportings', [UserReportingController::class, 'index']);
    Route::get('/user-reportings-list', [UserReportingController::class, 'index']);
    Route::get('/user-reportings-show/{id}', [UserReportingController::class, 'show']);
    Route::post('/user-reportings-create', [UserReportingController::class, 'store']);
    Route::put('/user-reportings-update/{id}', [UserReportingController::class, 'update']);
    Route::delete('/user-reportings-destroy/{id}', [UserReportingController::class, 'destroy']);
    Route::post('/user-reportings-submit/{id}', [UserReportingController::class, 'submit']);
    Route::post('/user-reportings-generate', [UserReportingController::class, 'generate']);
    Route::get('/user-reportings-stats', [UserReportingController::class, 'statistics']);

    // Routes pour les évaluations (tous les utilisateurs)
    Route::get('/my-evaluations', [EvaluationController::class, 'index']);
    Route::post('/my-evaluations/{id}/sign-employee', [EvaluationController::class, 'signByEmployee']);

    // Routes pour les clients (tous les utilisateurs authentifiés)
    Route::get('/clients-show/{id}', [ClientController::class, 'show']);

    // Routes pour les fournisseurs (tous les utilisateurs authentifiés)
    Route::get('/fournisseurs-show/{id}', [FournisseurController::class, 'show']);

    // Routes pour la liste et consultation (commercial, comptable, technicien, admin, patron)
    Route::middleware(['role:1,2,3,4,5,6'])->group(function () {
        Route::get('/factures-show/{id}', [FactureController::class, 'show']);

        // Routes pour les pointages
        Route::get('/attendances', [AttendanceController::class, 'index']);
        Route::get('/attendances/{id}', [AttendanceController::class, 'show']);
        Route::post('/attendances', [AttendanceController::class, 'store']);
        Route::post('/attendances/check-in', [AttendanceController::class, 'checkIn']);
        Route::post('/attendances/check-out', [AttendanceController::class, 'checkOut']);
        Route::put('/attendances/{id}', [AttendanceController::class, 'update']);
        Route::delete('/attendances/{id}', [AttendanceController::class, 'destroy']);
        Route::get('/attendances/current-status', [AttendanceController::class, 'currentStatus']);
        Route::get('/attendances/can-punch', [AttendanceController::class, 'canPunch']);
        Route::get('/attendances-statistics', [AttendanceController::class, 'statistics']);
        Route::get('/attendance-settings', [AttendanceController::class, 'settings']);

        // Mise à jour tâche (statut) : tous les rôles (contrôleur vérifie assigné ou patron/admin)
        Route::put('/tasks-update/{id}', [TaskController::class, 'update']);
    });

    /* -------------------------------------------------------------- */
    /* ROUTES POUR LES COMMERCIAUX, COMPTABLES, ADMIN ET PATRON */
    /* -------------------------------------------------------------- */

    Route::middleware(['role:1,2,3,6'])->group(function () {
        // Routes pour les clients
        Route::post('/clients-create', [ClientController::class, 'store']);
        Route::post('/clients-update/{id}', [ClientController::class, 'update']);
        Route::get('/clients-destroy/{id}', [ClientController::class, 'destroy']);

        // Routes pour les bons de commande
        Route::get('/bons-de-commande-show/{id}', [BonDeCommandeController::class, 'show']);
        Route::post('/bons-de-commande-create', [BonDeCommandeController::class, 'store']);
        Route::put('/bons-de-commande-update/{id}', [BonDeCommandeController::class, 'update']);
        Route::delete('/bons-de-commande-destroy/{id}', [BonDeCommandeController::class, 'destroy']);
        Route::post('/mark-in-progress-bons-de-commande/{id}', [BonDeCommandeController::class, 'markInProgress']);
        Route::post('/bons-de-commande-mark-delivered/{id}', [BonDeCommandeController::class, 'markDelivered']);
        Route::post('/bons-de-commande-cancel/{id}', [BonDeCommandeController::class, 'cancel']);
        Route::get('/bons-de-commande-reports', [BonDeCommandeController::class, 'reports']);

        // Routes pour les commandes entreprise
        Route::get('/commandes-entreprise-show/{id}', [CommandeEntrepriseController::class, 'show']);
        Route::post('/commandes-entreprise-create', [CommandeEntrepriseController::class, 'store']);
        Route::put('/commandes-entreprise-update/{id}', [CommandeEntrepriseController::class, 'update']);
        Route::delete('/commandes-entreprise-destroy/{id}', [CommandeEntrepriseController::class, 'destroy']);
        Route::post('/commandes-entreprise-mark-delivered/{id}', [CommandeEntrepriseController::class, 'markAsDelivered']);
        Route::post('/commandes-entreprise-mark-invoiced/{id}', [CommandeEntrepriseController::class, 'markAsInvoiced']);
        
        // Routes pour les devis
        Route::get('/devis-show/{id}', [DevisController::class, 'show']);
        Route::post('/devis-create', [DevisController::class, 'store']);
        Route::put('/devis-update/{id}', [DevisController::class, 'update']);
        Route::delete('/devis-destroy/{id}', [DevisController::class, 'destroy']);

        // Routes pour les bordereaux
        Route::get('/bordereaux-show/{id}', [BordereauController::class, 'show']);
        Route::post('/bordereaux-create', [BordereauController::class, 'store']);
        Route::put('/bordereaux-update/{id}', [BordereauController::class, 'update']);
        Route::delete('/bordereaux/{id}', [BordereauController::class, 'destroy']);
    });

    /* -------------------------------------------------------------- */
    /* ROUTES POUR LES PATRON ET ADMIN */
    /* -------------------------------------------------------------- */

    Route::middleware(['role:1,6'])->group(function () {
        // Routes pour la gestion des utilisateurs
        Route::get('/users-show/{id}', [UserController::class, 'show']);
        Route::post('/users-create', [UserController::class, 'store']);
        Route::put('/users-update/{id}', [UserController::class, 'update']);
        Route::delete('/users-destroy/{id}', [UserController::class, 'destroy']);
        Route::post('/users-activate/{id}', [UserController::class, 'activate']);
        Route::post('/users-deactivate/{id}', [UserController::class, 'deactivate']);
        Route::get('/users-statistics', [UserController::class, 'statistics']);
        // Inscriptions en attente (patron/admin)
        Route::get('/users-pending-registrations', [UserController::class, 'pendingRegistrations']);
        Route::post('/users-approve-registration/{id}', [UserController::class, 'approveRegistration']);
        Route::post('/users-reject-registration/{id}', [UserController::class, 'rejectRegistration']);

        // Routes pour les pointages (approbation/rejet par patron/admin)
        Route::post('/attendances-validate/{id}', [AttendanceController::class, 'approve']);
        Route::post('/attendances-reject/{id}', [AttendanceController::class, 'reject']);
       

        // Routes pour les reportings
        Route::post('/user-reportings-validate/{id}', [UserReportingController::class, 'approve']);
        Route::post('/user-reportings-reject/{id}', [UserReportingController::class, 'reject']);
        Route::post('/user-reportings-note/{id}', [UserReportingController::class, 'addPatronNote']);

        // Routes pour les clients
        Route::post('/clients-validate/{id}', [ClientController::class, 'approve']);
        Route::post('/clients-reject/{id}', [ClientController::class, 'reject']);

        //Routes pour les bons de commande fournisseur
        Route::post('/bons-de-commande-validate/{id}', [BonDeCommandeController::class, 'validateBon']);
        Route::post('/bons-de-commande-reject/{id}', [BonDeCommandeController::class, 'reject']);

        // Routes pour les commandes entreprise
        Route::post('/commandes-entreprise-validate/{id}', [CommandeEntrepriseController::class, 'validateCommande']);
        Route::post('/commandes-entreprise-reject/{id}', [CommandeEntrepriseController::class, 'rejectCommande']);

        //Routes pour les bordereaux
        Route::post('/bordereaux-validate/{id}', [BordereauController::class, 'validateBordereau']);
        Route::post('/bordereaux/{id}/reject', [BordereauController::class, 'reject']);

        //Route pour les devis
        Route::post('/devis-validate/{id}', [DevisController::class, 'validateDevis']);
        Route::post('/devis-accept/{id}', [DevisController::class, 'accept']);
        Route::post('/devis-reject/{id}', [DevisController::class, 'reject']);

        //Routes 
        // Routes pour les paiements
        Route::post('/paiements-validate/{id}', [PaiementController::class, 'validatePaiement']);
        Route::post('/paiements-reject/{id}', [PaiementController::class, 'reject']);
        Route::post('/payments/{id}/submit', [PaiementController::class, 'submit']);
        Route::post('/payments/{id}/approve', [PaiementController::class, 'approve']);
        Route::patch('/payments/{id}/approve', [PaiementController::class, 'approve']);
        Route::post('/payments/{id}/reject', [PaiementController::class, 'reject']);
        Route::patch('/payments/{id}/reject', [PaiementController::class, 'reject']);

        // Routes pour les impôts et taxes
        Route::post('/taxes-validate/{id}', [TaxController::class, 'validateTax']);
        Route::post('/taxes-reject/{id}', [TaxController::class, 'reject']);

        // Routes pour les factures
        Route::post('/factures-validate/{id}', [FactureController::class, 'validateFacture']);
        Route::post('/factures-reject/{id}', [FactureController::class, 'reject']);
        Route::get('/factures-reports', [FactureController::class, 'reports']);

        // Routes pour les stocks
        Route::post('/stocks/{id}/valider', [StockController::class, 'valider']);
        Route::post('/stocks/{id}/rejeter', [StockController::class, 'rejeter']);

        // Routes pour les dépenses
        Route::post('/expenses-validate/{id}', [ExpenseController::class, 'approve']);
        Route::post('/expenses-reject/{id}', [ExpenseController::class, 'reject']);

        // Routes pour les salaires
        Route::post('/salaries-validate/{id}', [SalaryController::class, 'approve']);
        Route::post('/salaries-reject/{id}', [SalaryController::class, 'reject']);

        // Routes pour les fournisseurs
        Route::post('/fournisseurs-validate/{id}', [FournisseurController::class, 'approve']);
        Route::post('/fournisseurs-reject/{id}', [FournisseurController::class, 'reject']);

        // Routes pour les reports
        Route::get('/paiements-reports', [PaiementController::class, 'reports']);
        Route::get('/bordereaux-reports', [BordereauController::class, 'reports']);
        Route::get('/attendances-reports', [AttendanceController::class, 'reports']);
        Route::get('/attendances-presence-summary', [AttendanceController::class, 'presenceSummary']);

        // Routes pour les tâches (création/suppression réservées au patron/admin ; update est dans le groupe auth)
        Route::post('/tasks-create', [TaskController::class, 'store']);
        Route::delete('/tasks-destroy/{id}', [TaskController::class, 'destroy']);
    });

    /* -------------------------------------------------------------- */
    /* ROUTES POUR LES COMPTABLES, ADMIN ET PATRON */
    /* -------------------------------------------------------------- */

    Route::middleware(['role:1,3,6'])->group(function () {
        // Routes pour la gestion financière
        Route::post('/factures-create', [FactureController::class, 'store']);
        Route::put('/factures-update/{id}', [FactureController::class, 'update']);
        Route::post('/factures-cancel-rejection/{id}', [FactureController::class, 'cancelRejection']);
        Route::get('/factures-validation-history/{id}', [FactureController::class, 'validationHistory']);
        Route::post('/factures/{id}/mark-paid', [FactureController::class, 'markAsPaid']);
        
        // Routes pour les paiements
        Route::get('/paiements-show/{id}', [PaiementController::class, 'show']);
        Route::post('/paiements-create', [PaiementController::class, 'store']);
        Route::post('/paiements-create-with-number', [PaiementController::class, 'createWithNumber']);
        Route::put('/paiements-update/{id}', [PaiementController::class, 'update']);
        Route::post('/paiements-submit/{id}', [PaiementController::class, 'submit']);
        Route::post('/paiements-approve/{id}', [PaiementController::class, 'approve']);
        Route::post('/paiements-mark-paid/{id}', [PaiementController::class, 'markAsPaid']);
        Route::post('/paiements-mark-overdue/{id}', [PaiementController::class, 'markAsOverdue']);

        // Routes alias en anglais pour compatibilité Flutter/Dart
        Route::get('/payments/{id}', [PaiementController::class, 'show']);
        Route::post('/payments', [PaiementController::class, 'store']);
        Route::put('/payments/{id}', [PaiementController::class, 'update']);
        Route::delete('/payments/{id}', [PaiementController::class, 'destroy']);
        Route::post('/payments/{id}/mark-paid', [PaiementController::class, 'markAsPaid']);
        Route::patch('/payments/{id}/mark-paid', [PaiementController::class, 'markAsPaid']);
        Route::patch('/payments/{id}/reactivate', [PaiementController::class, 'reactivate']);

        // Routes pour le journal des entrées et sorties
        Route::get('/journal-show/{id}', [JournalController::class, 'show']);
        Route::post('/journal-create', [JournalController::class, 'store']);
        Route::put('/journal-update/{id}', [JournalController::class, 'update']);
        Route::delete('/journal-destroy/{id}', [JournalController::class, 'destroy']);
        
        // Routes pour les plannings de paiement
        Route::get('/payment-schedules/{id}', [PaymentScheduleController::class, 'show']);
        
        // Routes pour les taxes
        Route::post('/taxes-create', [TaxController::class, 'store']);

        Route::put('/taxes-update/{id}', [TaxController::class, 'update']);
        Route::delete('/taxes-destroy/{id}', [TaxController::class, 'destroy']);
        Route::post('/taxes/{id}/calculate', [TaxController::class, 'calculate']);
        Route::post('/taxes/{id}/declare', [TaxController::class, 'declare']);
        Route::post('/taxes/{id}/mark-paid', [TaxController::class, 'markAsPaid']);
        Route::get('/taxes-statistics', [TaxController::class, 'statistics']);
        Route::get('/tax-categories', [TaxController::class, 'categories']);
        
        // Routes pour les salaires
        Route::post('/salaries-create', [SalaryController::class, 'store']);
        Route::put('/salaries-update/{id}', [SalaryController::class, 'update']);
        Route::delete('/salaries-destroy/{id}', [SalaryController::class, 'destroy']);
        Route::post('/salaries-calculate/{id}', [SalaryController::class, 'calculate']);
        Route::post('/salaries-mark-paid/{id}', [SalaryController::class, 'markAsPaid']);
        Route::get('/salaries-statistics', [SalaryController::class, 'statistics']);
        Route::get('/salary-components', [SalaryController::class, 'components']);
        Route::get('/payroll-settings', [SalaryController::class, 'settings']);
        Route::get('/salaries-pending', [SalaryController::class, 'pending']);
        Route::post('/salaries/{id}/pay', [SalaryController::class, 'markAsPaid']);
        Route::get('/salaries/stats', [SalaryController::class, 'statistics']);

        // Routes pour les fournisseurs
        Route::post('/fournisseurs-create', [FournisseurController::class, 'store']);
        Route::put('/fournisseurs-update/{id}', [FournisseurController::class, 'update']);
       
        
        // Routes pour les dépenses
        Route::post('/expenses-create', [ExpenseController::class, 'store']);
        Route::put('/expenses-update/{id}', [ExpenseController::class, 'update']);
        Route::delete('/expenses-destroy/{id}', [ExpenseController::class, 'destroy']);
        Route::get('/expenses/{id}/receipt', [ExpenseController::class, 'showReceipt'])->name('api.expenses.receipt.show');
        Route::get('/expenses/{id}/receipt/download', [ExpenseController::class, 'downloadReceipt']);
       
        
        // Routes pour le stock
        Route::post('/stocks-create', [StockController::class, 'store']);
        Route::put('/stocks-update/{id}', [StockController::class, 'update']);
        Route::delete('/stocks-destroy/{id}', [StockController::class, 'destroy']);
        Route::post('stocks-add-stock/{id}', [StockController::class, 'addStock']);
        Route::post('stocks-remove-stock/{id}', [StockController::class, 'removeStock']);
        Route::post('stocks-adjust-stock/{id}', [StockController::class, 'adjustStock']);
        Route::post('stocks-transfer-stock/{id}', [StockController::class, 'transferStock']);
        Route::post('stocks-merge-stock/{id}', [StockController::class, 'mergeStock']);
        Route::post('stocks-split-stock/{id}', [StockController::class, 'splitStock']);
        Route::post('stocks-merge-stock/{id}', [StockController::class, 'mergeStock']);

    });

    /* -------------------------------------------------------------- */
    /* ROUTES POUR LES TECHNICIENS, ADMIN ET PATRON */
    /* -------------------------------------------------------------- */

    Route::middleware(['role:1,5,6'])->group(function () {
        // Routes pour les interventions
        Route::get('/interventions-show/{id}', [InterventionController::class, 'show']);
        Route::post('/interventions-create', [InterventionController::class, 'store']);
        Route::put('/interventions/{id}', [InterventionController::class, 'update']);
        Route::put('/interventions-update/{id}', [InterventionController::class, 'update']);
        Route::delete('/interventions/{id}', [InterventionController::class, 'destroy']);
        Route::delete('/interventions-destroy/{id}', [InterventionController::class, 'destroy']);
        Route::delete('/interventions-delete/{id}', [InterventionController::class, 'destroy']);
        Route::post('/interventions-approve/{id}', [InterventionController::class, 'approve']);
        Route::post('/interventions-reject/{id}', [InterventionController::class, 'reject']);
        Route::post('/interventions/{id}/start', [InterventionController::class, 'start']);
        Route::post('/interventions-start/{id}', [InterventionController::class, 'start']);
        Route::post('/interventions/{id}/complete', [InterventionController::class, 'complete']);
        Route::post('/interventions-complete/{id}', [InterventionController::class, 'complete']);
        Route::get('/interventions-statistics', [InterventionController::class, 'statistics']);
        Route::get('/interventions-stats', [InterventionController::class, 'statistics']);
        Route::get('/interventions/pending', [InterventionController::class, 'pending']);
        Route::get('/interventions-overdue', [InterventionController::class, 'overdue']);
        Route::get('/interventions-due-soon', [InterventionController::class, 'dueSoon']);
        Route::get('/intervention-types', [InterventionController::class, 'types']);
        Route::get('/equipment', [InterventionController::class, 'equipment']);
        // Besoins : technicien crée, patron marque traité
        Route::post('/besoins-create', [BesoinController::class, 'store']);
        Route::post('/besoins/{id}/mark-treated', [BesoinController::class, 'markTreated']);
        Route::post('/besoins-mark-treated/{id}', [BesoinController::class, 'markTreated']);

        // Routes pour les équipements
        Route::get('/equipment/{id}', [EquipmentController::class, 'show']);
        Route::post('/equipment-create', [EquipmentController::class, 'store']);
        Route::put('/equipment-update/{id}', [EquipmentController::class, 'update']);
        Route::delete('/equipment-destroy/{id}', [EquipmentController::class, 'destroy']);
    });

    /* -------------------------------------------------------------- */
    /* ROUTES POUR LES RH, ADMIN ET PATRON */
    /* -------------------------------------------------------------- */

    Route::middleware(['role:1,3,4,6'])->group(function () {
        // Routes pour les employés
        Route::get('/employees/{id}', [EmployeeController::class, 'show']);
        Route::post('/employees', [EmployeeController::class, 'store']);
        Route::put('/employees/{id}', [EmployeeController::class, 'update']);
        Route::delete('/employees/{id}', [EmployeeController::class, 'destroy']);
        Route::post('/employees/{id}/activate', [EmployeeController::class, 'activate']);
        Route::post('/employees/{id}/deactivate', [EmployeeController::class, 'deactivate']);
        Route::post('/employees/{id}/terminate', [EmployeeController::class, 'terminate']);
        Route::post('/employees/{id}/put-on-leave', [EmployeeController::class, 'putOnLeave']);
        Route::post('/employees/{id}/update-salary', [EmployeeController::class, 'updateSalary']);
        Route::post('/employees/{id}/update-contract', [EmployeeController::class, 'updateContract']);
        Route::get('/employees-statistics', [EmployeeController::class, 'statistics']);
        Route::get('/employees/stats', [EmployeeController::class, 'stats']);
        Route::get('/employees/by-department/{department}', [EmployeeController::class, 'byDepartment']);
        Route::get('/employees/by-position/{position}', [EmployeeController::class, 'byPosition']);
        Route::get('/employees/contract-expiring', [EmployeeController::class, 'contractExpiring']);
        Route::get('/employees/contract-expired', [EmployeeController::class, 'contractExpired']);
        Route::get('/employees/search', [EmployeeController::class, 'search']);
        Route::get('/employees/departments', [EmployeeController::class, 'departments']);
        Route::get('/employees/positions', [EmployeeController::class, 'positions']);
        Route::post('/employees/{employeeId}/documents', [EmployeeController::class, 'addDocument']);
        Route::post('/employees/{employeeId}/leaves', [EmployeeController::class, 'addLeave']);
        Route::post('/employees/{employeeId}/performances', [EmployeeController::class, 'addPerformance']);
        Route::post('/leaves/{leaveId}/approve', [EmployeeController::class, 'approveLeave']);
        Route::post('/leaves/{leaveId}/reject', [EmployeeController::class, 'rejectLeave']);

        // Routes pour les recrutements
        Route::get('/recruitment-requests/{id}', [RecruitmentController::class, 'show']);
        Route::get('/recruitment-requests/{id}/applications', [RecruitmentController::class, 'applications']);
        Route::post('/recruitment-requests', [RecruitmentController::class, 'store']);
        Route::put('/recruitment-requests/{id}', [RecruitmentController::class, 'update']);
        Route::delete('/recruitment-requests/{id}', [RecruitmentController::class, 'destroy']);
        Route::post('/recruitment-requests/{id}/publish', [RecruitmentController::class, 'publish']);
        Route::post('/recruitment-requests/{id}/close', [RecruitmentController::class, 'close']);
        Route::post('/recruitment-requests/{id}/cancel', [RecruitmentController::class, 'cancel']);
        Route::post('/recruitment-requests/{id}/reject', [RecruitmentController::class, 'reject']);
        Route::put('/recruitment-requests/{id}/reject', [RecruitmentController::class, 'reject']);
        Route::post('/recruitment-requests/{id}/approve', [RecruitmentController::class, 'approve']);
        Route::get('/recruitment-statistics', [RecruitmentController::class, 'statistics']);
        Route::get('/recruitment-requests/stats', [RecruitmentController::class, 'statistics']);
        Route::get('/recruitment-departments', [RecruitmentController::class, 'departments']);
        Route::get('/recruitment-requests/departments', [RecruitmentController::class, 'departments']);
        Route::get('/recruitment-positions', [RecruitmentController::class, 'positions']);
        Route::get('/recruitment-requests/positions', [RecruitmentController::class, 'positions']);
        Route::get('/recruitment-requests-by-department/{department}', [RecruitmentController::class, 'byDepartment']);
        Route::get('/recruitment-requests-by-position/{position}', [RecruitmentController::class, 'byPosition']);
        Route::get('/recruitment-requests-expiring', [RecruitmentController::class, 'expiring']);
        Route::get('/recruitment-requests-expired', [RecruitmentController::class, 'expired']);
        Route::get('/recruitment-requests-published', [RecruitmentController::class, 'published']);
        Route::get('/recruitment-requests-drafts', [RecruitmentController::class, 'drafts']);
        
        // Routes pour les candidatures
        Route::get('/recruitment-applications/{id}', [RecruitmentApplicationController::class, 'show']);
        Route::post('/recruitment-applications', [RecruitmentApplicationController::class, 'store']);
        Route::put('/recruitment-applications/{id}', [RecruitmentApplicationController::class, 'update']);
        Route::put('/recruitment-applications/{id}/status', [RecruitmentApplicationController::class, 'updateStatus']);
        Route::post('/recruitment-applications/{id}/review', [RecruitmentApplicationController::class, 'review']);
        Route::post('/recruitment-applications/{id}/shortlist', [RecruitmentApplicationController::class, 'shortlist']);
        Route::post('/recruitment-applications/{id}/reject', [RecruitmentApplicationController::class, 'reject']);
        Route::post('/recruitment-applications/{id}/hire', [RecruitmentApplicationController::class, 'hire']);
        
        // Routes pour les documents de recrutement
        Route::get('/recruitment-documents/{id}', [RecruitmentDocumentController::class, 'show']);
        Route::post('/recruitment-documents', [RecruitmentDocumentController::class, 'store']);
        Route::put('/recruitment-documents/{id}', [RecruitmentDocumentController::class, 'update']);
        Route::delete('/recruitment-documents/{id}', [RecruitmentDocumentController::class, 'destroy']);
        Route::get('/recruitment-documents/{id}/download', [RecruitmentDocumentController::class, 'download']);
        
        // Routes pour les entretiens
        Route::get('/recruitment-interviews/{id}', [RecruitmentInterviewController::class, 'show']);
        Route::post('/recruitment-interviews', [RecruitmentInterviewController::class, 'store']);
        Route::put('/recruitment-interviews/{id}', [RecruitmentInterviewController::class, 'update']);
        Route::post('/recruitment-interviews/{id}/complete', [RecruitmentInterviewController::class, 'complete']);
        Route::post('/recruitment-interviews/{id}/cancel', [RecruitmentInterviewController::class, 'cancel']);
        Route::post('/recruitment-interviews/{id}/reschedule', [RecruitmentInterviewController::class, 'reschedule']);

        // Routes pour les contrats
        Route::get('/contracts/{id}', [ContractController::class, 'show']);
        Route::post('/contracts', [ContractController::class, 'store']);
        Route::put('/contracts/{id}', [ContractController::class, 'update']);
        Route::delete('/contracts/{id}', [ContractController::class, 'destroy']);
        Route::put('/contracts/{id}/approve', [ContractController::class, 'approve']);
        Route::put('/contracts/{id}/reject', [ContractController::class, 'reject']);
        Route::put('/contracts/{id}/terminate', [ContractController::class, 'terminate']);
        Route::put('/contracts/{id}/cancel', [ContractController::class, 'cancel']);
        Route::get('/contracts/{id}/clauses', [ContractController::class, 'getClauses']);
        Route::post('/contracts/{id}/clauses', [ContractController::class, 'addClause']);
        Route::get('/contracts/{id}/attachments', [ContractController::class, 'getAttachments']);
        Route::post('/contracts/{id}/attachments', [ContractController::class, 'addAttachment']);
        Route::get('/contracts/{contractId}/attachments/{attachmentId}/download', [ContractController::class, 'downloadAttachment']);
        Route::get('/contracts/expiring', [ContractController::class, 'expiringSoon']);
        Route::get('/contract-stats', [ContractController::class, 'statistics']);
        Route::get('/contract-templates', [ContractController::class, 'getTemplates']);
        Route::get('/contracts/generate-number', [ContractController::class, 'generateNumber']);

        // Routes pour les demandes de congé
        Route::get('/leave-requests/employee/{employeeId}', [LeaveRequestController::class, 'getEmployeeRequests']);
        Route::get('/leave-requests/{id}', [LeaveRequestController::class, 'show']);
        Route::post('/leave-requests', [LeaveRequestController::class, 'store']);
        Route::put('/leave-requests/{id}', [LeaveRequestController::class, 'update']);
        Route::delete('/leave-requests/{id}', [LeaveRequestController::class, 'destroy']);
        Route::put('/leave-requests/{id}/approve', [LeaveRequestController::class, 'approve']);
        Route::put('/leave-requests/{id}/reject', [LeaveRequestController::class, 'reject']);
        Route::put('/leave-requests/{id}/cancel', [LeaveRequestController::class, 'cancel']);
        Route::post('/leave-requests/check-conflicts', [LeaveRequestController::class, 'checkConflicts']);
        Route::get('/leave-stats', [LeaveRequestController::class, 'statistics']);
        Route::get('/leave-types', [LeaveRequestController::class, 'getLeaveTypes']);
        Route::get('/leave-balance/{employeeId}', [LeaveBalanceController::class, 'show']);
    });
});

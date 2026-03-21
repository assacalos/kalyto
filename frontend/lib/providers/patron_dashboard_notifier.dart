import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/providers/patron_dashboard_state.dart';
import 'package:easyconnect/providers/patron_validation_item.dart';
import 'package:easyconnect/providers/services_providers.dart';
import 'package:easyconnect/services/session_service.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/services/api_service.dart';
import 'package:easyconnect/utils/dashboard_entity_colors.dart';
import 'package:intl/intl.dart';

/// Notifier Riverpod pour le dashboard patron. Un seul provider pour toute l'app.
class PatronDashboardNotifier extends AsyncNotifier<PatronDashboardState> {
  Timer? _refreshTimer;
  bool _mounted = true;

  static bool _isFactureEnAttente(String status) {
    final s = status.toLowerCase().trim();
    return s == 'draft' ||
        s == 'en_attente' ||
        s == 'pending' ||
        s == 'en attente';
  }

  @override
  Future<PatronDashboardState> build() async {
    _refreshTimer?.cancel();
    // Rafraîchissement en arrière-plan sans afficher "chargement" pour ne pas faire disparaître les données
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      refresh(silent: true);
    });
    ref.onDispose(() {
      _mounted = false;
      _refreshTimer?.cancel();
    });
    try {
      await _waitForTokenAndLoad().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          AppLogger.warning(
            'Timeout chargement dashboard patron',
            tag: 'PATRON_DASHBOARD_RIVERPOD',
          );
        },
      );
    } catch (_) {}
    return state.valueOrNull ?? const PatronDashboardState();
  }

  Future<void> _waitForTokenAndLoad() async {
    for (int i = 0; i < 30; i++) {
      final token = SessionService.getTokenSync();
      final user = ref.read(authProvider).user;
      if (token == null || token.isEmpty || user == null) {
        if (i > 0) return;
        await Future.delayed(const Duration(milliseconds: 100));
        continue;
      }
      await refresh();
      return;
    }
    await refresh();
  }

  /// [silent] : si true (ex. timer), ne pas mettre isLoading à true pour garder les données visibles pendant le chargement.
  Future<void> refresh({bool silent = false}) async {
    final token = SessionService.getTokenSync();
    final user = ref.read(authProvider).user;
    if (token == null || token.isEmpty || user == null) return;

    final previous = state.valueOrNull ?? const PatronDashboardState();
    if (!silent) {
      state = AsyncValue.data(previous.copyWith(isLoading: true));
    }
    try {
      final newState = await _loadAll(previous);
      if (!_mounted) return;
      state = AsyncValue.data(newState);
    } catch (e) {
      if (!_mounted) return;
      AppLogger.warning(
        'Erreur refresh dashboard patron: $e',
        tag: 'PATRON_DASHBOARD_RIVERPOD',
      );
      state = AsyncValue.data(previous.copyWith(isLoading: false));
    }
  }

  Future<PatronDashboardState> _loadAll(PatronDashboardState current) async {
    PatronDashboardState s = current.copyWith(
      isLoading: true,
      pendingClients:
          CacheHelper.get<int>('dashboard_patron_pendingClients') ??
          current.pendingClients,
      pendingDevis:
          CacheHelper.get<int>('dashboard_patron_pendingDevis') ??
          current.pendingDevis,
      pendingBordereaux:
          CacheHelper.get<int>('dashboard_patron_pendingBordereaux') ??
          current.pendingBordereaux,
      validatedClients:
          CacheHelper.get<int>('dashboard_patron_validatedClients') ??
          current.validatedClients,
      totalRevenue:
          CacheHelper.get<double>('dashboard_patron_totalRevenue') ??
          current.totalRevenue,
    );

    try {
      s = await _loadPendingValidations(s);
      s = await _loadPerformanceMetrics(s);
      s = s.copyWith(isLoading: false);
    } catch (_) {
      s = s.copyWith(isLoading: false);
    }
    return s;
  }

  /// Appel résilient : en cas d'échec d'une requête, retourne [] au lieu de faire échouer tout le chargement.
  static Future<List> _safeList(Future<List> f) async {
    try {
      return await f;
    } catch (_) {
      return [];
    }
  }

  Future<PatronDashboardState> _loadPendingValidations(
    PatronDashboardState s,
  ) async {
    final clientService = ref.read(clientServiceProvider);
    final devisService = ref.read(devisServiceProvider);
    final bordereauService = ref.read(bordereauServiceProvider);
    final bonCommandeService = ref.read(bonCommandeServiceProvider);
    final invoiceService = ref.read(invoiceServiceProvider);
    final paymentService = ref.read(paymentServiceProvider);
    final expenseService = ref.read(expenseServiceProvider);
    final salaryService = ref.read(salaryServiceProvider);
    final reportingService = ref.read(reportingServiceProvider);
    final attendanceService = ref.read(attendancePunchServiceProvider);
    final interventionService = ref.read(interventionServiceProvider);
    final taskService = ref.read(taskServiceProvider);
    final taxService = ref.read(taxServiceProvider);
    final recruitmentService = ref.read(recruitmentServiceProvider);
    final contractService = ref.read(contractServiceProvider);
    final leaveService = ref.read(leaveServiceProvider);
    final supplierService = ref.read(supplierServiceProvider);
    final stockService = ref.read(stockServiceProvider);

    final results = await Future.wait([
      _safeList(clientService.getClients(status: 0)),
      _safeList(devisService.getDevis(status: 0)),
      _safeList(bordereauService.getBordereaux(status: 1)),
      _safeList(bonCommandeService.getBonCommandes(status: 1)),
      _safeList(invoiceService.getAllInvoices()),
      _safeList(paymentService.getAllPayments()),
      _safeList(expenseService.getExpenses()),
      _safeList(salaryService.getSalaries()),
      _safeList(reportingService.getAllReports()),
      _safeList(attendanceService.getAttendances()),
      _safeList(interventionService.getInterventions()),
      _safeList(taxService.getTaxes()),
      _safeList(recruitmentService.getAllRecruitmentRequests()),
      _safeList(contractService.getAllContracts()),
      _safeList(leaveService.getAllLeaveRequests()),
      _safeList(supplierService.getSuppliers()),
      _safeList(stockService.getStocks()),
      _safeList(taskService.getTasksList(status: 'pending')),
    ]);

    int pendingClients = (results[0]).length;
    int pendingDevis = (results[1]).length;
    int pendingBordereaux = (results[2]).length;
    int pendingBonCommandes = (results[3]).length;
    final factures = results[4];
    int pendingFactures =
        factures.where((f) => _isFactureEnAttente(f.status)).length;
    final paiements = results[5];
    int pendingPaiements = paiements.where((p) => p.isPending).length;
    final depenses = results[6];
    int pendingDepenses = depenses.where((d) => d.status == 'pending').length;
    final salaires = results[7];
    int pendingSalaires = salaires.where((s) => s.status == 'pending').length;
    final reports = results[8];
    int pendingReporting = reports.where((r) => r.status == 'submitted').length;
    final pointages = results[9];
    int pendingPointages =
        pointages.where((p) => p.status.toLowerCase() == 'pending').length;
    final interventions = results[10];
    int pendingInterventions =
        interventions.where((i) => i.status.toLowerCase() == 'pending').length;
    final taxes = results[11];
    int pendingTaxes = taxes.where((t) => t.isPending).length;
    final recruitments = results[12];
    int pendingRecruitments =
        recruitments
            .where(
              (r) => ['draft', 'published'].contains(r.status.toLowerCase()),
            )
            .length;
    final contracts = results[13];
    int pendingContracts =
        contracts
            .where((c) => ['pending', 'draft'].contains(c.status.toLowerCase()))
            .length;
    final leaves = results[14];
    int pendingLeaves =
        leaves
            .where(
              (l) => ['pending', 'submitted'].contains(l.status.toLowerCase()),
            )
            .length;
    final suppliers = results[15];
    int pendingSuppliers =
        suppliers.where((sup) => sup.statut == 'pending').length;
    final stocks = results[16];
    int pendingStocks = stocks.where((st) => st.status == 'pending').length;
    int pendingTasks = (results[17]).length;

    int pendingRegistrations = 0;
    try {
      final res = await ApiService.getPendingRegistrations();
      if (res['success'] == true && res['data'] != null) {
        pendingRegistrations = (res['data'] as List).length;
      }
    } catch (_) {}

    CacheHelper.set('dashboard_patron_pendingClients', pendingClients);
    CacheHelper.set('dashboard_patron_pendingDevis', pendingDevis);
    CacheHelper.set('dashboard_patron_pendingBordereaux', pendingBordereaux);
    CacheHelper.set(
      'dashboard_patron_pendingBonCommandes',
      pendingBonCommandes,
    );
    CacheHelper.set('dashboard_patron_pendingFactures', pendingFactures);
    CacheHelper.set('dashboard_patron_pendingPaiements', pendingPaiements);
    CacheHelper.set('dashboard_patron_pendingDepenses', pendingDepenses);
    CacheHelper.set('dashboard_patron_pendingSalaires', pendingSalaires);
    CacheHelper.set(
      'dashboard_patron_pendingInterventions',
      pendingInterventions,
    );
    CacheHelper.set('dashboard_patron_pendingTaxes', pendingTaxes);

    // File "Urgence & Validations" : premiers éléments par type (congés, dépenses, interventions)
    final queue = <PatronValidationItem>[];
    final pendingLeavesList = leaves
        .where(
          (l) => ['pending', 'submitted'].contains(l.status.toLowerCase()),
        )
        .toList();
    for (var i = 0; i < pendingLeavesList.length && i < 4; i++) {
      final l = pendingLeavesList[i];
      final start = l.startDate;
      final fromTomorrow = start.isAfter(DateTime.now()) &&
          start.difference(DateTime.now()).inDays <= 1;
      queue.add(PatronValidationItem(
        entityType: 'leave',
        entityId: l.id.toString(),
        title: '${l.employeeName} - ${l.totalDays} jour(s)',
        subtitle: fromTomorrow ? 'À partir de demain' : 'À partir du ${DateFormat('dd/MM').format(start)}',
        icon: Icons.beach_access,
        color: DashboardEntityColors.conges,
        route: '/leave/validation',
      ));
    }
    final pendingExpensesList = depenses.where((d) => d.status == 'pending').toList();
    for (var i = 0; i < pendingExpensesList.length && i < 4; i++) {
      final e = pendingExpensesList[i];
      final amount = NumberFormat('#,##0', 'fr_FR').format(e.amount);
      queue.add(PatronValidationItem(
        entityType: 'expense',
        entityId: e.id.toString(),
        title: '${e.title} - $amount FCFA',
        subtitle: 'Dépense en attente',
        icon: Icons.money_off,
        color: DashboardEntityColors.depenses,
        route: '/depenses/validation',
      ));
    }
    final pendingInterventionsList = interventions
        .where((i) => i.status.toLowerCase() == 'pending')
        .toList();
    for (var i = 0; i < pendingInterventionsList.length && i < 4; i++) {
      final inv = pendingInterventionsList[i];
      queue.add(PatronValidationItem(
        entityType: 'intervention',
        entityId: inv.id.toString(),
        title: inv.title,
        subtitle: inv.clientName != null ? '${inv.clientName} - En attente' : 'Technicien en attente de confirmation',
        icon: Icons.build,
        color: DashboardEntityColors.interventions,
        route: '/interventions/validation',
      ));
    }

    // KPIs : CA et dépenses par période (jour, semaine, mois), encaissable
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final startOfMonth = DateTime(now.year, now.month, 1);

    double kpiCaJour = 0.0, kpiCaSemaine = 0.0, kpiCaMois = 0.0;
    double kpiEncaissable = 0.0;
    for (final f in factures) {
      final status = (f.status as String?)?.toLowerCase() ?? '';
      final total = (f.totalAmount is num) ? (f.totalAmount as num).toDouble() : 0.0;
      if (status == 'paid' && f.paidAt != null) {
        final paidAt = f.paidAt is DateTime ? f.paidAt as DateTime : DateTime.tryParse(f.paidAt.toString());
        if (paidAt != null) {
          if (!paidAt.isBefore(startOfDay)) kpiCaJour += total;
          if (!paidAt.isBefore(startOfWeekDay)) kpiCaSemaine += total;
          if (!paidAt.isBefore(startOfMonth)) kpiCaMois += total;
        }
      } else if (status == 'sent' || status == 'draft') {
        kpiEncaissable += total;
      }
    }
    double kpiDepensesJour = 0.0, kpiDepensesSemaine = 0.0, kpiDepensesMois = 0.0;
    for (final d in depenses) {
      if (d.status != 'approved') continue;
      final amount = (d.amount is num) ? (d.amount as num).toDouble() : 0.0;
      DateTime? date = d.approvedAt is DateTime ? d.approvedAt : (d.expenseDate is DateTime ? d.expenseDate : null);
      if (date == null && d.approvedAt != null) date = DateTime.tryParse(d.approvedAt.toString());
      if (date == null && d.expenseDate != null) date = DateTime.tryParse(d.expenseDate.toString());
      if (date != null) {
        if (!date.isBefore(startOfDay)) kpiDepensesJour += amount;
        if (!date.isBefore(startOfWeekDay)) kpiDepensesSemaine += amount;
        if (!date.isBefore(startOfMonth)) kpiDepensesMois += amount;
      }
    }
    final kpiMargeJour = kpiCaJour - kpiDepensesJour;
    final kpiMargeSemaine = kpiCaSemaine - kpiDepensesSemaine;
    final kpiMargeBrute = kpiCaMois - kpiDepensesMois;

    // Dernières factures (3)
    final sortedInvoices = List.from(factures)
      ..sort((a, b) {
        final da = a.invoiceDate is DateTime ? (a.invoiceDate as DateTime) : DateTime.tryParse(a.invoiceDate.toString()) ?? DateTime(0);
        final db = b.invoiceDate is DateTime ? (b.invoiceDate as DateTime) : DateTime.tryParse(b.invoiceDate.toString()) ?? DateTime(0);
        return db.compareTo(da);
      });
    final lastInvoices = sortedInvoices.take(3).map<Map<String, dynamic>>((f) => {
      'id': f.id,
      'clientName': f.clientName ?? '',
      'totalAmount': (f.totalAmount is num) ? (f.totalAmount as num).toDouble() : 0.0,
    }).toList();

    // Alertes stock (rupture ou sous seuil)
    int stockAlertsCount = 0;
    for (final st in stocks) {
      if (st.quantity <= 0 || (st.minQuantity > 0 && st.quantity <= st.minQuantity)) stockAlertsCount++;
    }

    // Répartition interventions pour PieChart
    final Map<String, int> interventionPie = {};
    for (final i in interventions) {
      final key = (i.status as String?)?.toLowerCase() ?? 'other';
      interventionPie[key] = (interventionPie[key] ?? 0) + 1;
    }

    // Rappels / alertes pour inciter à l'action
    final List<String> rappels = [];
    final totalPending = pendingClients + pendingDevis + pendingFactures + pendingDepenses +
        pendingLeaves + pendingInterventions + pendingPointages + pendingReporting;
    if (totalPending > 0) rappels.add('$totalPending élément(s) en attente de validation');
    if (kpiEncaissable > 0) rappels.add('Factures à encaisser : ${NumberFormat('#,##0', 'fr_FR').format(kpiEncaissable)} FCFA');
    if (stockAlertsCount > 0) rappels.add('$stockAlertsCount alerte(s) stock (rupture ou sous seuil)');

    return s.copyWith(
      pendingClients: pendingClients,
      pendingDevis: pendingDevis,
      pendingBordereaux: pendingBordereaux,
      pendingBonCommandes: pendingBonCommandes,
      pendingFactures: pendingFactures,
      pendingPaiements: pendingPaiements,
      pendingDepenses: pendingDepenses,
      pendingSalaires: pendingSalaires,
      pendingReporting: pendingReporting,
      pendingPointages: pendingPointages,
      pendingInterventions: pendingInterventions,
      pendingTaxes: pendingTaxes,
      pendingRecruitments: pendingRecruitments,
      pendingContracts: pendingContracts,
      pendingLeaves: pendingLeaves,
      pendingSuppliers: pendingSuppliers,
      pendingStocks: pendingStocks,
      pendingRegistrations: pendingRegistrations,
      pendingTasks: pendingTasks,
      validationQueue: queue,
      kpiCaJour: kpiCaJour,
      kpiCaSemaine: kpiCaSemaine,
      kpiCaMois: kpiCaMois,
      kpiEncaissable: kpiEncaissable,
      kpiDepensesJour: kpiDepensesJour,
      kpiDepensesSemaine: kpiDepensesSemaine,
      kpiDepensesMois: kpiDepensesMois,
      kpiMargeJour: kpiMargeJour,
      kpiMargeSemaine: kpiMargeSemaine,
      kpiMargeBrute: kpiMargeBrute,
      rappels: rappels,
      lastInvoices: lastInvoices,
      stockAlertsCount: stockAlertsCount,
      interventionPie: interventionPie,
    );
  }

  /// Nombre de clients validés, 0 en cas d'erreur.
  Future<int> _safeClientCount(dynamic clientService) async {
    try {
      final paginated = await clientService.getClientsPaginated(status: 1, page: 1, perPage: 1);
      int total = paginated?.meta.total ?? 0;
      if (total == 0) {
        final list = await clientService.getClients(status: 1);
        total = list.length;
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  Future<PatronDashboardState> _loadPerformanceMetrics(
    PatronDashboardState s,
  ) async {
    try {
      final invoiceService = ref.read(invoiceServiceProvider);
      final employeeService = ref.read(employeeServiceProvider);
      final supplierService = ref.read(supplierServiceProvider);
      final clientService = ref.read(clientServiceProvider);

      final results = await Future.wait([
        _safeList(invoiceService.getAllInvoices()),
        _safeList(employeeService.getEmployees()),
        _safeList(supplierService.getSuppliers()),
        _safeClientCount(clientService),
      ]);

      final factures = results[0] as List;
      double totalRevenue = 0.0;
      for (final f in factures) {
        final status = (f.status as String?)?.toLowerCase().trim() ?? '';
        if (['valide', 'validated', 'approved'].contains(status)) {
          totalRevenue += (f.totalAmount is num) ? (f.totalAmount as num).toDouble() : 0.0;
        }
      }
      final totalEmployees = (results[1] as List).length;
      final totalSuppliers = (results[2] as List).length;
      final validatedClients = results[3] as int;

      CacheHelper.set('dashboard_patron_totalRevenue', totalRevenue);
      CacheHelper.set('dashboard_patron_validatedClients', validatedClients);

      return s.copyWith(
        totalRevenue: totalRevenue,
        totalEmployees: totalEmployees,
        totalSuppliers: totalSuppliers,
        validatedClients: validatedClients,
      );
    } catch (_) {
      return s;
    }
  }

  /// Approuver un élément de la file (swipe droite). Appelle le service adapté puis refresh.
  void setKpiPeriod(String period) {
    final current = state.valueOrNull;
    if (current != null && period != current.kpiPeriod) {
      state = AsyncValue.data(current.copyWith(kpiPeriod: period));
    }
  }

  Future<bool> approveValidationItem(PatronValidationItem item) async {
    try {
      final leaveService = ref.read(leaveServiceProvider);
      final expenseService = ref.read(expenseServiceProvider);
      final interventionService = ref.read(interventionServiceProvider);
      final id = int.tryParse(item.entityId);
      if (id == null) return false;
      switch (item.entityType) {
        case 'leave':
          await leaveService.approveLeaveRequest(id);
          break;
        case 'expense':
          final expense = await expenseService.getExpenseById(id);
          await expenseService.approveExpense(expense.id!);
          break;
        case 'intervention':
          await interventionService.approveIntervention(id);
          break;
        default:
          return false;
      }
      await refresh();
      return true;
    } catch (e) {
      AppLogger.warning('Approbation rapide échouée: $e', tag: 'PATRON_DASHBOARD');
      return false;
    }
  }

  /// Rejeter un élément de la file (swipe gauche).
  Future<bool> rejectValidationItem(PatronValidationItem item, {String? reason}) async {
    try {
      final leaveService = ref.read(leaveServiceProvider);
      final expenseService = ref.read(expenseServiceProvider);
      final interventionService = ref.read(interventionServiceProvider);
      final id = int.tryParse(item.entityId);
      if (id == null) return false;
      switch (item.entityType) {
        case 'leave':
          await leaveService.rejectLeaveRequest(id, rejectionReason: reason ?? 'Rejeté depuis le dashboard');
          break;
        case 'expense':
          await expenseService.rejectExpense(id, reason: reason ?? 'Rejeté depuis le dashboard');
          break;
        case 'intervention':
          await interventionService.rejectIntervention(id, reason: reason ?? 'Rejeté');
          break;
        default:
          return false;
      }
      await refresh();
      return true;
    } catch (e) {
      AppLogger.warning('Rejet rapide échoué: $e', tag: 'PATRON_DASHBOARD');
      return false;
    }
  }

}

final patronDashboardProvider =
    AsyncNotifierProvider<PatronDashboardNotifier, PatronDashboardState>(
      PatronDashboardNotifier.new,
    );

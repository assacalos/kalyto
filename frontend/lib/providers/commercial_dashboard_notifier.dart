import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/providers/commercial_dashboard_state.dart';
import 'package:easyconnect/providers/services_providers.dart';
import 'package:easyconnect/services/session_service.dart';
import 'package:easyconnect/Views/Components/data_chart.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/utils/logger.dart';

/// Notifier qui charge et garde l'état du dashboard commercial.
class CommercialDashboardNotifier extends AsyncNotifier<CommercialDashboardState> {
  Timer? _refreshTimer;
  bool _mounted = true;

  @override
  Future<CommercialDashboardState> build() async {
    _refreshTimer?.cancel();
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
            'Timeout chargement dashboard commercial',
            tag: 'COMMERCIAL_DASHBOARD_RIVERPOD',
          );
        },
      );
    } catch (_) {}
    final current = state.valueOrNull ?? const CommercialDashboardState();
    return current;
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
      AppLogger.info(
        'Token disponible, chargement dashboard commercial',
        tag: 'COMMERCIAL_DASHBOARD_RIVERPOD',
      );
      await refresh();
      return;
    }
    await refresh();
  }

  /// Rafraîchit les compteurs et montants.
  /// [silent] : si true (ex. timer), ne pas afficher l'état chargement pour garder les données visibles.
  Future<void> refresh({bool silent = false}) async {
    final token = SessionService.getTokenSync();
    final user = ref.read(authProvider).user;
    if (token == null || token.isEmpty || user == null) return;

    final previous = state.valueOrNull ?? const CommercialDashboardState();
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
        'Erreur refresh dashboard commercial: $e',
        tag: 'COMMERCIAL_DASHBOARD_RIVERPOD',
      );
      state = AsyncValue.data(previous.copyWith(isLoading: false));
    }
  }

  Future<CommercialDashboardState> _loadAll(
    CommercialDashboardState current,
  ) async {
    final cached = _loadCached();
    CommercialDashboardState s = current.copyWith(
      isLoading: true,
      pendingClients: cached.pendingClients,
      pendingDevis: cached.pendingDevis,
      pendingBordereaux: cached.pendingBordereaux,
      pendingBonCommandes: cached.pendingBonCommandes,
      validatedClients: cached.validatedClients,
      totalRevenue: cached.totalRevenue,
    );

    try {
      final clientService = ref.read(clientServiceProvider);
      final devisService = ref.read(devisServiceProvider);
      final bordereauService = ref.read(bordereauServiceProvider);
      final bonCommandeService = ref.read(bonCommandeServiceProvider);
      final bonCommandeFournisseurService =
          ref.read(bonDeCommandeFournisseurServiceProvider);
      final taskService = ref.read(taskServiceProvider);

      final results = await Future.wait([
        clientService.getClients(),
        devisService.getDevis(),
        bordereauService.getBordereaux(),
        bonCommandeService.getBonCommandes(),
        bonCommandeFournisseurService.getBonDeCommandes(),
      ]);

      final clients = results[0] as List;
      final pendingClientsCount =
          clients.where((c) => c.status == 0 || c.status == null).length;
      final validatedClientsCount =
          clients.where((c) => c.status == 1).length;
      s = s.copyWith(
        pendingClients: pendingClientsCount,
        validatedClients: validatedClientsCount,
      );
      CacheHelper.set(
        'dashboard_commercial_pendingClients',
        pendingClientsCount,
      );
      CacheHelper.set(
        'dashboard_commercial_validatedClients',
        validatedClientsCount,
      );

      final devis = results[1] as List;
      final pendingDevisCount = devis.where((d) => d.status == 1).length;
      s = s.copyWith(
        pendingDevis: pendingDevisCount,
        validatedDevis: devis.length - pendingDevisCount,
      );
      CacheHelper.set('dashboard_commercial_pendingDevis', pendingDevisCount);

      final bordereaux = results[2] as List;
      final pendingBordereauxCount =
          bordereaux.where((b) => b.status == 1).length;
      s = s.copyWith(
        pendingBordereaux: pendingBordereauxCount,
        validatedBordereaux: bordereaux.length - pendingBordereauxCount,
      );
      CacheHelper.set(
        'dashboard_commercial_pendingBordereaux',
        pendingBordereauxCount,
      );

      final bonCommandes = results[3] as List;
      final pendingBonCommandesCount =
          bonCommandes.where((bc) => bc.status == 1).length;
      s = s.copyWith(
        pendingBonCommandes: pendingBonCommandesCount,
        validatedBonCommandes: bonCommandes.length - pendingBonCommandesCount,
      );
      CacheHelper.set(
        'dashboard_commercial_pendingBonCommandes',
        pendingBonCommandesCount,
      );

      final bonCommandesFournisseur = results[4] as List;
      final pendingFournisseurCount = bonCommandesFournisseur.where((bc) {
        final statut = bc.statut?.toString().toLowerCase().trim() ?? '';
        return statut == 'en_attente' || statut == 'pending';
      }).length;
      s = s.copyWith(
        pendingBonCommandesFournisseur: pendingFournisseurCount,
      );

      final taskResult = await taskService.getTasks(
        status: 'pending',
        page: 1,
        perPage: 1,
      );
      if (taskResult['success'] == true) {
        final pagination =
            taskResult['pagination'] as Map<String, dynamic>? ?? {};
        s = s.copyWith(
          pendingTasks: pagination['total'] as int? ?? 0,
        );
      }

      final revenue = devis.fold(0.0, (sum, d) => sum + d.totalTTC);
      final pendingDevisAmount = devis
          .where((d) => d.status == 1)
          .fold(0.0, (sum, d) => sum + d.totalTTC);
      final paidBordereauxAmount = bordereaux
          .where((b) => b.status == 2)
          .fold(0.0, (sum, b) => sum + b.montantTTC);
      s = s.copyWith(
        totalRevenue: revenue,
        pendingDevisAmount: pendingDevisAmount,
        paidBordereauxAmount: paidBordereauxAmount,
      );
      CacheHelper.set('dashboard_commercial_totalRevenue', revenue);

      s = s.copyWith(
        isLoading: false,
        revenueData: const [
          ChartData(1, 85000, "Janvier"),
          ChartData(2, 92000, "Février"),
          ChartData(3, 88000, "Mars"),
          ChartData(4, 95000, "Avril"),
          ChartData(5, 103000, "Mai"),
          ChartData(6, 110000, "Juin"),
        ],
        clientData: const [
          ChartData(1, 35, "Nouveaux"),
          ChartData(2, 25, "Actifs"),
          ChartData(3, 20, "Inactifs"),
          ChartData(4, 10, "Prospects"),
        ],
        devisData: const [
          ChartData(1, 45, "En attente"),
          ChartData(2, 15, "Acceptés"),
          ChartData(3, 8, "Refusés"),
          ChartData(4, 2, "Expirés"),
        ],
        bordereauData: const [
          ChartData(1, 12, "En cours"),
          ChartData(2, 15, "Payés"),
          ChartData(3, 8, "En retard"),
          ChartData(4, 10, "Annulés"),
        ],
      );
    } catch (_) {
      s = s.copyWith(isLoading: false);
    }
    return s;
  }

  CommercialDashboardState _loadCached() {
    return CommercialDashboardState(
      pendingClients:
          CacheHelper.get<int>('dashboard_commercial_pendingClients') ?? 0,
      pendingDevis:
          CacheHelper.get<int>('dashboard_commercial_pendingDevis') ?? 0,
      pendingBordereaux:
          CacheHelper.get<int>('dashboard_commercial_pendingBordereaux') ?? 0,
      pendingBonCommandes:
          CacheHelper.get<int>('dashboard_commercial_pendingBonCommandes') ?? 0,
      validatedClients:
          CacheHelper.get<int>('dashboard_commercial_validatedClients') ?? 0,
      totalRevenue:
          CacheHelper.get<double>('dashboard_commercial_totalRevenue') ?? 0.0,
    );
  }

}

final commercialDashboardProvider = AsyncNotifierProvider<
    CommercialDashboardNotifier, CommercialDashboardState>(
  CommercialDashboardNotifier.new,
);

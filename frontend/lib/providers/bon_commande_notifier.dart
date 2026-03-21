import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/Models/bon_commande_model.dart';
import 'package:easyconnect/Models/client_model.dart';
import 'package:easyconnect/providers/bon_commande_state.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/services/bon_commande_service.dart';
import 'package:easyconnect/services/client_service.dart';
import 'package:easyconnect/services/pdf_service.dart';
import 'package:easyconnect/utils/dashboard_refresh_helper.dart';
import 'package:easyconnect/utils/notification_helper.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/auth_error_handler.dart';
import 'package:easyconnect/utils/app_config.dart';

final bonCommandeProvider =
    NotifierProvider<BonCommandeNotifier, BonCommandeState>(BonCommandeNotifier.new);

class BonCommandeNotifier extends Notifier<BonCommandeState> {
  final BonCommandeService _service = BonCommandeService();
  final ClientService _clientService = ClientService();
  bool _isLoadingInProgress = false;
  Timer? _searchDebounceTimer;

  int get _userId => ref.read(authProvider).user?.id ?? 0;

  @override
  BonCommandeState build() {
    ref.onDispose(() => _searchDebounceTimer?.cancel());
    return const BonCommandeState();
  }

  void setSelectedStatus(int? tabIndex) {
    state = state.copyWith(selectedStatus: tabIndex);
  }

  void setSearchQuery(String query) {
    if (state.searchQuery == query) return;
    _searchDebounceTimer?.cancel();
    state = state.copyWith(searchQuery: query);
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (!_isLoadingInProgress) loadBonCommandes(status: state.currentStatus, forceRefresh: true);
    });
  }

  Future<void> loadBonCommandes({
    int? status,
    bool forceRefresh = false,
    int page = 1,
  }) async {
    if (_isLoadingInProgress) return;
    if (!forceRefresh &&
        state.bonCommandes.isNotEmpty &&
        state.currentStatus == status &&
        state.currentPage == page &&
        page == 1) return;
    _isLoadingInProgress = true;
    state = state.copyWith(currentStatus: status);
    final entityKey = 'bon_commandes_${status ?? 'all'}';
    if (page == 1) {
      state = state.copyWith(isLoading: true);
      final cached = BonCommandeService.getCachedBonCommandes(status);
      if (cached.isNotEmpty && !forceRefresh) {
        state = state.copyWith(bonCommandes: cached, isLoading: false, currentPage: 1);
        _isLoadingInProgress = false;
        return;
      }
      state = state.copyWith(bonCommandes: [], isLoading: false);
    } else {
      state = state.copyWith(isLoadingMore: true);
    }
    try {
      final response = await _service.getBonCommandesPaginated(
        status: status,
        page: page,
        perPage: state.perPage,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
      );
      if (state.currentStatus != status) {
        _isLoadingInProgress = false;
        state = state.copyWith(isLoading: false, isLoadingMore: false);
        return;
      }
      List<BonCommande> newList;
      int newPage = state.currentPage;
      if (page == 1) {
        newList = response.data;
        CacheHelper.set(entityKey, response.data);
        BonCommandeService.saveCachedBonCommandes(response.data, status);
        newPage = 1;
      } else {
        newList = [...state.bonCommandes, ...response.data];
        newPage = response.meta.currentPage;
      }
      state = state.copyWith(
        bonCommandes: newList,
        isLoading: false,
        isLoadingMore: false,
        currentPage: newPage,
        totalPages: response.meta.lastPage,
        totalItems: response.meta.total,
        hasNextPage: response.hasNextPage,
        hasPreviousPage: response.hasPreviousPage,
      );
    } catch (e) {
      AppLogger.error('Erreur API Bons de commande: $e', tag: 'BON_COMMANDE_NOTIFIER');
      if (state.bonCommandes.isEmpty) {
        final fallback = BonCommandeService.getCachedBonCommandes(status);
        if (fallback.isNotEmpty) {
          state = state.copyWith(bonCommandes: fallback, isLoading: false);
        }
        rethrow;
      }
      state = state.copyWith(isLoading: false, isLoadingMore: false);
      rethrow;
    } finally {
      _isLoadingInProgress = false;
    }
  }

  void loadMore() {
    if (state.hasNextPage && !state.isLoading && !state.isLoadingMore) {
      loadBonCommandes(status: state.currentStatus, page: state.currentPage + 1);
    }
  }

  Future<void> loadStats() async {
    try {
      final stats = await _service.getBonCommandeStats();
      state = state.copyWith(
        totalBonCommandes: stats['total'] ?? 0,
        bonCommandesEnvoyes: stats['envoyes'] ?? 0,
        bonCommandesAcceptes: stats['acceptes'] ?? 0,
        bonCommandesRefuses: stats['refuses'] ?? 0,
        bonCommandesLivres: stats['livres'] ?? 0,
        montantTotal: (stats['montant_total'] ?? 0.0).toDouble(),
      );
    } catch (_) {}
  }

  void addSelectedFile(Map<String, dynamic> file) {
    state = state.copyWith(selectedFiles: [...state.selectedFiles, file]);
  }

  void addSelectedFiles(List<Map<String, dynamic>> files) {
    state = state.copyWith(selectedFiles: [...state.selectedFiles, ...files]);
  }

  void removeSelectedFile(int index) {
    if (index < 0 || index >= state.selectedFiles.length) return;
    final l = List<Map<String, dynamic>>.from(state.selectedFiles);
    l.removeAt(index);
    state = state.copyWith(selectedFiles: l);
  }

  Future<bool> createBonCommande() async {
    if (state.isLoading) return false;
    if (state.selectedClient == null) throw Exception('Aucun client sélectionné');
    if (state.selectedClient!.id == null) throw Exception('L\'ID du client est manquant. Veuillez sélectionner un client valide.');
    if (state.selectedFiles.isEmpty) throw Exception('Veuillez ajouter au moins un fichier scanné');
    try {
      state = state.copyWith(isLoading: true);
      final clientId = state.selectedClient!.id!;
      final fichiersPaths = state.selectedFiles.map((f) => f['path'] as String).toList();
      final newBonCommande = BonCommande(
        clientId: clientId,
        commercialId: _userId,
        fichiers: fichiersPaths,
        status: 1,
      );
      final created = await _service.createBonCommande(newBonCommande);
      CacheHelper.clearByPrefix('bon_commandes_');
      const newBonStatus = 1;
      final shouldInsert = state.currentStatus == null || state.currentStatus == newBonStatus;
      if (shouldInsert) {
        state = state.copyWith(bonCommandes: [created, ...state.bonCommandes]);
        BonCommandeService.saveCachedBonCommandes(state.bonCommandes, state.currentStatus);
      }
      if (created.id != null) {
        NotificationHelper.notifySubmission(
          entityType: 'bon_commande',
          entityName: NotificationHelper.getEntityDisplayName('bon_commande', created),
          entityId: created.id.toString(),
          route: NotificationHelper.getEntityRoute('bon_commande', created.id.toString()),
        );
      }
      DashboardRefreshHelper.refreshPatronCounter('bon_commande');
      clearForm();
      return true;
    } catch (e) {
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> updateBonCommande(int bonCommandeId) async {
    if (state.isLoading) return false;
    try {
      state = state.copyWith(isLoading: true);
      final toUpdate = state.bonCommandes.firstWhere((b) => b.id == bonCommandeId);
      final fichiersPaths = state.selectedFiles.isEmpty
          ? toUpdate.fichiers
          : state.selectedFiles.map((f) => f['path'] as String).toList();
      final updated = BonCommande(
        id: bonCommandeId,
        clientId: state.selectedClient?.id ?? toUpdate.clientId,
        commercialId: toUpdate.commercialId,
        fichiers: fichiersPaths,
        status: toUpdate.status,
      );
      await _service.updateBonCommande(updated);
      try {
        await loadBonCommandes();
      } catch (_) {}
      return true;
    } catch (e) {
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> deleteBonCommande(int bonCommandeId) async {
    try {
      state = state.copyWith(isLoading: true);
      final success = await _service.deleteBonCommande(bonCommandeId);
      if (success) {
        state = state.copyWith(bonCommandes: state.bonCommandes.where((b) => b.id != bonCommandeId).toList());
      } else {
        throw Exception('Erreur lors de la suppression');
      }
    } catch (e) {
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> submitBonCommande(int bonCommandeId) async {
    try {
      state = state.copyWith(isLoading: true);
      final success = await _service.submitBonCommande(bonCommandeId);
      if (success) {
        await loadBonCommandes();
        final bc = state.bonCommandes.where((b) => b.id == bonCommandeId).toList();
        if (bc.isNotEmpty) {
          NotificationHelper.notifySubmission(
            entityType: 'bon_commande',
            entityName: NotificationHelper.getEntityDisplayName('bon_commande', bc.first),
            entityId: bonCommandeId.toString(),
            route: NotificationHelper.getEntityRoute('bon_commande', bonCommandeId.toString()),
          );
        }
      } else {
        throw Exception('Erreur lors de la soumission');
      }
    } catch (e) {
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> approveBonCommande(int bonCommandeId) async {
    try {
      state = state.copyWith(isLoading: true);
      CacheHelper.clearByPrefix('bon_commandes_');
      final list = List<BonCommande>.from(state.bonCommandes);
      final idx = list.indexWhere((b) => b.id == bonCommandeId);
      if (idx != -1) {
        final orig = list[idx];
        list[idx] = BonCommande(
          id: orig.id,
          clientId: orig.clientId,
          commercialId: orig.commercialId,
          fichiers: orig.fichiers,
          status: 2,
        );
        state = state.copyWith(bonCommandes: list);
      }
      final success = await _service.approveBonCommande(bonCommandeId);
      if (success) {
        DashboardRefreshHelper.refreshPatronCounter('boncommande');
        DashboardRefreshHelper.refreshCommercialDashboard();
        final bc = state.bonCommandes.where((b) => b.id == bonCommandeId).toList();
        if (bc.isNotEmpty) {
          NotificationHelper.notifyValidation(
            entityType: 'bon_commande',
            entityName: NotificationHelper.getEntityDisplayName('bon_commande', bc.first),
            entityId: bonCommandeId.toString(),
            route: NotificationHelper.getEntityRoute('bon_commande', bonCommandeId.toString()),
            entity: bc.first,
          );
        }
        Future.delayed(const Duration(milliseconds: 500), () => loadBonCommandes(status: state.currentStatus).catchError((_) {}));
      } else {
        await loadBonCommandes(status: state.currentStatus);
        throw Exception('La validation peut avoir réussi. Veuillez vérifier.');
      }
    } catch (e) {
      final s = e.toString().toLowerCase();
      if (s.contains('parsing') || s.contains('json') || s.contains('type') || s.contains('cast') || s.contains('null')) {
        loadBonCommandes(status: state.currentStatus).catchError((_) {});
        return;
      }
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> rejectBonCommande(int bonCommandeId, String commentaire) async {
    try {
      state = state.copyWith(isLoading: true);
      CacheHelper.clearByPrefix('bon_commandes_');
      final list = List<BonCommande>.from(state.bonCommandes);
      final idx = list.indexWhere((b) => b.id == bonCommandeId);
      if (idx != -1) {
        final orig = list[idx];
        list[idx] = BonCommande(
          id: orig.id,
          clientId: orig.clientId,
          commercialId: orig.commercialId,
          fichiers: orig.fichiers,
          status: 3,
        );
        state = state.copyWith(bonCommandes: list);
      }
      final success = await _service.rejectBonCommande(bonCommandeId, commentaire);
      if (success) {
        DashboardRefreshHelper.refreshPatronCounter('boncommande');
        DashboardRefreshHelper.refreshCommercialDashboard();
        final bc = state.bonCommandes.where((b) => b.id == bonCommandeId).toList();
        if (bc.isNotEmpty) {
          NotificationHelper.notifyRejection(
            entityType: 'bon_commande',
            entityName: NotificationHelper.getEntityDisplayName('bon_commande', bc.first),
            entityId: bonCommandeId.toString(),
            reason: commentaire,
            route: NotificationHelper.getEntityRoute('bon_commande', bonCommandeId.toString()),
            entity: bc.first,
          );
        }
        Future.delayed(const Duration(milliseconds: 500), () => loadBonCommandes(status: state.currentStatus).catchError((_) {}));
      } else {
        await loadBonCommandes(status: state.currentStatus);
        throw Exception('Erreur lors du rejet');
      }
    } catch (e) {
      final s = e.toString().toLowerCase();
      if (s.contains('parsing') || s.contains('json') || s.contains('type') || s.contains('cast') || s.contains('null')) {
        loadBonCommandes(status: state.currentStatus).catchError((_) {});
        return;
      }
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> markAsDelivered(int bonCommandeId) async {
    try {
      state = state.copyWith(isLoading: true);
      final success = await _service.markAsDelivered(bonCommandeId);
      if (success) await loadBonCommandes();
      else throw Exception('Erreur lors du marquage comme livré');
    } catch (e) {
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> generateInvoice(int bonCommandeId) async {
    try {
      state = state.copyWith(isLoading: true);
      final success = await _service.generateInvoice(bonCommandeId);
      if (success) await loadBonCommandes();
      else throw Exception('Erreur lors de la génération de la facture');
    } catch (e) {
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadValidatedClients() async {
    state = state.copyWith(isLoadingClients: true);
    final cached = ClientService.getCachedClients(1);
    if (cached.isNotEmpty) {
      state = state.copyWith(clients: cached, isLoadingClients: false);
    } else {
      state = state.copyWith(clients: []);
    }
    try {
      final list = await _clientService.getClients(status: 1);
      state = state.copyWith(clients: list);
    } catch (e) {
      if (state.clients.isEmpty) {
        final fallback = ClientService.getCachedClients(1);
        if (fallback.isNotEmpty) state = state.copyWith(clients: fallback);
        else rethrow;
      }
    } finally {
      state = state.copyWith(isLoadingClients: false);
    }
  }

  void selectClient(Client client) => state = state.copyWith(selectedClient: client);
  void clearSelectedClient() => state = state.copyWith(selectedClient: null);

  void clearForm() {
    state = state.copyWith(selectedClient: null, selectedFiles: []);
  }

  Future<void> generatePDF(int bonCommandeId) async {
    try {
      state = state.copyWith(isLoading: true);
      final list = state.bonCommandes.where((b) => b.id == bonCommandeId).toList();
      if (list.isEmpty) throw Exception('Bon de commande introuvable');
      final bonCommande = list.first;
      final clients = await _clientService.getClients(timeout: AppConfig.extraLongTimeout);
      final clientList = clients.where((c) => c.id == bonCommande.clientId).toList();
      if (clientList.isEmpty) throw Exception('Client introuvable pour ce bon de commande');
      final client = clientList.first;
      await PdfService().generateBonCommandePdf(
        bonCommande: {
          'reference': bonCommande.id != null ? 'BC-${bonCommande.id}' : 'N/A',
          'date_creation': DateTime.now(),
          'montant_ht': 0.0,
          'tva': 0.0,
          'total_ttc': 0.0,
        },
        items: [],
        fournisseur: {},
        client: {
          'nom': client.nom ?? '',
          'prenom': client.prenom ?? '',
          'nom_entreprise': client.nomEntreprise ?? '',
          'email': client.email ?? '',
          'contact': client.contact ?? '',
          'adresse': client.adresse ?? '',
          'numero_contribuable': client.numeroContribuable ?? '',
        },
      );
    } catch (e) {
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

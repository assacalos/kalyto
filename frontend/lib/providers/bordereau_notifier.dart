import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/Models/bordereau_model.dart';
import 'package:easyconnect/Models/client_model.dart';
import 'package:easyconnect/Models/devis_model.dart';
import 'package:easyconnect/providers/bordereau_state.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/services/bordereau_service.dart';
import 'package:easyconnect/services/client_service.dart';
import 'package:easyconnect/services/devis_service.dart';
import 'package:easyconnect/services/pdf_service.dart';
import 'package:easyconnect/utils/dashboard_refresh_helper.dart';
import 'package:easyconnect/utils/notification_helper.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/auth_error_handler.dart';
import 'package:easyconnect/utils/app_config.dart';

final bordereauProvider =
    NotifierProvider<BordereauNotifier, BordereauState>(BordereauNotifier.new);

class BordereauNotifier extends Notifier<BordereauState> {
  final BordereauService _bordereauService = BordereauService();
  final ClientService _clientService = ClientService();
  final DevisService _devisService = DevisService();
  bool _isLoadingInProgress = false;
  Timer? _searchDebounceTimer;

  int get _userId => ref.read(authProvider).user?.id ?? 0;

  @override
  BordereauState build() {
    ref.onDispose(() => _searchDebounceTimer?.cancel());
    return const BordereauState();
  }

  void setSearchQuery(String query) {
    if (state.searchQuery == query) return;
    _searchDebounceTimer?.cancel();
    state = state.copyWith(searchQuery: query);
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (!_isLoadingInProgress) loadBordereaux(status: state.currentStatus, forceRefresh: true);
    });
  }

  Future<void> loadBordereaux({
    int? status,
    bool forceRefresh = false,
    int page = 1,
  }) async {
    if (_isLoadingInProgress) return;
    if (!forceRefresh &&
        state.bordereaux.isNotEmpty &&
        state.currentStatus == status &&
        state.currentPage == page &&
        page == 1) return;
    _isLoadingInProgress = true;
    state = state.copyWith(currentStatus: status);
    final entityKey = 'bordereaux_${status ?? 'all'}';
    if (page == 1) {
      state = state.copyWith(isLoading: true);
      if (!forceRefresh) {
        final cachedData = BordereauService.getCachedBordereaux(status);
        if (cachedData.isNotEmpty) {
          state = state.copyWith(bordereaux: cachedData, isLoading: false, currentPage: 1);
          _isLoadingInProgress = false;
          return;
        }
      }
      state = state.copyWith(bordereaux: [], isLoading: false);
    } else {
      state = state.copyWith(isLoadingMore: true);
    }
    try {
      final response = await _bordereauService.getBordereauxPaginated(
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
      List<Bordereau> newList;
      int newPage = state.currentPage;
      if (page == 1) {
        newList = response.data;
        CacheHelper.set(entityKey, response.data);
        BordereauService.saveBordereauxToHive(response.data, status);
        newPage = 1;
      } else {
        newList = [...state.bordereaux, ...response.data];
        newPage = response.meta.currentPage;
      }
      state = state.copyWith(
        bordereaux: newList,
        isLoading: false,
        isLoadingMore: false,
        currentPage: newPage,
        totalPages: response.meta.lastPage,
        totalItems: response.meta.total,
        hasNextPage: response.hasNextPage,
        hasPreviousPage: response.hasPreviousPage,
      );
    } catch (e) {
      if (AuthErrorHandler.shouldIgnoreError(e)) {
        _isLoadingInProgress = false;
        state = state.copyWith(isLoading: false, isLoadingMore: false);
        return;
      }
      final err = e.toString().toLowerCase();
      if (err.contains('401') || err.contains('unauthorized') || err.contains('non autorisé')) {
        _isLoadingInProgress = false;
        state = state.copyWith(isLoading: false, isLoadingMore: false);
        return;
      }
      AppLogger.error('Erreur API Bordereaux: $e', tag: 'BORDEREAU_NOTIFIER');
      if (state.bordereaux.isEmpty) {
        final fallback = BordereauService.getCachedBordereaux(status);
        if (fallback.isNotEmpty) {
          state = state.copyWith(bordereaux: fallback, isLoading: false);
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
      loadBordereaux(status: state.currentStatus, page: state.currentPage + 1);
    }
  }

  Future<void> loadByStatus(int index) async {
    final status = index == 0 ? 1 : index == 1 ? 2 : 3;
    await loadBordereaux(status: status, forceRefresh: false);
  }

  Future<void> loadStats() async {
    try {
      final stats = await _bordereauService.getBordereauStats();
      state = state.copyWith(
        totalBordereaux: stats['total'] ?? 0,
        bordereauEnvoyes: stats['envoyes'] ?? 0,
        bordereauAcceptes: stats['acceptes'] ?? 0,
        bordereauRefuses: stats['refuses'] ?? 0,
        montantTotal: (stats['montant_total'] ?? 0.0).toDouble(),
      );
    } catch (_) {}
  }

  Future<bool> createBordereau(Map<String, dynamic> data) async {
    if (state.isLoading) return false;
    if (state.selectedClient == null) throw Exception('Aucun client sélectionné');
    if (state.items.isEmpty) throw Exception('Aucun article ajouté au bordereau');
    try {
      state = state.copyWith(isLoading: true);
      final reference = state.selectedDevis != null && state.generatedReference.isNotEmpty
          ? state.generatedReference
          : data['reference'] as String;
      DateTime? parseDateLivraison(dynamic v) {
        if (v == null) return null;
        if (v is DateTime) return v;
        if (v is String && v.isNotEmpty) {
          try {
            return DateTime.parse(v);
          } catch (_) {}
        }
        return null;
      }
      final newBordereau = Bordereau(
        clientId: state.selectedClient!.id!,
        devisId: state.selectedDevis?.id,
        reference: reference,
        titre: data['titre']?.toString(),
        dateCreation: DateTime.now(),
        notes: data['notes'],
        status: 1,
        items: state.items,
        commercialId: _userId,
        etatLivraison: data['etat_livraison']?.toString(),
        garantie: data['garantie']?.toString(),
        dateLivraison: parseDateLivraison(data['date_livraison']),
      );
      final createdBordereau = await _bordereauService.createBordereau(newBordereau);
      if (createdBordereau.id == null) {
        throw Exception('Le bordereau a été créé mais sans ID. Veuillez réessayer.');
      }
      CacheHelper.clearByPrefix('bordereaux_');
      await BordereauService.clearBordereauxHiveCache();
      const newBordereauStatus = 1;
      final shouldInsert = state.currentStatus == null || state.currentStatus == newBordereauStatus;
      if (shouldInsert) {
        final fullList = [createdBordereau, ...state.bordereaux];
        state = state.copyWith(bordereaux: fullList);
        BordereauService.saveBordereauxToHive(state.bordereaux, state.currentStatus);
      }
      if (createdBordereau.id != null) {
        NotificationHelper.notifySubmission(
          entityType: 'bordereau',
          entityName: NotificationHelper.getEntityDisplayName('bordereau', createdBordereau),
          entityId: createdBordereau.id.toString(),
          route: NotificationHelper.getEntityRoute('bordereau', createdBordereau.id.toString()),
        );
      }
      DashboardRefreshHelper.refreshPatronCounter('bordereau');
      clearForm();
      return true;
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('parsing') || errorStr.contains('json') || errorStr.contains('type') || errorStr.contains('cast') || errorStr.contains('null')) {
        return false;
      }
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> updateBordereau(int bordereauId, Map<String, dynamic> data) async {
    if (state.isLoading) return false;
    try {
      state = state.copyWith(isLoading: true);
      final bordereauToUpdate = state.bordereaux.firstWhere((b) => b.id == bordereauId);
      DateTime? parseDate(dynamic v) {
        if (v == null) return null;
        if (v is DateTime) return v;
        if (v is String && v.isNotEmpty) {
          try {
            return DateTime.parse(v);
          } catch (_) {}
        }
        return null;
      }
      final updatedBordereau = Bordereau(
        id: bordereauId,
        clientId: bordereauToUpdate.clientId,
        devisId: bordereauToUpdate.devisId,
        reference: (data['reference'] as String?) ?? bordereauToUpdate.reference,
        titre: data['titre'] ?? bordereauToUpdate.titre,
        dateCreation: bordereauToUpdate.dateCreation,
        dateValidation: bordereauToUpdate.dateValidation,
        notes: data['notes'] ?? bordereauToUpdate.notes,
        status: bordereauToUpdate.status,
        items: state.items.isEmpty ? bordereauToUpdate.items : state.items,
        commercialId: bordereauToUpdate.commercialId,
        commentaireRejet: bordereauToUpdate.commentaireRejet,
        etatLivraison: data['etat_livraison'] ?? bordereauToUpdate.etatLivraison,
        garantie: data['garantie'] ?? bordereauToUpdate.garantie,
        dateLivraison: parseDate(data['date_livraison']) ?? bordereauToUpdate.dateLivraison,
      );
      await _bordereauService.updateBordereau(updatedBordereau);
      try {
        await loadBordereaux();
      } catch (_) {}
      return true;
    } catch (e) {
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> deleteBordereau(int bordereauId) async {
    try {
      state = state.copyWith(isLoading: true);
      final success = await _bordereauService.deleteBordereau(bordereauId);
      if (success) {
        state = state.copyWith(bordereaux: state.bordereaux.where((b) => b.id != bordereauId).toList());
      } else {
        throw Exception('Erreur lors de la suppression');
      }
    } catch (e) {
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> submitBordereau(int bordereauId) async {
    try {
      state = state.copyWith(isLoading: true);
      final success = await _bordereauService.submitBordereau(bordereauId);
      if (success) {
        await loadBordereaux();
        final bordereau = state.bordereaux.where((b) => b.id == bordereauId).toList();
        if (bordereau.isNotEmpty) {
          NotificationHelper.notifySubmission(
            entityType: 'bordereau',
            entityName: NotificationHelper.getEntityDisplayName('bordereau', bordereau.first),
            entityId: bordereauId.toString(),
            route: NotificationHelper.getEntityRoute('bordereau', bordereauId.toString()),
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

  Future<void> approveBordereau(int bordereauId) async {
    bool validationSucceeded = false;
    try {
      state = state.copyWith(isLoading: true);
      CacheHelper.clearByPrefix('bordereaux_');
      await BordereauService.clearBordereauxHiveCache();
      final bordereauList = List<Bordereau>.from(state.bordereaux);
      final idx = bordereauList.indexWhere((b) => b.id == bordereauId);
      Bordereau? originalBordereau;
      if (idx != -1) {
        originalBordereau = bordereauList[idx];
        if (state.currentStatus == 1) {
          bordereauList.removeAt(idx);
        } else {
          bordereauList[idx] = Bordereau(
            id: originalBordereau.id,
            reference: originalBordereau.reference,
            clientId: originalBordereau.clientId,
            commercialId: originalBordereau.commercialId,
            devisId: originalBordereau.devisId,
            dateCreation: originalBordereau.dateCreation,
            dateValidation: originalBordereau.dateValidation,
            notes: originalBordereau.notes,
            status: 2,
            items: originalBordereau.items,
          );
        }
        state = state.copyWith(bordereaux: bordereauList);
      }
      try {
        final success = await _bordereauService.approveBordereau(bordereauId);
        if (success) {
          validationSucceeded = true;
          DashboardRefreshHelper.refreshPatronCounter('bordereau');
          DashboardRefreshHelper.refreshCommercialDashboard();
          final b = state.bordereaux.where((x) => x.id == bordereauId).toList();
          if (b.isNotEmpty) {
            NotificationHelper.notifyValidation(
              entityType: 'bordereau',
              entityName: NotificationHelper.getEntityDisplayName('bordereau', b.first),
              entityId: bordereauId.toString(),
              route: NotificationHelper.getEntityRoute('bordereau', bordereauId.toString()),
              entity: b.first,
            );
          }
          Future.delayed(const Duration(milliseconds: 500), () {
            loadBordereaux(status: state.currentStatus).catchError((_) {});
          });
        } else {
          await loadBordereaux(status: state.currentStatus);
          throw Exception('Erreur lors de l\'approbation - La réponse du serveur indique un échec');
        }
      } catch (e) {
        if (originalBordereau != null) {
          await loadBordereaux(status: state.currentStatus);
        }
        if (!validationSucceeded) rethrow;
      }
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('parsing') || errorStr.contains('json') || errorStr.contains('type') || errorStr.contains('cast') || errorStr.contains('null')) {
        loadBordereaux(status: state.currentStatus).catchError((_) {});
        return;
      }
      if (!validationSucceeded) rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> rejectBordereau(int bordereauId, String commentaire) async {
    try {
      state = state.copyWith(isLoading: true);
      final bordereauList = List<Bordereau>.from(state.bordereaux);
      final idx = bordereauList.indexWhere((b) => b.id == bordereauId);
      Bordereau? originalBordereau;
      if (idx != -1) {
        originalBordereau = bordereauList[idx];
        if (state.currentStatus == 1) {
          bordereauList.removeAt(idx);
        } else {
          bordereauList[idx] = Bordereau(
            id: originalBordereau.id,
            reference: originalBordereau.reference,
            titre: originalBordereau.titre,
            clientId: originalBordereau.clientId,
            commercialId: originalBordereau.commercialId,
            devisId: originalBordereau.devisId,
            dateCreation: originalBordereau.dateCreation,
            dateValidation: originalBordereau.dateValidation,
            notes: originalBordereau.notes,
            status: 3,
            items: originalBordereau.items,
            commentaireRejet: commentaire,
            etatLivraison: originalBordereau.etatLivraison,
            garantie: originalBordereau.garantie,
            dateLivraison: originalBordereau.dateLivraison,
          );
        }
        state = state.copyWith(bordereaux: bordereauList);
      }
      try {
        final success = await _bordereauService.rejectBordereau(bordereauId, commentaire);
        if (success) {
          await BordereauService.clearBordereauxHiveCache();
          loadBordereaux(status: state.currentStatus).catchError((_) {});
          DashboardRefreshHelper.refreshPatronCounter('bordereau');
          DashboardRefreshHelper.refreshCommercialDashboard();
          final b = state.bordereaux.where((x) => x.id == bordereauId).toList();
          final bordereau = b.isNotEmpty ? b.first : originalBordereau;
          if (bordereau != null) {
            NotificationHelper.notifyRejection(
              entityType: 'bordereau',
              entityName: NotificationHelper.getEntityDisplayName('bordereau', bordereau),
              entityId: bordereauId.toString(),
              reason: commentaire,
              route: NotificationHelper.getEntityRoute('bordereau', bordereauId.toString()),
              entity: bordereau,
            );
          }
        } else {
          throw Exception('Erreur lors du rejet - La réponse du serveur indique un échec');
        }
      } catch (e) {
        rethrow;
      }
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('parsing') || errorStr.contains('json') || errorStr.contains('type') || errorStr.contains('cast') || errorStr.contains('null')) {
        loadBordereaux(status: state.currentStatus).catchError((_) {});
        return;
      }
      if (errorStr.contains('401') || errorStr.contains('403') || errorStr.contains('unauthorized') || errorStr.contains('forbidden')) {
        rethrow;
      }
      loadBordereaux(status: state.currentStatus).catchError((_) {});
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void addItem(BordereauItem item) => state = state.copyWith(items: [...state.items, item]);
  void removeItem(int index) {
    final l = List<BordereauItem>.from(state.items);
    l.removeAt(index);
    state = state.copyWith(items: l);
  }
  void updateItem(int index, BordereauItem item) {
    final l = List<BordereauItem>.from(state.items);
    l[index] = item;
    state = state.copyWith(items: l);
  }
  void clearItems() => state = state.copyWith(items: []);

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
        if (fallback.isNotEmpty) {
          state = state.copyWith(clients: fallback);
        } else {
          rethrow;
        }
      }
    } finally {
      state = state.copyWith(isLoadingClients: false);
    }
  }

  void selectClient(Client client) {
    state = state.copyWith(selectedClient: client);
    onClientChanged(client);
  }

  void clearSelectedClient() => state = state.copyWith(selectedClient: null);

  void clearForm() {
    state = state.copyWith(selectedClient: null, selectedDevis: null, availableDevis: [], items: [], generatedReference: '');
  }

  Future<void> loadValidatedDevisForClient(int clientId) async {
    state = state.copyWith(isLoadingDevis: true);
    final cached = DevisService.getCachedDevis(2);
    final cachedForClient = cached.where((d) => d.clientId == clientId).toList();
    if (cachedForClient.isNotEmpty) {
      state = state.copyWith(availableDevis: cachedForClient, isLoadingDevis: false);
    } else {
      state = state.copyWith(availableDevis: []);
    }
    try {
      final devis = await _devisService.getDevis(status: 2, clientId: clientId);
      state = state.copyWith(availableDevis: devis);
    } catch (e) {
      if (state.availableDevis.isEmpty) {
        final fallback = DevisService.getCachedDevis(2).where((d) => d.clientId == clientId).toList();
        if (fallback.isNotEmpty) {
          state = state.copyWith(availableDevis: fallback);
        } else {
          rethrow;
        }
      }
    } finally {
      state = state.copyWith(isLoadingDevis: false);
    }
  }

  Future<String> generateBordereauReference(int? devisId) async {
    if (devisId == null) return 'BL-${DateTime.now().millisecondsSinceEpoch}';
    final devis = state.selectedDevis;
    if (devis == null) return 'BL-${DateTime.now().millisecondsSinceEpoch}';
    await loadBordereaux();
    final existingBordereaux = state.bordereaux.where((b) => b.devisId == devisId).toList();
    final increment = existingBordereaux.length + 1;
    return '${devis.reference}-BL$increment';
  }

  Future<void> selectDevis(Devis devis) async {
    state = state.copyWith(selectedDevis: devis);
    final ref = await generateBordereauReference(devis.id);
    state = state.copyWith(generatedReference: ref);
    final items = <BordereauItem>[];
    for (final devisItem in devis.items) {
      items.add(BordereauItem(
        reference: devisItem.reference,
        designation: devisItem.designation,
        unite: 'unité',
        quantite: devisItem.quantite,
        description: 'Basé sur le devis ${devis.reference}',
      ));
    }
    state = state.copyWith(items: items);
  }

  void clearSelectedDevis() {
    state = state.copyWith(selectedDevis: null, generatedReference: '', items: []);
  }

  void onClientChanged(Client? client) {
    if (client != null) {
      loadValidatedDevisForClient(client.id!);
    } else {
      state = state.copyWith(availableDevis: [], selectedDevis: null, items: []);
    }
  }

  Future<void> generatePDF(int bordereauId) async {
    try {
      state = state.copyWith(isLoading: true);
      final bordereauList = state.bordereaux.where((b) => b.id == bordereauId).toList();
      if (bordereauList.isEmpty) throw Exception('Bordereau introuvable');
      final bordereau = bordereauList.first;
      final clients = await _clientService.getClients(timeout: AppConfig.extraLongTimeout);
      final clientList = clients.where((c) => c.id == bordereau.clientId).toList();
      if (clientList.isEmpty) throw Exception('Client introuvable pour ce bordereau');
      final client = clientList.first;
      final itemsMap = bordereau.items.map((item) => {
        'reference': item.reference ?? '',
        'designation': item.designation,
        'quantite': item.quantite,
      }).toList();
      await PdfService().generateBordereauPdf(
        bordereau: {
          'reference': bordereau.reference,
          'titre': bordereau.titre,
          'date_creation': bordereau.dateCreation,
          'montant_ht': bordereau.montantHT,
          'total_ttc': bordereau.montantTTC,
          'date_livraison': bordereau.dateLivraison,
          'garantie': bordereau.garantie,
        },
        items: itemsMap,
        client: {
          'nom': client.nom ?? '',
          'prenom': client.prenom ?? '',
          'nom_entreprise': client.nomEntreprise ?? '',
          'email': client.email ?? '',
          'contact': client.contact ?? '',
          'adresse': client.adresse ?? '',
          'numero_contribuable': client.numeroContribuable ?? '',
        },
        commercial: {'nom': 'Commercial', 'prenom': '', 'email': ''},
      );
    } catch (e) {
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

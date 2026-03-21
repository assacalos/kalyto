import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/Models/devis_model.dart';
import 'package:easyconnect/Models/client_model.dart';
import 'package:easyconnect/providers/devis_state.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/services/devis_service.dart';
import 'package:easyconnect/services/client_service.dart';
import 'package:easyconnect/services/pdf_service.dart';
import 'package:easyconnect/utils/dashboard_refresh_helper.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/notification_helper.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/utils/reference_generator.dart';
import 'package:easyconnect/utils/app_config.dart';

final devisProvider =
    NotifierProvider<DevisNotifier, DevisState>(DevisNotifier.new);

class DevisNotifier extends Notifier<DevisState> {
  final DevisService _devisService = DevisService();
  final ClientService _clientService = ClientService();
  bool _isLoadingInProgress = false;
  Timer? _searchDebounceTimer;

  int get _userId => ref.read(authProvider).user?.id ?? 0;

  @override
  DevisState build() {
    ref.onDispose(() => _searchDebounceTimer?.cancel());
    return const DevisState();
  }

  void setSearchQuery(String query) {
    if (state.searchQuery == query) return;
    _searchDebounceTimer?.cancel();
    state = state.copyWith(searchQuery: query);
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (!_isLoadingInProgress) loadDevis(status: state.currentStatus, forceRefresh: true);
    });
  }

  Future<void> loadDevis({int? status, bool forceRefresh = false, int page = 1}) async {
    if (_isLoadingInProgress) return;
    if (!forceRefresh &&
        state.devis.isNotEmpty &&
        state.currentStatus == status &&
        state.currentPage == page &&
        page == 1) return;
    _isLoadingInProgress = true;
    state = state.copyWith(currentStatus: status);
    final entityKey = 'devis_${status ?? 'all'}';
    if (page == 1) {
      state = state.copyWith(isLoading: true);
      if (!forceRefresh) {
        final cached = DevisService.getCachedDevis(status);
        if (cached.isNotEmpty) {
          state = state.copyWith(devis: cached, isLoading: false, currentPage: 1);
          _isLoadingInProgress = false;
          return;
        }
      }
      state = state.copyWith(devis: [], isLoading: false);
    } else {
      state = state.copyWith(isLoadingMore: true);
    }
    try {
      final response = await _devisService.getDevisPaginated(
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
      List<Devis> newList;
      int newPage = state.currentPage;
      if (page == 1) {
        newList = response.data;
        CacheHelper.set(entityKey, response.data);
        DevisService.saveDevisToHive(response.data, status);
        newPage = 1;
      } else {
        newList = [...state.devis, ...response.data];
        newPage = response.meta.currentPage;
      }
      state = state.copyWith(
        devis: newList,
        isLoading: false,
        isLoadingMore: false,
        currentPage: newPage,
        totalPages: response.meta.lastPage,
        totalItems: response.meta.total,
        hasNextPage: response.hasNextPage,
        hasPreviousPage: response.hasPreviousPage,
      );
    } catch (e) {
      AppLogger.error('Erreur API Devis: $e', tag: 'DEVIS_NOTIFIER');
      if (state.devis.isEmpty) {
        final fallback = DevisService.getCachedDevis(status);
        if (fallback.isNotEmpty) state = state.copyWith(devis: fallback, isLoading: false);
      }
      state = state.copyWith(isLoading: false, isLoadingMore: false);
      rethrow;
    } finally {
      _isLoadingInProgress = false;
    }
  }

  void loadMore() {
    if (state.hasNextPage && !state.isLoading && !state.isLoadingMore) {
      loadDevis(status: state.currentStatus, page: state.currentPage + 1);
    }
  }

  Future<void> loadStats() async {
    try {
      final stats = await _devisService.getDevisStats();
      state = state.copyWith(
        totalDevis: stats['total'] ?? 0,
        devisEnvoyes: stats['envoyes'] ?? 0,
        devisAcceptes: stats['acceptes'] ?? 0,
        devisRefuses: stats['refuses'] ?? 0,
        tauxConversion: (stats['taux_conversion'] ?? 0.0).toDouble(),
        montantTotal: (stats['montant_total'] ?? 0.0).toDouble(),
      );
    } catch (_) {}
  }

  Future<bool> createDevis(Map<String, dynamic> data) async {
    if (state.isLoading) return false;
    if (state.selectedClient == null || state.selectedClient!.id == null) {
      throw Exception('Veuillez sélectionner un client valide');
    }
    if (state.items.isEmpty) throw Exception('Veuillez ajouter au moins un article');
    try {
      state = state.copyWith(isLoading: true);
      final newDevis = Devis(
        clientId: state.selectedClient!.id!,
        reference: data['reference'] as String,
        dateCreation: DateTime.now(),
        dateValidite: data['date_validite'] as DateTime?,
        notes: data['notes'] as String?,
        status: 1,
        items: state.items,
        remiseGlobale: data['remise_globale'] as double?,
        tva: data['tva'] as double?,
        conditions: data['conditions'] as String?,
        commercialId: _userId,
        titre: data['titre'] as String?,
        delaiLivraison: data['delai_livraison'] as String?,
        garantie: data['garantie'] as String?,
      );
      final created = await _devisService.createDevis(newDevis);
      CacheHelper.clearByPrefix('devis_');
      const newStatus = 1;
      final shouldInsert = state.currentStatus == null || state.currentStatus == newStatus;
      if (created.id != null && shouldInsert) {
        final toAdd = Devis(
          id: created.id,
          clientId: created.clientId,
          reference: created.reference,
          dateCreation: created.dateCreation,
          dateValidite: created.dateValidite,
          notes: created.notes,
          status: 1,
          items: created.items,
          remiseGlobale: created.remiseGlobale,
          tva: created.tva,
          conditions: created.conditions,
          commercialId: _userId,
          titre: created.titre,
          delaiLivraison: created.delaiLivraison,
          garantie: created.garantie,
        );
        if (!state.devis.any((d) => d.id == toAdd.id)) {
          state = state.copyWith(devis: [toAdd, ...state.devis]);
          DevisService.saveDevisToHive(state.devis, state.currentStatus);
        }
      }
      DashboardRefreshHelper.refreshPatronCounter('devis');
      if (created.id != null) {
        NotificationHelper.notifySubmission(
          entityType: 'devis',
          entityName: NotificationHelper.getEntityDisplayName('devis', created),
          entityId: created.id.toString(),
          route: NotificationHelper.getEntityRoute('devis', created.id.toString()),
        );
      }
      clearForm();
      return true;
    } catch (e) {
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> updateDevis(int devisId, Map<String, dynamic> data) async {
    if (state.isLoading) return false;
    try {
      state = state.copyWith(isLoading: true);
      final devisToUpdate = state.devis.firstWhere((d) => d.id == devisId);
      final updated = Devis(
        id: devisId,
        clientId: devisToUpdate.clientId,
        reference: (data['reference'] as String?) ?? devisToUpdate.reference,
        dateCreation: devisToUpdate.dateCreation,
        dateValidite: data['date_validite'] as DateTime? ?? devisToUpdate.dateValidite,
        notes: data['notes'] as String? ?? devisToUpdate.notes,
        status: devisToUpdate.status,
        items: state.items.isEmpty ? devisToUpdate.items : state.items,
        remiseGlobale: data['remise_globale'] as double? ?? devisToUpdate.remiseGlobale,
        tva: data['tva'] as double? ?? devisToUpdate.tva,
        conditions: data['conditions'] as String? ?? devisToUpdate.conditions,
        commercialId: devisToUpdate.commercialId,
        titre: data['titre'] as String? ?? devisToUpdate.titre,
        delaiLivraison: data['delai_livraison'] as String? ?? devisToUpdate.delaiLivraison,
        garantie: data['garantie'] as String? ?? devisToUpdate.garantie,
      );
      await _devisService.updateDevis(updated);
      try {
        await loadDevis();
      } catch (_) {}
      return true;
    } catch (e) {
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> deleteDevis(int devisId) async {
    try {
      state = state.copyWith(isLoading: true);
      final success = await _devisService.deleteDevis(devisId);
      if (success) {
        state = state.copyWith(devis: state.devis.where((d) => d.id != devisId).toList());
      } else {
        throw Exception('Erreur lors de la suppression');
      }
    } catch (e) {
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> sendDevis(int devisId) async {
    try {
      state = state.copyWith(isLoading: true);
      final success = await _devisService.sendDevis(devisId);
      if (success) await loadDevis();
      else throw Exception('Erreur lors de l\'envoi');
    } catch (e) {
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> acceptDevis(int devisId) async {
    try {
      state = state.copyWith(isLoading: true);
      final devisList = List<Devis>.from(state.devis);
      final idx = devisList.indexWhere((d) => d.id == devisId);
      Devis? original;
      if (idx != -1) {
        original = devisList[idx];
        devisList[idx] = Devis(
          id: original.id,
          clientId: original.clientId,
          reference: original.reference,
          dateCreation: original.dateCreation,
          dateValidite: original.dateValidite,
          notes: original.notes,
          status: 2,
          items: original.items,
          remiseGlobale: original.remiseGlobale,
          tva: original.tva,
          conditions: original.conditions,
          commercialId: original.commercialId,
          submittedBy: original.submittedBy,
          rejectionComment: original.rejectionComment,
          submittedAt: original.submittedAt,
          validatedAt: DateTime.now(),
          titre: original.titre,
          delaiLivraison: original.delaiLivraison,
          garantie: original.garantie,
        );
        state = state.copyWith(devis: devisList);
      }
      final success = await _devisService.acceptDevis(devisId);
      if (success) {
        CacheHelper.clearByPrefix('devis_');
        CacheHelper.clearByPrefix('dashboard_');
        await DevisService.clearDevisHiveCache();
        DashboardRefreshHelper.refreshPatronCounter('devis');
        DashboardRefreshHelper.refreshCommercialDashboard();
        if (original != null) {
          NotificationHelper.notifyValidation(
            entityType: 'devis',
            entityName: NotificationHelper.getEntityDisplayName('devis', original),
            entityId: devisId.toString(),
            route: NotificationHelper.getEntityRoute('devis', devisId.toString()),
            entity: original,
          );
        }
        Future.delayed(const Duration(milliseconds: 500), () => loadDevis(status: null, forceRefresh: true).catchError((_) {}));
      } else {
        if (original != null && idx != -1 && idx < state.devis.length) {
          final restore = List<Devis>.from(state.devis);
          restore[idx] = original;
          state = state.copyWith(devis: restore);
        }
        throw Exception('La validation peut avoir réussi. Veuillez vérifier.');
      }
    } catch (e) {
      final s = e.toString().toLowerCase();
      if (s.contains('parsing') || s.contains('json') || s.contains('type') || s.contains('cast') || s.contains('null')) {
        loadDevis().catchError((_) {});
        return;
      }
      if (s.contains('401') || s.contains('403') || s.contains('unauthorized') || s.contains('forbidden')) rethrow;
      loadDevis().catchError((_) {});
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> rejectDevis(int devisId, String commentaire) async {
    try {
      state = state.copyWith(isLoading: true);
      final devisList = List<Devis>.from(state.devis);
      final idx = devisList.indexWhere((d) => d.id == devisId);
      Devis? original;
      if (idx != -1) {
        original = devisList[idx];
        if (state.currentStatus == 1) {
          devisList.removeAt(idx);
        } else {
          devisList[idx] = Devis(
            id: original.id,
            clientId: original.clientId,
            reference: original.reference,
            dateCreation: original.dateCreation,
            dateValidite: original.dateValidite,
            notes: original.notes,
            status: 3,
            items: original.items,
            remiseGlobale: original.remiseGlobale,
            tva: original.tva,
            conditions: original.conditions,
            commercialId: original.commercialId,
            titre: original.titre,
            delaiLivraison: original.delaiLivraison,
            garantie: original.garantie,
          );
        }
        state = state.copyWith(devis: devisList);
      }
      final success = await _devisService.rejectDevis(devisId, commentaire);
      if (success) {
        CacheHelper.clearByPrefix('devis_');
        CacheHelper.clearByPrefix('dashboard_');
        await DevisService.clearDevisHiveCache();
        DashboardRefreshHelper.refreshPatronCounter('devis');
        DashboardRefreshHelper.refreshCommercialDashboard();
        if (original != null) {
          NotificationHelper.notifyRejection(
            entityType: 'devis',
            entityName: NotificationHelper.getEntityDisplayName('devis', original),
            entityId: devisId.toString(),
            reason: commentaire,
            route: NotificationHelper.getEntityRoute('devis', devisId.toString()),
            entity: original,
          );
        }
        loadDevis(status: state.currentStatus).catchError((_) {});
      } else {
        if (original != null && idx != -1) {
          final restore = List<Devis>.from(state.devis);
          if (idx < restore.length) restore.insert(idx, original);
          else restore.add(original);
          state = state.copyWith(devis: restore);
        }
        throw Exception('Erreur lors du rejet du devis');
      }
    } catch (e) {
      final s = e.toString().toLowerCase();
      if (s.contains('parsing') || s.contains('json') || s.contains('type') || s.contains('cast') || s.contains('null')) {
        loadDevis().catchError((_) {});
        return;
      }
      if (s.contains('401') || s.contains('403') || s.contains('unauthorized') || s.contains('forbidden')) rethrow;
      loadDevis().catchError((_) {});
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void addItem(DevisItem item) => state = state.copyWith(items: [...state.items, item]);
  void removeItem(int index) {
    final l = List<DevisItem>.from(state.items);
    l.removeAt(index);
    state = state.copyWith(items: l);
  }
  void updateItem(int index, DevisItem item) {
    final l = List<DevisItem>.from(state.items);
    l[index] = item;
    state = state.copyWith(items: l);
  }
  void clearItems() => state = state.copyWith(items: []);

  Future<void> loadValidatedClients() async {
    state = state.copyWith(isLoadingClients: true);
    final cached = ClientService.getCachedClients(1);
    if (cached.isNotEmpty) {
      state = state.copyWith(clients: cached, isLoadingClients: false);
      return;
    }
    state = state.copyWith(clients: []);
    try {
      final list = await _clientService.getClients(status: 1);
      state = state.copyWith(clients: list.where((c) => c.status == 1).toList());
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

  Future<void> searchClients(String query) async {
    if (query.isEmpty) {
      await loadValidatedClients();
      return;
    }
    final cached = ClientService.getCachedClients(1);
    List<Client> validated = cached.isNotEmpty ? List.from(cached) : List.from(state.clients);
    if (validated.isEmpty) {
      await loadValidatedClients();
      validated = List.from(state.clients);
    }
    final q = query.toLowerCase();
    state = state.copyWith(
      clients: validated.where((c) {
        final nom = (c.nom ?? '').toLowerCase();
        final email = (c.email ?? '').toLowerCase();
        return nom.contains(q) || email.contains(q);
      }).toList(),
    );
  }

  void selectClient(Client client) => state = state.copyWith(selectedClient: client);
  void clearSelectedClient() => state = state.copyWith(selectedClient: null);

  Future<String> generateReference() async {
    await loadDevis();
    final existing = state.devis.map((d) => d.reference).where((r) => r.isNotEmpty).toList();
    return ReferenceGenerator.generateReferenceWithIncrement('DEV', existing);
  }

  Future<void> initializeGeneratedReference() async {
    if (state.generatedReference.isEmpty) {
      state = state.copyWith(generatedReference: await generateReference());
    }
  }

  void clearForm() {
    state = state.copyWith(selectedClient: null, items: [], generatedReference: '');
    initializeGeneratedReference();
  }

  Future<void> generatePDF(int devisId) async {
    try {
      state = state.copyWith(isLoading: true);
      final selectedDevis = state.devis.where((d) => d.id == devisId).toList();
      if (selectedDevis.isEmpty) throw Exception('Devis introuvable');
      final devis = selectedDevis.first;
      final clientsList = await _clientService.getClients(timeout: AppConfig.extraLongTimeout);
      final clientList = clientsList.where((c) => c.id == devis.clientId).toList();
      if (clientList.isEmpty) throw Exception('Client introuvable');
      final client = clientList.first;
      final itemsMap = devis.items.map((item) => {
        'reference': item.reference?.toString().trim() ?? '',
        'designation': (item.designation.toString().trim().isNotEmpty ? item.designation : 'Article sans désignation').toString(),
        'unite': 'unité',
        'quantite': item.quantite > 0 ? item.quantite : 1,
        'prix_unitaire': item.prixUnitaire.isFinite && item.prixUnitaire >= 0 ? item.prixUnitaire : 0.0,
        'montant_total': item.total.isFinite && item.total >= 0 ? item.total : 0.0,
      }).toList();
      await PdfService().generateDevisPdf(
        devis: {
          'reference': devis.reference.trim().isNotEmpty ? devis.reference : 'N/A',
          'date_creation': devis.dateCreation,
          'montant_ht': devis.totalHT.isFinite ? devis.totalHT : 0.0,
          'tva': devis.tva ?? 0.0,
          'total_ttc': devis.totalTTC.isFinite ? devis.totalTTC : 0.0,
          'titre': devis.titre?.toString().trim() ?? '',
          'delai_livraison': devis.delaiLivraison?.toString().trim() ?? '',
          'garantie': devis.garantie?.toString().trim() ?? '',
          'conditions': devis.conditions?.toString().trim() ?? '',
        },
        items: itemsMap,
        client: {
          'nom': client.nom?.toString().trim() ?? '',
          'prenom': client.prenom?.toString().trim() ?? '',
          'nom_entreprise': client.nomEntreprise?.toString().trim() ?? '',
          'email': client.email?.toString().trim() ?? '',
          'contact': client.contact?.toString().trim() ?? '',
          'adresse': client.adresse?.toString().trim() ?? '',
          'numero_contribuable': client.numeroContribuable?.toString().trim() ?? '',
          'ninea': client.ninea?.toString().trim() ?? '',
        },
        commercial: {'nom': 'Commercial', 'prenom': '', 'email': ''},
      );
    } catch (e) {
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refreshData() async => loadDevis(status: state.currentStatus, forceRefresh: true, page: 1);
}

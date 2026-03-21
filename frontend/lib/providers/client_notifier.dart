import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/Models/client_model.dart';
import 'package:easyconnect/providers/client_state.dart';
import 'package:easyconnect/services/client_service.dart';
import 'package:easyconnect/utils/dashboard_refresh_helper.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/utils/notification_helper.dart';

final clientProvider =
    NotifierProvider<ClientNotifier, ClientState>(ClientNotifier.new);

class ClientNotifier extends Notifier<ClientState> {
  final ClientService _clientService = ClientService();
  bool _isLoadingInProgress = false;
  Timer? _searchDebounceTimer;

  @override
  ClientState build() {
    ref.onDispose(() {
      _searchDebounceTimer?.cancel();
    });
    return const ClientState();
  }

  void setSearchQuery(String query) {
    if (state.searchQuery == query) return;
    _searchDebounceTimer?.cancel();
    state = state.copyWith(searchQuery: query);
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (!_isLoadingInProgress) {
        AppLogger.debug(
          'Recherche (debounce): rechargement statut=${state.currentStatus}, query="$query"',
          tag: 'CLIENT_NOTIFIER',
        );
        loadClients(status: state.currentStatus, forceRefresh: true);
      }
    });
  }

  Future<void> loadClients({
    int? status,
    bool forceRefresh = false,
    int page = 1,
  }) async {
    if (_isLoadingInProgress) return;
    if (!forceRefresh &&
        state.clients.isNotEmpty &&
        state.currentStatus == status &&
        state.currentPage == page &&
        page == 1) {
      return;
    }

    _isLoadingInProgress = true;
    state = state.copyWith(currentStatus: status);
    final entityKey = 'clients_${status ?? 'all'}';

    if (page == 1) {
      state = state.copyWith(isLoading: true);
      final cachedData = ClientService.getCachedClients(status);
      if (cachedData.isNotEmpty) {
        state = state.copyWith(
          clients: cachedData,
          isLoading: false,
          currentPage: 1,
        );
        _isLoadingInProgress = false;
        AppLogger.debug(
          '[Hive] statut=$status, ${cachedData.length} client(s) → affichage instantané',
          tag: 'CLIENT_NOTIFIER',
        );
        return;
      }
      state = state.copyWith(clients: [], isLoading: false);
    } else {
      state = state.copyWith(isLoadingMore: true);
    }

    try {
      final response = await _clientService.getClientsPaginated(
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

      List<Client> newList;
      int newPage = state.currentPage;
      if (page == 1) {
        newList = response.data;
        CacheHelper.set(entityKey, response.data);
        ClientService.saveClientsToHive(response.data, status);
        newPage = 1;
      } else {
        newList = [...state.clients, ...response.data];
        newPage = response.meta.currentPage;
      }

      state = state.copyWith(
        clients: newList,
        isLoading: false,
        isLoadingMore: false,
        currentPage: newPage,
        totalPages: response.meta.lastPage,
        totalItems: response.meta.total,
        hasNextPage: response.hasNextPage,
        hasPreviousPage: response.hasPreviousPage,
      );
    } catch (e) {
      AppLogger.error('Erreur API Clients: $e', tag: 'CLIENT_NOTIFIER');
      if (state.clients.isEmpty) {
        final fallback = ClientService.getCachedClients(status);
        if (fallback.isNotEmpty) {
          state = state.copyWith(clients: fallback, isLoading: false);
        }
      }
      state = state.copyWith(isLoading: false, isLoadingMore: false);
      rethrow;
    } finally {
      _isLoadingInProgress = false;
    }
  }

  void loadMore() {
    if (state.hasNextPage && !state.isLoading && !state.isLoadingMore) {
      loadClients(status: state.currentStatus, page: state.currentPage + 1);
    }
  }

  Future<void> loadByStatus(int index) async {
    await loadClients(status: index, forceRefresh: false);
  }

  Future<void> refreshData() async {
    await loadClients(status: state.currentStatus, forceRefresh: true, page: 1);
  }

  Future<void> createClient(Client client) async {
    try {
      state = state.copyWith(isLoading: true);
      final createdClient = await _clientService.createClient(client);
      CacheHelper.clearByPrefix('clients_');

      final newStatus = createdClient.status ?? 0;
      final shouldInsert =
          state.currentStatus == null || state.currentStatus == newStatus;
      if (shouldInsert) {
        final fullList = [createdClient, ...state.clients];
        ClientService.saveClientsToHive(fullList, state.currentStatus);
        state = state.copyWith(clients: fullList);
      }
      if (createdClient.id != null) {
        NotificationHelper.notifySubmission(
          entityType: 'client',
          entityName: NotificationHelper.getEntityDisplayName(
            'client',
            createdClient,
          ),
          entityId: createdClient.id.toString(),
          route: NotificationHelper.getEntityRoute(
            'client',
            createdClient.id.toString(),
          ),
        );
      }
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (!errorStr.contains('parsing') &&
          !errorStr.contains('json') &&
          !errorStr.contains('type') &&
          !errorStr.contains('cast') &&
          !errorStr.contains('null')) {
        rethrow;
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> createClientFromMap(Map<String, dynamic> data) async {
    if (state.isLoading) return false;
    try {
      state = state.copyWith(isLoading: true);
      final client = Client.fromJson(data);
      final createdClient = await _clientService.createClient(client);
      CacheHelper.clearByPrefix('clients_');

      final newStatus = createdClient.status ?? 0;
      final shouldInsert =
          state.currentStatus == null || state.currentStatus == newStatus;
      if (shouldInsert) {
        final fullList = [createdClient, ...state.clients];
        ClientService.saveClientsToHive(fullList, state.currentStatus);
        state = state.copyWith(clients: fullList);
      }
      if (createdClient.id != null) {
        NotificationHelper.notifySubmission(
          entityType: 'client',
          entityName: NotificationHelper.getEntityDisplayName(
            'client',
            createdClient,
          ),
          entityId: createdClient.id.toString(),
          route: NotificationHelper.getEntityRoute(
            'client',
            createdClient.id.toString(),
          ),
        );
      }
      DashboardRefreshHelper.refreshPatronCounter('client');
      return true;
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('parsing') ||
          errorStr.contains('json') ||
          errorStr.contains('type') ||
          errorStr.contains('cast') ||
          errorStr.contains('null')) {
        return false;
      }
      AppLogger.error(
        'Erreur lors de la création du client: $e',
        tag: 'CLIENT_NOTIFIER',
      );
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> updateClient(Map<String, dynamic> data) async {
    if (state.isLoading) return false;
    try {
      state = state.copyWith(isLoading: true);
      final client = Client.fromJson(data);
      await _clientService.updateClient(client);
      try {
        await loadClients();
      } catch (_) {}
      return true;
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('parsing') ||
          errorStr.contains('json') ||
          errorStr.contains('type') ||
          errorStr.contains('cast') ||
          errorStr.contains('null')) {
        return false;
      }
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Client? _findClient(int clientId) {
    final list = state.clients.where((c) => c.id == clientId).toList();
    return list.isEmpty ? null : list.first;
  }

  Future<void> approveClient(int clientId) async {
    try {
      CacheHelper.clearByPrefix('clients_');
      CacheHelper.clearByPrefix('dashboard_');

      final clients = List<Client>.from(state.clients);
      final clientIndex = clients.indexWhere((c) => c.id == clientId);
      if (clientIndex != -1) {
        if (state.currentStatus == 0) {
          clients.removeAt(clientIndex);
        } else {
          final o = clients[clientIndex];
          clients[clientIndex] = Client(
            id: o.id,
            nomEntreprise: o.nomEntreprise,
            nom: o.nom,
            prenom: o.prenom,
            email: o.email,
            contact: o.contact,
            adresse: o.adresse,
            status: 1,
            createdAt: o.createdAt,
            updatedAt: o.updatedAt,
          );
        }
        state = state.copyWith(clients: clients);
      }

      final success = await _clientService.approveClient(clientId);
      if (success) {
        DashboardRefreshHelper.refreshPatronCounter('client');
        final client = _findClient(clientId);
        if (client != null) {
          NotificationHelper.notifyValidation(
            entityType: 'client',
            entityName: NotificationHelper.getEntityDisplayName(
              'client',
              client,
            ),
            entityId: clientId.toString(),
            route: NotificationHelper.getEntityRoute(
              'client',
              clientId.toString(),
            ),
            entity: client,
          );
        }
        DashboardRefreshHelper.refreshCommercialDashboard();
        Future.delayed(const Duration(milliseconds: 500), () {
          loadClients(status: state.currentStatus).catchError((_) {});
        });
      } else {
        await loadClients(status: state.currentStatus);
        throw Exception('La validation peut avoir réussi. Veuillez vérifier.');
      }
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('parsing') ||
          errorStr.contains('json') ||
          errorStr.contains('type') ||
          errorStr.contains('cast') ||
          errorStr.contains('null')) {
        loadClients(status: state.currentStatus).catchError((_) {});
        return;
      }
      if (errorStr.contains('401') ||
          errorStr.contains('403') ||
          errorStr.contains('unauthorized') ||
          errorStr.contains('forbidden')) {
        rethrow;
      }
      loadClients(status: state.currentStatus).catchError((_) {});
    }
  }

  Future<void> rejectClient(int clientId, String comment) async {
    try {
      CacheHelper.clearByPrefix('clients_');
      CacheHelper.clearByPrefix('dashboard_');

      final clients = List<Client>.from(state.clients);
      final clientIndex = clients.indexWhere((c) => c.id == clientId);
      if (clientIndex != -1) {
        if (state.currentStatus == 0) {
          clients.removeAt(clientIndex);
        } else {
          final o = clients[clientIndex];
          clients[clientIndex] = Client(
            id: o.id,
            nomEntreprise: o.nomEntreprise,
            nom: o.nom,
            prenom: o.prenom,
            email: o.email,
            contact: o.contact,
            adresse: o.adresse,
            status: 2,
            createdAt: o.createdAt,
            updatedAt: o.updatedAt,
          );
        }
        state = state.copyWith(clients: clients);
      }

      final success = await _clientService.rejectClient(clientId, comment);
      if (success) {
        DashboardRefreshHelper.refreshPatronCounter('client');
        final client = _findClient(clientId);
        if (client != null) {
          NotificationHelper.notifyRejection(
            entityType: 'client',
            entityName: NotificationHelper.getEntityDisplayName(
              'client',
              client,
            ),
            entityId: clientId.toString(),
            reason: comment,
            route: NotificationHelper.getEntityRoute(
              'client',
              clientId.toString(),
            ),
            entity: client,
          );
        }
        DashboardRefreshHelper.refreshCommercialDashboard();
        Future.delayed(const Duration(milliseconds: 500), () {
          loadClients(status: state.currentStatus).catchError((_) {});
        });
      } else {
        await loadClients(status: state.currentStatus);
        throw Exception('Erreur lors du rejet - Service a retourné false');
      }
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('parsing') ||
          errorStr.contains('json') ||
          errorStr.contains('type') ||
          errorStr.contains('cast') ||
          errorStr.contains('null')) {
        loadClients(status: state.currentStatus).catchError((_) {});
        return;
      }
      if (errorStr.contains('401') ||
          errorStr.contains('403') ||
          errorStr.contains('unauthorized') ||
          errorStr.contains('forbidden')) {
        rethrow;
      }
      loadClients(status: state.currentStatus).catchError((_) {});
    }
  }

  Future<void> deleteClient(int clientId) async {
    try {
      state = state.copyWith(isLoading: true);
      final success = await _clientService.deleteClient(clientId);
      if (success) {
        state = state.copyWith(
          clients: state.clients.where((c) => c.id != clientId).toList(),
        );
      } else {
        throw Exception('Erreur lors de la suppression');
      }
    } catch (e) {
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

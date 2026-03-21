import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/Models/supplier_model.dart';
import 'package:easyconnect/providers/supplier_state.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/services/supplier_service.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/utils/notification_helper.dart';
import 'package:easyconnect/utils/dashboard_refresh_helper.dart';

final supplierProvider =
    NotifierProvider<SupplierNotifier, SupplierState>(SupplierNotifier.new);

class SupplierNotifier extends Notifier<SupplierState> {
  final SupplierService _service = SupplierService();
  bool _loadingInProgress = false;

  @override
  SupplierState build() {
    return const SupplierState();
  }

  Future<void> loadSuppliers({bool forceRefresh = false}) async {
    if (_loadingInProgress) return;
    final user = ref.read(authProvider).user;
    if (user == null) return;

    const cacheKey = 'suppliers_all';
    try {
      final hiveList = SupplierService.getCachedFournisseurs();
      if (!forceRefresh && hiveList.isNotEmpty) {
        state = state.copyWith(
          allSuppliers: hiveList,
          isLoading: false,
        );
        _applyFilters();
        Future.microtask(() => _refreshFromApi());
        return;
      }
      final cached = CacheHelper.get<List<Supplier>>(cacheKey);
      if (!forceRefresh && cached != null && cached.isNotEmpty) {
        state = state.copyWith(allSuppliers: cached, isLoading: false);
        _applyFilters();
        Future.microtask(() => _refreshFromApi());
        return;
      }
      state = state.copyWith(isLoading: true);
      _loadingInProgress = true;

      final loaded =
          await _service.getSuppliers(status: null, search: null);
      state = state.copyWith(
        allSuppliers: loaded,
        isLoading: false,
      );
      CacheHelper.set(
        cacheKey,
        loaded,
        duration: AppConfig.mediumCacheDuration,
      );
      _applyFilters();
    } catch (e) {
      final err = e.toString().toLowerCase();
      if (!err.contains('session expirée') &&
          !err.contains('401') &&
          !err.contains('unauthorized')) {
        if (state.allSuppliers.isEmpty) {
          final cached = CacheHelper.get<List<Supplier>>(cacheKey);
          if (cached != null && cached.isNotEmpty) {
            state = state.copyWith(
              allSuppliers: cached,
              isLoading: false,
            );
            _applyFilters();
          } else {
            state = state.copyWith(isLoading: false);
          }
        } else {
          state = state.copyWith(isLoading: false);
        }
      } else {
        state = state.copyWith(isLoading: false);
      }
    } finally {
      _loadingInProgress = false;
    }
  }

  Future<void> _refreshFromApi() async {
    try {
      const cacheKey = 'suppliers_all';
      final loaded =
          await _service.getSuppliers(status: null, search: null);
      state = state.copyWith(allSuppliers: loaded);
      CacheHelper.set(
        cacheKey,
        loaded,
        duration: AppConfig.mediumCacheDuration,
      );
      _applyFilters();
    } catch (_) {}
  }

  Future<void> loadSupplierStats() async {
    try {
      final stats = await _service.getSupplierStats();
      state = state.copyWith(supplierStats: stats);
    } catch (_) {}
  }

  void _applyFilters() {
    List<Supplier> filtered = List.from(state.allSuppliers);
    if (state.selectedStatus != 'all') {
      filtered =
          filtered.where((s) => s.statut == state.selectedStatus).toList();
    }
    if (state.searchQuery.isNotEmpty) {
      final q = state.searchQuery.toLowerCase();
      filtered = filtered.where((s) {
        return s.nom.toLowerCase().contains(q) ||
            s.email.toLowerCase().contains(q) ||
            s.telephone.toLowerCase().contains(q) ||
            s.ville.toLowerCase().contains(q) ||
            s.pays.toLowerCase().contains(q);
      }).toList();
    }
    state = state.copyWith(suppliers: filtered);
  }

  void searchSuppliers(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilters();
  }

  void filterByStatus(String status) {
    state = state.copyWith(selectedStatus: status);
    _applyFilters();
  }

  Future<bool> createSupplier(Supplier supplier) async {
    try {
      state = state.copyWith(isLoading: true);
      final created = await _service.createSupplier(supplier);
      CacheHelper.clearByPrefix('suppliers_');
      NotificationHelper.notifySubmission(
        entityType: 'supplier',
        entityName: NotificationHelper.getEntityDisplayName('supplier', created),
        entityId: created.id.toString(),
        route: NotificationHelper.getEntityRoute('supplier', created.id.toString()),
      );
      await loadSuppliers();
      await loadSupplierStats();
      DashboardRefreshHelper.refreshPatronCounter('supplier');
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<bool> updateSupplier(Supplier supplier) async {
    try {
      state = state.copyWith(isLoading: true);
      await _service.updateSupplier(supplier);
      await loadSuppliers();
      await loadSupplierStats();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> deleteSupplier(Supplier supplier) async {
    if (supplier.id == null) return;
    try {
      state = state.copyWith(isLoading: true);
      final success = await _service.deleteSupplier(supplier.id!);
      if (success) {
        await loadSuppliers();
        await loadSupplierStats();
      } else {
        throw Exception('Erreur lors de la suppression');
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> approveSupplier(Supplier supplier, {String? validationComment}) async {
    if (supplier.id == null) return false;
    try {
      state = state.copyWith(isLoading: true);
      final success = await _service.approveSupplier(
        supplier.id!,
        validationComment: validationComment,
      );
      if (success) {
        CacheHelper.clearByPrefix('suppliers_');
        NotificationHelper.notifyValidation(
          entityType: 'supplier',
          entityName: NotificationHelper.getEntityDisplayName('supplier', supplier),
          entityId: supplier.id.toString(),
          route: NotificationHelper.getEntityRoute('supplier', supplier.id.toString()),
          entity: supplier,
        );
        await loadSuppliers();
        await loadSupplierStats();
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (_) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> rejectSupplier(
    Supplier supplier, {
    required String rejectionReason,
    String? rejectionComment,
  }) async {
    if (supplier.id == null) return;
    try {
      state = state.copyWith(isLoading: true);
      final success = await _service.rejectSupplier(
        supplier.id!,
        rejectionReason: rejectionReason,
        rejectionComment: rejectionComment,
      );
      if (success) {
        NotificationHelper.notifyRejection(
          entityType: 'supplier',
          entityName: NotificationHelper.getEntityDisplayName('supplier', supplier),
          entityId: supplier.id.toString(),
          reason: rejectionReason,
          route: NotificationHelper.getEntityRoute('supplier', supplier.id.toString()),
          entity: supplier,
        );
        await loadSuppliers();
        await loadSupplierStats();
      } else {
        throw Exception('Erreur lors du rejet');
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> rateSupplier(Supplier supplier, double rating, {String? comments}) async {
    if (supplier.id == null) return;
    try {
      state = state.copyWith(isLoading: true);
      final success = await _service.rateSupplier(
        supplier.id!,
        rating,
        comments: comments,
      );
      if (success) {
        await loadSuppliers();
        await loadSupplierStats();
      } else {
        throw Exception('Erreur lors de l\'évaluation');
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> submitSupplier(Supplier supplier) async {
    if (supplier.id == null) return false;
    try {
      state = state.copyWith(isLoading: true);
      final success = await _service.submitSupplier(supplier.id!);
      if (success) {
        NotificationHelper.notifySubmission(
          entityType: 'supplier',
          entityName: NotificationHelper.getEntityDisplayName('supplier', supplier),
          entityId: supplier.id.toString(),
          route: NotificationHelper.getEntityRoute('supplier', supplier.id.toString()),
        );
        await loadSuppliers();
        await loadSupplierStats();
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (_) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }
}

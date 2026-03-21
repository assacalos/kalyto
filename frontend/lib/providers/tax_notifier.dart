import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/Models/tax_model.dart';
import 'package:easyconnect/providers/tax_state.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/services/tax_service.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/utils/dashboard_refresh_helper.dart';
import 'package:easyconnect/utils/notification_helper.dart';
import 'package:easyconnect/utils/logger.dart';

final taxProvider = NotifierProvider<TaxNotifier, TaxState>(TaxNotifier.new);

class TaxNotifier extends Notifier<TaxState> {
  final TaxService _taxService = TaxService();
  String? _currentStatusFilter;
  bool _loadingInProgress = false;

  @override
  TaxState build() {
    return const TaxState();
  }

  Future<void> loadTaxes({
    String? statusFilter,
    int page = 1,
    bool forceRefresh = false,
  }) async {
    if (_loadingInProgress) return;
    final user = ref.read(authProvider).user;
    if (user == null) return;

    _currentStatusFilter =
        statusFilter ?? (state.selectedStatus == 'all' ? null : state.selectedStatus);
    final cacheKey = 'taxes_${_currentStatusFilter ?? 'all'}';

    if (page == 1) {
      if (!forceRefresh) {
        final hiveList = TaxService.getCachedTaxes();
        if (hiveList.isNotEmpty) {
          state = state.copyWith(
            allTaxes: hiveList,
            isLoading: false,
            currentPage: 1,
          );
          _applyFilters();
          Future.microtask(() => _refreshTaxesFromApi(cacheKey));
          return;
        }
        final cached = CacheHelper.get<List<Tax>>(cacheKey);
        if (cached != null && cached.isNotEmpty) {
          state = state.copyWith(
            allTaxes: cached,
            isLoading: false,
            currentPage: 1,
          );
          _applyFilters();
          Future.microtask(() => _refreshTaxesFromApi(cacheKey));
          return;
        }
      }
      state = state.copyWith(allTaxes: [], isLoading: true);
    } else {
      state = state.copyWith(isLoadingMore: true);
    }

    _loadingInProgress = true;
    try {
      final res = await _taxService.getTaxesPaginated(
        status: _currentStatusFilter,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        page: page,
        perPage: state.perPage,
      );

      if (page == 1) {
        state = state.copyWith(
          allTaxes: res.data,
          isLoading: false,
          currentPage: res.meta.currentPage,
          totalPages: res.meta.lastPage,
          totalItems: res.meta.total,
        );
        CacheHelper.set(cacheKey, res.data);
      } else {
        state = state.copyWith(
          allTaxes: [...state.allTaxes, ...res.data],
          isLoadingMore: false,
          currentPage: res.meta.currentPage,
          totalPages: res.meta.lastPage,
          totalItems: res.meta.total,
        );
      }
      _applyFilters();
      loadTaxStats();
    } catch (e) {
      AppLogger.warning('Erreur chargement taxes: $e', tag: 'TAX_NOTIFIER');
      if (state.allTaxes.isEmpty) {
        final fallback = CacheHelper.get<List<Tax>>(cacheKey);
        if (fallback != null && fallback.isNotEmpty) {
          state = state.copyWith(allTaxes: fallback, isLoading: false);
          _applyFilters();
        } else {
          state = state.copyWith(isLoading: false, isLoadingMore: false);
        }
      } else {
        state = state.copyWith(isLoading: false, isLoadingMore: false);
      }
    } finally {
      _loadingInProgress = false;
    }
  }

  Future<void> _refreshTaxesFromApi(String cacheKey) async {
    if (_currentStatusFilter != (state.selectedStatus == 'all' ? null : state.selectedStatus)) return;
    try {
      final res = await _taxService.getTaxesPaginated(
        status: _currentStatusFilter,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        page: 1,
        perPage: state.perPage,
      );
      if (_currentStatusFilter != (state.selectedStatus == 'all' ? null : state.selectedStatus)) return;
      state = state.copyWith(
        allTaxes: res.data,
        currentPage: 1,
        totalPages: res.meta.lastPage,
        totalItems: res.meta.total,
      );
      CacheHelper.set(cacheKey, res.data);
      _applyFilters();
      loadTaxStats();
    } catch (_) {}
  }

  void _applyFilters() {
    List<Tax> filtered = List.from(state.allTaxes);
    if (state.selectedStatus != 'all') {
      final s = state.selectedStatus.toLowerCase();
      filtered = filtered.where((t) {
        if (s == 'en_attente') return t.isPending;
        if (s == 'valide') return t.isValidated;
        if (s == 'rejete') return t.isRejected;
        if (s == 'paid') return t.isPaid;
        return true;
      }).toList();
    }
    if (state.searchQuery.isNotEmpty) {
      final q = state.searchQuery.toLowerCase();
      filtered = filtered.where((t) {
        return (t.name.toLowerCase().contains(q)) ||
            (t.description?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
    state = state.copyWith(taxes: filtered);
  }

  void loadMore() {
    if (state.hasNextPage && !state.isLoading && !state.isLoadingMore) {
      loadTaxes(statusFilter: _currentStatusFilter, page: state.currentPage + 1);
    }
  }

  void filterByStatus(String status) {
    state = state.copyWith(selectedStatus: status);
    _applyFilters();
  }

  void searchTaxes(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilters();
  }

  Future<void> loadTaxStats() async {
    try {
      final stats = await _taxService.getTaxStats();
      state = state.copyWith(taxStats: stats);
    } catch (_) {}
  }

  Future<void> validateTax(Tax tax, {String? validationComment}) async {
    state = state.copyWith(isLoading: true);
    try {
      CacheHelper.clearByPrefix('taxes_');
      final success = await _taxService.approveTax(tax.id!, notes: validationComment);
      if (success) {
        DashboardRefreshHelper.refreshPatronCounter('tax');
        NotificationHelper.notifyValidation(
          entityType: 'taxe',
          entityName: NotificationHelper.getEntityDisplayName('taxe', tax),
          entityId: tax.id.toString(),
          route: NotificationHelper.getEntityRoute('taxe', tax.id.toString()),
          entity: tax,
        );
        await loadTaxes(statusFilter: _currentStatusFilter);
        await loadTaxStats();
      } else {
        await loadTaxes(statusFilter: _currentStatusFilter);
        throw Exception('Erreur lors de la validation');
      }
    } catch (e) {
      await loadTaxes(statusFilter: _currentStatusFilter);
      await loadTaxStats();
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> rejectTax(Tax tax, String reason, {String? rejectionComment}) async {
    state = state.copyWith(isLoading: true);
    try {
      CacheHelper.clearByPrefix('taxes_');
      final success = await _taxService.rejectTax(tax.id!, reason: reason, notes: rejectionComment);
      if (success) {
        DashboardRefreshHelper.refreshPatronCounter('tax');
        NotificationHelper.notifyRejection(
          entityType: 'taxe',
          entityName: NotificationHelper.getEntityDisplayName('taxe', tax),
          entityId: tax.id.toString(),
          reason: reason,
          route: NotificationHelper.getEntityRoute('taxe', tax.id.toString()),
          entity: tax,
        );
        await loadTaxes(statusFilter: _currentStatusFilter);
        await loadTaxStats();
      } else {
        await loadTaxes(statusFilter: _currentStatusFilter);
        throw Exception('Erreur lors du rejet');
      }
    } catch (e) {
      await loadTaxes(statusFilter: _currentStatusFilter);
      await loadTaxStats();
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> markTaxAsPaid(Tax tax) async {
    state = state.copyWith(isLoading: true);
    try {
      final success = await _taxService.markTaxAsPaid(
        tax.id!,
        paymentMethod: 'manual',
        notes: 'Marqué comme payé depuis l\'application',
      );
      if (success) {
        await loadTaxes();
        await loadTaxStats();
      } else {
        throw Exception('Erreur lors du marquage comme payé');
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> deleteTax(Tax tax) async {
    state = state.copyWith(isLoading: true);
    try {
      final success = await _taxService.deleteTax(tax.id!);
      if (success) {
        await loadTaxes();
        await loadTaxStats();
      } else {
        throw Exception('Erreur lors de la suppression');
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

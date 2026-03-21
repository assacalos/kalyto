import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/Models/stock_model.dart';
import 'package:easyconnect/providers/stock_state.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/services/stock_service.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/utils/notification_helper.dart';
import 'package:easyconnect/utils/logger.dart';

final stockProvider =
    NotifierProvider<StockNotifier, StockState>(StockNotifier.new);

class StockNotifier extends Notifier<StockState> {
  final StockService _stockService = StockService();
  bool _loadingInProgress = false;

  @override
  StockState build() {
    return const StockState();
  }

  Future<void> loadStocks({
    String? statusFilter,
    int page = 1,
    bool forceRefresh = false,
  }) async {
    if (_loadingInProgress) return;
    final user = ref.read(authProvider).user;
    if (user == null) return;

    final statusParam = statusFilter ?? (state.selectedStatus == 'all' ? null : state.selectedStatus);
    final categoryParam = state.selectedCategoryFilter == 'all' ? null : state.selectedCategoryFilter;
    final cacheKey = 'stocks_${statusParam ?? 'all'}_${categoryParam ?? 'all'}';

    if (page == 1) {
      if (!forceRefresh) {
        final hiveList = StockService.getCachedStocks();
        if (hiveList.isNotEmpty) {
          state = state.copyWith(
            stocks: hiveList,
            isLoading: false,
            currentPage: 1,
          );
          Future.microtask(() => _refreshFromApi(cacheKey, statusParam, categoryParam));
          return;
        }
        final cached = CacheHelper.get<List<Stock>>(cacheKey);
        if (cached != null && cached.isNotEmpty) {
          state = state.copyWith(
            stocks: cached,
            isLoading: false,
            currentPage: 1,
          );
          Future.microtask(() => _refreshFromApi(cacheKey, statusParam, categoryParam));
          return;
        }
      }
      state = state.copyWith(stocks: [], isLoading: true);
    } else {
      state = state.copyWith(isLoadingMore: true);
    }

    _loadingInProgress = true;
    try {
      final res = await _stockService.getStocksPaginated(
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        category: categoryParam,
        status: statusParam,
        page: page,
        perPage: state.perPage,
      );

      if (page == 1) {
        state = state.copyWith(
          stocks: res.data,
          isLoading: false,
          currentPage: res.meta.currentPage,
          totalPages: res.meta.lastPage,
          totalItems: res.meta.total,
        );
        CacheHelper.set(cacheKey, res.data);
      } else {
        state = state.copyWith(
          stocks: [...state.stocks, ...res.data],
          isLoadingMore: false,
          currentPage: res.meta.currentPage,
          totalPages: res.meta.lastPage,
          totalItems: res.meta.total,
        );
      }
      loadStockStats();
    } catch (e) {
      AppLogger.error('Erreur chargement stocks: $e', tag: 'STOCK_NOTIFIER');
      if (state.stocks.isEmpty) {
        final fallback = CacheHelper.get<List<Stock>>(cacheKey);
        if (fallback != null && fallback.isNotEmpty) {
          state = state.copyWith(stocks: fallback, isLoading: false);
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

  Future<void> _refreshFromApi(
    String cacheKey,
    String? statusParam,
    String? categoryParam,
  ) async {
    try {
      final res = await _stockService.getStocksPaginated(
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        category: categoryParam,
        status: statusParam,
        page: 1,
        perPage: state.perPage,
      );
      state = state.copyWith(
        stocks: res.data,
        currentPage: 1,
        totalPages: res.meta.lastPage,
        totalItems: res.meta.total,
      );
      CacheHelper.set(cacheKey, res.data);
      loadStockStats();
    } catch (_) {}
    state = state.copyWith(isLoading: false);
  }

  void loadMore() {
    if (state.hasNextPage && !state.isLoading && !state.isLoadingMore) {
      loadStocks(
        statusFilter: state.selectedStatus == 'all' ? null : state.selectedStatus,
        page: state.currentPage + 1,
      );
    }
  }

  void filterByStatus(String status) {
    state = state.copyWith(selectedStatus: status);
    loadStocks(statusFilter: status == 'all' ? null : status);
  }

  void filterByCategory(String category) {
    state = state.copyWith(selectedCategoryFilter: category);
    loadStocks();
  }

  void searchStocks(String query) {
    state = state.copyWith(searchQuery: query);
    loadStocks();
  }

  Future<void> loadCategories() async {
    try {
      final list = await _stockService.getStockCategories();
      state = state.copyWith(categories: list);
    } catch (_) {
      state = state.copyWith(categories: []);
    }
  }

  Future<void> loadStockStats() async {
    try {
      final stats = await _stockService.getStockStats();
      state = state.copyWith(stockStats: stats);
    } catch (_) {}
  }

  Future<void> loadStockAlerts() async {
    try {
      final list = await _stockService.getStockAlerts();
      state = state.copyWith(alerts: list);
    } catch (_) {
      state = state.copyWith(alerts: []);
    }
  }

  Future<Stock?> createStock(Stock stock) async {
    state = state.copyWith(isLoading: true);
    try {
      final created = await _stockService.createStock(stock);
      CacheHelper.clearByPrefix('stocks_');
      await loadStocks(forceRefresh: true);
      await loadStockStats();
      if (created.id != null) {
        NotificationHelper.notifySubmission(
          entityType: 'stock',
          entityName: NotificationHelper.getEntityDisplayName('stock', created),
          entityId: created.id.toString(),
          route: NotificationHelper.getEntityRoute('stock', created.id.toString()),
        );
      }
      return created;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> updateStock(Stock stock) async {
    state = state.copyWith(isLoading: true);
    try {
      await _stockService.updateStock(stock);
      CacheHelper.clearByPrefix('stocks_');
      await loadStocks(forceRefresh: true);
      await loadStockStats();
      return true;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> deleteStock(Stock stock) async {
    state = state.copyWith(isLoading: true);
    try {
      await _stockService.deleteStock(stock.id!);
      state = state.copyWith(
        stocks: state.stocks.where((s) => s.id != stock.id).toList(),
      );
      await loadStockStats();
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> approveStock(Stock stock, {String? validationComment}) async {
    state = state.copyWith(isLoading: true);
    try {
      await _stockService.approveStock(
        stockId: stock.id!,
        validationComment: validationComment,
      );
      NotificationHelper.notifyValidation(
        entityType: 'stock',
        entityName: NotificationHelper.getEntityDisplayName('stock', stock),
        entityId: stock.id.toString(),
        route: NotificationHelper.getEntityRoute('stock', stock.id.toString()),
        entity: stock,
      );
      CacheHelper.clearByPrefix('stocks_');
      await loadStocks(forceRefresh: true);
      await loadStockStats();
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> rejectStock(Stock stock, String commentaire) async {
    state = state.copyWith(isLoading: true);
    try {
      await _stockService.rejectStock(
        stockId: stock.id!,
        commentaire: commentaire,
      );
      NotificationHelper.notifyRejection(
        entityType: 'stock',
        entityName: NotificationHelper.getEntityDisplayName('stock', stock),
        entityId: stock.id.toString(),
        reason: commentaire,
        route: NotificationHelper.getEntityRoute('stock', stock.id.toString()),
        entity: stock,
      );
      CacheHelper.clearByPrefix('stocks_');
      await loadStocks(forceRefresh: true);
      await loadStockStats();
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> addStockMovement({
    required int stockId,
    required String type,
    required double quantity,
    String? reason,
    String? reference,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await _stockService.addStockMovement(
        stockId: stockId,
        type: type,
        quantity: quantity,
        reason: reason,
        reference: reference,
        notes: notes,
      );
      await loadStocks(forceRefresh: true);
      await loadStockStats();
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> adjustStock({
    required int stockId,
    required double newQuantity,
    required String reason,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await _stockService.adjustStock(
        stockId: stockId,
        newQuantity: newQuantity,
        reason: reason,
        notes: notes,
      );
      await loadStocks(forceRefresh: true);
      await loadStockStats();
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

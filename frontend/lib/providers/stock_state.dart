import 'package:easyconnect/Models/stock_model.dart';

/// État du provider des stocks (Riverpod).
class StockState {
  final List<Stock> stocks;
  final List<StockCategory> categories;
  final List<StockAlert> alerts;
  final bool isLoading;
  final bool isLoadingMore;
  final StockStats? stockStats;
  final String selectedStatus;
  final String selectedCategoryFilter;
  final String searchQuery;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int perPage;

  const StockState({
    this.stocks = const [],
    this.categories = const [],
    this.alerts = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.stockStats,
    this.selectedStatus = 'all',
    this.selectedCategoryFilter = 'all',
    this.searchQuery = '',
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalItems = 0,
    this.perPage = 15,
  });

  bool get hasNextPage => currentPage < totalPages;

  StockState copyWith({
    List<Stock>? stocks,
    List<StockCategory>? categories,
    List<StockAlert>? alerts,
    bool? isLoading,
    bool? isLoadingMore,
    StockStats? stockStats,
    String? selectedStatus,
    String? selectedCategoryFilter,
    String? searchQuery,
    int? currentPage,
    int? totalPages,
    int? totalItems,
    int? perPage,
  }) {
    return StockState(
      stocks: stocks ?? this.stocks,
      categories: categories ?? this.categories,
      alerts: alerts ?? this.alerts,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      stockStats: stockStats ?? this.stockStats,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      selectedCategoryFilter: selectedCategoryFilter ?? this.selectedCategoryFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalItems: totalItems ?? this.totalItems,
      perPage: perPage ?? this.perPage,
    );
  }
}

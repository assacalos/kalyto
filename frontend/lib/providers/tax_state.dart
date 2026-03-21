import 'package:easyconnect/Models/tax_model.dart';

/// État du provider des taxes (Riverpod).
class TaxState {
  final List<Tax> allTaxes;
  final List<Tax> taxes;
  final bool isLoading;
  final bool isLoadingMore;
  final String selectedStatus;
  final String searchQuery;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int perPage;
  final TaxStats? taxStats;

  const TaxState({
    this.allTaxes = const [],
    this.taxes = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.selectedStatus = 'all',
    this.searchQuery = '',
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalItems = 0,
    this.perPage = 15,
    this.taxStats,
  });

  bool get hasNextPage => currentPage < totalPages;
  bool get hasPreviousPage => currentPage > 1;

  TaxState copyWith({
    List<Tax>? allTaxes,
    List<Tax>? taxes,
    bool? isLoading,
    bool? isLoadingMore,
    String? selectedStatus,
    String? searchQuery,
    int? currentPage,
    int? totalPages,
    int? totalItems,
    int? perPage,
    TaxStats? taxStats,
  }) {
    return TaxState(
      allTaxes: allTaxes ?? this.allTaxes,
      taxes: taxes ?? this.taxes,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalItems: totalItems ?? this.totalItems,
      perPage: perPage ?? this.perPage,
      taxStats: taxStats ?? this.taxStats,
    );
  }
}

class GlobalSearchState {
  final String searchQuery;
  final bool isSearching;
  final bool hasNoResults;
  final List<dynamic> clientsResults;
  final List<dynamic> invoicesResults;
  final List<dynamic> paymentsResults;
  final List<dynamic> employeesResults;
  final List<dynamic> suppliersResults;
  final List<dynamic> stocksResults;

  const GlobalSearchState({
    this.searchQuery = '',
    this.isSearching = false,
    this.hasNoResults = false,
    this.clientsResults = const [],
    this.invoicesResults = const [],
    this.paymentsResults = const [],
    this.employeesResults = const [],
    this.suppliersResults = const [],
    this.stocksResults = const [],
  });

  GlobalSearchState copyWith({
    String? searchQuery,
    bool? isSearching,
    bool? hasNoResults,
    List<dynamic>? clientsResults,
    List<dynamic>? invoicesResults,
    List<dynamic>? paymentsResults,
    List<dynamic>? employeesResults,
    List<dynamic>? suppliersResults,
    List<dynamic>? stocksResults,
  }) {
    return GlobalSearchState(
      searchQuery: searchQuery ?? this.searchQuery,
      isSearching: isSearching ?? this.isSearching,
      hasNoResults: hasNoResults ?? this.hasNoResults,
      clientsResults: clientsResults ?? this.clientsResults,
      invoicesResults: invoicesResults ?? this.invoicesResults,
      paymentsResults: paymentsResults ?? this.paymentsResults,
      employeesResults: employeesResults ?? this.employeesResults,
      suppliersResults: suppliersResults ?? this.suppliersResults,
      stocksResults: stocksResults ?? this.stocksResults,
    );
  }
}

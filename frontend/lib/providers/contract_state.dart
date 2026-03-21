import 'package:easyconnect/Models/contract_model.dart';

class ContractState {
  final List<Contract> contracts;
  final bool isLoading;
  final bool isLoadingMore;
  final ContractStats? contractStats;
  final String searchQuery;
  final String selectedStatus;
  final String selectedContractType;
  final String selectedDepartment;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final int perPage;

  const ContractState({
    this.contracts = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.contractStats,
    this.searchQuery = '',
    this.selectedStatus = 'all',
    this.selectedContractType = 'all',
    this.selectedDepartment = 'all',
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalItems = 0,
    this.hasNextPage = false,
    this.hasPreviousPage = false,
    this.perPage = 15,
  });

  ContractState copyWith({
    List<Contract>? contracts,
    bool? isLoading,
    bool? isLoadingMore,
    ContractStats? contractStats,
    String? searchQuery,
    String? selectedStatus,
    String? selectedContractType,
    String? selectedDepartment,
    int? currentPage,
    int? totalPages,
    int? totalItems,
    bool? hasNextPage,
    bool? hasPreviousPage,
    int? perPage,
  }) {
    return ContractState(
      contracts: contracts ?? this.contracts,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      contractStats: contractStats ?? this.contractStats,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      selectedContractType: selectedContractType ?? this.selectedContractType,
      selectedDepartment: selectedDepartment ?? this.selectedDepartment,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalItems: totalItems ?? this.totalItems,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      hasPreviousPage: hasPreviousPage ?? this.hasPreviousPage,
      perPage: perPage ?? this.perPage,
    );
  }
}

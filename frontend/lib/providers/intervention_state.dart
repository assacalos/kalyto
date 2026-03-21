import 'package:easyconnect/Models/intervention_model.dart';

class InterventionState {
  final List<Intervention> interventions;
  final List<Intervention> pendingInterventions;
  final bool isLoading;
  final bool isLoadingMore;
  final InterventionStats? interventionStats;
  final String searchQuery;
  final String selectedStatus;
  final String selectedType;
  final String selectedPriority;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final int perPage;
  final bool canManageInterventions;
  final bool canApproveInterventions;
  final bool canViewInterventions;

  const InterventionState({
    this.interventions = const [],
    this.pendingInterventions = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.interventionStats,
    this.searchQuery = '',
    this.selectedStatus = 'all',
    this.selectedType = 'all',
    this.selectedPriority = 'all',
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalItems = 0,
    this.hasNextPage = false,
    this.hasPreviousPage = false,
    this.perPage = 15,
    this.canManageInterventions = true,
    this.canApproveInterventions = true,
    this.canViewInterventions = true,
  });

  InterventionState copyWith({
    List<Intervention>? interventions,
    List<Intervention>? pendingInterventions,
    bool? isLoading,
    bool? isLoadingMore,
    InterventionStats? interventionStats,
    String? searchQuery,
    String? selectedStatus,
    String? selectedType,
    String? selectedPriority,
    int? currentPage,
    int? totalPages,
    int? totalItems,
    bool? hasNextPage,
    bool? hasPreviousPage,
    int? perPage,
    bool? canManageInterventions,
    bool? canApproveInterventions,
    bool? canViewInterventions,
  }) {
    return InterventionState(
      interventions: interventions ?? this.interventions,
      pendingInterventions: pendingInterventions ?? this.pendingInterventions,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      interventionStats: interventionStats ?? this.interventionStats,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      selectedType: selectedType ?? this.selectedType,
      selectedPriority: selectedPriority ?? this.selectedPriority,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalItems: totalItems ?? this.totalItems,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      hasPreviousPage: hasPreviousPage ?? this.hasPreviousPage,
      perPage: perPage ?? this.perPage,
      canManageInterventions:
          canManageInterventions ?? this.canManageInterventions,
      canApproveInterventions:
          canApproveInterventions ?? this.canApproveInterventions,
      canViewInterventions: canViewInterventions ?? this.canViewInterventions,
    );
  }
}

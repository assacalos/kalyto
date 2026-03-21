import 'package:flutter/material.dart';
import 'package:easyconnect/Models/bon_commande_model.dart';
import 'package:easyconnect/Models/client_model.dart';

@immutable
class BonCommandeState {
  final List<BonCommande> bonCommandes;
  final Client? selectedClient;
  final List<Client> clients;
  final bool isLoading;
  final bool isLoadingMore;
  final BonCommande? currentBonCommande;
  final List<Map<String, dynamic>> selectedFiles;
  final int? currentStatus;
  final int? selectedStatus;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final int perPage;
  final String searchQuery;
  final int totalBonCommandes;
  final int bonCommandesEnvoyes;
  final int bonCommandesAcceptes;
  final int bonCommandesRefuses;
  final int bonCommandesLivres;
  final double montantTotal;
  final bool isLoadingClients;

  const BonCommandeState({
    this.bonCommandes = const [],
    this.selectedClient,
    this.clients = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.currentBonCommande,
    this.selectedFiles = const [],
    this.currentStatus,
    this.selectedStatus,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalItems = 0,
    this.hasNextPage = false,
    this.hasPreviousPage = false,
    this.perPage = 15,
    this.searchQuery = '',
    this.totalBonCommandes = 0,
    this.bonCommandesEnvoyes = 0,
    this.bonCommandesAcceptes = 0,
    this.bonCommandesRefuses = 0,
    this.bonCommandesLivres = 0,
    this.montantTotal = 0.0,
    this.isLoadingClients = false,
  });

  BonCommandeState copyWith({
    List<BonCommande>? bonCommandes,
    Client? selectedClient,
    List<Client>? clients,
    bool? isLoading,
    bool? isLoadingMore,
    BonCommande? currentBonCommande,
    List<Map<String, dynamic>>? selectedFiles,
    int? currentStatus,
    int? selectedStatus,
    int? currentPage,
    int? totalPages,
    int? totalItems,
    bool? hasNextPage,
    bool? hasPreviousPage,
    int? perPage,
    String? searchQuery,
    int? totalBonCommandes,
    int? bonCommandesEnvoyes,
    int? bonCommandesAcceptes,
    int? bonCommandesRefuses,
    int? bonCommandesLivres,
    double? montantTotal,
    bool? isLoadingClients,
  }) {
    return BonCommandeState(
      bonCommandes: bonCommandes ?? this.bonCommandes,
      selectedClient: selectedClient ?? this.selectedClient,
      clients: clients ?? this.clients,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      currentBonCommande: currentBonCommande ?? this.currentBonCommande,
      selectedFiles: selectedFiles ?? this.selectedFiles,
      currentStatus: currentStatus ?? this.currentStatus,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalItems: totalItems ?? this.totalItems,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      hasPreviousPage: hasPreviousPage ?? this.hasPreviousPage,
      perPage: perPage ?? this.perPage,
      searchQuery: searchQuery ?? this.searchQuery,
      totalBonCommandes: totalBonCommandes ?? this.totalBonCommandes,
      bonCommandesEnvoyes: bonCommandesEnvoyes ?? this.bonCommandesEnvoyes,
      bonCommandesAcceptes: bonCommandesAcceptes ?? this.bonCommandesAcceptes,
      bonCommandesRefuses: bonCommandesRefuses ?? this.bonCommandesRefuses,
      bonCommandesLivres: bonCommandesLivres ?? this.bonCommandesLivres,
      montantTotal: montantTotal ?? this.montantTotal,
      isLoadingClients: isLoadingClients ?? this.isLoadingClients,
    );
  }

  /// Filtre selon l'onglet (0 = Tous, 1 = En attente, 2 = Validés, 3 = Rejetés, 4 = Livrés).
  List<BonCommande> getFilteredBonCommandes() {
    if (selectedStatus == null) return bonCommandes;
    if (selectedStatus == 1) {
      return bonCommandes.where((bc) => bc.status == 0 || bc.status == 1).toList();
    }
    return bonCommandes.where((bc) => bc.status == selectedStatus).toList();
  }
}

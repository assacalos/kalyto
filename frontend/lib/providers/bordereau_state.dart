import 'package:flutter/material.dart';
import 'package:easyconnect/Models/bordereau_model.dart';
import 'package:easyconnect/Models/client_model.dart';
import 'package:easyconnect/Models/devis_model.dart';

@immutable
class BordereauState {
  final List<Bordereau> bordereaux;
  final Client? selectedClient;
  final List<Client> clients;
  final bool isLoading;
  final bool isLoadingMore;
  final Bordereau? currentBordereau;
  final List<BordereauItem> items;
  final List<Devis> availableDevis;
  final Devis? selectedDevis;
  final bool isLoadingDevis;
  final String generatedReference;
  final int? currentStatus;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final int perPage;
  final String searchQuery;
  final int totalBordereaux;
  final int bordereauEnvoyes;
  final int bordereauAcceptes;
  final int bordereauRefuses;
  final double montantTotal;
  final bool isLoadingClients;

  const BordereauState({
    this.bordereaux = const [],
    this.selectedClient,
    this.clients = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.currentBordereau,
    this.items = const [],
    this.availableDevis = const [],
    this.selectedDevis,
    this.isLoadingDevis = false,
    this.generatedReference = '',
    this.currentStatus,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalItems = 0,
    this.hasNextPage = false,
    this.hasPreviousPage = false,
    this.perPage = 15,
    this.searchQuery = '',
    this.totalBordereaux = 0,
    this.bordereauEnvoyes = 0,
    this.bordereauAcceptes = 0,
    this.bordereauRefuses = 0,
    this.montantTotal = 0.0,
    this.isLoadingClients = false,
  });

  BordereauState copyWith({
    List<Bordereau>? bordereaux,
    Client? selectedClient,
    List<Client>? clients,
    bool? isLoading,
    bool? isLoadingMore,
    Bordereau? currentBordereau,
    List<BordereauItem>? items,
    List<Devis>? availableDevis,
    Devis? selectedDevis,
    bool? isLoadingDevis,
    String? generatedReference,
    int? currentStatus,
    int? currentPage,
    int? totalPages,
    int? totalItems,
    bool? hasNextPage,
    bool? hasPreviousPage,
    int? perPage,
    String? searchQuery,
    int? totalBordereaux,
    int? bordereauEnvoyes,
    int? bordereauAcceptes,
    int? bordereauRefuses,
    double? montantTotal,
    bool? isLoadingClients,
  }) {
    return BordereauState(
      bordereaux: bordereaux ?? this.bordereaux,
      selectedClient: selectedClient ?? this.selectedClient,
      clients: clients ?? this.clients,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      currentBordereau: currentBordereau ?? this.currentBordereau,
      items: items ?? this.items,
      availableDevis: availableDevis ?? this.availableDevis,
      selectedDevis: selectedDevis ?? this.selectedDevis,
      isLoadingDevis: isLoadingDevis ?? this.isLoadingDevis,
      generatedReference: generatedReference ?? this.generatedReference,
      currentStatus: currentStatus ?? this.currentStatus,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalItems: totalItems ?? this.totalItems,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      hasPreviousPage: hasPreviousPage ?? this.hasPreviousPage,
      perPage: perPage ?? this.perPage,
      searchQuery: searchQuery ?? this.searchQuery,
      totalBordereaux: totalBordereaux ?? this.totalBordereaux,
      bordereauEnvoyes: bordereauEnvoyes ?? this.bordereauEnvoyes,
      bordereauAcceptes: bordereauAcceptes ?? this.bordereauAcceptes,
      bordereauRefuses: bordereauRefuses ?? this.bordereauRefuses,
      montantTotal: montantTotal ?? this.montantTotal,
      isLoadingClients: isLoadingClients ?? this.isLoadingClients,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:easyconnect/Models/devis_model.dart';
import 'package:easyconnect/Models/client_model.dart';

@immutable
class DevisState {
  final List<Devis> devis;
  final Client? selectedClient;
  final bool isLoading;
  final Devis? currentDevis;
  final List<DevisItem> items;
  final bool isLoadingMore;
  final int? currentStatus;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final int perPage;
  final String searchQuery;
  final int totalDevis;
  final int devisEnvoyes;
  final int devisAcceptes;
  final int devisRefuses;
  final double tauxConversion;
  final double montantTotal;
  final List<Client> clients;
  final bool isLoadingClients;
  final String generatedReference;

  const DevisState({
    this.devis = const [],
    this.selectedClient,
    this.isLoading = false,
    this.currentDevis,
    this.items = const [],
    this.isLoadingMore = false,
    this.currentStatus,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalItems = 0,
    this.hasNextPage = false,
    this.hasPreviousPage = false,
    this.perPage = 15,
    this.searchQuery = '',
    this.totalDevis = 0,
    this.devisEnvoyes = 0,
    this.devisAcceptes = 0,
    this.devisRefuses = 0,
    this.tauxConversion = 0.0,
    this.montantTotal = 0.0,
    this.clients = const [],
    this.isLoadingClients = false,
    this.generatedReference = '',
  });

  DevisState copyWith({
    List<Devis>? devis,
    Client? selectedClient,
    bool? isLoading,
    Devis? currentDevis,
    List<DevisItem>? items,
    bool? isLoadingMore,
    int? currentStatus,
    int? currentPage,
    int? totalPages,
    int? totalItems,
    bool? hasNextPage,
    bool? hasPreviousPage,
    int? perPage,
    String? searchQuery,
    int? totalDevis,
    int? devisEnvoyes,
    int? devisAcceptes,
    int? devisRefuses,
    double? tauxConversion,
    double? montantTotal,
    List<Client>? clients,
    bool? isLoadingClients,
    String? generatedReference,
  }) {
    return DevisState(
      devis: devis ?? this.devis,
      selectedClient: selectedClient ?? this.selectedClient,
      isLoading: isLoading ?? this.isLoading,
      currentDevis: currentDevis ?? this.currentDevis,
      items: items ?? this.items,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      currentStatus: currentStatus ?? this.currentStatus,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalItems: totalItems ?? this.totalItems,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      hasPreviousPage: hasPreviousPage ?? this.hasPreviousPage,
      perPage: perPage ?? this.perPage,
      searchQuery: searchQuery ?? this.searchQuery,
      totalDevis: totalDevis ?? this.totalDevis,
      devisEnvoyes: devisEnvoyes ?? this.devisEnvoyes,
      devisAcceptes: devisAcceptes ?? this.devisAcceptes,
      devisRefuses: devisRefuses ?? this.devisRefuses,
      tauxConversion: tauxConversion ?? this.tauxConversion,
      montantTotal: montantTotal ?? this.montantTotal,
      clients: clients ?? this.clients,
      isLoadingClients: isLoadingClients ?? this.isLoadingClients,
      generatedReference: generatedReference ?? this.generatedReference,
    );
  }
}

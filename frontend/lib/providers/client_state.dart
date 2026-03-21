import 'package:flutter/material.dart';
import 'package:easyconnect/Models/client_model.dart';

/// État immutable de la liste des clients (pagination, filtre par statut, recherche).
@immutable
class ClientState {
  final List<Client> clients;
  final bool isLoading;
  final bool isLoadingMore;
  final int? currentStatus;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final int perPage;
  final String searchQuery;

  const ClientState({
    this.clients = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.currentStatus,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalItems = 0,
    this.hasNextPage = false,
    this.hasPreviousPage = false,
    this.perPage = 15,
    this.searchQuery = '',
  });

  ClientState copyWith({
    List<Client>? clients,
    bool? isLoading,
    bool? isLoadingMore,
    int? currentStatus,
    int? currentPage,
    int? totalPages,
    int? totalItems,
    bool? hasNextPage,
    bool? hasPreviousPage,
    int? perPage,
    String? searchQuery,
  }) {
    return ClientState(
      clients: clients ?? this.clients,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      currentStatus: currentStatus ?? this.currentStatus,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalItems: totalItems ?? this.totalItems,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      hasPreviousPage: hasPreviousPage ?? this.hasPreviousPage,
      perPage: perPage ?? this.perPage,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

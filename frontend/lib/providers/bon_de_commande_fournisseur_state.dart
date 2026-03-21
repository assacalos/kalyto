import 'package:flutter/material.dart';
import 'package:easyconnect/Models/bon_de_commande_fournisseur_model.dart';
import 'package:easyconnect/Models/supplier_model.dart';

@immutable
class BonDeCommandeFournisseurState {
  final List<BonDeCommande> bonDeCommandes;
  final Supplier? selectedSupplier;
  final List<Supplier> suppliers;
  final List<BonDeCommandeItem> items;
  final String generatedNumeroCommande;
  final bool isLoading;
  final bool isLoadingSuppliers;
  final BonDeCommande? currentBonDeCommande;
  final String? currentStatus; // 'en_attente', 'valide', 'rejete', 'livre', null = all

  const BonDeCommandeFournisseurState({
    this.bonDeCommandes = const [],
    this.selectedSupplier,
    this.suppliers = const [],
    this.items = const [],
    this.generatedNumeroCommande = '',
    this.isLoading = false,
    this.isLoadingSuppliers = false,
    this.currentBonDeCommande,
    this.currentStatus,
  });

  BonDeCommandeFournisseurState copyWith({
    List<BonDeCommande>? bonDeCommandes,
    Supplier? selectedSupplier,
    List<Supplier>? suppliers,
    List<BonDeCommandeItem>? items,
    String? generatedNumeroCommande,
    bool? isLoading,
    bool? isLoadingSuppliers,
    BonDeCommande? currentBonDeCommande,
    String? currentStatus,
  }) {
    return BonDeCommandeFournisseurState(
      bonDeCommandes: bonDeCommandes ?? this.bonDeCommandes,
      selectedSupplier: selectedSupplier ?? this.selectedSupplier,
      suppliers: suppliers ?? this.suppliers,
      items: items ?? this.items,
      generatedNumeroCommande:
          generatedNumeroCommande ?? this.generatedNumeroCommande,
      isLoading: isLoading ?? this.isLoading,
      isLoadingSuppliers: isLoadingSuppliers ?? this.isLoadingSuppliers,
      currentBonDeCommande: currentBonDeCommande ?? this.currentBonDeCommande,
      currentStatus: currentStatus ?? this.currentStatus,
    );
  }

  List<BonDeCommande> getFilteredBonDeCommandes() {
    if (currentStatus == null || currentStatus == 'all') {
      return bonDeCommandes;
    }
    final statusLower = currentStatus!.toLowerCase().trim();
    return bonDeCommandes.where((bc) {
      final bcStatus = bc.statut.toLowerCase().trim();
      switch (statusLower) {
        case 'en_attente':
        case 'pending':
          return bcStatus == 'en_attente' || bcStatus == 'pending';
        case 'valide':
        case 'approved':
        case 'validated':
          return bcStatus == 'valide' ||
              bcStatus == 'approved' ||
              bcStatus == 'validated';
        case 'rejete':
        case 'rejected':
          return bcStatus == 'rejete' || bcStatus == 'rejected';
        case 'livre':
          return bcStatus == 'livre';
        default:
          return bcStatus == statusLower;
      }
    }).toList();
  }
}

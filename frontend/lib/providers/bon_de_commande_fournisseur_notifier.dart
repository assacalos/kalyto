import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/Models/bon_de_commande_fournisseur_model.dart';
import 'package:easyconnect/Models/supplier_model.dart';
import 'package:easyconnect/providers/bon_de_commande_fournisseur_state.dart';
import 'package:easyconnect/services/bon_de_commande_fournisseur_service.dart';
import 'package:easyconnect/services/supplier_service.dart';
import 'package:easyconnect/services/pdf_service.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/utils/dashboard_refresh_helper.dart';
import 'package:easyconnect/utils/notification_helper.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/reference_generator.dart';

final bonDeCommandeFournisseurProvider =
    NotifierProvider<BonDeCommandeFournisseurNotifier,
        BonDeCommandeFournisseurState>(BonDeCommandeFournisseurNotifier.new);

class BonDeCommandeFournisseurNotifier
    extends Notifier<BonDeCommandeFournisseurState> {
  final BonDeCommandeFournisseurService _service =
      BonDeCommandeFournisseurService();
  final SupplierService _supplierService = SupplierService();
  static const String _cacheKey = 'bon_de_commandes_fournisseur_all';

  @override
  BonDeCommandeFournisseurState build() {
    return const BonDeCommandeFournisseurState();
  }

  void setCurrentStatus(String? status) {
    state = state.copyWith(currentStatus: status);
  }

  Future<void> loadBonDeCommandes({
    String? status,
    bool forceRefresh = false,
  }) async {
    state = state.copyWith(currentStatus: status);
    try {
      final cached =
          CacheHelper.get<List<BonDeCommande>>(_cacheKey);
      if (cached != null && cached.isNotEmpty && !forceRefresh) {
        state = state.copyWith(bonDeCommandes: cached, isLoading: false);
        return;
      }
      state = state.copyWith(isLoading: true);
      final list = await _service.getBonDeCommandes();
      state = state.copyWith(bonDeCommandes: list, isLoading: false);
      CacheHelper.set(_cacheKey, list);
    } catch (e) {
      AppLogger.error(
        'loadBonDeCommandes fournisseur: $e',
        tag: 'BON_DE_COMMANDE_FOURNISSEUR_NOTIFIER',
      );
      if (state.bonDeCommandes.isEmpty) {
        final fallback = CacheHelper.get<List<BonDeCommande>>(_cacheKey);
        if (fallback != null && fallback.isNotEmpty) {
          state = state.copyWith(bonDeCommandes: fallback, isLoading: false);
        }
        rethrow;
      }
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<BonDeCommande?> loadBonDeCommandeById(int id) async {
    try {
      return state.bonDeCommandes.firstWhere((b) => b.id == id);
    } catch (_) {}
    try {
      final bon = await _service.getBonDeCommande(id);
      state = state.copyWith(currentBonDeCommande: bon);
      return bon;
    } catch (e) {
      rethrow;
    }
  }

  BonDeCommande? getBonDeCommandeById(int id) {
    try {
      return state.bonDeCommandes.firstWhere((b) => b.id == id);
    } catch (_) {
      return state.currentBonDeCommande?.id == id
          ? state.currentBonDeCommande
          : null;
    }
  }

  Future<void> loadSuppliers() async {
    state = state.copyWith(isLoadingSuppliers: true);
    final cached = SupplierService.getCachedFournisseurs();
    if (cached.isNotEmpty) {
      state = state.copyWith(suppliers: cached, isLoadingSuppliers: false);
    }
    try {
      final suppliers = await _supplierService.getSuppliers();
      state = state.copyWith(suppliers: suppliers, isLoadingSuppliers: false);
    } catch (e) {
      if (state.suppliers.isEmpty && cached.isNotEmpty) {
        state = state.copyWith(suppliers: cached, isLoadingSuppliers: false);
      }
      state = state.copyWith(isLoadingSuppliers: false);
    }
  }

  Future<String> generateNumeroCommande() async {
    if (state.bonDeCommandes.isEmpty) await loadBonDeCommandes();
    final existing = state.bonDeCommandes
        .map((bc) => bc.numeroCommande)
        .where((num) => num.isNotEmpty)
        .toList();
    return ReferenceGenerator.generateReferenceWithIncrement('BCF', existing);
  }

  Future<void> initializeGeneratedNumeroCommande() async {
    if (state.generatedNumeroCommande.isEmpty) {
      final num = await generateNumeroCommande();
      state = state.copyWith(generatedNumeroCommande: num);
    }
  }

  void selectSupplier(Supplier? supplier) {
    state = state.copyWith(selectedSupplier: supplier);
  }

  void addItem(BonDeCommandeItem item) {
    state = state.copyWith(
        items: [...state.items, item]);
  }

  void removeItem(int index) {
    final list = List<BonDeCommandeItem>.from(state.items);
    list.removeAt(index);
    state = state.copyWith(items: list);
  }

  void updateItem(int index, BonDeCommandeItem item) {
    final list = List<BonDeCommandeItem>.from(state.items);
    if (index >= 0 && index < list.length) {
      list[index] = item;
      state = state.copyWith(items: list);
    }
  }

  void setItems(List<BonDeCommandeItem> items) {
    state = state.copyWith(items: items);
  }

  void clearForm() {
    state = state.copyWith(
      selectedSupplier: null,
      items: [],
      generatedNumeroCommande: '',
    );
    initializeGeneratedNumeroCommande();
  }

  Future<bool> createBonDeCommande(Map<String, dynamic> data) async {
    if (state.isLoading) return false;
    if (state.selectedSupplier == null) {
      throw Exception('Veuillez sélectionner un fournisseur');
    }
    if (state.selectedSupplier!.id == null) {
      throw Exception(
        'L\'ID du fournisseur est manquant. Veuillez sélectionner un fournisseur valide.',
      );
    }
    if (state.items.isEmpty) {
      throw Exception('Aucun article ajouté au bon de commande');
    }
    for (var i = 0; i < state.items.length; i++) {
      final item = state.items[i];
      if (item.designation.isEmpty) {
        throw Exception('La désignation de l\'article ${i + 1} est requise');
      }
      if (item.quantite <= 0) {
        throw Exception(
          'La quantité de l\'article ${i + 1} doit être supérieure à 0',
        );
      }
      if (item.prixUnitaire <= 0) {
        throw Exception(
          'Le prix unitaire de l\'article ${i + 1} doit être supérieur à 0',
        );
      }
    }
    final numeroCommande = state.generatedNumeroCommande.isNotEmpty
        ? state.generatedNumeroCommande
        : (data['numero_commande'] as String? ?? '');
    final newBon = BonDeCommande(
      clientId: null,
      fournisseurId: state.selectedSupplier!.id!,
      numeroCommande: numeroCommande,
      dateCommande: data['date_commande'] ?? DateTime.now(),
      description: data['description'],
      statut: 'en_attente',
      commentaire: data['commentaire'],
      conditionsPaiement: data['conditions_paiement'],
      delaiLivraison: data['delai_livraison'],
      items: state.items,
    );
    state = state.copyWith(isLoading: true);
    try {
      final created = await _service.createBonDeCommande(newBon);
      CacheHelper.clearByPrefix('bon_de_commandes_fournisseur_');
      final list = [created, ...state.bonDeCommandes];
      state = state.copyWith(bonDeCommandes: list, isLoading: false);
      if (created.id != null) {
        NotificationHelper.notifySubmission(
          entityType: 'bon_de_commande_fournisseur',
          entityName: NotificationHelper.getEntityDisplayName(
            'bon_de_commande_fournisseur',
            created,
          ),
          entityId: created.id.toString(),
          route: NotificationHelper.getEntityRoute(
            'bon_de_commande_fournisseur',
            created.id.toString(),
          ),
        );
      }
      DashboardRefreshHelper.refreshPatronCounter('bon_de_commande_fournisseur');
      clearForm();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<bool> updateBonDeCommande(
    int bonDeCommandeId,
    Map<String, dynamic> data,
  ) async {
    if (state.isLoading) return false;
    BonDeCommande? toUpdate;
    try {
      toUpdate =
          state.bonDeCommandes.firstWhere((b) => b.id == bonDeCommandeId);
    } catch (_) {
      toUpdate = null;
    }
    if (toUpdate == null) return false;
    final updated = BonDeCommande(
      id: bonDeCommandeId,
      clientId: data['client_id'] ?? toUpdate.clientId,
      fournisseurId: data['fournisseur_id'] ?? toUpdate.fournisseurId,
      numeroCommande: data['numero_commande'] ?? toUpdate.numeroCommande,
      dateCommande: toUpdate.dateCommande,
      description: data['description'] ?? toUpdate.description,
      statut: toUpdate.statut,
      commentaire: data['commentaire'] ?? toUpdate.commentaire,
      conditionsPaiement:
          data['conditions_paiement'] ?? toUpdate.conditionsPaiement,
      delaiLivraison: data['delai_livraison'] ?? toUpdate.delaiLivraison,
      items: state.items.isEmpty ? toUpdate.items : state.items,
    );
    state = state.copyWith(isLoading: true);
    try {
      await _service.updateBonDeCommande(bonDeCommandeId, updated);
      await loadBonDeCommandes(status: state.currentStatus);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> deleteBonDeCommande(int bonDeCommandeId) async {
    state = state.copyWith(isLoading: true);
    try {
      final success =
          await _service.deleteBonDeCommande(bonDeCommandeId);
      if (success) {
        state = state.copyWith(
          bonDeCommandes: state.bonDeCommandes
              .where((b) => b.id != bonDeCommandeId)
              .toList(),
        );
        CacheHelper.clearByPrefix('bon_de_commandes_fournisseur_');
      } else {
        throw Exception('Erreur lors de la suppression');
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> approveBonDeCommande(int bonDeCommandeId) async {
    state = state.copyWith(isLoading: true);
    CacheHelper.clearByPrefix('bon_de_commandes_fournisseur_');
    try {
      final success = await _service.validateBonDeCommande(bonDeCommandeId);
      if (success) {
        DashboardRefreshHelper.refreshPatronCounter('bon_de_commande_fournisseur');
        DashboardRefreshHelper.refreshCommercialDashboard();
        BonDeCommande? bon;
        try {
          bon = state.bonDeCommandes
              .firstWhere((b) => b.id == bonDeCommandeId);
        } catch (_) {
          bon = null;
        }
        if (bon != null) {
          NotificationHelper.notifyValidation(
            entityType: 'bon_de_commande_fournisseur',
            entityName: NotificationHelper.getEntityDisplayName(
              'bon_de_commande_fournisseur',
              bon,
            ),
            entityId: bonDeCommandeId.toString(),
            route: NotificationHelper.getEntityRoute(
              'bon_de_commande_fournisseur',
              bonDeCommandeId.toString(),
            ),
            entity: bon,
          );
        }
        Future.delayed(const Duration(milliseconds: 500),
            () => loadBonDeCommandes(status: state.currentStatus).catchError((_) {}));
      } else {
        await loadBonDeCommandes(status: state.currentStatus);
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> rejectBonDeCommande(int bonDeCommandeId, String commentaire) async {
    state = state.copyWith(isLoading: true);
    CacheHelper.clearByPrefix('bon_de_commandes_fournisseur_');
    try {
      final success =
          await _service.rejectBonDeCommande(bonDeCommandeId, commentaire);
      if (success) {
        DashboardRefreshHelper.refreshPatronCounter('bon_de_commande_fournisseur');
        DashboardRefreshHelper.refreshCommercialDashboard();
        BonDeCommande? bon;
        try {
          bon = state.bonDeCommandes
              .firstWhere((b) => b.id == bonDeCommandeId);
        } catch (_) {
          bon = null;
        }
        if (bon != null) {
          NotificationHelper.notifyRejection(
            entityType: 'bon_de_commande_fournisseur',
            entityName: NotificationHelper.getEntityDisplayName(
              'bon_de_commande_fournisseur',
              bon,
            ),
            entityId: bonDeCommandeId.toString(),
            reason: commentaire,
            route: NotificationHelper.getEntityRoute(
              'bon_de_commande_fournisseur',
              bonDeCommandeId.toString(),
            ),
            entity: bon,
          );
        }
        Future.delayed(const Duration(milliseconds: 500),
            () => loadBonDeCommandes(status: state.currentStatus).catchError((_) {}));
      } else {
        await loadBonDeCommandes(status: state.currentStatus);
        throw Exception('Erreur lors du rejet');
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> generatePDF(int bonDeCommandeId) async {
    state = state.copyWith(isLoading: true);
    try {
      BonDeCommande? bon = getBonDeCommandeById(bonDeCommandeId);
      if (bon == null) {
        bon = await loadBonDeCommandeById(bonDeCommandeId);
      }
      if (bon == null) throw Exception('Bon de commande introuvable');
      Supplier? supplier = state.selectedSupplier;
      if (supplier == null &&
          bon.fournisseurId != null &&
          state.suppliers.isNotEmpty) {
        try {
          supplier = state.suppliers
              .firstWhere((s) => s.id == bon!.fournisseurId);
        } catch (_) {}
      }
      final itemsData = bon.items
          .map(
            (item) => {
              'reference': item.ref ?? '',
              'ref': item.ref ?? '',
              'designation': item.designation,
              'quantite': item.quantite,
              'prix_unitaire': item.prixUnitaire,
              'montant_total': item.montantTotal,
            },
          )
          .toList();
      await PdfService().generateBonCommandePdf(
        bonCommande: {
          'reference': bon.numeroCommande,
          'titre': bon.description,
          'date_creation': bon.dateCommande,
          'montant_ht': bon.montantTotalCalcule,
          'tva': 0.0,
          'total_ttc': bon.montantTotalCalcule,
          'delai_livraison': bon.delaiLivraison,
          'conditions_paiement': bon.conditionsPaiement,
        },
        items: itemsData,
        fournisseur: {
          'nom': supplier?.nom ?? 'N/A',
          'email': supplier?.email ?? '',
          'contact': supplier?.telephone ?? '',
          'adresse': supplier?.adresse ?? '',
        },
      );
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

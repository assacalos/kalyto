class BonDeCommandeItem {
  final int? id;
  final String? ref;
  final String designation;
  final int quantite;
  final double prixUnitaire;
  final String? description;

  BonDeCommandeItem({
    this.id,
    this.ref,
    required this.designation,
    required this.quantite,
    required this.prixUnitaire,
    this.description,
  });

  double get montantTotal => quantite * prixUnitaire;

  Map<String, dynamic> toJson() => {
    'id': id,
    'ref': ref,
    'designation': designation,
    'quantite': quantite,
    'prix_unitaire': prixUnitaire,
    'description': description,
  };

  /// Méthode pour créer un JSON uniquement avec les champs nécessaires à la création
  Map<String, dynamic> toJsonForCreate() => {
    if (ref != null && ref!.isNotEmpty) 'ref': ref,
    'designation': designation,
    'quantite': quantite, // int
    'prix_unitaire': prixUnitaire, // double
    if (description != null && description!.isNotEmpty)
      'description': description,
  };

  factory BonDeCommandeItem.fromJson(Map<String, dynamic> json) =>
      BonDeCommandeItem(
        id: json['id'],
        ref: json['ref'],
        designation: json['designation'] ?? '',
        quantite:
            json['quantite'] is String
                ? int.tryParse(json['quantite']) ?? 0
                : json['quantite'] ?? 0,
        prixUnitaire:
            json['prix_unitaire'] is String
                ? double.tryParse(json['prix_unitaire']) ?? 0.0
                : (json['prix_unitaire']?.toDouble() ?? 0.0),
        description: json['description'],
      );
}

class BonDeCommande {
  final int? id;
  final int? clientId;
  final int? fournisseurId;
  final String numeroCommande;
  final DateTime dateCommande;
  final String? description;
  final String statut; // 'en_attente', 'valide', 'rejete', 'livre'
  final String? commentaire;
  final String? conditionsPaiement;
  final int? delaiLivraison;
  final double? montantTotal;
  final List<BonDeCommandeItem> items;

  BonDeCommande({
    this.id,
    this.clientId,
    this.fournisseurId,
    required this.numeroCommande,
    required this.dateCommande,
    this.description,
    this.statut = 'en_attente',
    this.commentaire,
    this.conditionsPaiement,
    this.delaiLivraison,
    this.montantTotal,
    required this.items,
  });

  // Calculer le montant total à partir des items
  double get montantTotalCalcule {
    return items.fold(0.0, (sum, item) => sum + item.montantTotal);
  }

  String get statusText {
    switch (statut.toLowerCase()) {
      case 'en_attente':
        return 'En attente';
      case 'valide':
      case 'validé':
        return 'Validé';
      case 'rejete':
      case 'rejeté':
        return 'Rejeté';
      case 'livre':
      case 'livré':
        return 'Livré';
      default:
        return 'Inconnu';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'client_id': clientId,
    'fournisseur_id': fournisseurId,
    'numero_commande': numeroCommande,
    'date_commande': dateCommande.toIso8601String().split('T')[0],
    'description': description,
    'statut': statut,
    'commentaire': commentaire,
    'conditions_paiement': conditionsPaiement,
    'delai_livraison': delaiLivraison,
    'montant_total': montantTotal,
    'items': items.map((item) => item.toJson()).toList(),
  };

  Map<String, dynamic> toJsonForCreate() => {
    // Ne jamais envoyer client_id pour un bon de commande fournisseur
    if (fournisseurId != null) 'fournisseur_id': fournisseurId,
    'numero_commande': numeroCommande,
    'date_commande': dateCommande.toIso8601String().split('T')[0],
    if (description != null && description!.isNotEmpty)
      'description': description,
    // La colonne dans la base de données s'appelle 'status' (en anglais)
    if (statut.isNotEmpty) 'status': statut,
    if (commentaire != null && commentaire!.isNotEmpty)
      'commentaire': commentaire,
    if (conditionsPaiement != null && conditionsPaiement!.isNotEmpty)
      'conditions_paiement': conditionsPaiement,
    if (delaiLivraison != null) 'delai_livraison': delaiLivraison,
    // Si items est fourni, ne pas envoyer montant_total (le backend le calcule automatiquement)
    // Si items est vide, envoyer montant_total si fourni
    if (items.isEmpty && montantTotal != null) 'montant_total': montantTotal,
    // Envoyer items seulement s'il y en a (le backend calcule alors montant_total automatiquement)
    if (items.isNotEmpty)
      'items': items.map((item) => item.toJsonForCreate()).toList(),
  };

  factory BonDeCommande.fromJson(Map<String, dynamic> json) => BonDeCommande(
    id: json['id'] is String ? int.tryParse(json['id']) : json['id'],
    clientId:
        json['client_id'] is String
            ? int.tryParse(json['client_id'])
            : json['client_id'],
    fournisseurId:
        json['fournisseur_id'] is String
            ? int.tryParse(json['fournisseur_id'])
            : json['fournisseur_id'],
    numeroCommande: json['numero_commande'] ?? '',
    dateCommande:
        json['date_commande'] != null
            ? DateTime.parse(json['date_commande'])
            : DateTime.now(),
    description: json['description'],
    // La colonne dans la base de données s'appelle 'status' (en anglais)
    statut:
        json['status']?.toString() ??
        json['statut']?.toString() ??
        'en_attente',
    commentaire: json['commentaire'],
    conditionsPaiement: json['conditions_paiement'],
    delaiLivraison:
        json['delai_livraison'] is String
            ? int.tryParse(json['delai_livraison'])
            : json['delai_livraison'],
    montantTotal:
        json['montant_total'] is String
            ? double.tryParse(json['montant_total'])
            : json['montant_total']?.toDouble(),
    items:
        json['items'] != null
            ? (json['items'] as List)
                .map((item) => BonDeCommandeItem.fromJson(item))
                .toList()
            : [],
  );
}

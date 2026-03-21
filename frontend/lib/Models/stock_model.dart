class Stock {
  final int? id;
  final String category; // Catégorie (string directement dans la table)
  final String name;
  final String? description; // Nullable selon la DB
  final String sku; // Stock Keeping Unit (unique)
  final String unit; // Unité de mesure (requis par le backend)
  final double quantity; // Quantité actuelle
  final double minQuantity; // Seuil minimum
  final double maxQuantity; // Seuil maximum
  final double unitPrice; // Prix unitaire
  final String? commentaire; // Commentaires (nullable)
  final String status; // 'en_attente', 'valide', 'rejete'
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<StockMovement>? movements;

  Stock({
    this.id,
    required this.category,
    required this.name,
    this.description,
    required this.sku,
    required this.unit,
    required this.quantity,
    required this.minQuantity,
    required this.maxQuantity,
    required this.unitPrice,
    this.commentaire,
    this.status = 'en_attente',
    this.createdAt,
    this.updatedAt,
    this.movements,
  });

  // Méthode utilitaire pour parser les doubles de manière sécurisée
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // Méthode utilitaire pour parser les dates de manière sécurisée
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  factory Stock.fromJson(Map<String, dynamic> jsonData) {
    try {
      final stock = Stock(
        id:
            jsonData['id'] != null
                ? int.tryParse(jsonData['id'].toString())
                : null,
        category: jsonData['category']?.toString() ?? '',
        name: jsonData['name']?.toString() ?? '',
        description: jsonData['description']?.toString(),
        sku: jsonData['sku']?.toString() ?? '',
        unit: jsonData['unit']?.toString() ?? 'pièce',
        // Supporte les deux formats : modèle Laravel (current_quantity) et migration (quantity)
        quantity: Stock._parseDouble(
          jsonData['current_quantity'] ?? jsonData['quantity'] ?? 0,
        ),
        // Supporte les deux formats : modèle Laravel (minimum_quantity) et migration (min_quantity)
        minQuantity: Stock._parseDouble(
          jsonData['minimum_quantity'] ??
              jsonData['min_quantity'] ??
              jsonData['minQuantity'] ??
              0,
        ),
        // Supporte les deux formats : modèle Laravel (maximum_quantity) et migration (max_quantity)
        maxQuantity: Stock._parseDouble(
          jsonData['maximum_quantity'] ??
              jsonData['max_quantity'] ??
              jsonData['maxQuantity'] ??
              0,
        ),
        // Supporte les deux formats : modèle Laravel (unit_cost) et migration (unit_price)
        unitPrice: Stock._parseDouble(
          jsonData['unit_cost'] ??
              jsonData['unit_price'] ??
              jsonData['unitPrice'] ??
              0,
        ),
        // Supporte les deux formats : modèle Laravel (notes) et migration (commentaire)
        commentaire:
            jsonData['notes']?.toString() ??
            jsonData['commentaire']?.toString() ??
            jsonData['comments']?.toString(),
        status: jsonData['status']?.toString() ?? 'en_attente',
        createdAt: Stock._parseDateTime(jsonData['created_at']),
        updatedAt: Stock._parseDateTime(jsonData['updated_at']),
        movements:
            jsonData['movements'] != null
                ? (jsonData['movements'] as List)
                    .map((m) => StockMovement.fromJson(m))
                    .toList()
                : null,
      );
      // Stocker le JSON original pour accéder aux champs calculés du backend
      stock.json = jsonData;
      return stock;
    } catch (e) {
      rethrow;
    }
  }

  // Sérialisation JSON pour création/mise à jour
  // Utilise les noms exacts du modèle Laravel ($fillable)
  Map<String, dynamic> toJson() {
    final jsonData = <String, dynamic>{
      if (id != null) 'id': id,
      'name': name,
      if (description != null && description!.isNotEmpty)
        'description': description,
      'category': category,
      'sku': sku,
      'quantity': quantity, // Migration DB: quantity (requis par validation)
      'current_quantity': quantity, // Modèle Laravel: current_quantity
      'min_quantity': minQuantity, // Migration DB: min_quantity (au cas où)
      'minimum_quantity': minQuantity, // Modèle Laravel: minimum_quantity
      'max_quantity': maxQuantity, // Migration DB: max_quantity (au cas où)
      'maximum_quantity': maxQuantity, // Modèle Laravel: maximum_quantity
      'unit_price': unitPrice, // Migration DB: unit_price (au cas où)
      'unit_cost': unitPrice, // Modèle Laravel: unit_cost
      if (commentaire != null && commentaire!.isNotEmpty)
        'commentaire': commentaire, // Migration DB: commentaire (au cas où)
      if (commentaire != null && commentaire!.isNotEmpty)
        'notes': commentaire, // Modèle Laravel: notes
      'status': status,
      // Tous les champs requis sont toujours envoyés, même s'ils sont à 0
    };
    // Note: 'unit' n'est pas envoyé car il n'existe pas dans le backend
    return jsonData;
  }

  // Propriétés calculées
  bool get isLowStock => quantity <= minQuantity;
  bool get isOutOfStock => quantity <= 0;
  bool get isOverstocked => maxQuantity > 0 && quantity >= maxQuantity;

  // Pour compatibilité avec l'ancien code
  double get currentQuantity => quantity;
  double get minimumQuantity => minQuantity;
  double get maximumQuantity => maxQuantity;
  double get unitCost => unitPrice;
  String get notes => commentaire ?? '';

  String get stockStatus {
    if (isOutOfStock) return 'Rupture';
    if (isLowStock) return 'Stock faible';
    if (isOverstocked) return 'Surstock';
    return 'Normal';
  }

  String get stockStatusText {
    switch (stockStatus) {
      case 'Rupture':
        return 'Rupture de stock';
      case 'Stock faible':
        return 'Stock faible';
      case 'Surstock':
        return 'Surstock';
      default:
        return 'Stock normal';
    }
  }

  String get stockStatusIcon {
    switch (stockStatus) {
      case 'Rupture':
        return 'error';
      case 'Stock faible':
        return 'warning';
      case 'Surstock':
        return 'info';
      default:
        return 'check_circle';
    }
  }

  String get stockStatusColor {
    switch (stockStatus) {
      case 'Rupture':
        return 'red';
      case 'Stock faible':
        return 'orange';
      case 'Surstock':
        return 'blue';
      default:
        return 'green';
    }
  }

  // Méthodes pour gérer le statut (en_attente, valide, rejete)
  bool get isPending => status == 'en_attente' || status == 'pending';
  bool get isValidated => status == 'valide' || status == 'approved';
  bool get isRejected => status == 'rejete' || status == 'rejected';

  String get statusText {
    switch (status.toLowerCase()) {
      case 'en_attente':
      case 'pending':
        return 'En attente';
      case 'valide':
      case 'approved':
        return 'Validé';
      case 'rejete':
      case 'rejected':
        return 'Rejeté';
      default:
        return 'Inconnu';
    }
  }

  String get statusIcon {
    switch (status.toLowerCase()) {
      case 'en_attente':
      case 'pending':
        return 'schedule';
      case 'valide':
      case 'approved':
        return 'check_circle';
      case 'rejete':
      case 'rejected':
        return 'cancel';
      default:
        return 'help';
    }
  }

  String get statusColor {
    switch (status.toLowerCase()) {
      case 'en_attente':
      case 'pending':
        return 'orange';
      case 'valide':
      case 'approved':
        return 'green';
      case 'rejete':
      case 'rejected':
        return 'red';
      default:
        return 'grey';
    }
  }

  // Pour compatibilité avec l'ancien code
  bool get isActive => isValidated;
  bool get isInactive => isPending;
  bool get isDiscontinued => isRejected;

  double get totalValue => quantity * unitPrice;

  String get formattedQuantity => '${quantity.toStringAsFixed(2)}';
  String get formattedUnitPrice => '${unitPrice.toStringAsFixed(2)} FCFA';
  String get formattedTotalValue => '${totalValue.toStringAsFixed(2)} FCFA';

  // Stocker le JSON original pour accéder aux champs calculés du backend
  Map<String, dynamic>? json;

  // Méthode de copie
  Stock copyWith({
    int? id,
    String? category,
    String? name,
    String? description,
    String? sku,
    String? unit,
    double? quantity,
    double? minQuantity,
    double? maxQuantity,
    double? unitPrice,
    String? commentaire,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<StockMovement>? movements,
  }) {
    return Stock(
      id: id ?? this.id,
      category: category ?? this.category,
      name: name ?? this.name,
      description: description ?? this.description,
      sku: sku ?? this.sku,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      minQuantity: minQuantity ?? this.minQuantity,
      maxQuantity: maxQuantity ?? this.maxQuantity,
      unitPrice: unitPrice ?? this.unitPrice,
      commentaire: commentaire ?? this.commentaire,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      movements: movements ?? this.movements,
    )..json = this.json;
  }

  get user => null;
}

class StockMovement {
  final int? id;
  final int stockId;
  final String type; // 'in', 'out', 'adjustment', 'transfer'
  final double quantity;
  final String? reason;
  final String? reference; // Référence du mouvement (commande, facture, etc.)
  final String? notes;
  final DateTime createdAt;
  final String? createdBy;

  const StockMovement({
    this.id,
    required this.stockId,
    required this.type,
    required this.quantity,
    this.reason,
    this.reference,
    this.notes,
    required this.createdAt,
    this.createdBy,
  });

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    return StockMovement(
      id: json['id'],
      stockId: json['stock_id'] ?? 0,
      type: json['type'] ?? '',
      quantity: Stock._parseDouble(json['quantity']),
      reason: json['reason'],
      reference: json['reference'],
      notes: json['notes'],
      createdAt: Stock._parseDateTime(json['created_at']),
      createdBy: json['created_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stock_id': stockId,
      'type': type,
      'quantity': quantity,
      'reason': reason,
      'reference': reference,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
    };
  }

  String get typeText {
    switch (type) {
      case 'in':
        return 'Entrée';
      case 'out':
        return 'Sortie';
      case 'adjustment':
        return 'Ajustement';
      case 'transfer':
        return 'Transfert';
      default:
        return type;
    }
  }

  String get typeIcon {
    switch (type) {
      case 'in':
        return 'add';
      case 'out':
        return 'remove';
      case 'adjustment':
        return 'edit';
      case 'transfer':
        return 'swap_horiz';
      default:
        return 'help';
    }
  }

  String get typeColor {
    switch (type) {
      case 'in':
        return 'green';
      case 'out':
        return 'red';
      case 'adjustment':
        return 'blue';
      case 'transfer':
        return 'orange';
      default:
        return 'grey';
    }
  }
}

class StockCategory {
  final int? id;
  final String name;
  final String description;
  final String? parentCategory;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StockCategory({
    this.id,
    required this.name,
    required this.description,
    this.parentCategory,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StockCategory.fromJson(Map<String, dynamic> json) {
    return StockCategory(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      parentCategory: json['parent_category'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'parent_category': parentCategory,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class StockAlert {
  final int? id;
  final int stockId;
  final String type; // 'low_stock', 'out_of_stock', 'overstock'
  final String message;
  final bool isRead;
  final DateTime createdAt;

  const StockAlert({
    this.id,
    required this.stockId,
    required this.type,
    required this.message,
    this.isRead = false,
    required this.createdAt,
  });

  factory StockAlert.fromJson(Map<String, dynamic> json) {
    return StockAlert(
      id: json['id'],
      stockId: json['stock_id'] ?? 0,
      type: json['type'] ?? '',
      message: json['message'] ?? '',
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stock_id': stockId,
      'type': type,
      'message': message,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get typeText {
    switch (type) {
      case 'low_stock':
        return 'Stock faible';
      case 'out_of_stock':
        return 'Rupture de stock';
      case 'overstock':
        return 'Surstock';
      default:
        return type;
    }
  }

  String get typeIcon {
    switch (type) {
      case 'low_stock':
        return 'warning';
      case 'out_of_stock':
        return 'error';
      case 'overstock':
        return 'info';
      default:
        return 'help';
    }
  }

  String get typeColor {
    switch (type) {
      case 'low_stock':
        return 'orange';
      case 'out_of_stock':
        return 'red';
      case 'overstock':
        return 'blue';
      default:
        return 'grey';
    }
  }
}

class StockStats {
  final int totalProducts;
  final int activeProducts;
  final int lowStockProducts;
  final int outOfStockProducts;
  final int overstockedProducts;
  final double totalValue;
  final double averageValue;
  final int totalMovements;
  final int movementsThisMonth;
  final List<StockCategory> topCategories;
  final List<Stock> topProducts;

  const StockStats({
    required this.totalProducts,
    required this.activeProducts,
    required this.lowStockProducts,
    required this.outOfStockProducts,
    required this.overstockedProducts,
    required this.totalValue,
    required this.averageValue,
    required this.totalMovements,
    required this.movementsThisMonth,
    required this.topCategories,
    required this.topProducts,
  });

  factory StockStats.fromJson(Map<String, dynamic> json) {
    return StockStats(
      totalProducts: json['total_products'] ?? 0,
      activeProducts: json['active_products'] ?? 0,
      lowStockProducts: json['low_stock_products'] ?? 0,
      outOfStockProducts: json['out_of_stock_products'] ?? 0,
      overstockedProducts: json['overstocked_products'] ?? 0,
      totalValue: Stock._parseDouble(json['total_value']),
      averageValue: Stock._parseDouble(json['average_value']),
      totalMovements: json['total_movements'] ?? 0,
      movementsThisMonth: json['movements_this_month'] ?? 0,
      topCategories:
          json['top_categories'] != null
              ? (json['top_categories'] as List)
                  .map((c) => StockCategory.fromJson(c))
                  .toList()
              : [],
      topProducts:
          json['top_products'] != null
              ? (json['top_products'] as List)
                  .map((p) => Stock.fromJson(p))
                  .toList()
              : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_products': totalProducts,
      'active_products': activeProducts,
      'low_stock_products': lowStockProducts,
      'out_of_stock_products': outOfStockProducts,
      'overstocked_products': overstockedProducts,
      'total_value': totalValue,
      'average_value': averageValue,
      'total_movements': totalMovements,
      'movements_this_month': movementsThisMonth,
      'top_categories': topCategories.map((c) => c.toJson()).toList(),
      'top_products': topProducts.map((p) => p.toJson()).toList(),
    };
  }
}

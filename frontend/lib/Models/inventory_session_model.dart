import 'package:flutter/material.dart';

/// Session d'inventaire physique (date, dépôt, statut).
class InventorySession {
  final int? id;
  final String? date;
  final String? depot;
  final String status; // 'in_progress' | 'closed'
  final String? closedAt;
  final int? linesCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const InventorySession({
    this.id,
    this.date,
    this.depot,
    this.status = 'in_progress',
    this.closedAt,
    this.linesCount,
    this.createdAt,
    this.updatedAt,
  });

  factory InventorySession.fromJson(Map<String, dynamic> json) {
    return InventorySession(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      date: json['date']?.toString(),
      depot: json['depot']?.toString(),
      status: json['status']?.toString() ?? 'in_progress',
      closedAt: json['closed_at']?.toString(),
      linesCount: json['lines_count'] != null
          ? int.tryParse(json['lines_count'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'depot': depot,
        'status': status,
        'closed_at': closedAt,
        'lines_count': linesCount,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  bool get isClosed => status == 'closed';
  String get statusLabel => isClosed ? 'Clôturé' : 'En cours';
  Color get statusColor => isClosed ? Colors.grey : Colors.green;
}

/// Ligne d'inventaire : article (réf. stock) + quantité théorique + comptée + écart.
class InventoryLine {
  final int? id;
  final int? sessionId;
  final int? stockId;
  final String? sku;
  final String? productName;
  final String? unit;
  final double theoreticalQty;
  final double? countedQty;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const InventoryLine({
    this.id,
    this.sessionId,
    this.stockId,
    this.sku,
    this.productName,
    this.unit,
    required this.theoreticalQty,
    this.countedQty,
    this.createdAt,
    this.updatedAt,
  });

  double get countedOrZero => countedQty ?? 0.0;
  double get ecart => countedOrZero - theoreticalQty;
  bool get hasEcart => ecart != 0;

  factory InventoryLine.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }
    return InventoryLine(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      sessionId: json['session_id'] != null
          ? int.tryParse(json['session_id'].toString())
          : null,
      stockId: json['stock_id'] != null
          ? int.tryParse(json['stock_id'].toString())
          : null,
      sku: json['sku']?.toString(),
      productName: json['product_name']?.toString() ?? json['name']?.toString(),
      unit: json['unit']?.toString() ?? 'pièce',
      theoreticalQty: parseDouble(json['theoretical_qty'] ?? json['quantity']),
      countedQty: json['counted_qty'] != null
          ? parseDouble(json['counted_qty'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'session_id': sessionId,
        'stock_id': stockId,
        'sku': sku,
        'product_name': productName,
        'unit': unit,
        'theoretical_qty': theoreticalQty,
        'counted_qty': countedQty,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  InventoryLine copyWith({
    int? id,
    int? sessionId,
    int? stockId,
    String? sku,
    String? productName,
    String? unit,
    double? theoreticalQty,
    double? countedQty,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryLine(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      stockId: stockId ?? this.stockId,
      sku: sku ?? this.sku,
      productName: productName ?? this.productName,
      unit: unit ?? this.unit,
      theoreticalQty: theoreticalQty ?? this.theoreticalQty,
      countedQty: countedQty ?? this.countedQty,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

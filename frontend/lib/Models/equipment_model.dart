import 'package:flutter/material.dart';

class Equipment {
  final int? id;
  final String name;
  final String description;
  final String category;
  final String
  status; // 'active', 'inactive', 'maintenance', 'broken', 'retired'
  final String condition; // 'excellent', 'good', 'fair', 'poor', 'critical'
  final String? serialNumber;
  final String? model;
  final String? brand;
  final String? location;
  final String? department;
  final String? assignedTo;
  final DateTime? purchaseDate;
  final DateTime? warrantyExpiry;
  final DateTime? lastMaintenance;
  final DateTime? nextMaintenance;
  final double? purchasePrice;
  final double? currentValue;
  final String? supplier;
  final String? notes;
  final List<String>? attachments;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? createdBy;
  final int? updatedBy;

  Equipment({
    this.id,
    required this.name,
    required this.description,
    required this.category,
    this.status = 'active',
    this.condition = 'good',
    this.serialNumber,
    this.model,
    this.brand,
    this.location,
    this.department,
    this.assignedTo,
    this.purchaseDate,
    this.warrantyExpiry,
    this.lastMaintenance,
    this.nextMaintenance,
    this.purchasePrice,
    this.currentValue,
    this.supplier,
    this.notes,
    this.attachments,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    // Helper function pour parser les dates de manière sécurisée
    DateTime? _parseDate(dynamic dateValue) {
      if (dateValue == null) return null;
      try {
        if (dateValue is String) {
          return DateTime.parse(dateValue);
        }
        return null;
      } catch (e) {
        return null;
      }
    }

    // Helper function pour normaliser le statut
    String _normalizeStatus(dynamic statusValue) {
      print('🔍 [EQUIPMENT_MODEL] Normalisation du statut: $statusValue (type: ${statusValue.runtimeType})');
      
      if (statusValue == null) {
        print('⚠️ [EQUIPMENT_MODEL] Statut null, utilisation de "active" par défaut');
        return 'active';
      }
      
      // Si c'est un entier, mapper vers les valeurs de statut
      if (statusValue is int) {
        print('🔍 [EQUIPMENT_MODEL] Statut est un entier: $statusValue');
        final intStatusMap = {
          1: 'active',
          0: 'inactive',
          2: 'maintenance',
          3: 'broken',
          4: 'retired',
          5: 'pending',
        };
        if (intStatusMap.containsKey(statusValue)) {
          final normalized = intStatusMap[statusValue]!;
          print('✅ [EQUIPMENT_MODEL] Statut entier $statusValue mappé vers "$normalized"');
          return normalized;
        }
        print('⚠️ [EQUIPMENT_MODEL] Statut entier $statusValue non reconnu, utilisation de "active" par défaut');
        return 'active';
      }
      
      final statusStr = statusValue.toString().toLowerCase().trim();
      print('🔍 [EQUIPMENT_MODEL] Statut en string: "$statusStr"');
      
      // Mapper les libellés français vers les valeurs anglaises
      final statusMap = {
        'actif': 'active',
        'inactif': 'inactive',
        'en maintenance': 'maintenance',
        'hors service': 'broken',
        'retiré': 'retired',
        'retire': 'retired',
        'en attente': 'pending',
        'en_attente': 'pending',
        'pending': 'pending',
      };
      // Vérifier si c'est un libellé français
      if (statusMap.containsKey(statusStr)) {
        final normalized = statusMap[statusStr]!;
        print('✅ [EQUIPMENT_MODEL] Statut français "$statusStr" mappé vers "$normalized"');
        return normalized;
      }
      // Vérifier si c'est déjà une valeur valide
      if ([
        'active',
        'inactive',
        'maintenance',
        'broken',
        'retired',
        'pending',
        'en_attente',
      ].contains(statusStr)) {
        print('✅ [EQUIPMENT_MODEL] Statut "$statusStr" est déjà valide');
        return statusStr;
      }
      print('⚠️ [EQUIPMENT_MODEL] Statut "$statusStr" non reconnu, utilisation de "active" par défaut');
      return 'active'; // Valeur par défaut
    }

    return Equipment(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      status: _normalizeStatus(json['status']),
      condition: json['condition'] ?? 'good',
      serialNumber: json['serial_number'],
      model: json['model'],
      brand: json['brand'],
      location: json['location'],
      department: json['department'],
      assignedTo: json['assigned_to'],
      purchaseDate: _parseDate(json['purchase_date']),
      warrantyExpiry: _parseDate(json['warranty_expiry']),
      lastMaintenance: _parseDate(json['last_maintenance']),
      nextMaintenance: _parseDate(json['next_maintenance']),
      purchasePrice:
          json['purchase_price'] != null
              ? double.tryParse(json['purchase_price'].toString())
              : null,
      currentValue:
          json['current_value'] != null
              ? double.tryParse(json['current_value'].toString())
              : null,
      supplier: json['supplier'],
      notes: json['notes'],
      attachments:
          json['attachments'] != null
              ? List<String>.from(json['attachments'])
              : null,
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updated_at']) ?? DateTime.now(),
      createdBy: json['created_by'],
      updatedBy: json['updated_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'status': status,
      'condition': condition,
      'serial_number': serialNumber,
      'model': model,
      'brand': brand,
      'location': location,
      'department': department,
      'assigned_to': assignedTo,
      'purchase_date': purchaseDate?.toIso8601String(),
      'warranty_expiry': warrantyExpiry?.toIso8601String(),
      'last_maintenance': lastMaintenance?.toIso8601String(),
      'next_maintenance': nextMaintenance?.toIso8601String(),
      'purchase_price': purchasePrice,
      'current_value': currentValue,
      'supplier': supplier,
      'notes': notes,
      'attachments': attachments,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
      'updated_by': updatedBy,
    };
  }

  // Méthodes utilitaires
  String get statusText {
    switch (status) {
      case 'active':
        return 'Actif';
      case 'inactive':
        return 'Inactif';
      case 'maintenance':
        return 'En maintenance';
      case 'broken':
        return 'Hors service';
      case 'retired':
        return 'Retiré';
      case 'pending':
      case 'en_attente':
        return 'En attente';
      default:
        return 'Inconnu';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.grey;
      case 'maintenance':
        return Colors.orange;
      case 'broken':
        return Colors.red;
      case 'retired':
        return Colors.purple;
      case 'pending':
      case 'en_attente':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'active':
        return Icons.check_circle;
      case 'inactive':
        return Icons.pause_circle;
      case 'maintenance':
        return Icons.build;
      case 'broken':
        return Icons.error;
      case 'retired':
        return Icons.archive;
      case 'pending':
      case 'en_attente':
        return Icons.hourglass_empty;
      default:
        return Icons.help;
    }
  }

  String get conditionText {
    switch (condition) {
      case 'excellent':
        return 'Excellent';
      case 'good':
        return 'Bon';
      case 'fair':
        return 'Correct';
      case 'poor':
        return 'Mauvais';
      case 'critical':
        return 'Critique';
      default:
        return 'Inconnu';
    }
  }

  Color get conditionColor {
    switch (condition) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.blue;
      case 'fair':
        return Colors.orange;
      case 'poor':
        return Colors.red;
      case 'critical':
        return Colors.red[800]!;
      default:
        return Colors.grey;
    }
  }

  IconData get conditionIcon {
    switch (condition) {
      case 'excellent':
        return Icons.star;
      case 'good':
        return Icons.thumb_up;
      case 'fair':
        return Icons.thumbs_up_down;
      case 'poor':
        return Icons.thumb_down;
      case 'critical':
        return Icons.warning;
      default:
        return Icons.help;
    }
  }

  // Vérifier si l'équipement nécessite une maintenance
  bool get needsMaintenance {
    if (nextMaintenance == null) return false;
    return DateTime.now().isAfter(nextMaintenance!);
  }

  // Vérifier si la garantie est expirée
  bool get isWarrantyExpired {
    if (warrantyExpiry == null) return false;
    return DateTime.now().isAfter(warrantyExpiry!);
  }

  // Vérifier si la garantie expire bientôt
  bool get isWarrantyExpiringSoon {
    if (warrantyExpiry == null) return false;
    final now = DateTime.now();
    final expiryDate = warrantyExpiry!;
    final daysUntilExpiry = expiryDate.difference(now).inDays;
    return daysUntilExpiry <= 30 && daysUntilExpiry > 0;
  }

  // Calculer l'âge de l'équipement
  int? get ageInYears {
    if (purchaseDate == null) return null;
    return DateTime.now().difference(purchaseDate!).inDays ~/ 365;
  }

  // Calculer la dépréciation
  double? get depreciationRate {
    if (purchasePrice == null || currentValue == null) return null;
    if (purchasePrice == 0) return null;
    return ((purchasePrice! - currentValue!) / purchasePrice!) * 100;
  }
}

class EquipmentCategory {
  final int? id;
  final String name;
  final String description;
  final String? icon;
  final Color? color;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  EquipmentCategory({
    this.id,
    required this.name,
    required this.description,
    this.icon,
    this.color,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EquipmentCategory.fromJson(Map<String, dynamic> json) {
    // Helper function pour parser les dates de manière sécurisée
    DateTime? _parseDate(dynamic dateValue) {
      if (dateValue == null) return null;
      try {
        if (dateValue is String) {
          return DateTime.parse(dateValue);
        }
        return null;
      } catch (e) {
        return null;
      }
    }

    return EquipmentCategory(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'],
      color: json['color'] != null ? Color(json['color']) : null,
      isActive: json['is_active'] ?? true,
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updated_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color?.value,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class EquipmentStats {
  final int totalEquipment;
  final int activeEquipment;
  final int inactiveEquipment;
  final int maintenanceEquipment;
  final int brokenEquipment;
  final int retiredEquipment;
  final int excellentCondition;
  final int goodCondition;
  final int fairCondition;
  final int poorCondition;
  final int criticalCondition;
  final int needsMaintenance;
  final int warrantyExpired;
  final int warrantyExpiringSoon;
  final double totalValue;
  final double averageAge;
  final Map<String, int> equipmentByCategory;
  final Map<String, int> equipmentByStatus;
  final Map<String, int> equipmentByCondition;

  EquipmentStats({
    required this.totalEquipment,
    required this.activeEquipment,
    required this.inactiveEquipment,
    required this.maintenanceEquipment,
    required this.brokenEquipment,
    required this.retiredEquipment,
    required this.excellentCondition,
    required this.goodCondition,
    required this.fairCondition,
    required this.poorCondition,
    required this.criticalCondition,
    required this.needsMaintenance,
    required this.warrantyExpired,
    required this.warrantyExpiringSoon,
    required this.totalValue,
    required this.averageAge,
    required this.equipmentByCategory,
    required this.equipmentByStatus,
    required this.equipmentByCondition,
  });

  factory EquipmentStats.fromJson(Map<String, dynamic> json) {
    return EquipmentStats(
      totalEquipment: json['total_equipment'] ?? 0,
      activeEquipment: json['active_equipment'] ?? 0,
      inactiveEquipment: json['inactive_equipment'] ?? 0,
      maintenanceEquipment: json['maintenance_equipment'] ?? 0,
      brokenEquipment: json['broken_equipment'] ?? 0,
      retiredEquipment: json['retired_equipment'] ?? 0,
      excellentCondition: json['excellent_condition'] ?? 0,
      goodCondition: json['good_condition'] ?? 0,
      fairCondition: json['fair_condition'] ?? 0,
      poorCondition: json['poor_condition'] ?? 0,
      criticalCondition: json['critical_condition'] ?? 0,
      needsMaintenance: json['needs_maintenance'] ?? 0,
      warrantyExpired: json['warranty_expired'] ?? 0,
      warrantyExpiringSoon: json['warranty_expiring_soon'] ?? 0,
      totalValue: (json['total_value'] ?? 0.0).toDouble(),
      averageAge: (json['average_age'] ?? 0.0).toDouble(),
      equipmentByCategory: Map<String, int>.from(
        json['equipment_by_category'] ?? {},
      ),
      equipmentByStatus: Map<String, int>.from(
        json['equipment_by_status'] ?? {},
      ),
      equipmentByCondition: Map<String, int>.from(
        json['equipment_by_condition'] ?? {},
      ),
    );
  }
}

class EquipmentMaintenance {
  final int? id;
  final int equipmentId;
  final String type; // 'preventive', 'corrective', 'emergency'
  final String status; // 'scheduled', 'in_progress', 'completed', 'cancelled'
  final String description;
  final String? notes;
  final DateTime scheduledDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? technician;
  final double? cost;
  final List<String>? attachments;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? createdBy;

  EquipmentMaintenance({
    this.id,
    required this.equipmentId,
    required this.type,
    this.status = 'scheduled',
    required this.description,
    this.notes,
    required this.scheduledDate,
    this.startDate,
    this.endDate,
    this.technician,
    this.cost,
    this.attachments,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  factory EquipmentMaintenance.fromJson(Map<String, dynamic> json) {
    // Helper function pour parser les dates de manière sécurisée
    DateTime? _parseDate(dynamic dateValue) {
      if (dateValue == null) return null;
      try {
        if (dateValue is String) {
          return DateTime.parse(dateValue);
        }
        return null;
      } catch (e) {
        return null;
      }
    }

    return EquipmentMaintenance(
      id: json['id'],
      equipmentId: json['equipment_id'] ?? 0,
      type: json['type'] ?? 'preventive',
      status: json['status'] ?? 'scheduled',
      description: json['description'] ?? '',
      notes: json['notes'],
      scheduledDate: _parseDate(json['scheduled_date']) ?? DateTime.now(),
      startDate: _parseDate(json['start_date']),
      endDate: _parseDate(json['end_date']),
      technician: json['technician'],
      cost: json['cost']?.toDouble(),
      attachments:
          json['attachments'] != null
              ? List<String>.from(json['attachments'])
              : null,
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updated_at']) ?? DateTime.now(),
      createdBy: json['created_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'equipment_id': equipmentId,
      'type': type,
      'status': status,
      'description': description,
      'notes': notes,
      'scheduled_date': scheduledDate.toIso8601String(),
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'technician': technician,
      'cost': cost,
      'attachments': attachments,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
    };
  }

  String get typeText {
    switch (type) {
      case 'preventive':
        return 'Préventive';
      case 'corrective':
        return 'Corrective';
      case 'emergency':
        return 'Urgente';
      default:
        return 'Inconnue';
    }
  }

  String get statusText {
    switch (status) {
      case 'scheduled':
        return 'Programmée';
      case 'in_progress':
        return 'En cours';
      case 'completed':
        return 'Terminée';
      case 'cancelled':
        return 'Annulée';
      default:
        return 'Inconnue';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'scheduled':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

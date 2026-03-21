import 'package:flutter/material.dart';
import 'package:easyconnect/utils/app_config.dart';

class Expense {
  final int? id;
  final String title;
  final String description;
  final double amount;
  final String category;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime expenseDate;
  final String? receiptPath;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? createdBy;
  final int? approvedBy;
  final String? rejectionReason;
  final String? approvedAt;

  Expense({
    this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.category,
    this.status = 'pending',
    required this.expenseDate,
    this.receiptPath,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.approvedBy,
    this.rejectionReason,
    this.approvedAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    // Helper pour parser les dates de manière sécurisée
    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) return DateTime.now();
      if (dateValue is DateTime) return dateValue;
      if (dateValue is String) {
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return Expense(
      id: json['id'] is String ? int.tryParse(json['id']) : json['id'],
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      amount:
          json['amount'] is String
              ? double.tryParse(json['amount']) ?? 0.0
              : (json['amount']?.toDouble() ?? 0.0),
      category: json['category']?.toString() ?? 'other',
      status: json['status']?.toString() ?? 'pending',
      expenseDate: parseDate(json['expense_date'] ?? json['expenseDate']),
      receiptPath:
          json['receipt_path']?.toString() ?? json['receiptPath']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: parseDate(json['created_at'] ?? json['createdAt']),
      updatedAt: parseDate(json['updated_at'] ?? json['updatedAt']),
      createdBy:
          json['created_by'] is String
              ? int.tryParse(json['created_by'])
              : json['created_by'],
      approvedBy:
          json['approved_by'] is String
              ? int.tryParse(json['approved_by'])
              : json['approved_by'],
      rejectionReason:
          json['rejection_reason']?.toString() ??
          json['rejectionReason']?.toString(),
      approvedAt:
          json['approved_at']?.toString() ?? json['approvedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'amount': amount,
      'category': category,
      'status': status,
      'expense_date': expenseDate.toIso8601String(),
      'receipt_path': receiptPath,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
      'approved_by': approvedBy,
      'rejection_reason': rejectionReason,
      'approved_at': approvedAt,
    };
  }

  // Méthodes utilitaires
  String get statusText {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'approved':
        return 'Approuvée';
      case 'rejected':
        return 'Rejetée';
      default:
        return 'Inconnu';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String get categoryText {
    switch (category) {
      case 'office_supplies':
        return 'Fournitures de bureau';
      case 'travel':
        return 'Voyage';
      case 'meals':
        return 'Repas';
      case 'transport':
        return 'Transport';
      case 'utilities':
        return 'Services publics';
      case 'marketing':
        return 'Marketing';
      case 'equipment':
        return 'Équipement';
      case 'other':
        return 'Autre';
      default:
        return 'Inconnu';
    }
  }

  Color get categoryColor {
    switch (category) {
      case 'office_supplies':
        return Colors.blue;
      case 'travel':
        return Colors.purple;
      case 'meals':
        return Colors.orange;
      case 'transport':
        return Colors.green;
      case 'utilities':
        return Colors.red;
      case 'marketing':
        return Colors.pink;
      case 'equipment':
        return Colors.indigo;
      case 'other':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData get categoryIcon {
    switch (category) {
      case 'office_supplies':
        return Icons.work;
      case 'travel':
        return Icons.flight;
      case 'meals':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'utilities':
        return Icons.electrical_services;
      case 'marketing':
        return Icons.campaign;
      case 'equipment':
        return Icons.computer;
      case 'other':
        return Icons.category;
      default:
        return Icons.help;
    }
  }

  /// Construire l'URL complète du reçu
  String get receiptUrl {
    if (receiptPath != null && receiptPath!.isNotEmpty) {
      // Si le receiptPath est déjà une URL complète, le retourner tel quel
      if (receiptPath!.startsWith('http://') ||
          receiptPath!.startsWith('https://')) {
        return receiptPath!;
      }

      // Construire l'URL complète avec la base URL
      // Enlever /api de la fin de baseUrl car storage est à la racine du serveur
      String baseUrlWithoutApi = AppConfig.baseUrl;
      if (baseUrlWithoutApi.endsWith('/api')) {
        baseUrlWithoutApi = baseUrlWithoutApi.substring(
          0,
          baseUrlWithoutApi.length - 4,
        );
      }

      // Nettoyer le receiptPath
      String cleanPath = receiptPath!;
      if (cleanPath.startsWith('/')) {
        cleanPath = cleanPath.substring(1);
      }

      // Si le receiptPath contient déjà storage/, l'utiliser tel quel
      if (cleanPath.contains('storage/')) {
        return '$baseUrlWithoutApi/$cleanPath';
      }

      // Sinon, ajouter storage/ devant
      return '$baseUrlWithoutApi/storage/$cleanPath';
    }
    return '';
  }

  /// URL pour télécharger le reçu
  String get receiptDownloadUrl {
    final url = receiptUrl;
    if (url.isNotEmpty) {
      return '$url?download=1';
    }
    return '';
  }
}

class ExpenseCategory {
  final int? id;
  final String name;
  final String description;
  final String color;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExpenseCategory({
    this.id,
    required this.name,
    required this.description,
    required this.color,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) {
    return ExpenseCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      color: json['color'] ?? '#000000',
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class ExpenseStats {
  final double totalAmount;
  final double pendingAmount;
  final double approvedAmount;
  final double rejectedAmount;
  final int totalExpenses;
  final int pendingExpenses;
  final int approvedExpenses;
  final int rejectedExpenses;
  final Map<String, double> amountByCategory;
  final Map<String, int> countByCategory;

  ExpenseStats({
    required this.totalAmount,
    required this.pendingAmount,
    required this.approvedAmount,
    required this.rejectedAmount,
    required this.totalExpenses,
    required this.pendingExpenses,
    required this.approvedExpenses,
    required this.rejectedExpenses,
    required this.amountByCategory,
    required this.countByCategory,
  });

  factory ExpenseStats.fromJson(Map<String, dynamic> json) {
    return ExpenseStats(
      totalAmount: (json['total_amount'] ?? 0.0).toDouble(),
      pendingAmount: (json['pending_amount'] ?? 0.0).toDouble(),
      approvedAmount: (json['approved_amount'] ?? 0.0).toDouble(),
      rejectedAmount: (json['rejected_amount'] ?? 0.0).toDouble(),
      totalExpenses: json['total_expenses'] ?? 0,
      pendingExpenses: json['pending_expenses'] ?? 0,
      approvedExpenses: json['approved_expenses'] ?? 0,
      rejectedExpenses: json['rejected_expenses'] ?? 0,
      amountByCategory: Map<String, double>.from(
        json['amount_by_category'] ?? {},
      ),
      countByCategory: Map<String, int>.from(json['count_by_category'] ?? {}),
    );
  }
}

import 'package:flutter/material.dart';

class Salary {
  final int? id;
  final int? employeeId;
  final String? employeeName;
  final String? employeeEmail;
  final double baseSalary;
  final double bonus;
  final double deductions;
  final double netSalary;
  final String? month;
  final int? year;
  final String? status; // 'pending', 'approved', 'paid'
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? createdBy;
  final int? approvedBy;
  final String? approvedAt;
  final String? paidAt;
  final String? rejectionReason;
  final List<String> justificatifs; // Fichiers justificatifs
  /// Totaux issus de l'API (bulletin ivoirien : CNPS, IR)
  final double? totalAllowances;
  final double? totalDeductions;
  final double? totalTaxes;
  final double? totalSocialSecurity;
  final double? grossSalary;
  /// CNPS part employeur (optionnel, quand l'API le fournit)
  final double? cnpsEmployeur;

  Salary({
    this.id,
    this.employeeId,
    this.employeeName,
    this.employeeEmail,
    required this.baseSalary,
    this.bonus = 0.0,
    this.deductions = 0.0,
    required this.netSalary,
    this.month,
    this.year,
    this.status = 'pending',
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.approvedBy,
    this.approvedAt,
    this.paidAt,
    this.rejectionReason,
    this.justificatifs = const [],
    this.totalAllowances,
    this.totalDeductions,
    this.totalTaxes,
    this.totalSocialSecurity,
    this.grossSalary,
    this.cnpsEmployeur,
  });

  factory Salary.fromJson(Map<String, dynamic> json) {
    print('🔍 Salary.fromJson: Parsing des données JSON');
    print('📦 Salary.fromJson: JSON reçu: $json');

    try {
      return Salary(
        id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
        employeeId:
            json['employee_id'] != null
                ? int.tryParse(json['employee_id'].toString())
                : null,
        employeeName: json['employee_name']?.toString(),
        employeeEmail: json['employee_email']?.toString(),
        baseSalary:
            json['base_salary'] != null
                ? (json['base_salary'] is String
                    ? double.tryParse(json['base_salary']) ?? 0.0
                    : (json['base_salary']?.toDouble() ?? 0.0))
                : 0.0,
        bonus:
            json['bonus'] != null
                ? (json['bonus'] is String
                    ? double.tryParse(json['bonus']) ?? 0.0
                    : (json['bonus']?.toDouble() ?? 0.0))
                : 0.0,
        deductions:
            json['deductions'] != null
                ? (json['deductions'] is String
                    ? double.tryParse(json['deductions']) ?? 0.0
                    : (json['deductions']?.toDouble() ?? 0.0))
                : 0.0,
        netSalary:
            json['net_salary'] != null
                ? (json['net_salary'] is String
                    ? double.tryParse(json['net_salary']) ?? 0.0
                    : (json['net_salary']?.toDouble() ?? 0.0))
                : 0.0,
        month: json['month']?.toString(),
        year:
            json['year'] != null ? int.tryParse(json['year'].toString()) : null,
        status: _normalizeStatus(json['status']),
        notes: json['notes']?.toString(),
        createdAt:
            json['created_at'] != null
                ? DateTime.tryParse(json['created_at'].toString())
                : null,
        updatedAt:
            json['updated_at'] != null
                ? DateTime.tryParse(json['updated_at'].toString())
                : null,
        createdBy:
            json['created_by'] != null
                ? int.tryParse(json['created_by'].toString())
                : null,
        approvedBy:
            json['approved_by'] != null
                ? int.tryParse(json['approved_by'].toString())
                : null,
        approvedAt: json['approved_at']?.toString(),
        paidAt: json['paid_at']?.toString(),
        rejectionReason: json['rejection_reason']?.toString(),
        justificatifs:
            json['justificatifs'] != null
                ? (json['justificatifs'] is List
                    ? (json['justificatifs'] as List)
                        .map((f) => f.toString())
                        .toList()
                    : json['justificatifs'] is String
                    ? [json['justificatifs']]
                    : [])
                : [],
        totalAllowances: _parseOptionalDouble(json['total_allowances']),
        totalDeductions: _parseOptionalDouble(json['total_deductions']),
        totalTaxes: _parseOptionalDouble(json['total_taxes']),
        totalSocialSecurity: _parseOptionalDouble(json['total_social_security']),
        grossSalary: _parseOptionalDouble(json['gross_salary']),
        cnpsEmployeur: _parseOptionalDouble(json['cnps_employeur']),
      );
    } catch (e) {
      print('❌ Salary.fromJson: Erreur lors du parsing: $e');
      print('📦 Salary.fromJson: JSON problématique: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'employee_name': employeeName,
      'employee_email': employeeEmail,
      'base_salary': baseSalary,
      'bonus': bonus,
      'deductions': deductions,
      'net_salary': netSalary,
      'month': month,
      'year': year,
      'status': status,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'created_by': createdBy,
      'approved_by': approvedBy,
      'approved_at': approvedAt,
      'paid_at': paidAt,
      'rejection_reason': rejectionReason,
      'justificatifs': justificatifs,
      'total_allowances': totalAllowances,
      'total_deductions': totalDeductions,
      'total_taxes': totalTaxes,
      'total_social_security': totalSocialSecurity,
      'gross_salary': grossSalary,
      'cnps_employeur': cnpsEmployeur,
    };
  }

  static double? _parseOptionalDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    final d = double.tryParse(value.toString());
    return d;
  }

  // Normaliser le statut pour gérer les variations de format
  static String _normalizeStatus(dynamic statusValue) {
    if (statusValue == null) {
      return 'pending';
    }
    
    // Si c'est un entier, mapper vers les valeurs de statut
    if (statusValue is int) {
      final intStatusMap = {
        0: 'pending',
        1: 'approved',
        2: 'paid',
        3: 'rejected',
      };
      return intStatusMap[statusValue] ?? 'pending';
    }
    
    final statusStr = statusValue.toString().toLowerCase().trim();
    
    // Mapper les libellés français vers les valeurs anglaises
    final statusMap = {
      'en_attente': 'pending',
      'en attente': 'pending',
      'pending': 'pending',
      'approuvé': 'approved',
      'approuve': 'approved',
      'approved': 'approved',
      'validé': 'approved',
      'valide': 'approved',
      'payé': 'paid',
      'paye': 'paid',
      'paid': 'paid',
      'rejeté': 'rejected',
      'rejete': 'rejected',
      'rejected': 'rejected',
    };
    
    return statusMap[statusStr] ?? 'pending';
  }

  // Méthodes utilitaires
  String get statusText {
    final normalizedStatus = _normalizeStatus(status);
    switch (normalizedStatus) {
      case 'pending':
        return 'En attente';
      case 'approved':
        return 'Approuvé';
      case 'paid':
        return 'Payé';
      case 'rejected':
        return 'Rejeté';
      default:
        return 'En attente'; // Par défaut, considérer comme "En attente" au lieu de "Inconnu"
    }
  }

  Color get statusColor {
    final normalizedStatus = _normalizeStatus(status);
    switch (normalizedStatus) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'paid':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange; // Par défaut, considérer comme "En attente"
    }
  }

  IconData get statusIcon {
    final normalizedStatus = _normalizeStatus(status);
    switch (normalizedStatus) {
      case 'pending':
        return Icons.schedule;
      case 'approved':
        return Icons.check_circle;
      case 'paid':
        return Icons.payment;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.schedule; // Par défaut, considérer comme "En attente"
    }
  }

  String get monthText {
    if (month == null) return 'N/A';
    switch (month) {
      case '01':
        return 'Janvier';
      case '02':
        return 'Février';
      case '03':
        return 'Mars';
      case '04':
        return 'Avril';
      case '05':
        return 'Mai';
      case '06':
        return 'Juin';
      case '07':
        return 'Juillet';
      case '08':
        return 'Août';
      case '09':
        return 'Septembre';
      case '10':
        return 'Octobre';
      case '11':
        return 'Novembre';
      case '12':
        return 'Décembre';
      default:
        return month!;
    }
  }

  String get periodText => '$monthText ${year ?? 'N/A'}';
}

class SalaryComponent {
  final int? id;
  final String name;
  final String type; // 'base', 'bonus', 'deduction'
  final double amount;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  SalaryComponent({
    this.id,
    required this.name,
    required this.type,
    required this.amount,
    this.description,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SalaryComponent.fromJson(Map<String, dynamic> json) {
    print('🔍 SalaryComponent.fromJson: Parsing des données JSON');
    print('📦 SalaryComponent.fromJson: JSON reçu: $json');

    try {
      return SalaryComponent(
        id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
        name: json['name']?.toString() ?? '',
        type: json['type']?.toString() ?? 'base',
        amount:
            json['amount'] != null
                ? (json['amount'] is String
                    ? double.tryParse(json['amount']) ?? 0.0
                    : (json['amount']?.toDouble() ?? 0.0))
                : 0.0,
        description: json['description']?.toString(),
        isActive: json['is_active'] ?? true,
        createdAt:
            json['created_at'] != null
                ? DateTime.tryParse(json['created_at'].toString()) ??
                    DateTime.now()
                : DateTime.now(),
        updatedAt:
            json['updated_at'] != null
                ? DateTime.tryParse(json['updated_at'].toString()) ??
                    DateTime.now()
                : DateTime.now(),
      );
    } catch (e) {
      print('❌ SalaryComponent.fromJson: Erreur lors du parsing: $e');
      print('📦 SalaryComponent.fromJson: JSON problématique: $json');
      // Retourner un composant par défaut en cas d'erreur
      return SalaryComponent(
        id: null,
        name: 'Composant par défaut',
        type: 'base',
        amount: 0.0,
        description: 'Composant créé en cas d\'erreur de parsing',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'amount': amount,
      'description': description,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get typeText {
    switch (type) {
      case 'base':
        return 'Salaire de base';
      case 'bonus':
        return 'Prime';
      case 'deduction':
        return 'Déduction';
      default:
        return 'Autre';
    }
  }

  Color get typeColor {
    switch (type) {
      case 'base':
        return Colors.blue;
      case 'bonus':
        return Colors.green;
      case 'deduction':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData get typeIcon {
    switch (type) {
      case 'base':
        return Icons.account_balance_wallet;
      case 'bonus':
        return Icons.star;
      case 'deduction':
        return Icons.remove_circle;
      default:
        return Icons.help;
    }
  }
}

class SalaryStats {
  final double totalSalaries;
  final double pendingSalaries;
  final double approvedSalaries;
  final double paidSalaries;
  final int totalEmployees;
  final int pendingCount;
  final int approvedCount;
  final int paidCount;
  final Map<String, double> salariesByMonth;
  final Map<String, int> countByMonth;

  SalaryStats({
    required this.totalSalaries,
    required this.pendingSalaries,
    required this.approvedSalaries,
    required this.paidSalaries,
    required this.totalEmployees,
    required this.pendingCount,
    required this.approvedCount,
    required this.paidCount,
    required this.salariesByMonth,
    required this.countByMonth,
  });

  factory SalaryStats.fromJson(Map<String, dynamic> json) {
    return SalaryStats(
      totalSalaries:
          json['total_salaries'] != null
              ? (json['total_salaries'] is String
                  ? double.tryParse(json['total_salaries']) ?? 0.0
                  : (json['total_salaries']?.toDouble() ?? 0.0))
              : 0.0,
      pendingSalaries:
          json['pending_salaries'] != null
              ? (json['pending_salaries'] is String
                  ? double.tryParse(json['pending_salaries']) ?? 0.0
                  : (json['pending_salaries']?.toDouble() ?? 0.0))
              : 0.0,
      approvedSalaries:
          json['approved_salaries'] != null
              ? (json['approved_salaries'] is String
                  ? double.tryParse(json['approved_salaries']) ?? 0.0
                  : (json['approved_salaries']?.toDouble() ?? 0.0))
              : 0.0,
      paidSalaries:
          json['paid_salaries'] != null
              ? (json['paid_salaries'] is String
                  ? double.tryParse(json['paid_salaries']) ?? 0.0
                  : (json['paid_salaries']?.toDouble() ?? 0.0))
              : 0.0,
      totalEmployees:
          json['total_employees'] != null
              ? int.tryParse(json['total_employees'].toString()) ?? 0
              : 0,
      pendingCount:
          json['pending_count'] != null
              ? int.tryParse(json['pending_count'].toString()) ?? 0
              : 0,
      approvedCount:
          json['approved_count'] != null
              ? int.tryParse(json['approved_count'].toString()) ?? 0
              : 0,
      paidCount:
          json['paid_count'] != null
              ? int.tryParse(json['paid_count'].toString()) ?? 0
              : 0,
      salariesByMonth: Map<String, double>.from(
        json['salaries_by_month'] ?? {},
      ),
      countByMonth: Map<String, int>.from(json['count_by_month'] ?? {}),
    );
  }
}

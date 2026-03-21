// Modèle Tax conforme à la documentation API

class TaxCategory {
  final int? id;
  final String name;
  final String code;
  final String? description;
  final double defaultRate;
  final String type; // 'percentage' ou 'fixed'
  final String frequency; // 'monthly', 'quarterly', 'yearly'
  final bool isActive;
  final List<String>? applicableTo;
  final String? formattedRate;

  TaxCategory({
    this.id,
    required this.name,
    required this.code,
    this.description,
    required this.defaultRate,
    this.type = 'percentage',
    this.frequency = 'monthly',
    this.isActive = true,
    this.applicableTo,
    this.formattedRate,
  });

  factory TaxCategory.fromJson(Map<String, dynamic> json) {
    return TaxCategory(
      id: json['id'],
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      description: json['description'],
      defaultRate:
          json['default_rate'] != null
              ? (json['default_rate'] is String
                  ? double.tryParse(json['default_rate']) ?? 0.0
                  : (json['default_rate']?.toDouble() ?? 0.0))
              : 0.0,
      type: json['type'] ?? 'percentage',
      frequency: json['frequency'] ?? 'monthly',
      isActive: json['is_active'] ?? true,
      applicableTo:
          json['applicable_to'] != null
              ? List<String>.from(json['applicable_to'])
              : null,
      formattedRate: json['formatted_rate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'description': description,
      'default_rate': defaultRate,
      'type': type,
      'frequency': frequency,
      'is_active': isActive,
      'applicable_to': applicableTo,
      'formatted_rate': formattedRate,
    };
  }
}

class Tax {
  final int? id;
  final String? category; // Catégorie de taxe (ex: "TVA", "IS", "IRPP", etc.)
  final int? comptableId;
  final Map<String, dynamic>? comptable;
  final String? reference;
  final String? period; // Format: "YYYY-MM"
  final String? periodStart; // Format: "YYYY-MM-DD"
  final String? periodEnd; // Format: "YYYY-MM-DD"
  final String? dueDate; // Format: "YYYY-MM-DD"
  final double baseAmount;
  final double? taxRate;
  final double? taxAmount;
  final double? totalAmount;
  final String status; // 'en_attente', 'valide', 'rejete', 'paid'
  final String? statusLibelle;
  final String? description;
  final String? notes;
  final Map<String, dynamic>? calculationDetails;
  final String? declaredAt;
  final String? paidAt;
  final int? validatedBy;
  final String? validatedAt;
  final String? validationComment;
  final int? rejectedBy;
  final String? rejectedAt;
  final String? rejectionReason;
  final String? rejectionComment;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? daysUntilDue;
  final bool? isOverdue;
  final double? totalPaid;
  final double? remainingAmount;

  // Propriétés calculées pour compatibilité avec l'ancien modèle
  String get name => category ?? reference ?? 'Taxe';
  double get amount => totalAmount ?? taxAmount ?? 0.0;
  DateTime get dueDateTime {
    if (dueDate != null) {
      return DateTime.parse(dueDate!);
    }
    return DateTime.now().add(const Duration(days: 30));
  }

  Tax({
    this.id,
    this.category,
    this.comptableId,
    this.comptable,
    this.reference,
    this.period,
    this.periodStart,
    this.periodEnd,
    this.dueDate,
    required this.baseAmount,
    this.taxRate,
    this.taxAmount,
    this.totalAmount,
    this.status = 'en_attente',
    this.statusLibelle,
    this.description,
    this.notes,
    this.calculationDetails,
    this.declaredAt,
    this.paidAt,
    this.validatedBy,
    this.validatedAt,
    this.validationComment,
    this.rejectedBy,
    this.rejectedAt,
    this.rejectionReason,
    this.rejectionComment,
    this.createdAt,
    this.updatedAt,
    this.daysUntilDue,
    this.isOverdue,
    this.totalPaid,
    this.remainingAmount,
  });

  // Méthodes utilitaires - Normalisation vers les 4 statuts
  bool get isPending {
    final statusLower = status.toLowerCase();
    return statusLower == 'en_attente' ||
        statusLower == 'pending' ||
        statusLower == 'draft' ||
        statusLower == 'declared';
  }

  bool get isValidated {
    final statusLower = status.toLowerCase();
    return statusLower == 'valide' || statusLower == 'validated';
  }

  bool get isRejected {
    final statusLower = status.toLowerCase();
    return statusLower == 'rejete' || statusLower == 'rejected';
  }

  bool get isPaid {
    final statusLower = status.toLowerCase();
    return statusLower == 'paid' || statusLower == 'paye';
  }

  bool get isOverdueTax => isOverdue ?? false;

  // Normaliser le statut vers un des 4 statuts autorisés
  String get normalizedStatus {
    final statusLower = status.toLowerCase();
    if (statusLower == 'en_attente' ||
        statusLower == 'pending' ||
        statusLower == 'draft' ||
        statusLower == 'declared' ||
        statusLower == 'calculated') {
      return 'en_attente';
    }
    if (statusLower == 'valide' || statusLower == 'validated') {
      return 'valide';
    }
    if (statusLower == 'rejete' || statusLower == 'rejected') {
      return 'rejete';
    }
    if (statusLower == 'paid' || statusLower == 'paye') {
      return 'paid';
    }
    // Par défaut, retourner en_attente
    return 'en_attente';
  }

  String get statusText {
    final statusLower = status.toLowerCase();
    switch (statusLower) {
      case 'en_attente':
      case 'pending':
      case 'draft':
      case 'declared':
      case 'calculated':
        return 'En attente';
      case 'valide':
      case 'validated':
        return 'Validé';
      case 'rejete':
      case 'rejected':
        return 'Rejeté';
      case 'paid':
      case 'paye':
        return 'Payé';
      default:
        return statusLibelle ?? 'En attente';
    }
  }

  String get statusColor {
    final statusLower = status.toLowerCase();
    switch (statusLower) {
      case 'en_attente':
      case 'pending':
      case 'draft':
      case 'declared':
      case 'calculated':
        return 'orange';
      case 'valide':
      case 'validated':
        return 'green';
      case 'rejete':
      case 'rejected':
        return 'red';
      case 'paid':
      case 'paye':
        return 'blue';
      default:
        return 'orange';
    }
  }

  String get periodText {
    if (period != null) {
      return period!;
    }
    if (periodStart != null && periodEnd != null) {
      return '${periodStart!.substring(0, 7)}';
    }
    return 'N/A';
  }

  // Sérialisation JSON pour création
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      if (id != null) 'id': id,
      if (category != null && category!.isNotEmpty) 'category': category,
      if (comptableId != null) 'comptableId': comptableId,
      if (reference != null) 'reference': reference,
      if (period != null) 'period': period,
      if (periodStart != null) 'periodStart': periodStart,
      if (periodEnd != null) 'periodEnd': periodEnd,
      if (dueDate != null) 'dueDate': dueDate,
      'baseAmount': baseAmount,
      if (taxRate != null) 'taxRate': taxRate,
      if (taxAmount != null) 'taxAmount': taxAmount,
      if (totalAmount != null) 'totalAmount': totalAmount,
      if (description != null && description!.isNotEmpty)
        'description': description,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
    return json;
  }

  factory Tax.fromJson(Map<String, dynamic> json) {
    return Tax(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      category: json['category']?.toString(),
      comptableId:
          json['comptable_id'] != null
              ? int.tryParse(json['comptable_id'].toString())
              : null,
      comptable:
          json['comptable'] is Map<String, dynamic>
              ? Map<String, dynamic>.from(json['comptable'])
              : null,
      reference: json['reference']?.toString(),
      period: json['period']?.toString(),
      periodStart: json['period_start']?.toString(),
      periodEnd: json['period_end']?.toString(),
      dueDate: json['due_date']?.toString(),
      baseAmount:
          json['base_amount'] != null
              ? (json['base_amount'] is String
                  ? double.tryParse(json['base_amount']) ?? 0.0
                  : (json['base_amount']?.toDouble() ?? 0.0))
              : 0.0,
      taxRate:
          json['tax_rate'] != null
              ? (json['tax_rate'] is String
                  ? double.tryParse(json['tax_rate'])
                  : (json['tax_rate']?.toDouble()))
              : null,
      taxAmount:
          json['tax_amount'] != null
              ? (json['tax_amount'] is String
                  ? double.tryParse(json['tax_amount'])
                  : (json['tax_amount']?.toDouble()))
              : null,
      totalAmount:
          json['total_amount'] != null
              ? (json['total_amount'] is String
                  ? double.tryParse(json['total_amount'])
                  : (json['total_amount']?.toDouble()))
              : null,
      status: json['status']?.toString() ?? 'draft',
      statusLibelle: json['status_libelle']?.toString(),
      description: json['description']?.toString(),
      notes: json['notes']?.toString(),
      calculationDetails:
          json['calculation_details'] is Map<String, dynamic>
              ? Map<String, dynamic>.from(json['calculation_details'])
              : null,
      declaredAt: json['declared_at']?.toString(),
      paidAt: json['paid_at']?.toString(),
      validatedBy:
          json['validated_by'] != null
              ? int.tryParse(json['validated_by'].toString())
              : null,
      validatedAt: json['validated_at']?.toString(),
      validationComment: json['validation_comment']?.toString(),
      rejectedBy:
          json['rejected_by'] != null
              ? int.tryParse(json['rejected_by'].toString())
              : null,
      rejectedAt: json['rejected_at']?.toString(),
      rejectionReason: json['rejection_reason']?.toString(),
      rejectionComment: json['rejection_comment']?.toString(),
      createdAt:
          json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString())
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.tryParse(json['updated_at'].toString())
              : null,
      daysUntilDue:
          json['days_until_due'] != null
              ? int.tryParse(json['days_until_due'].toString())
              : null,
      isOverdue: json['is_overdue'] as bool?,
      totalPaid:
          json['total_paid'] != null
              ? (json['total_paid'] is String
                  ? double.tryParse(json['total_paid'])
                  : (json['total_paid']?.toDouble()))
              : null,
      remainingAmount:
          json['remaining_amount'] != null
              ? (json['remaining_amount'] is String
                  ? double.tryParse(json['remaining_amount'])
                  : (json['remaining_amount']?.toDouble()))
              : null,
    );
  }

  Tax copyWith({
    int? id,
    String? category,
    int? comptableId,
    Map<String, dynamic>? comptable,
    String? reference,
    String? period,
    String? periodStart,
    String? periodEnd,
    String? dueDate,
    double? baseAmount,
    double? taxRate,
    double? taxAmount,
    double? totalAmount,
    String? status,
    String? statusLibelle,
    String? description,
    String? notes,
    Map<String, dynamic>? calculationDetails,
    String? declaredAt,
    String? paidAt,
    int? validatedBy,
    String? validatedAt,
    String? validationComment,
    int? rejectedBy,
    String? rejectedAt,
    String? rejectionReason,
    String? rejectionComment,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? daysUntilDue,
    bool? isOverdue,
    double? totalPaid,
    double? remainingAmount,
  }) {
    return Tax(
      id: id ?? this.id,
      category: category ?? this.category,
      comptableId: comptableId ?? this.comptableId,
      comptable: comptable ?? this.comptable,
      reference: reference ?? this.reference,
      period: period ?? this.period,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      dueDate: dueDate ?? this.dueDate,
      baseAmount: baseAmount ?? this.baseAmount,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      statusLibelle: statusLibelle ?? this.statusLibelle,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      calculationDetails: calculationDetails ?? this.calculationDetails,
      declaredAt: declaredAt ?? this.declaredAt,
      paidAt: paidAt ?? this.paidAt,
      validatedBy: validatedBy ?? this.validatedBy,
      validatedAt: validatedAt ?? this.validatedAt,
      validationComment: validationComment ?? this.validationComment,
      rejectedBy: rejectedBy ?? this.rejectedBy,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      rejectionComment: rejectionComment ?? this.rejectionComment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      daysUntilDue: daysUntilDue ?? this.daysUntilDue,
      isOverdue: isOverdue ?? this.isOverdue,
      totalPaid: totalPaid ?? this.totalPaid,
      remainingAmount: remainingAmount ?? this.remainingAmount,
    );
  }

  @override
  String toString() {
    return 'Tax(id: $id, reference: $reference, status: $status, baseAmount: $baseAmount)';
  }
}

// Classe pour les statistiques des taxes
class TaxStats {
  final int total;
  final int pending;
  final int validated;
  final int rejected;
  final double totalAmount;
  final double pendingAmount;
  final double validatedAmount;
  final double rejectedAmount;

  TaxStats({
    required this.total,
    required this.pending,
    required this.validated,
    required this.rejected,
    required this.totalAmount,
    required this.pendingAmount,
    required this.validatedAmount,
    required this.rejectedAmount,
  });

  factory TaxStats.fromJson(Map<String, dynamic> json) {
    return TaxStats(
      total: json['total'] ?? json['en_attente'] ?? 0,
      pending: json['pending'] ?? json['en_attente'] ?? 0,
      validated: json['validated'] ?? json['valide'] ?? 0,
      rejected: json['rejected'] ?? json['rejete'] ?? 0,
      totalAmount:
          json['total_amount'] != null
              ? (json['total_amount'] is String
                  ? double.tryParse(json['total_amount']) ?? 0.0
                  : (json['total_amount']?.toDouble() ?? 0.0))
              : (json['montant_total_en_attente'] != null
                  ? (json['montant_total_en_attente'] is String
                      ? double.tryParse(json['montant_total_en_attente']) ?? 0.0
                      : (json['montant_total_en_attente']?.toDouble() ?? 0.0))
                  : 0.0),
      pendingAmount:
          json['pending_amount'] != null
              ? (json['pending_amount'] is String
                  ? double.tryParse(json['pending_amount']) ?? 0.0
                  : (json['pending_amount']?.toDouble() ?? 0.0))
              : (json['montant_total_en_attente'] != null
                  ? (json['montant_total_en_attente'] is String
                      ? double.tryParse(json['montant_total_en_attente']) ?? 0.0
                      : (json['montant_total_en_attente']?.toDouble() ?? 0.0))
                  : 0.0),
      validatedAmount:
          json['validated_amount'] != null
              ? (json['validated_amount'] is String
                  ? double.tryParse(json['validated_amount']) ?? 0.0
                  : (json['validated_amount']?.toDouble() ?? 0.0))
              : (json['montant_total_valide'] != null
                  ? (json['montant_total_valide'] is String
                      ? double.tryParse(json['montant_total_valide']) ?? 0.0
                      : (json['montant_total_valide']?.toDouble() ?? 0.0))
                  : 0.0),
      rejectedAmount:
          json['rejected_amount'] != null
              ? (json['rejected_amount'] is String
                  ? double.tryParse(json['rejected_amount']) ?? 0.0
                  : (json['rejected_amount']?.toDouble() ?? 0.0))
              : (json['montant_total_rejete'] != null
                  ? (json['montant_total_rejete'] is String
                      ? double.tryParse(json['montant_total_rejete']) ?? 0.0
                      : (json['montant_total_rejete']?.toDouble() ?? 0.0))
                  : 0.0),
    );
  }
}

class InvoiceModel {
  final int id;
  final String invoiceNumber;
  final int clientId;
  final String clientName;
  final String clientEmail;
  final String clientAddress;
  final String? clientNinea;
  final int commercialId;
  final String commercialName;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final String status; // 'draft', 'sent', 'paid', 'overdue', 'cancelled'
  final double subtotal;
  final double taxRate;
  final double taxAmount;
  final double totalAmount;
  final String currency;
  final String? notes;
  final String? terms;
  final List<InvoiceItem> items;
  final PaymentInfo? paymentInfo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? sentAt;
  final DateTime? paidAt;

  InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.clientId,
    required this.clientName,
    required this.clientEmail,
    required this.clientAddress,
    this.clientNinea,
    required this.commercialId,
    required this.commercialName,
    required this.invoiceDate,
    required this.dueDate,
    required this.status,
    required this.subtotal,
    required this.taxRate,
    required this.taxAmount,
    required this.totalAmount,
    required this.currency,
    this.notes,
    this.terms,
    required this.items,
    this.paymentInfo,
    required this.createdAt,
    required this.updatedAt,
    this.sentAt,
    this.paidAt,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    try {
      return InvoiceModel(
        id: _parseInt(json['id']) ?? 0,
        invoiceNumber:
            json['invoice_number']?.toString() ??
            json['numero_facture']?.toString() ??
            '',
        clientId:
            _parseInt(
              json['client_id'] ?? json['cliennt_id'] ?? json['clieent_id'],
            ) ??
            0,
        clientName:
            json['nom']?.toString() ?? json['client_name']?.toString() ?? '',
        clientEmail:
            json['email']?.toString() ?? json['client_email']?.toString() ?? '',
        clientAddress:
            json['adresse']?.toString() ??
            json['client_address']?.toString() ??
            '',
        clientNinea: () {
          final fromRoot = json['client_ninea']?.toString().trim() ?? json['ninea']?.toString().trim();
          if (fromRoot != null && fromRoot.isNotEmpty) return fromRoot;
          final clientObj = json['client'];
          if (clientObj is Map) {
            final fromClient = clientObj['ninea']?.toString().trim();
            if (fromClient != null && fromClient.isNotEmpty) return fromClient;
          }
          return null;
        }(),
        commercialId: _parseInt(json['user_id']) ?? 0,
        commercialName:
            json['commercial_name']?.toString() ??
            json['nom']?.toString() ??
            '',
        invoiceDate:
            _parseDateTime(json['invoice_date'] ?? json['date_facture']) ??
            DateTime.now(),
        dueDate:
            _parseDateTime(json['due_date'] ?? json['date_echeance']) ??
            DateTime.now(),
        status: json['status']?.toString() ?? 'en_attente',
        subtotal: _parseDouble(json['subtotal'] ?? json['montant_ht']),
        taxRate: _parseDouble(json['tax_rate'] ?? json['tva']),
        taxAmount: _parseDouble(json['tax_amount'] ?? json['tva']),
        totalAmount: _parseDouble(json['total_amount'] ?? json['montant_ttc']),
        currency: json['currency']?.toString() ?? 'FCFA',
        notes: json['notes']?.toString(),
        terms: json['terms']?.toString(),
        items:
            json['items'] != null && json['items'] is List
                ? (json['items'] as List<dynamic>)
                    .map((item) {
                      try {
                        return InvoiceItem.fromJson(
                          item is Map<String, dynamic>
                              ? item
                              : Map<String, dynamic>.from(item),
                        );
                      } catch (e) {
                        print('⚠️ InvoiceModel: Erreur parsing item: $e');
                        return null;
                      }
                    })
                    .where((item) => item != null)
                    .cast<InvoiceItem>()
                    .toList()
                : [],
        paymentInfo:
            json['payment_info'] != null
                ? PaymentInfo.fromJson(json['payment_info'])
                : null,
        createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
        updatedAt: _parseDateTime(json['updated_at']) ?? DateTime.now(),
        sentAt: _parseDateTime(json['sent_at']),
        paidAt: _parseDateTime(json['paid_at']),
      );
    } catch (e, stackTrace) {
      print('❌ InvoiceModel.fromJson: Erreur: $e');
      print('❌ InvoiceModel.fromJson: Stack trace: $stackTrace');
      print('❌ InvoiceModel.fromJson: JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'client_id': clientId,
      'nom': clientName,
      'email': clientEmail,
      'adresse': clientAddress,
      'client_ninea': clientNinea,
      'user_id': commercialId,
      'commercial_name': commercialName,
      'invoice_date': invoiceDate.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'status': status,
      'subtotal': subtotal,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
      'currency': currency,
      'notes': notes,
      'terms': terms,
      'items': items.map((item) => item.toJson()).toList(),
      'payment_info': paymentInfo?.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sent_at': sentAt?.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
    };
  }
}

class InvoiceItem {
  final int id;
  final String description;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? unit;

  InvoiceItem({
    required this.id,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.unit,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    try {
      return InvoiceItem(
        id: _parseInt(json['id']) ?? 0,
        description: json['description']?.toString() ?? '',
        quantity:
            _parseInt(json['quantity']) ?? _parseInt(json['quantite']) ?? 0,
        unitPrice: _parseDouble(
          json['unit_price'] ?? json['prix_unitaire'] ?? 0,
        ),
        totalPrice: _parseDouble(json['total_price'] ?? json['total'] ?? 0),
        unit: json['unit']?.toString(),
      );
    } catch (e) {
      print('⚠️ InvoiceItem.fromJson: Erreur: $e');
      print('⚠️ InvoiceItem.fromJson: JSON: $json');
      // Retourner un item par défaut en cas d'erreur
      return InvoiceItem(
        id: 0,
        description: json['description']?.toString() ?? '',
        quantity: 0,
        unitPrice: 0.0,
        totalPrice: 0.0,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'unit': unit,
    };
  }
}

class PaymentInfo {
  final String method; // 'bank_transfer', 'check', 'cash', 'card'
  final String? reference;
  final DateTime? paymentDate;
  final double amount;
  final String? notes;

  PaymentInfo({
    required this.method,
    this.reference,
    this.paymentDate,
    required this.amount,
    this.notes,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      method: json['method'],
      reference: json['reference'],
      paymentDate:
          json['payment_date'] != null
              ? DateTime.parse(json['payment_date'])
              : null,
      amount: (json['amount'] ?? 0).toDouble(),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'method': method,
      'reference': reference,
      'payment_date': paymentDate?.toIso8601String(),
      'amount': amount,
      'notes': notes,
    };
  }
}

class InvoiceStats {
  final int totalInvoices;
  final int draftInvoices;
  final int sentInvoices;
  final int paidInvoices;
  final int overdueInvoices;
  final double totalAmount;
  final double paidAmount;
  final double pendingAmount;
  final double overdueAmount;
  final List<InvoiceModel> recentInvoices;
  final Map<String, double> monthlyStats;

  InvoiceStats({
    required this.totalInvoices,
    required this.draftInvoices,
    required this.sentInvoices,
    required this.paidInvoices,
    required this.overdueInvoices,
    required this.totalAmount,
    required this.paidAmount,
    required this.pendingAmount,
    required this.overdueAmount,
    required this.recentInvoices,
    required this.monthlyStats,
  });

  factory InvoiceStats.fromJson(Map<String, dynamic> json) {
    return InvoiceStats(
      totalInvoices: json['total_invoices'] ?? 0,
      draftInvoices: json['draft_invoices'] ?? 0,
      sentInvoices: json['sent_invoices'] ?? 0,
      paidInvoices: json['paid_invoices'] ?? 0,
      overdueInvoices: json['overdue_invoices'] ?? 0,
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      paidAmount: (json['paid_amount'] ?? 0).toDouble(),
      pendingAmount: (json['pending_amount'] ?? 0).toDouble(),
      overdueAmount: (json['overdue_amount'] ?? 0).toDouble(),
      recentInvoices:
          (json['recent_invoices'] as List<dynamic>?)
              ?.map((invoice) => InvoiceModel.fromJson(invoice))
              .toList() ??
          [],
      monthlyStats: Map<String, double>.from(json['monthly_stats'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_invoices': totalInvoices,
      'draft_invoices': draftInvoices,
      'sent_invoices': sentInvoices,
      'paid_invoices': paidInvoices,
      'overdue_invoices': overdueInvoices,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'pending_amount': pendingAmount,
      'overdue_amount': overdueAmount,
      'recent_invoices':
          recentInvoices.map((invoice) => invoice.toJson()).toList(),
      'monthly_stats': monthlyStats,
    };
  }
}

class InvoiceTemplate {
  final int id;
  final String name;
  final String description;
  final String template;
  final bool isDefault;
  final DateTime createdAt;

  InvoiceTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.template,
    required this.isDefault,
    required this.createdAt,
  });

  factory InvoiceTemplate.fromJson(Map<String, dynamic> json) {
    return InvoiceTemplate(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      template: json['template'],
      isDefault: json['is_default'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'template': template,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// Méthodes de parsing robustes pour InvoiceModel
int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }
  if (value is num) return value.toInt();
  return null;
}

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 0.0;
    final parsed = double.tryParse(trimmed);
    if (parsed != null) return parsed;
    final cleaned = trimmed
        .replaceAll(RegExp(r'[^\d.,-]'), '')
        .replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 0.0;
  }
  if (value is num) return value.toDouble();
  return 0.0;
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) {
    try {
      if (value.contains('T') || value.contains(' ')) {
        return DateTime.parse(value);
      } else {
        return DateTime.parse('${value}T00:00:00');
      }
    } catch (e) {
      print('⚠️ InvoiceModel: Erreur parsing DateTime: $value - $e');
      return null;
    }
  }
  return null;
}

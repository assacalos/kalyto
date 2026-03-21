import 'package:flutter/material.dart';

class DevisItem {
  final int? id;
  final String? reference;
  final String designation;
  final int quantite;
  final double prixUnitaire;

  DevisItem({
    this.id,
    this.reference,
    required this.designation,
    required this.quantite,
    required this.prixUnitaire,
  });

  double get total {
    final result = quantite * prixUnitaire;
    return result.isFinite ? result : 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference': reference,
      'designation': designation,
      'quantite': quantite,
      'prix_unitaire': prixUnitaire,
    };
  }

  factory DevisItem.fromJson(Map<String, dynamic> json) {
    return DevisItem(
      id: json['id'] is String ? int.tryParse(json['id']) : json['id'],
      reference: json['reference']?.toString(),
      designation: json['designation']?.toString() ?? '',
      quantite:
          json['quantite'] is String
              ? int.tryParse(json['quantite']) ?? 0
              : (json['quantite'] ?? 0),
      prixUnitaire: _parseDouble(json['prix_unitaire']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) {
      if (value.isFinite) return value;
      return 0.0;
    }
    if (value is int) return value.toDouble();
    if (value is String) {
      if (value.isEmpty) return 0.0;
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
}

class Devis {
  final int? id;
  final int clientId;
  final String reference;
  final DateTime dateCreation;
  final DateTime? dateValidite;
  final String? notes;
  final int status; // 1: envoyé, 2: accepté, 3: refusé
  final List<DevisItem> items;
  final double? remiseGlobale;
  final double? tva;
  final String? conditions;
  final String? commentaire;
  final int commercialId;
  final String? submittedBy; // Nom de l'utilisateur qui a soumis
  final String? rejectionComment; // Commentaire de rejet du patron
  final DateTime? submittedAt; // Date de soumission
  final DateTime? validatedAt; // Date de validation
  final String? titre; // Titre du devis
  final String? delaiLivraison; // Délai de livraison
  final String? garantie; // Garantie
  final String? clientNomEntreprise; // Nom de l'entreprise (client) pour affichage liste

  Devis({
    this.id,
    required this.clientId,
    required this.reference,
    required this.dateCreation,
    this.dateValidite,
    this.notes,
    this.status = 1,
    required this.items,
    this.remiseGlobale,
    this.tva,
    this.conditions,
    this.commentaire,
    required this.commercialId,
    this.submittedBy,
    this.rejectionComment,
    this.submittedAt,
    this.validatedAt,
    this.titre,
    this.delaiLivraison,
    this.garantie,
    this.clientNomEntreprise,
  });

  double get sousTotal {
    if (items.isEmpty) return 0.0;
    final total = items.fold(0.0, (sum, item) {
      final itemTotal = item.total;
      if (itemTotal.isFinite) {
        return sum + itemTotal;
      }
      return sum;
    });
    return total.isFinite ? total : 0.0;
  }

  double get remise {
    if (remiseGlobale != null && remiseGlobale! > 0) {
      final remiseValue = sousTotal * (remiseGlobale! / 100);
      return remiseValue.isFinite ? remiseValue : 0.0;
    }
    return 0.0;
  }

  double get totalHT {
    final total = sousTotal - remise;
    return total.isFinite ? total : 0.0;
  }

  double get montantTVA {
    if (tva != null && tva! > 0) {
      final tvaValue = totalHT * (tva! / 100);
      return tvaValue.isFinite ? tvaValue : 0.0;
    }
    return 0.0;
  }

  double get totalTTC {
    final total = totalHT + montantTVA;
    return total.isFinite ? total : 0.0;
  }

  String get statusText {
    switch (status) {
      case 1:
        return "En attente";
      case 2:
        return "Validé";
      case 3:
        return "Rejeté";
      default:
        return "Inconnu";
    }
  }

  Color get statusColor {
    switch (status) {
      case 1:
        return Colors.orange;
      case 2:
        return Colors.green;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 1:
        return Icons.access_time;
      case 2:
        return Icons.check_circle;
      case 3:
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'reference': reference,
      'date_creation': dateCreation.toIso8601String(),
      'date_validite': dateValidite?.toIso8601String(),
      'notes': notes,
      'status': status,
      'items': items.map((item) => item.toJson()).toList(),
      'remise_globale': remiseGlobale,
      'tva': tva,
      'conditions': conditions,
      'commentaire': commentaire,
      'user_id': commercialId,
      'submitted_by': submittedBy,
      'rejection_comment': rejectionComment,
      'submitted_at': submittedAt?.toIso8601String(),
      'validated_at': validatedAt?.toIso8601String(),
      'titre': titre,
      'delai_livraison': delaiLivraison,
      'garantie': garantie,
    };
  }

  factory Devis.fromJson(Map<String, dynamic> json) {
    return Devis(
      id: json['id'] is String ? int.tryParse(json['id']) : json['id'],
      clientId:
          _parseInt(
            json['client_id'] ?? json['cliennt_id'] ?? json['clieent_id'],
          ) ??
          0, // Valeur par défaut si null
      reference: json['reference'],
      dateCreation: DateTime.parse(json['date_creation']),
      dateValidite:
          json['date_validite'] != null
              ? DateTime.parse(json['date_validite'])
              : null,
      notes: json['notes'],
      status: () {
        // BDD: 0=en attente, 2=validé, 3=rejeté. App: 1=attente, 2=validé, 3=rejeté
        final p = _parseInt(json['status']);
        if (p == null) return 1;
        return p == 0 ? 1 : p; // 0 → 1 (en attente) ; 2, 3 inchangés
      }(),
      items:
          ((json['items'] as List?) ?? [])
              .map((item) => DevisItem.fromJson(item as Map<String, dynamic>))
              .toList(),
      remiseGlobale:
          json['remise_globale'] != null
              ? _parseDouble(json['remise_globale'])
              : null,
      tva: json['tva'] != null ? _parseDouble(json['tva']) : null,
      conditions: json['conditions'],
      commentaire: json['commentaire'],
      commercialId:
          _parseInt(
            json['user_id'] ?? json['commercial_id'] ?? json['commercialId'],
          ) ??
          0, // Valeur par défaut si null
      submittedBy: json['submitted_by'],
      rejectionComment: json['rejection_comment'],
      submittedAt:
          json['submitted_at'] != null
              ? DateTime.parse(json['submitted_at'])
              : null,
      validatedAt:
          json['validated_at'] != null
              ? DateTime.parse(json['validated_at'])
              : null,
      titre: json['titre'],
      delaiLivraison: json['delai_livraison'],
      garantie: json['garantie'],
      clientNomEntreprise: _clientDisplayName(json['client']),
    );
  }

  static String? _clientDisplayName(dynamic client) {
    if (client == null || client is! Map) return null;
    final c = client as Map<String, dynamic>;
    final nomEnt = c['nom_entreprise']?.toString().trim();
    if (nomEnt != null && nomEnt.isNotEmpty) return nomEnt;
    final display = c['display_name']?.toString().trim();
    if (display != null && display.isNotEmpty) return display;
    final nom = (c['nom']?.toString() ?? '').trim();
    final prenom = (c['prenom']?.toString() ?? '').trim();
    final full = '$prenom $nom'.trim();
    return full.isEmpty ? null : full;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    if (value is double) {
      return value.toInt();
    }
    return null;
  }
}

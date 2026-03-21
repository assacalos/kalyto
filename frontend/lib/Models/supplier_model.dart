class Supplier {
  final int? id;
  final String nom;
  final String email;
  final String telephone;
  final String adresse;
  final String ville;
  final String pays;
  final String? description;
  final String? ninea; // NINEA (numéro d'identification ivoirien, 9 chiffres)
  final String statut; // 'en_attente', 'valide', 'rejete'
  final double? noteEvaluation;
  final String? commentaires;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Supplier({
    this.id,
    required this.nom,
    required this.email,
    required this.telephone,
    required this.adresse,
    required this.ville,
    required this.pays,
    this.description,
    this.ninea,
    this.statut = 'en_attente',
    this.noteEvaluation,
    this.commentaires,
    this.createdAt,
    this.updatedAt,
  });

  // Méthodes utilitaires - Statuts normalisés vers 3 statuts
  bool get isPending {
    final statusLower = statut.toLowerCase();
    return statusLower == 'en_attente' || statusLower == 'pending';
  }

  bool get isValidated {
    final statusLower = statut.toLowerCase();
    return statusLower == 'valide' ||
        statusLower == 'validated' ||
        statusLower == 'approved';
  }

  bool get isRejected {
    final statusLower = statut.toLowerCase();
    return statusLower == 'rejete' || statusLower == 'rejected';
  }

  String get statusText {
    final statusLower = statut.toLowerCase();
    if (statusLower == 'en_attente' || statusLower == 'pending') {
      return 'En attente';
    }
    if (statusLower == 'valide' ||
        statusLower == 'validated' ||
        statusLower == 'approved') {
      return 'Validé';
    }
    if (statusLower == 'rejete' || statusLower == 'rejected') {
      return 'Rejeté';
    }
    return 'Inconnu';
  }

  String get statusColor {
    final statusLower = statut.toLowerCase();
    if (statusLower == 'en_attente' || statusLower == 'pending') {
      return 'orange';
    }
    if (statusLower == 'valide' ||
        statusLower == 'validated' ||
        statusLower == 'approved') {
      return 'green';
    }
    if (statusLower == 'rejete' || statusLower == 'rejected') {
      return 'red';
    }
    return 'grey';
  }

  // Sérialisation JSON pour création/mise à jour
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      if (id != null) 'id': id,
      'nom': nom,
      'email': email,
      'telephone': telephone,
      'adresse': adresse,
      'ville': ville,
      'pays': pays,
      if (description != null && description!.isNotEmpty)
        'description': description,
      if (ninea != null && ninea!.isNotEmpty) 'ninea': ninea,
      if (noteEvaluation != null) 'noteEvaluation': noteEvaluation,
      if (commentaires != null && commentaires!.isNotEmpty)
        'commentaires': commentaires,
    };
    return json;
  }

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      nom: json['nom']?.toString() ?? json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      telephone:
          json['telephone']?.toString() ?? json['phone']?.toString() ?? '',
      adresse: json['adresse']?.toString() ?? json['address']?.toString() ?? '',
      ville: json['ville']?.toString() ?? json['city']?.toString() ?? '',
      pays: json['pays']?.toString() ?? json['country']?.toString() ?? '',
      description: json['description']?.toString(),
      ninea: json['ninea']?.toString(),
      statut: () {
        // Essayer d'abord statut, puis status, puis status_text
        String? parsedStatut =
            json['statut']?.toString() ?? json['status']?.toString();

        // Si statut est null, essayer de déduire depuis status_text
        if (parsedStatut == null || parsedStatut.isEmpty) {
          final statusText =
              json['status_text']?.toString().toLowerCase() ??
              json['statusText']?.toString().toLowerCase();
          if (statusText != null) {
            if (statusText.contains('validé') ||
                statusText.contains('validated') ||
                statusText.contains('approved')) {
              parsedStatut = 'valide';
            } else if (statusText.contains('rejeté') ||
                statusText.contains('rejected')) {
              parsedStatut = 'rejete';
            } else if (statusText.contains('attente') ||
                statusText.contains('pending')) {
              parsedStatut = 'en_attente';
            }
          }
        }

        return parsedStatut ?? 'en_attente';
      }(),
      noteEvaluation:
          json['note_evaluation'] != null || json['noteEvaluation'] != null
              ? (json['note_evaluation'] ?? json['noteEvaluation']) is String
                  ? double.tryParse(
                    (json['note_evaluation'] ?? json['noteEvaluation'])
                        .toString(),
                  )
                  : (json['note_evaluation'] ?? json['noteEvaluation'])
                      ?.toDouble()
              : null,
      commentaires:
          json['commentaires']?.toString() ?? json['comments']?.toString(),
      createdAt:
          json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString())
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.tryParse(json['updated_at'].toString())
              : null,
    );
  }

  // Méthode de copie
  Supplier copyWith({
    int? id,
    String? nom,
    String? email,
    String? telephone,
    String? adresse,
    String? ville,
    String? pays,
    String? description,
    String? ninea,
    String? statut,
    double? noteEvaluation,
    String? commentaires,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      email: email ?? this.email,
      telephone: telephone ?? this.telephone,
      adresse: adresse ?? this.adresse,
      ville: ville ?? this.ville,
      pays: pays ?? this.pays,
      description: description ?? this.description,
      ninea: ninea ?? this.ninea,
      statut: statut ?? this.statut,
      noteEvaluation: noteEvaluation ?? this.noteEvaluation,
      commentaires: commentaires ?? this.commentaires,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Classe pour les statistiques
class SupplierStats {
  final int total;
  final int pending;
  final int validated;
  final int rejected;
  final double averageRating;

  SupplierStats({
    required this.total,
    required this.pending,
    required this.validated,
    required this.rejected,
    required this.averageRating,
  });

  factory SupplierStats.fromJson(Map<String, dynamic> json) {
    return SupplierStats(
      total: json['total'] ?? 0,
      pending: json['pending'] ?? json['en_attente'] ?? 0,
      validated: json['validated'] ?? json['valide'] ?? json['approved'] ?? 0,
      rejected: json['rejected'] ?? json['rejete'] ?? 0,
      averageRating:
          json['average_rating'] != null
              ? (json['average_rating'] is String
                  ? double.tryParse(json['average_rating']) ?? 0.0
                  : (json['average_rating']?.toDouble() ?? 0.0))
              : 0.0,
    );
  }
}

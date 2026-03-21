class JournalEntryModel {
  final int id;
  final String date; // Y-m-d
  final String? reference;
  final String libelle;
  final String? categorie;
  final String modePaiement;
  final String? modePaiementLibelle;
  final double entree;
  final double sortie;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;
  final Map<String, dynamic>? user;

  JournalEntryModel({
    required this.id,
    required this.date,
    this.reference,
    required this.libelle,
    this.categorie,
    required this.modePaiement,
    this.modePaiementLibelle,
    required this.entree,
    required this.sortie,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.user,
  });

  factory JournalEntryModel.fromJson(Map<String, dynamic> json) {
    return JournalEntryModel(
      id: _int(json['id']),
      date: json['date']?.toString() ?? '',
      reference: json['reference']?.toString(),
      libelle: json['libelle']?.toString() ?? '',
      categorie: json['categorie']?.toString(),
      modePaiement: json['mode_paiement']?.toString() ?? 'especes',
      modePaiementLibelle: json['mode_paiement_libelle']?.toString(),
      entree: _double(json['entree']),
      sortie: _double(json['sortie']),
      notes: json['notes']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      user: json['user'] is Map ? Map<String, dynamic>.from(json['user'] as Map) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'reference': reference,
        'libelle': libelle,
        'categorie': categorie,
        'mode_paiement': modePaiement,
        'entree': entree,
        'sortie': sortie,
        'notes': notes,
      };

  static int _int(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    if (v is num) return v.toInt();
    return 0;
  }

  static double _double(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    if (v is num) return v.toDouble();
    return 0.0;
  }

  static const List<String> modePaiementValues = [
    'especes',
    'virement',
    'cheque',
    'carte_bancaire',
    'mobile_money',
    'autre',
  ];

  static String modePaiementLabel(String value) {
    switch (value) {
      case 'especes':
        return 'Espèces';
      case 'virement':
        return 'Virement';
      case 'cheque':
        return 'Chèque';
      case 'carte_bancaire':
        return 'Carte bancaire';
      case 'mobile_money':
        return 'Mobile Money';
      case 'autre':
        return 'Autre';
      default:
        return value;
    }
  }
}

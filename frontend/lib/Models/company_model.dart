/// Modèle d'une société (multi-société).
class Company {
  final int id;
  final String name;
  final String? code;
  final String? ninea;
  final String? address;
  /// URL du logo (en-tête PDF), fournie par l'API.
  final String? logoUrl;
  /// URL de la signature (pied de page PDF), fournie par l'API.
  final String? signatureUrl;

  const Company({
    required this.id,
    required this.name,
    this.code,
    this.ninea,
    this.address,
    this.logoUrl,
    this.signatureUrl,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: _parseId(json['id']),
      name: json['name']?.toString() ?? json['raison_sociale']?.toString() ?? '',
      code: json['code']?.toString(),
      ninea: json['ninea']?.toString(),
      address: json['address']?.toString() ?? json['adresse']?.toString(),
      logoUrl: json['logo_url']?.toString(),
      signatureUrl: json['signature_url']?.toString(),
    );
  }

  static int _parseId(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (code != null) 'code': code,
        if (ninea != null) 'ninea': ninea,
        if (address != null) 'address': address,
        if (logoUrl != null) 'logo_url': logoUrl,
        if (signatureUrl != null) 'signature_url': signatureUrl,
      };

  @override
  String toString() => name;
}

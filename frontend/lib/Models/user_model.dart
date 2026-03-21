import 'package:easyconnect/utils/app_config.dart';

class UserModel {
  final int id;
  final String? nom;
  final String? prenom;
  final String? email;
  final String? avatar;
  final int? role;
  final int? companyId;
  final dynamic createdAt;
  final dynamic updatedAt;
  final bool isActive;

  UserModel({
    required this.id,
    this.nom,
    this.prenom,
    this.email,
    this.avatar,
    this.role,
    this.companyId,
    this.createdAt,
    this.updatedAt,
    required this.isActive,
  });

  /// URL complète de la photo de profil (avatar) pour affichage.
  /// - Si le backend renvoie un chemin relatif, on construit l'URL avec l'origine de l'API.
  /// - Si l'URL absolue pointe vers un autre domaine (ex. localhost), on la reconstruit avec l'origine de l'API.
  String? get photoUrl {
    if (avatar == null || avatar!.trim().isEmpty) return null;
    final a = avatar!.trim();
    final origin = AppConfig.baseUrl.replaceFirst(RegExp(r'/api$'), '');
    if (a.startsWith('http://') || a.startsWith('https://')) {
      try {
        final uri = Uri.parse(a);
        final apiUri = Uri.parse(AppConfig.baseUrl);
        if (uri.host == apiUri.host && uri.port == apiUri.port) return a;
        return origin + (uri.path.startsWith('/') ? uri.path : '/$uri.path');
      } catch (_) {
        return a;
      }
    }
    return origin + (a.startsWith('/') ? a : '/storage/$a');
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Conversion ID en int (avec gestion robuste)
    int idValue;
    if (json['id'] is String) {
      final idStr = json['id'] as String;
      idValue = int.tryParse(idStr.trim()) ?? 0;
    } else if (json['id'] is int) {
      idValue = json['id'] as int;
    } else if (json['id'] is num) {
      idValue = (json['id'] as num).toInt();
    } else {
      idValue = 0;
    }

    // Conversion rôle en int
    int? roleValue;
    if (json['role'] != null) {
      roleValue =
          json['role'] is String ? int.tryParse(json['role']) : json['role'];
    }

    // Conversion isActive en bool
    bool activeValue;
    if (json['is_active'] != null) {
      if (json['is_active'] is int) {
        activeValue = json['is_active'] == 1;
      } else {
        activeValue = json['is_active'] ?? true;
      }
    } else if (json['isActive'] != null) {
      if (json['isActive'] is int) {
        activeValue = json['isActive'] == 1;
      } else {
        activeValue = json['isActive'] ?? true;
      }
    } else {
      activeValue = true; // Valeur par défaut
    }

    int? companyIdValue;
    if (json['company_id'] != null) {
      if (json['company_id'] is int) {
        companyIdValue = json['company_id'] as int;
      } else {
        companyIdValue = int.tryParse(json['company_id'].toString());
      }
    }

    return UserModel(
      id: idValue,
      nom: json['nom'],
      prenom: json['prenom'],
      email: json['email'],
      avatar: json['avatar'] as String?,
      role: roleValue,
      companyId: companyIdValue,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      isActive: activeValue,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'prenom': prenom,
    'email': email,
    'avatar': avatar,
    'role': role,
    'company_id': companyId,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'is_active': isActive,
  };
}

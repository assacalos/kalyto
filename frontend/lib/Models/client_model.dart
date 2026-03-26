import 'package:flutter/material.dart';

class Client {
  final int? id;
  final String? nom;
  final String? prenom;
  final String? email;
  final String? contact;
  final String? adresse;
  final String? nomEntreprise;
  final String? situationGeographique;
  final String? numeroContribuable; // Numéro contribuable
  final String? ninea; // NINEA (numéro d'identification ivoirien, 9 chiffres)
  final int? status; // 0: en attente, 1: validé, 2: rejeté
  final String? commentaire;
  final String? createdAt;
  final String? updatedAt;
  final int? userId;

  Client({
    this.id,
    this.nom,
    this.prenom,
    this.email,
    this.contact,
    this.adresse,
    this.nomEntreprise,
    this.situationGeographique,
    this.numeroContribuable,
    this.ninea,
    this.status = 0,
    this.commentaire,
    this.createdAt,
    this.updatedAt,
    this.userId,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] is String ? int.tryParse(json['id']) : json['id'],
      nom: json['nom'],
      prenom: json['prenom'],
      email: json['email'],
      contact: json['contact'],
      adresse: json['adresse'],
      nomEntreprise: json['nom_entreprise'],
      situationGeographique: json['situation_geographique'],
      numeroContribuable: json['numero_contribuable'],
      ninea: json['ninea'],
      // Backend: 0=en attente, 1=validé, 2=rejeté (ClientController)
      status:
          (json['status'] is String
              ? int.tryParse(json['status'])
              : json['status'] as int?) ??
          0,
      commentaire: json['commentaire'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      userId:
          json['user_id'] is String
              ? int.tryParse(json['user_id'])
              : json['user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'contact': contact,
      'adresse': adresse,
      'nom_entreprise': nomEntreprise,
      'situation_geographique': situationGeographique,
      'numero_contribuable': numeroContribuable,
      'ninea': ninea,
      'status': status,
      'commentaire': commentaire,
      'user_id': userId,
    };
  }

  String get statusText {
    switch (status) {
      case 1:
        return "Validé";
      case 2:
        return "Rejeté";
      default:
        return "En attente";
    }
  }

  Color get statusColor {
    switch (status) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 1:
        return Icons.check_circle;
      case 2:
        return Icons.cancel;
      default:
        return Icons.pending;
    }
  }
}

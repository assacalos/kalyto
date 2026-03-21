import 'dart:convert';

class ReportingModel {
  final int id;
  final int userId;
  final String userName;
  final String userRole;
  final DateTime reportDate;
  final String status; // 'submitted', 'approved', 'rejected'
  
  // Nouveaux champs du formulaire
  final String? nature; // Nature du reporting (échange téléphonique, visite, dépannage, etc.)
  final String? nomSociete;
  final String? contactSociete;
  final String? nomPersonne;
  final String? contactPersonne;
  final String? moyenContact; // mail, whatsapp, linkedin
  final String? produitDemarche;
  final String? commentaire;
  final String? typeRelance; // relance_telephonique, relance_mail, relance_rdv
  final DateTime? relanceDateHeure;
  
  // Métriques spécifiques selon le rôle (commercial, technicien, RH, etc.)
  final Map<String, dynamic> metrics;
  
  // Champs de validation
  final DateTime? submittedAt;
  final DateTime? approvedAt;
  final int? approvedBy;
  final DateTime? rejectedAt;
  final int? rejectedBy;
  final String? rejectionReason;
  final String? patronNote; // Note du patron avant validation
  
  final DateTime createdAt;
  final DateTime updatedAt;

  ReportingModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.reportDate,
    required this.status,
    this.nature,
    this.nomSociete,
    this.contactSociete,
    this.nomPersonne,
    this.contactPersonne,
    this.moyenContact,
    this.produitDemarche,
    this.commentaire,
    this.typeRelance,
    this.relanceDateHeure,
    Map<String, dynamic>? metrics,
    this.submittedAt,
    this.approvedAt,
    this.approvedBy,
    this.rejectedAt,
    this.rejectedBy,
    this.rejectionReason,
    this.patronNote,
    required this.createdAt,
    required this.updatedAt,
  }) : metrics = metrics ?? {};

  factory ReportingModel.fromJson(Map<String, dynamic> json) {
    return ReportingModel(
      id: _parseInt(json['id']) ?? 0,
      userId: _parseInt(json['user_id']) ?? 0,
      userName: json['user_name'] ?? '',
      userRole: json['user_role'] ?? '',
      reportDate: _parseDateTime(json['report_date']) ?? DateTime.now(),
      status: json['status'] ?? 'submitted',
      nature: json['nature'],
      nomSociete: json['nom_societe'],
      contactSociete: json['contact_societe'],
      nomPersonne: json['nom_personne'],
      contactPersonne: json['contact_personne'],
      moyenContact: json['moyen_contact'],
      produitDemarche: json['produit_demarche'],
      commentaire: json['commentaire'],
      typeRelance: json['type_relance'],
      relanceDateHeure: _parseDateTime(json['relance_date_heure']),
      metrics: _parseMetrics(json['metrics']),
      submittedAt: _parseDateTime(json['submitted_at']),
      approvedAt: _parseDateTime(json['approved_at']),
      approvedBy: _parseInt(json['approved_by']),
      rejectedAt: _parseDateTime(json['rejected_at']),
      rejectedBy: _parseInt(json['rejected_by']),
      rejectionReason: json['rejection_reason'],
      patronNote: json['patron_note'] ?? json['patronNote'],
      createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updated_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_role': userRole,
      'report_date': reportDate.toIso8601String(),
      'status': status,
      'nature': nature,
      'nom_societe': nomSociete,
      'contact_societe': contactSociete,
      'nom_personne': nomPersonne,
      'contact_personne': contactPersonne,
      'moyen_contact': moyenContact,
      'produit_demarche': produitDemarche,
      'commentaire': commentaire,
      'type_relance': typeRelance,
      'relance_date_heure': relanceDateHeure?.toIso8601String(),
      'metrics': metrics,
      'submitted_at': submittedAt?.toIso8601String(),
      'approved_at': approvedAt?.toIso8601String(),
      'approved_by': approvedBy,
      'rejected_at': rejectedAt?.toIso8601String(),
      'rejected_by': rejectedBy,
      'rejection_reason': rejectionReason,
      'patron_note': patronNote,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
  
  // Accesseurs pour les libellés
  String get natureLibelle {
    switch (nature) {
      case 'echange_telephonique':
        return 'Échange téléphonique';
      case 'visite':
        return 'Visite';
      case 'depannage_visite':
        return 'Dépannage visite';
      case 'depannage_bureau':
        return 'Dépannage bureau';
      case 'depannage_telephonique':
        return 'Dépannage téléphonique';
      case 'programmation':
        return 'Programmation';
      default:
        return nature ?? '';
    }
  }
  
  String get moyenContactLibelle {
    switch (moyenContact) {
      case 'mail':
        return 'Mail';
      case 'whatsapp':
        return 'WhatsApp';
      case 'linkedin':
        return 'LinkedIn';
      default:
        return moyenContact ?? '';
    }
  }
  
  String get typeRelanceLibelle {
    switch (typeRelance) {
      case 'relance_telephonique':
      case 'telephonique':
        return 'Relance téléphonique';
      case 'relance_mail':
      case 'mail':
        return 'Relance par mail';
      case 'relance_rdv':
      case 'rdv':
        return 'Relance par RDV';
      default:
        return typeRelance ?? '';
    }
  }

  // Méthodes de parsing robustes
  static Map<String, dynamic> _parseMetrics(dynamic value) {
    if (value == null) return {};
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String) {
      try {
        if (value.trim().isEmpty) return {};
        final parsed = jsonDecode(value);
        return parsed is Map ? Map<String, dynamic>.from(parsed) : {};
      } catch (_) {
        return {};
      }
    }
    return {};
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is bool) return value ? 1 : 0;
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || trimmed == 'null' || trimmed == 'NULL')
        return null;
      return int.tryParse(trimmed);
    }
    if (value is num) {
      try {
        return value.toInt();
      } catch (e) {
        print('⚠️ ReportingModel: Erreur conversion num vers int: $value - $e');
        return null;
      }
    }
    return null;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || trimmed == 'null' || trimmed == 'NULL')
        return null;
      try {
        // Gérer le cas où la date est mal formée (ex: "22025-10-14")
        if (trimmed.startsWith('22') && trimmed.length > 10) {
          // Corriger "22025" en "2025"
          final corrected = trimmed.replaceFirst('22025', '2025');
          print(
            '⚠️ ReportingModel: Correction date mal formée: "$trimmed" -> "$corrected"',
          );
          return DateTime.parse(corrected);
        }
        return DateTime.parse(trimmed);
      } catch (e) {
        print('⚠️ ReportingModel: Erreur parsing DateTime: $trimmed - $e');
        return null;
      }
    }
    return null;
  }
}

// Métriques spécifiques pour chaque rôle
class CommercialMetrics {
  final int clientsProspectes;
  final int rdvObtenus;
  final List<RdvInfo> rdvList;
  final int devisCrees;
  final int devisAcceptes;
  final int nouveauxClients;
  final int appelsEffectues;
  final int emailsEnvoyes;
  final int visitesRealisees;

  // Champs de notes pour chaque métrique
  final String? noteClientsProspectes;
  final String? noteRdvObtenus;
  final String? noteDevisCrees;
  final String? noteDevisAcceptes;
  final String? noteNouveauxClients;
  final String? noteAppelsEffectues;
  final String? noteEmailsEnvoyes;
  final String? noteVisitesRealisees;

  CommercialMetrics({
    required this.clientsProspectes,
    required this.rdvObtenus,
    required this.rdvList,
    required this.devisCrees,
    required this.devisAcceptes,
    required this.nouveauxClients,
    required this.appelsEffectues,
    required this.emailsEnvoyes,
    required this.visitesRealisees,
    this.noteClientsProspectes,
    this.noteRdvObtenus,
    this.noteDevisCrees,
    this.noteDevisAcceptes,
    this.noteNouveauxClients,
    this.noteAppelsEffectues,
    this.noteEmailsEnvoyes,
    this.noteVisitesRealisees,
  });

  factory CommercialMetrics.fromJson(Map<String, dynamic> json) {
    return CommercialMetrics(
      clientsProspectes: json['clients_prospectes'] ?? 0,
      rdvObtenus: json['rdv_obtenus'] ?? 0,
      rdvList:
          (json['rdv_list'] as List<dynamic>?)
              ?.map((e) => RdvInfo.fromJson(e))
              .toList() ??
          [],
      devisCrees: json['devis_crees'] ?? 0,
      devisAcceptes: json['devis_acceptes'] ?? 0,
      nouveauxClients: json['nouveaux_clients'] ?? 0,
      appelsEffectues: json['appels_effectues'] ?? 0,
      emailsEnvoyes: json['emails_envoyes'] ?? 0,
      visitesRealisees: json['visites_realisees'] ?? 0,
      noteClientsProspectes: json['note_clients_prospectes'],
      noteRdvObtenus: json['note_rdv_obtenus'],
      noteDevisCrees: json['note_devis_crees'],
      noteDevisAcceptes: json['note_devis_acceptes'],
      noteNouveauxClients: json['note_nouveaux_clients'],
      noteAppelsEffectues: json['note_appels_effectues'],
      noteEmailsEnvoyes: json['note_emails_envoyes'],
      noteVisitesRealisees: json['note_visites_realisees'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clients_prospectes': clientsProspectes,
      'rdv_obtenus': rdvObtenus,
      'rdv_list': rdvList.map((e) => e.toJson()).toList(),
      'devis_crees': devisCrees,
      'devis_acceptes': devisAcceptes,
      'nouveaux_clients': nouveauxClients,
      'appels_effectues': appelsEffectues,
      'emails_envoyes': emailsEnvoyes,
      'visites_realisees': visitesRealisees,
      'note_clients_prospectes': noteClientsProspectes,
      'note_rdv_obtenus': noteRdvObtenus,
      'note_devis_crees': noteDevisCrees,
      'note_devis_acceptes': noteDevisAcceptes,
      'note_nouveaux_clients': noteNouveauxClients,
      'note_appels_effectues': noteAppelsEffectues,
      'note_emails_envoyes': noteEmailsEnvoyes,
      'note_visites_realisees': noteVisitesRealisees,
    };
  }
}

class RdvInfo {
  final String clientName;
  final DateTime dateRdv;
  final String heureRdv;
  final String typeRdv; // 'presentiel', 'telephone', 'video'
  final String status; // 'planifie', 'realise', 'annule'
  final String? notes;

  RdvInfo({
    required this.clientName,
    required this.dateRdv,
    required this.heureRdv,
    required this.typeRdv,
    required this.status,
    this.notes,
  });

  factory RdvInfo.fromJson(Map<String, dynamic> json) {
    return RdvInfo(
      clientName: json['client_name'],
      dateRdv: RdvInfo._parseRdvDateTime(json['date_rdv']) ?? DateTime.now(),
      heureRdv: json['heure_rdv'],
      typeRdv: json['type_rdv'],
      status: json['status'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'client_name': clientName,
      'date_rdv': dateRdv.toIso8601String(),
      'heure_rdv': heureRdv,
      'type_rdv': typeRdv,
      'status': status,
      'notes': notes,
    };
  }

  // Méthode de parsing DateTime pour RdvInfo
  static DateTime? _parseRdvDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || trimmed == 'null' || trimmed == 'NULL')
        return null;
      try {
        return DateTime.parse(trimmed);
      } catch (e) {
        print('⚠️ RdvInfo: Erreur parsing DateTime: $trimmed - $e');
        return null;
      }
    }
    return null;
  }
}

class ComptableMetrics {
  final int facturesEmises;
  final int facturesPayees;
  final double montantFacture;
  final double montantEncaissement;
  final int bordereauxTraites;
  final int bonsCommandeTraites;
  final double chiffreAffaires;
  final int clientsFactures;
  final int relancesEffectuees;
  final double encaissements;

  // Champs de notes pour chaque métrique
  final String? noteFacturesEmises;
  final String? noteFacturesPayees;
  final String? noteMontantFacture;
  final String? noteMontantEncaissement;
  final String? noteBordereauxTraites;
  final String? noteBonsCommandeTraites;
  final String? noteChiffreAffaires;
  final String? noteClientsFactures;
  final String? noteRelancesEffectuees;
  final String? noteEncaissements;

  ComptableMetrics({
    required this.facturesEmises,
    required this.facturesPayees,
    required this.montantFacture,
    required this.montantEncaissement,
    required this.bordereauxTraites,
    required this.bonsCommandeTraites,
    required this.chiffreAffaires,
    required this.clientsFactures,
    required this.relancesEffectuees,
    required this.encaissements,
    this.noteFacturesEmises,
    this.noteFacturesPayees,
    this.noteMontantFacture,
    this.noteMontantEncaissement,
    this.noteBordereauxTraites,
    this.noteBonsCommandeTraites,
    this.noteChiffreAffaires,
    this.noteClientsFactures,
    this.noteRelancesEffectuees,
    this.noteEncaissements,
  });

  factory ComptableMetrics.fromJson(Map<String, dynamic> json) {
    return ComptableMetrics(
      facturesEmises: json['factures_emises'] ?? 0,
      facturesPayees: json['factures_payees'] ?? 0,
      montantFacture: (json['montant_facture'] ?? 0).toDouble(),
      montantEncaissement: (json['montant_encaissement'] ?? 0).toDouble(),
      bordereauxTraites: json['bordereaux_traites'] ?? 0,
      bonsCommandeTraites: json['bons_commande_traites'] ?? 0,
      chiffreAffaires: (json['chiffre_affaires'] ?? 0).toDouble(),
      clientsFactures: json['clients_factures'] ?? 0,
      relancesEffectuees: json['relances_effectuees'] ?? 0,
      encaissements: (json['encaissements'] ?? 0).toDouble(),
      noteFacturesEmises: json['note_factures_emises'],
      noteFacturesPayees: json['note_factures_payees'],
      noteMontantFacture: json['note_montant_facture'],
      noteMontantEncaissement: json['note_montant_encaissement'],
      noteBordereauxTraites: json['note_bordereaux_traites'],
      noteBonsCommandeTraites: json['note_bons_commande_traites'],
      noteChiffreAffaires: json['note_chiffre_affaires'],
      noteClientsFactures: json['note_clients_factures'],
      noteRelancesEffectuees: json['note_relances_effectuees'],
      noteEncaissements: json['note_encaissements'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'factures_emises': facturesEmises,
      'factures_payees': facturesPayees,
      'montant_facture': montantFacture,
      'montant_encaissement': montantEncaissement,
      'bordereaux_traites': bordereauxTraites,
      'bons_commande_traites': bonsCommandeTraites,
      'chiffre_affaires': chiffreAffaires,
      'clients_factures': clientsFactures,
      'relances_effectuees': relancesEffectuees,
      'encaissements': encaissements,
      'note_factures_emises': noteFacturesEmises,
      'note_factures_payees': noteFacturesPayees,
      'note_montant_facture': noteMontantFacture,
      'note_montant_encaissement': noteMontantEncaissement,
      'note_bordereaux_traites': noteBordereauxTraites,
      'note_bons_commande_traites': noteBonsCommandeTraites,
      'note_chiffre_affaires': noteChiffreAffaires,
      'note_clients_factures': noteClientsFactures,
      'note_relances_effectuees': noteRelancesEffectuees,
      'note_encaissements': noteEncaissements,
    };
  }
}

class TechnicienMetrics {
  final int interventionsPlanifiees;
  final int interventionsRealisees;
  final int interventionsAnnulees;
  final List<InterventionInfo> interventionsList;
  final int clientsVisites;
  final int problemesResolus;
  final int problemesEnCours;
  final double tempsTravail;
  final int deplacements;
  final String? notesTechniques;

  // Champs de notes pour chaque métrique
  final String? noteInterventionsPlanifiees;
  final String? noteInterventionsRealisees;
  final String? noteInterventionsAnnulees;
  final String? noteClientsVisites;
  final String? noteProblemesResolus;
  final String? noteProblemesEnCours;
  final String? noteTempsTravail;
  final String? noteDeplacements;

  TechnicienMetrics({
    required this.interventionsPlanifiees,
    required this.interventionsRealisees,
    required this.interventionsAnnulees,
    required this.interventionsList,
    required this.clientsVisites,
    required this.problemesResolus,
    required this.problemesEnCours,
    required this.tempsTravail,
    required this.deplacements,
    this.notesTechniques,
    this.noteInterventionsPlanifiees,
    this.noteInterventionsRealisees,
    this.noteInterventionsAnnulees,
    this.noteClientsVisites,
    this.noteProblemesResolus,
    this.noteProblemesEnCours,
    this.noteTempsTravail,
    this.noteDeplacements,
  });

  factory TechnicienMetrics.fromJson(Map<String, dynamic> json) {
    return TechnicienMetrics(
      interventionsPlanifiees: json['interventions_planifiees'] ?? 0,
      interventionsRealisees: json['interventions_realisees'] ?? 0,
      interventionsAnnulees: json['interventions_annulees'] ?? 0,
      interventionsList:
          (json['interventions_list'] as List<dynamic>?)
              ?.map((e) => InterventionInfo.fromJson(e))
              .toList() ??
          [],
      clientsVisites: json['clients_visites'] ?? 0,
      problemesResolus: json['problemes_resolus'] ?? 0,
      problemesEnCours: json['problemes_en_cours'] ?? 0,
      tempsTravail: (json['temps_travail'] ?? 0).toDouble(),
      deplacements: json['deplacements'] ?? 0,
      notesTechniques: json['notes_techniques'],
      noteInterventionsPlanifiees: json['note_interventions_planifiees'],
      noteInterventionsRealisees: json['note_interventions_realisees'],
      noteInterventionsAnnulees: json['note_interventions_annulees'],
      noteClientsVisites: json['note_clients_visites'],
      noteProblemesResolus: json['note_problemes_resolus'],
      noteProblemesEnCours: json['note_problemes_en_cours'],
      noteTempsTravail: json['note_temps_travail'],
      noteDeplacements: json['note_deplacements'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'interventions_planifiees': interventionsPlanifiees,
      'interventions_realisees': interventionsRealisees,
      'interventions_annulees': interventionsAnnulees,
      'interventions_list': interventionsList.map((e) => e.toJson()).toList(),
      'clients_visites': clientsVisites,
      'problemes_resolus': problemesResolus,
      'problemes_en_cours': problemesEnCours,
      'temps_travail': tempsTravail,
      'deplacements': deplacements,
      'notes_techniques': notesTechniques,
      'note_interventions_planifiees': noteInterventionsPlanifiees,
      'note_interventions_realisees': noteInterventionsRealisees,
      'note_interventions_annulees': noteInterventionsAnnulees,
      'note_clients_visites': noteClientsVisites,
      'note_problemes_resolus': noteProblemesResolus,
      'note_problemes_en_cours': noteProblemesEnCours,
      'note_temps_travail': noteTempsTravail,
      'note_deplacements': noteDeplacements,
    };
  }
}

class InterventionInfo {
  final String clientName;
  final DateTime dateIntervention;
  final String heureDebut;
  final String heureFin;
  final String typeIntervention;
  final String status;
  final String? description;
  final String? resultat;

  InterventionInfo({
    required this.clientName,
    required this.dateIntervention,
    required this.heureDebut,
    required this.heureFin,
    required this.typeIntervention,
    required this.status,
    this.description,
    this.resultat,
  });

  factory InterventionInfo.fromJson(Map<String, dynamic> json) {
    return InterventionInfo(
      clientName: json['client_name'],
      dateIntervention:
          _parseInterventionDateTime(json['date_intervention']) ??
          DateTime.now(),
      heureDebut: json['heure_debut'],
      heureFin: json['heure_fin'],
      typeIntervention: json['type_intervention'],
      status: json['status'],
      description: json['description'],
      resultat: json['resultat'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'client_name': clientName,
      'date_intervention': dateIntervention.toIso8601String(),
      'heure_debut': heureDebut,
      'heure_fin': heureFin,
      'type_intervention': typeIntervention,
      'status': status,
      'description': description,
      'resultat': resultat,
    };
  }

  // Méthode de parsing DateTime pour InterventionInfo
  static DateTime? _parseInterventionDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || trimmed == 'null' || trimmed == 'NULL')
        return null;
      try {
        return DateTime.parse(trimmed);
      } catch (e) {
        print('⚠️ InterventionInfo: Erreur parsing DateTime: $trimmed - $e');
        return null;
      }
    }
    return null;
  }
}

class RhMetrics {
  final int employesRecrutes;
  final int demandesCongeTraitees;
  final int demandesCongeApprouvees;
  final int demandesCongeRejetees;
  final int contratsCrees;
  final int contratsRenouveles;
  final int pointagesValides;
  final int entretiensRealises;
  final int formationsOrganisees;
  final int evaluationsEffectuees;

  // Champs de notes pour chaque métrique
  final String? noteEmployesRecrutes;
  final String? noteDemandesCongeTraitees;
  final String? noteContratsCrees;
  final String? notePointagesValides;
  final String? noteEntretiensRealises;
  final String? noteFormationsOrganisees;
  final String? noteEvaluationsEffectuees;

  RhMetrics({
    required this.employesRecrutes,
    required this.demandesCongeTraitees,
    required this.demandesCongeApprouvees,
    required this.demandesCongeRejetees,
    required this.contratsCrees,
    required this.contratsRenouveles,
    required this.pointagesValides,
    required this.entretiensRealises,
    required this.formationsOrganisees,
    required this.evaluationsEffectuees,
    this.noteEmployesRecrutes,
    this.noteDemandesCongeTraitees,
    this.noteContratsCrees,
    this.notePointagesValides,
    this.noteEntretiensRealises,
    this.noteFormationsOrganisees,
    this.noteEvaluationsEffectuees,
  });

  factory RhMetrics.fromJson(Map<String, dynamic> json) {
    return RhMetrics(
      employesRecrutes: json['employes_recrutes'] ?? 0,
      demandesCongeTraitees: json['demandes_conge_traitees'] ?? 0,
      demandesCongeApprouvees: json['demandes_conge_approuvees'] ?? 0,
      demandesCongeRejetees: json['demandes_conge_rejetees'] ?? 0,
      contratsCrees: json['contrats_crees'] ?? 0,
      contratsRenouveles: json['contrats_renouveles'] ?? 0,
      pointagesValides: json['pointages_valides'] ?? 0,
      entretiensRealises: json['entretiens_realises'] ?? 0,
      formationsOrganisees: json['formations_organisees'] ?? 0,
      evaluationsEffectuees: json['evaluations_effectuees'] ?? 0,
      noteEmployesRecrutes: json['note_employes_recrutes'],
      noteDemandesCongeTraitees: json['note_demandes_conge_traitees'],
      noteContratsCrees: json['note_contrats_crees'],
      notePointagesValides: json['note_pointages_valides'],
      noteEntretiensRealises: json['note_entretiens_realises'],
      noteFormationsOrganisees: json['note_formations_organisees'],
      noteEvaluationsEffectuees: json['note_evaluations_effectuees'],
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'employes_recrutes': employesRecrutes,
      'demandes_conge_traitees': demandesCongeTraitees,
      'demandes_conge_approuvees': demandesCongeApprouvees,
      'demandes_conge_rejetees': demandesCongeRejetees,
      'contrats_crees': contratsCrees,
      'contrats_renouveles': contratsRenouveles,
      'pointages_valides': pointagesValides,
      'entretiens_realises': entretiensRealises,
      'formations_organisees': formationsOrganisees,
      'evaluations_effectuees': evaluationsEffectuees,
    };
    
    // Ajouter les notes seulement si elles ne sont pas null et non vides
    if (noteEmployesRecrutes != null && noteEmployesRecrutes!.trim().isNotEmpty) {
      json['note_employes_recrutes'] = noteEmployesRecrutes!.trim();
    }
    if (noteDemandesCongeTraitees != null && noteDemandesCongeTraitees!.trim().isNotEmpty) {
      json['note_demandes_conge_traitees'] = noteDemandesCongeTraitees!.trim();
    }
    if (noteContratsCrees != null && noteContratsCrees!.trim().isNotEmpty) {
      json['note_contrats_crees'] = noteContratsCrees!.trim();
    }
    if (notePointagesValides != null && notePointagesValides!.trim().isNotEmpty) {
      json['note_pointages_valides'] = notePointagesValides!.trim();
    }
    if (noteEntretiensRealises != null && noteEntretiensRealises!.trim().isNotEmpty) {
      json['note_entretiens_realises'] = noteEntretiensRealises!.trim();
    }
    if (noteFormationsOrganisees != null && noteFormationsOrganisees!.trim().isNotEmpty) {
      json['note_formations_organisees'] = noteFormationsOrganisees!.trim();
    }
    if (noteEvaluationsEffectuees != null && noteEvaluationsEffectuees!.trim().isNotEmpty) {
      json['note_evaluations_effectuees'] = noteEvaluationsEffectuees!.trim();
    }
    
    return json;
  }
}

import 'package:easyconnect/services/notification_api_service.dart';
import 'package:easyconnect/utils/logger.dart';

/// Helper pour faciliter l'intégration des notifications dans les contrôleurs
class NotificationHelper {
  static final NotificationApiService _apiService = NotificationApiService();

  /// Notifier la soumission d'une entité
  /// Cette méthode envoie uniquement au patron (pas de notification locale à l'utilisateur)
  static Future<void> notifySubmission({
    required String entityType,
    required String entityName,
    required String entityId,
    String? route,
    String? recipientRole,
  }) async {
    // Créer la notification dans le backend uniquement (non-bloquant)
    // Le backend créera la notification dans la BDD et enverra les push FCM au patron
    // PAS de notification locale pour l'utilisateur qui soumet
    _apiService
        .createNotification(
          title: 'Soumission $entityType',
          message: '$entityName a été soumis pour validation',
          type: 'info',
          entityType: entityType,
          entityId: entityId,
          actionRoute: route,
          recipientRole:
              recipientRole ?? 'patron', // Toujours notifier le patron
        )
        .then((success) {
          if (success) {
            AppLogger.info(
              'Notification créée dans le backend pour la soumission de $entityType #$entityId (destinataire: patron)',
              tag: 'NOTIFICATION_HELPER',
            );
          } else {
            AppLogger.warning(
              'Échec de la création de notification dans le backend',
              tag: 'NOTIFICATION_HELPER',
            );
          }
        })
        .catchError((e) {
          AppLogger.error(
            'Erreur lors de la création de notification dans le backend: $e',
            tag: 'NOTIFICATION_HELPER',
          );
        });

    // PAS de notification locale - seul le patron doit recevoir la notification
  }

  /// Notifier la validation d'une entité
  /// Cette méthode envoie la notification à l'utilisateur qui a créé l'entité (pas au patron)
  /// [entity] : L'entité complète pour extraire l'ID de l'utilisateur créateur
  static Future<void> notifyValidation({
    required String entityType,
    required String entityName,
    required String entityId,
    String? route,
    dynamic entity,
    int? recipientId,
  }) async {
    // Extraire l'ID de l'utilisateur créateur depuis l'entité
    final creatorUserId = recipientId ?? getEntityCreatorId(entity);

    if (creatorUserId == null) {
      AppLogger.warning(
        'Impossible de déterminer l\'utilisateur créateur pour la notification de validation de $entityType #$entityId',
        tag: 'NOTIFICATION_HELPER',
      );
      return;
    }

    // Créer la notification dans le backend pour l'utilisateur créateur (non-bloquant)
    _apiService
        .createNotification(
          title: 'Validation $entityType',
          message: '$entityName a été validé',
          type: 'success',
          entityType: entityType,
          entityId: entityId,
          actionRoute: route,
          recipientIds: [
            creatorUserId,
          ], // Envoyer à l'utilisateur créateur uniquement
        )
        .then((success) {
          if (success) {
            AppLogger.info(
              'Notification créée dans le backend pour la validation de $entityType #$entityId (destinataire: user_id=$creatorUserId)',
              tag: 'NOTIFICATION_HELPER',
            );
          }
        })
        .catchError((e) {
          AppLogger.error(
            'Erreur lors de la création de notification dans le backend: $e',
            tag: 'NOTIFICATION_HELPER',
          );
        });

    // PAS de notification locale - seul l'utilisateur créateur doit recevoir la notification
  }

  /// Notifier le rejet d'une entité
  /// Cette méthode envoie la notification à l'utilisateur qui a créé l'entité (pas au patron)
  /// [entity] : L'entité complète pour extraire l'ID de l'utilisateur créateur
  static Future<void> notifyRejection({
    required String entityType,
    required String entityName,
    required String entityId,
    String? reason,
    String? route,
    dynamic entity,
    int? recipientId,
  }) async {
    final message =
        reason != null
            ? '$entityName a été rejeté. Raison: $reason'
            : '$entityName a été rejeté';

    // Extraire l'ID de l'utilisateur créateur depuis l'entité
    final creatorUserId = recipientId ?? getEntityCreatorId(entity);

    if (creatorUserId == null) {
      AppLogger.warning(
        'Impossible de déterminer l\'utilisateur créateur pour la notification de rejet de $entityType #$entityId',
        tag: 'NOTIFICATION_HELPER',
      );
      return;
    }

    // Créer la notification dans le backend pour l'utilisateur créateur (non-bloquant)
    _apiService
        .createNotification(
          title: 'Rejet $entityType',
          message: message,
          type: 'error',
          entityType: entityType,
          entityId: entityId,
          actionRoute: route,
          recipientIds: [
            creatorUserId,
          ], // Envoyer à l'utilisateur créateur uniquement
          metadata: reason != null ? {'reason': reason} : null,
        )
        .then((success) {
          if (success) {
            AppLogger.info(
              'Notification créée dans le backend pour le rejet de $entityType #$entityId (destinataire: user_id=$creatorUserId)',
              tag: 'NOTIFICATION_HELPER',
            );
          }
        })
        .catchError((e) {
          AppLogger.error(
            'Erreur lors de la création de notification dans le backend: $e',
            tag: 'NOTIFICATION_HELPER',
          );
        });

    // PAS de notification locale - seul l'utilisateur créateur doit recevoir la notification
  }

  /// Extraire l'ID de l'utilisateur créateur depuis une entité
  /// Essaie plusieurs champs possibles : user_id, created_by, createdBy, auteur_id, etc.
  static int? getEntityCreatorId(dynamic entity) {
    if (entity == null) return null;

    // Helper pour obtenir une valeur depuis un Map ou un objet
    dynamic getValue(dynamic obj, String key, [String? altKey]) {
      if (obj == null) return null;

      // Si c'est un Map, accéder directement
      if (obj is Map) {
        final value = obj[key] ?? (altKey != null ? obj[altKey] : null);
        if (value != null) {
          // Convertir en int si nécessaire
          if (value is int) return value;
          if (value is String) return int.tryParse(value);
          if (value is num) return value.toInt();
        }
        return null;
      }

      // Si ce n'est pas un Map, essayer d'accéder comme propriété d'objet
      try {
        // Essayer d'accéder dynamiquement (ne fonctionne pas en Dart, mais on peut essayer)
        return null;
      } catch (e) {
        return null;
      }
    }

    // Essayer différents noms de champs possibles
    final userId =
        getValue(entity, 'user_id', 'userId') ??
        getValue(entity, 'created_by', 'createdBy') ??
        getValue(entity, 'auteur_id', 'auteurId') ??
        getValue(entity, 'created_by_id', 'createdById');

    if (userId != null && userId is int) {
      return userId;
    }

    // Si c'est un objet avec des propriétés, essayer d'accéder directement
    try {
      if (entity.user_id != null) {
        final id = entity.user_id;
        if (id is int) return id;
        if (id is String) return int.tryParse(id);
        if (id is num) return id.toInt();
      }
      if (entity.createdBy != null) {
        final id = entity.createdBy;
        if (id is int) return id;
        if (id is String) return int.tryParse(id);
        if (id is num) return id.toInt();
      }
      if (entity.created_by != null) {
        final id = entity.created_by;
        if (id is int) return id;
        if (id is String) return int.tryParse(id);
        if (id is num) return id.toInt();
      }
    } catch (e) {
      // Ignorer les erreurs d'accès aux propriétés
    }

    return null;
  }

  /// Obtenir le nom d'entité formaté
  static String getEntityDisplayName(String entityType, dynamic entity) {
    // Helper pour obtenir une valeur depuis un Map ou un objet
    dynamic getValue(dynamic obj, String key, [String? altKey]) {
      if (obj == null) return null;

      // Si c'est un Map, accéder directement
      if (obj is Map) {
        return obj[key] ?? (altKey != null ? obj[altKey] : null);
      }

      // Si ce n'est pas un Map, essayer d'accéder comme propriété d'objet
      // Note: En Dart, on ne peut pas accéder dynamiquement aux propriétés
      // Donc on retourne null si ce n'est pas un Map
      return null;
    }

    // Helper pour obtenir l'ID
    dynamic getId(dynamic obj) {
      if (obj == null) return null;

      if (obj is Map) {
        return obj['id'];
      }

      try {
        // Si c'est un objet avec une propriété id
        return obj.id;
      } catch (e) {
        return null;
      }
    }

    final id = getId(entity) ?? '?';

    switch (entityType.toLowerCase()) {
      case 'invoice':
      case 'facture':
        final invoiceNumber = getValue(
          entity,
          'invoice_number',
          'invoiceNumber',
        );
        return 'Facture #${invoiceNumber ?? id}';
      case 'devis':
        final reference = getValue(entity, 'reference');
        return 'Devis ${reference ?? '#$id'}';
      case 'bordereau':
        final reference = getValue(entity, 'reference');
        return 'Bordereau ${reference ?? '#$id'}';
      case 'bon_commande':
      case 'bon de commande':
        return 'Bon de commande #$id';
      case 'payment':
      case 'paiement':
        final paymentNumber = getValue(
          entity,
          'payment_number',
          'paymentNumber',
        );
        return 'Paiement ${paymentNumber ?? '#$id'}';
      case 'expense':
      case 'depense':
        final title = getValue(entity, 'title');
        return 'Dépense ${title ?? '#$id'}';
      case 'salary':
      case 'salaire':
        final employeeName = getValue(entity, 'employee_name', 'employeeName');
        return 'Salaire ${employeeName ?? '#$id'}';
      case 'stock':
        final name = getValue(entity, 'name');
        return 'Stock ${name ?? '#$id'}';
      case 'tax':
      case 'taxe':
        final name = getValue(entity, 'name');
        return 'Taxe ${name ?? '#$id'}';
      case 'intervention':
        return 'Intervention #$id';
      case 'client':
        if (entity is Map) {
          final nomEntreprise = getValue(
            entity,
            'nom_entreprise',
            'nomEntreprise',
          );
          if (nomEntreprise != null && nomEntreprise.toString().isNotEmpty) {
            return nomEntreprise.toString();
          }
          final prenom = getValue(entity, 'prenom');
          final nom = getValue(entity, 'nom');
          return '${prenom ?? ''} ${nom ?? ''}'.trim();
        }
        try {
          return entity.nomEntreprise?.isNotEmpty == true
              ? entity.nomEntreprise!
              : '${entity.prenom ?? ''} ${entity.nom ?? ''}'.trim();
        } catch (e) {
          return 'Client #$id';
        }
      case 'supplier':
      case 'fournisseur':
        final nom = getValue(entity, 'nom', 'name');
        return nom ?? 'Fournisseur #$id';
      case 'report':
      case 'rapport':
        final title = getValue(entity, 'title', 'titre');
        return 'Rapport ${title ?? '#$id'}';
      case 'employee':
      case 'employe':
      case 'employé':
        final name = getValue(entity, 'nom', 'name');
        final prenom = getValue(entity, 'prenom', 'first_name');
        if (name != null || prenom != null) {
          return '${prenom ?? ''} ${name ?? ''}'.trim();
        }
        return 'Employé #$id';
      case 'bon_de_commande_fournisseur':
        final numero = getValue(entity, 'numero_commande', 'numeroCommande');
        return 'Bon de commande fournisseur ${numero ?? '#$id'}';
      case 'attendance':
      case 'pointage':
        final type = getValue(entity, 'type', 'punch_type');
        final typeStr =
            type != null
                ? (type.toString().toLowerCase().contains('check_in') ||
                        type.toString().toLowerCase().contains('arrivée')
                    ? 'Arrivée'
                    : 'Départ')
                : 'Pointage';
        return 'Pointage $typeStr #$id';
      default:
        return '$entityType #$id';
    }
  }

  /// Obtenir la route selon le type d'entité
  static String? getEntityRoute(String entityType, String entityId) {
    switch (entityType.toLowerCase()) {
      case 'invoice':
      case 'facture':
        return '/invoices/$entityId';
      case 'devis':
        return '/devis/$entityId';
      case 'bordereau':
        return '/bordereaux/$entityId';
      case 'bon_commande':
      case 'bon de commande':
        return '/bon-commandes/$entityId';
      case 'payment':
      case 'paiement':
        return '/payments/detail';
      case 'expense':
      case 'depense':
        return null; // Route à définir
      case 'salary':
      case 'salaire':
        return null; // Route à définir
      case 'stock':
        return '/stocks/$entityId';
      case 'tax':
      case 'taxe':
        return '/taxes/$entityId';
      case 'intervention':
        return '/interventions/$entityId';
      case 'equipment':
      case 'equipement':
        return '/equipments/$entityId';
      case 'recruitment':
      case 'recrutement':
        return '/recruitments/$entityId';
      case 'contract':
      case 'contrat':
        return '/contracts/$entityId';
      case 'leave':
      case 'conge':
        return '/leaves/$entityId';
      case 'client':
        return '/clients/$entityId';
      case 'supplier':
      case 'fournisseur':
        return '/suppliers/$entityId';
      case 'report':
      case 'rapport':
        return '/user-reportings/$entityId';
      case 'employee':
      case 'employe':
      case 'employé':
        return '/employees/$entityId';
      case 'bon_de_commande_fournisseur':
        return '/bons-de-commande-fournisseur/$entityId';
      case 'attendance':
      case 'pointage':
        return '/attendances/$entityId';
      default:
        return null;
    }
  }
}

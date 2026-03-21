import 'package:easyconnect/router/app_router.dart' show rootGoRouter;
import '../Models/notification_model.dart';
import '../utils/logger.dart';

/// Service centralisé pour gérer la navigation depuis les notifications
/// Supporte le nouveau format FCM v1 avec type, entity_id, action_route
class NotificationNavigationService {
  static final NotificationNavigationService _instance =
      NotificationNavigationService._internal();
  factory NotificationNavigationService() => _instance;
  NotificationNavigationService._internal();

  /// Appelé au clic sur une notification (liste in-app ou FCM).
  /// Délègue à handleNavigation avec les champs de l'objet notification.
  void handleNavigationFromNotification(AppNotification notification) {
    handleNavigation({
      'type': notification.entityType,
      'entity_type': notification.entityType,
      'entity_id': notification.entityId,
      'action_route': notification.actionRoute.isNotEmpty
          ? notification.actionRoute
          : null,
    });
  }

  /// Gère la navigation depuis une notification
  /// Accepte les données au format FCM v1 : {type, entity_id, action_route}
  void handleNavigation(Map<String, dynamic> data) {
    try {
      AppLogger.info(
        'Navigation depuis notification - Données reçues: $data',
        tag: 'NOTIFICATION_NAV',
      );

      // Support du nouveau format FCM v1 : 'type' (prioritaire)
      // et de l'ancien format : 'entity_type' (pour compatibilité)
      final type = data['type'] as String? ?? data['entity_type'] as String?;
      final entityId = data['entity_id']?.toString();
      final actionRoute = data['action_route'] as String?;

      AppLogger.info(
        'Type: $type, EntityId: $entityId, ActionRoute: $actionRoute',
        tag: 'NOTIFICATION_NAV',
      );

      // Si une route d'action est fournie, l'utiliser en priorité
      // Backend peut envoyer des routes en français (/depenses/, /conges/) : on les normalise
      if (actionRoute != null && actionRoute.isNotEmpty) {
        AppLogger.info(
          'Navigation vers action_route: $actionRoute',
          tag: 'NOTIFICATION_NAV',
        );

        String finalRoute = actionRoute;
        if (finalRoute.contains(':id') && entityId != null) {
          finalRoute = finalRoute.replaceAll(':id', entityId);
        } else if (!finalRoute.contains('/') ||
            (finalRoute.split('/').length == 2 && entityId != null)) {
          finalRoute = '$finalRoute/$entityId';
        }
        finalRoute = _normalizeBackendRoute(finalRoute);
        // Backend envoie parfois /bon-commandes/ pour bon_commande_fournisseur : corriger
        final typeLower = (type ?? '').toString().toLowerCase();
        if (typeLower == 'bon_commande_fournisseur' &&
            finalRoute.startsWith('/bon-commandes/')) {
          finalRoute =
              '/bons-de-commande-fournisseur/${finalRoute.substring('/bon-commandes/'.length)}';
        }
        _navigateToRoute(finalRoute, entityId);
        return;
      }

      // Sinon, utiliser le type d'entité pour déterminer la route
      if (type != null && entityId != null) {
        final route = _getRouteFromType(type, entityId);
        if (route != null) {
          AppLogger.info(
            'Navigation vers route calculée: $route',
            tag: 'NOTIFICATION_NAV',
          );
          _navigateToRoute(route, entityId);
        } else {
          _navigateToNotifications();
        }
      } else {
        // Si aucune information de navigation, aller vers la page des notifications
        _navigateToNotifications();
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erreur lors de la navigation depuis la notification: $e',
        tag: 'NOTIFICATION_NAV',
        error: e,
        stackTrace: stackTrace,
      );
      // En cas d'erreur, rediriger vers la page des notifications
      _navigateToNotifications();
    }
  }

  /// Normalise les routes envoyées par le backend (français) vers les routes Flutter (anglais)
  String _normalizeBackendRoute(String route) {
    final segments = route.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return route;
    final first = segments[0].toLowerCase();
    // Pointage/attendances : une seule page de validation, pas de détail par id
    if (first == 'attendances') return '/attendance-validation';
    final map = <String, String>{
      'depenses': 'expenses',
      'conges': 'leaves',
      'contrats': 'contracts',
      'recrutements': 'recruitment',
      'employes': 'employees',
      'fournisseurs': 'suppliers',
      'factures': 'invoices',
      'paiements': 'payments',
      'equipements': 'equipments',
      'salaires': 'salaries',
      'reportings': 'user-reportings',
      'commandes': 'bon-commandes',
    };
    final en = map[first] ?? first;
    segments[0] = en;
    return '/${segments.join('/')}';
  }

  /// Routes dont la page détail attend Get.arguments (objet), pas seulement l'id.
  /// Pour celles-ci on redirige vers la liste pour éviter un crash.
  static const _detailRoutesNeedingObject = [
    '/expenses/',
    '/leaves/',
    '/contracts/',
    '/recruitment/',
    '/employees/',
    '/suppliers/',
    '/invoices/',
    '/salaries/',
    '/taxes/',
    '/equipments/',
    '/stocks/',
    '/interventions/',
    '/user-reportings/',
    '/besoins/', // pas de page détail /besoins/:id dans l'app
  ];

  /// Convertit un type d'entité en route (aligné sur app_routes.dart et backend)
  String? _getRouteFromType(String type, String entityId) {
    switch (type.toLowerCase()) {
      // Comptable
      case 'expense':
      case 'depense':
        return '/expenses/$entityId';
      case 'invoice':
      case 'facture':
        return '/invoices';
      case 'payment':
      case 'paiement':
        return '/payments/detail';
      case 'salary':
      case 'salaire':
        return '/salaries/$entityId';
      case 'tax':
      case 'taxe':
        return '/taxes/$entityId';
      case 'supplier':
      case 'fournisseur':
        return '/suppliers/$entityId';
      case 'stock':
        return '/stocks/$entityId';
      // Commercial
      case 'client':
        return '/clients/$entityId';
      case 'devis':
        return '/devis/$entityId';
      case 'bordereau':
        return '/bordereaux/$entityId';
      case 'bon_commande':
        return '/bon-commandes/$entityId';
      case 'bon_commande_fournisseur':
      case 'commande_entreprise':
        return '/bons-de-commande-fournisseur/$entityId';
      // RH
      case 'leave_request':
      case 'leave':
      case 'conge':
        return '/leaves/$entityId';
      case 'contract':
      case 'contrat':
        return '/contracts/$entityId';
      case 'recruitment':
      case 'recrutement':
        return '/recruitment/$entityId';
      case 'employee':
      case 'employe':
        return '/employees/$entityId';
      case 'attendance':
        return '/attendance-validation';
      // Technicien
      case 'intervention':
        return '/interventions/$entityId';
      case 'besoin':
        return '/besoins/$entityId';
      case 'equipment':
      case 'equipement':
        return '/equipments/$entityId';
      // Autres
      case 'reporting':
        return '/user-reportings/$entityId';
      case 'task':
      case 'tache':
        return '/tasks/$entityId';
      default:
        return null;
    }
  }

  /// Navigue vers une route avec des arguments optionnels
  /// Certaines pages détail attendent Get.arguments (objet) : on va alors vers la liste.
  void _navigateToRoute(String route, String? entityId) {
    try {
      AppLogger.info(
        'Navigation vers route: $route (entityId: $entityId)',
        tag: 'NOTIFICATION_NAV',
      );

      route = route.trim();
      if (entityId != null && entityId.isNotEmpty) {
        route = route.replaceAll(':id', entityId);
        route = route.replaceAll(':entityId', entityId);
      }

      // Page détail qui attend l'objet en Get.arguments : aller vers la liste
      for (final prefix in _detailRoutesNeedingObject) {
        if (route.startsWith(prefix) && route.length > prefix.length) {
          final listRoute = prefix.replaceAll('/', '');
          rootGoRouter?.go('/$listRoute');
          return;
        }
      }

      if (route == '/payments/detail' && entityId != null) {
        rootGoRouter?.go(route, extra: entityId);
        return;
      }

      if (route.contains('/') && !route.endsWith('/')) {
        final parts = route.split('/');
        if (parts.length >= 3 && int.tryParse(parts.last) != null) {
          rootGoRouter?.go(route);
          return;
        }
      }

      rootGoRouter?.go(route);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erreur lors de la navigation vers $route: $e',
        tag: 'NOTIFICATION_NAV',
        error: e,
        stackTrace: stackTrace,
      );
      _navigateToNotifications();
    }
  }

  /// Navigue vers la page des notifications
  void _navigateToNotifications() {
    AppLogger.info(
      'Redirection vers /notifications',
      tag: 'NOTIFICATION_NAV',
    );
    try {
      rootGoRouter?.go('/notifications');
    } catch (e) {
      AppLogger.error(
        'Erreur lors de la navigation vers /notifications: $e',
        tag: 'NOTIFICATION_NAV',
        error: e,
      );
    }
  }
}


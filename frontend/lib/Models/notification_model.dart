/// Modèle de notification conforme au format JSON du backend
class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type; // 'info', 'success', 'warning', 'error', 'task'
  final String entityType;
  final String entityId;
  final bool isRead;
  final DateTime createdAt;
  final String actionRoute;
  final Map<String, dynamic>? metadata;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.entityType,
    required this.entityId,
    required this.isRead,
    required this.createdAt,
    required this.actionRoute,
    this.metadata,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    // Accepter à la fois 'title' et 'titre' pour compatibilité avec le backend
    final title = json['title'] ?? json['titre'] ?? '';

    return AppNotification(
      id: json['id'].toString(),
      title: title,
      message: json['message'] ?? '',
      type: json['type'] ?? 'info',
      entityType: json['entity_type'] ?? '',
      entityId: json['entity_id'].toString(),
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      actionRoute: json['action_route'] ?? '',
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'entity_type': entityType,
      'entity_id': entityId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'action_route': actionRoute,
      'metadata': metadata,
    };
  }

  /// Obtenir la raison du rejet depuis les métadonnées
  String? get rejectionReason => metadata?['reason'];

  /// Obtenir la couleur selon le type
  String get colorHex {
    switch (type) {
      case 'success':
        return '#4CAF50'; // Vert
      case 'error':
        return '#F44336'; // Rouge
      case 'warning':
        return '#FF9800'; // Orange
      case 'task':
        return '#9C27B0'; // Violet
      default: // 'info'
        return '#2196F3'; // Bleu
    }
  }

  /// Obtenir l'icône selon le type
  String get iconName {
    switch (type) {
      case 'success':
        return 'check_circle';
      case 'error':
        return 'error';
      case 'warning':
        return 'warning';
      case 'task':
        return 'task';
      default: // 'info'
        return 'info';
    }
  }

  /// Créer une copie avec isRead modifié
  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      message: message,
      type: type,
      entityType: entityType,
      entityId: entityId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      actionRoute: actionRoute,
      metadata: metadata,
    );
  }
}

/// Enum pour compatibilité avec l'ancien code
enum NotificationType { info, success, warning, error, task }

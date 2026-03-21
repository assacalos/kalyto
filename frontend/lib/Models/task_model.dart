class TaskModel {
  final int id;
  final String titre;
  final String? description;
  final int assignedTo;
  final int assignedBy;
  final String status;
  final String statusLibelle;
  final String priority;
  final String priorityLibelle;
  final String? dueDate;
  final String? completedAt;
  final String createdAt;
  final String updatedAt;
  final Map<String, dynamic>? assignedToUser;
  final Map<String, dynamic>? assignedByUser;

  TaskModel({
    required this.id,
    required this.titre,
    this.description,
    required this.assignedTo,
    required this.assignedBy,
    required this.status,
    required this.statusLibelle,
    required this.priority,
    required this.priorityLibelle,
    this.dueDate,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.assignedToUser,
    this.assignedByUser,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: _parseInt(json['id']) ?? 0,
      titre: json['titre'] ?? '',
      description: json['description'],
      assignedTo: _parseInt(json['assigned_to']) ?? 0,
      assignedBy: _parseInt(json['assigned_by']) ?? 0,
      status: json['status'] ?? 'pending',
      statusLibelle: json['status_libelle'] ?? _statusLibelle(json['status']),
      priority: json['priority'] ?? 'medium',
      priorityLibelle: json['priority_libelle'] ?? _priorityLibelle(json['priority']),
      dueDate: json['due_date'],
      completedAt: json['completed_at'],
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      assignedToUser: json['assigned_to_user'] != null
          ? Map<String, dynamic>.from(json['assigned_to_user'] as Map)
          : null,
      assignedByUser: json['assigned_by_user'] != null
          ? Map<String, dynamic>.from(json['assigned_by_user'] as Map)
          : null,
    );
  }

  static String _statusLibelle(dynamic status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'in_progress':
        return 'En cours';
      case 'completed':
        return 'Terminée';
      case 'cancelled':
        return 'Annulée';
      default:
        return status?.toString() ?? '';
    }
  }

  static String _priorityLibelle(dynamic priority) {
    switch (priority) {
      case 'urgent':
        return 'Urgent';
      case 'high':
        return 'Haute';
      case 'medium':
        return 'Moyenne';
      case 'low':
        return 'Basse';
      default:
        return priority?.toString() ?? '';
    }
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is num) return value.toInt();
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titre': titre,
      'description': description,
      'assigned_to': assignedTo,
      'assigned_by': assignedBy,
      'status': status,
      'status_libelle': statusLibelle,
      'priority': priority,
      'priority_libelle': priorityLibelle,
      'due_date': dueDate,
      'completed_at': completedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'assigned_to_user': assignedToUser,
      'assigned_by_user': assignedByUser,
    };
  }

  String get assigneeName {
    if (assignedToUser == null) return 'Utilisateur #$assignedTo';
    final prenom = assignedToUser!['prenom'] ?? '';
    final nom = assignedToUser!['nom'] ?? '';
    return '$prenom $nom'.trim().isEmpty ? 'Utilisateur #$assignedTo' : '$prenom $nom'.trim();
  }

  String get assignerName {
    if (assignedByUser == null) return '';
    final prenom = assignedByUser!['prenom'] ?? '';
    final nom = assignedByUser!['nom'] ?? '';
    return '$prenom $nom'.trim();
  }

  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
}

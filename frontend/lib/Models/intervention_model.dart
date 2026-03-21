import 'package:flutter/material.dart';

class Intervention {
  final int? id;
  final String title;
  final String description;
  final String type; // 'external', 'on_site'
  final String
  status; // 'pending', 'approved', 'in_progress', 'completed', 'rejected'
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final DateTime scheduledDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? location;
  final int? clientId;
  final String? clientName;
  final String? clientPhone;
  final String? clientEmail;
  final String? equipment;
  final String? problemDescription;
  final String? solution;
  final String? notes;
  final List<String>? attachments;
  final double? estimatedDuration;
  final double? actualDuration;
  final double? cost;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? createdBy;
  final int? approvedBy;
  final String? approvedAt;
  final String? rejectionReason;
  final String? completionNotes;

  Intervention({
    this.id,
    required this.title,
    required this.description,
    required this.type,
    this.status = 'pending',
    this.priority = 'medium',
    required this.scheduledDate,
    this.startDate,
    this.endDate,
    this.location,
    this.clientId,
    this.clientName,
    this.clientPhone,
    this.clientEmail,
    this.equipment,
    this.problemDescription,
    this.solution,
    this.notes,
    this.attachments,
    this.estimatedDuration,
    this.actualDuration,
    this.cost,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.completionNotes,
  });

  factory Intervention.fromJson(Map<String, dynamic> json) {
    return Intervention(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: json['type'],
      status: json['status'] ?? 'pending',
      priority: json['priority'] ?? 'medium',
      scheduledDate: DateTime.parse(json['scheduled_date']),
      startDate:
          json['start_date'] != null
              ? DateTime.parse(json['start_date'])
              : null,
      endDate:
          json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      location: json['location'],
      clientId: json['client_id'],
      clientName: json['client_name'],
      clientPhone: json['client_phone'],
      clientEmail: json['client_email'],
      equipment: json['equipment'],
      problemDescription: json['problem_description'],
      solution: json['solution'],
      notes: json['notes'],
      attachments:
          json['attachments'] != null
              ? List<String>.from(json['attachments'])
              : null,
      estimatedDuration:
          json['estimated_duration'] != null
              ? (json['estimated_duration'] is String
                  ? double.tryParse(json['estimated_duration'])
                  : (json['estimated_duration'] as num?)?.toDouble())
              : null,
      actualDuration:
          json['actual_duration'] != null
              ? (json['actual_duration'] is String
                  ? double.tryParse(json['actual_duration'])
                  : (json['actual_duration'] as num?)?.toDouble())
              : null,
      cost:
          json['cost'] != null
              ? (json['cost'] is String
                  ? double.tryParse(json['cost'])
                  : (json['cost'] as num?)?.toDouble())
              : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      createdBy: json['created_by'],
      approvedBy: json['approved_by'],
      approvedAt: json['approved_at'],
      rejectionReason: json['rejection_reason'],
      completionNotes: json['completion_notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'status': status,
      'priority': priority,
      'scheduled_date': scheduledDate.toIso8601String(),
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'location': location,
      if (clientId != null) 'client_id': clientId,
      'client_name': clientName,
      'client_phone': clientPhone,
      'client_email': clientEmail,
      'equipment': equipment,
      'problem_description': problemDescription,
      'solution': solution,
      'notes': notes,
      'attachments': attachments,
      'estimated_duration': estimatedDuration,
      'actual_duration': actualDuration,
      'cost': cost,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
      'approved_by': approvedBy,
      'approved_at': approvedAt,
      'rejection_reason': rejectionReason,
      'completion_notes': completionNotes,
    };
  }

  // Méthodes utilitaires
  String get statusText {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'approved':
        return 'Approuvée';
      case 'in_progress':
        return 'En cours';
      case 'completed':
        return 'Terminée';
      case 'rejected':
        return 'Rejetée';
      default:
        return 'Inconnu';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'in_progress':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'approved':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.build;
      case 'completed':
        return Icons.done_all;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String get typeText {
    switch (type) {
      case 'external':
        return 'Externe';
      case 'on_site':
        return 'Sur place';
      default:
        return 'Inconnu';
    }
  }

  Color get typeColor {
    switch (type) {
      case 'external':
        return Colors.blue;
      case 'on_site':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData get typeIcon {
    switch (type) {
      case 'external':
        return Icons.location_on;
      case 'on_site':
        return Icons.home;
      default:
        return Icons.help;
    }
  }

  String get priorityText {
    switch (priority) {
      case 'low':
        return 'Faible';
      case 'medium':
        return 'Moyenne';
      case 'high':
        return 'Élevée';
      case 'urgent':
        return 'Urgente';
      default:
        return 'Inconnue';
    }
  }

  Color get priorityColor {
    switch (priority) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.blue;
      case 'high':
        return Colors.orange;
      case 'urgent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData get priorityIcon {
    switch (priority) {
      case 'low':
        return Icons.keyboard_arrow_down;
      case 'medium':
        return Icons.remove;
      case 'high':
        return Icons.keyboard_arrow_up;
      case 'urgent':
        return Icons.priority_high;
      default:
        return Icons.help;
    }
  }

  // Calculer la durée réelle si les dates sont disponibles
  double? get calculatedDuration {
    if (startDate != null && endDate != null) {
      return endDate!.difference(startDate!).inMinutes / 60.0;
    }
    return actualDuration;
  }

  // Vérifier si l'intervention est en retard
  bool get isOverdue {
    if (status == 'completed') return false;
    return DateTime.now().isAfter(scheduledDate);
  }

  // Vérifier si l'intervention est due bientôt
  bool get isDueSoon {
    if (status == 'completed') return false;
    final now = DateTime.now();
    final dueDate = scheduledDate.subtract(const Duration(hours: 2));
    return now.isAfter(dueDate) && !isOverdue;
  }
}

class InterventionStats {
  final int totalInterventions;
  final int pendingInterventions;
  final int approvedInterventions;
  final int inProgressInterventions;
  final int completedInterventions;
  final int rejectedInterventions;
  final int externalInterventions;
  final int onSiteInterventions;
  final double averageDuration;
  final double totalCost;
  final Map<String, int> interventionsByMonth;
  final Map<String, int> interventionsByPriority;

  InterventionStats({
    required this.totalInterventions,
    required this.pendingInterventions,
    required this.approvedInterventions,
    required this.inProgressInterventions,
    required this.completedInterventions,
    required this.rejectedInterventions,
    required this.externalInterventions,
    required this.onSiteInterventions,
    required this.averageDuration,
    required this.totalCost,
    required this.interventionsByMonth,
    required this.interventionsByPriority,
  });

  factory InterventionStats.fromJson(Map<String, dynamic> json) {
    return InterventionStats(
      totalInterventions: json['total_interventions'] ?? 0,
      pendingInterventions: json['pending_interventions'] ?? 0,
      approvedInterventions: json['approved_interventions'] ?? 0,
      inProgressInterventions: json['in_progress_interventions'] ?? 0,
      completedInterventions: json['completed_interventions'] ?? 0,
      rejectedInterventions: json['rejected_interventions'] ?? 0,
      externalInterventions: json['external_interventions'] ?? 0,
      onSiteInterventions: json['on_site_interventions'] ?? 0,
      averageDuration: (json['average_duration'] ?? 0.0).toDouble(),
      totalCost: (json['total_cost'] ?? 0.0).toDouble(),
      interventionsByMonth: Map<String, int>.from(
        json['interventions_by_month'] ?? {},
      ),
      interventionsByPriority: Map<String, int>.from(
        json['interventions_by_priority'] ?? {},
      ),
    );
  }
}

class InterventionType {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const InterventionType({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  static const List<InterventionType> types = [
    InterventionType(
      value: 'external',
      label: 'Externe',
      icon: Icons.location_on,
      color: Colors.blue,
    ),
    InterventionType(
      value: 'on_site',
      label: 'Sur place',
      icon: Icons.home,
      color: Colors.green,
    ),
  ];
}

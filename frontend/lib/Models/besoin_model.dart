class Besoin {
  final int? id;
  final String title;
  final String? description;
  final int createdBy;
  final String reminderFrequency; // daily, every_2_days, weekly
  final DateTime? nextReminderAt;
  final String status; // pending, treated
  final DateTime? treatedAt;
  final int? treatedBy;
  final String? treatedNote;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? creatorName;

  Besoin({
    this.id,
    required this.title,
    this.description,
    required this.createdBy,
    required this.reminderFrequency,
    this.nextReminderAt,
    this.status = 'pending',
    this.treatedAt,
    this.treatedBy,
    this.treatedNote,
    required this.createdAt,
    required this.updatedAt,
    this.creatorName,
  });

  factory Besoin.fromJson(Map<String, dynamic> json) {
    return Besoin(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      createdBy: _int(json['created_by']) ?? 0,
      reminderFrequency: json['reminder_frequency']?.toString() ?? 'weekly',
      nextReminderAt: json['next_reminder_at'] != null
          ? DateTime.tryParse(json['next_reminder_at'].toString())
          : null,
      status: json['status']?.toString() ?? 'pending',
      treatedAt: json['treated_at'] != null
          ? DateTime.tryParse(json['treated_at'].toString())
          : null,
      treatedBy: _int(json['treated_by']),
      treatedNote: json['treated_note']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
      creatorName: json['creator'] is Map
          ? _creatorName(json['creator'] as Map<String, dynamic>)
          : null,
    );
  }

  static int? _int(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static String? _creatorName(Map<String, dynamic> creator) {
    final p = creator['prenom']?.toString() ?? '';
    final n = creator['nom']?.toString() ?? '';
    final s = '$p $n'.trim();
    return s.isNotEmpty ? s : creator['email']?.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'created_by': createdBy,
      'reminder_frequency': reminderFrequency,
      'next_reminder_at': nextReminderAt?.toIso8601String(),
      'status': status,
      'treated_at': treatedAt?.toIso8601String(),
      'treated_by': treatedBy,
      'treated_note': treatedNote,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get reminderFrequencyLabel {
    switch (reminderFrequency) {
      case 'daily':
        return 'Tous les jours';
      case 'every_2_days':
        return 'Tous les 2 jours';
      case 'weekly':
        return 'Toutes les semaines';
      default:
        return reminderFrequency;
    }
  }

  bool get isPending => status == 'pending';
}

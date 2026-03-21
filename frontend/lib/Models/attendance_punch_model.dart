import 'dart:math';
import 'package:easyconnect/utils/app_config.dart';

class AttendancePunchModel {
  final int? id;
  final int userId;
  final String type; // 'check_in' ou 'check_out'
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final String? address;
  final double? accuracy;
  final String? photoPath;
  final String? notes;
  final String status; // 'pending', 'approved', 'rejected'
  final String? rejectionReason;
  final int? approvedBy;
  final DateTime? approvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relations
  final String? userName;
  final String? approverName;

  AttendancePunchModel({
    this.id,
    required this.userId,
    required this.type,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.address,
    this.accuracy,
    this.photoPath,
    this.notes,
    required this.status,
    this.rejectionReason,
    this.approvedBy,
    this.approvedAt,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.approverName,
  });

  // Normaliser le statut (convertir en_attente, valide, rejete en anglais)
  static String _normalizeStatus(String? status) {
    if (status == null) return 'pending';
    final normalized = status.toLowerCase().trim();

    // Normaliser les statuts français vers anglais
    String normalizedStatus;
    switch (normalized) {
      case 'en_attente':
      case 'en attente':
      case 'pending':
        normalizedStatus = 'pending';
        break;
      case 'approuvé':
      case 'approuve':
      case 'approved':
      case 'valide':
      case 'validé':
        normalizedStatus = 'approved';
        break;
      case 'rejeté':
      case 'rejete':
      case 'rejected':
        normalizedStatus = 'rejected';
        break;
      default:
        // Si c'est déjà en anglais ou format inconnu, retourner tel quel
        normalizedStatus = normalized;
    }

    if (normalized != normalizedStatus) {}

    return normalizedStatus;
  }

  factory AttendancePunchModel.fromJson(Map<String, dynamic> json) {
    try {
      final rawStatus = json['status']?.toString();

      // Gérer les deux formats possibles : nouveau format (check_in_time/check_out_time) et ancien format (timestamp/type)
      DateTime timestamp;
      String type;

      if (json['check_in_time'] != null || json['check_out_time'] != null) {
        // Nouveau format avec check_in_time et check_out_time
        if (json['check_in_time'] != null) {
          timestamp = DateTime.parse(json['check_in_time']);
          type = 'check_in';
        } else {
          timestamp = DateTime.parse(json['check_out_time']);
          type = 'check_out';
        }
      } else {
        // Ancien format avec timestamp et type
        timestamp = DateTime.parse(json['timestamp']);
        type = json['type'] ?? 'check_in';
      }

      // Gérer la localisation (peut être un objet ou des champs directs)
      double latitude = 0.0;
      double longitude = 0.0;
      String? address;
      double? accuracy;

      if (json['location'] != null && json['location'] is Map) {
        // Format avec objet location
        final location = json['location'] as Map<String, dynamic>;
        latitude =
            double.tryParse(location['latitude']?.toString() ?? '0') ?? 0.0;
        longitude =
            double.tryParse(location['longitude']?.toString() ?? '0') ?? 0.0;
        address = location['address']?.toString();
        accuracy = double.tryParse(location['accuracy']?.toString() ?? '0');
      } else {
        // Format avec champs directs
        latitude = double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0;
        longitude =
            double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0;
        address = json['address']?.toString();
        accuracy = double.tryParse(json['accuracy']?.toString() ?? '0');
      }

      // Gérer les champs de validation (peut être validated_by ou approved_by)
      final approvedBy = json['approved_by'] ?? json['validated_by'];
      final approvedAtStr = json['approved_at'] ?? json['validated_at'];
      final rejectionReason =
          json['rejection_reason'] ?? json['validation_comment'];

      // Gérer l'approbateur (peut être approver ou validator)
      final approver = json['approver'] ?? json['validator'];

      final normalizedStatus = _normalizeStatus(rawStatus);

      return AttendancePunchModel(
        id: json['id'],
        userId: json['user_id'],
        type: type,
        timestamp: timestamp,
        latitude: latitude,
        longitude: longitude,
        address: address,
        accuracy: accuracy,
        photoPath: json['photo_path'],
        notes: json['notes'],
        status: normalizedStatus,
        rejectionReason: rejectionReason?.toString(),
        approvedBy:
            approvedBy != null ? int.tryParse(approvedBy.toString()) : null,
        approvedAt:
            approvedAtStr != null ? DateTime.parse(approvedAtStr) : null,
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
        userName:
            json['user']?['name'] ??
            json['user']?['nom'] ??
            '${json['user']?['prenom'] ?? ''} ${json['user']?['nom'] ?? ''}'
                .trim(),
        approverName:
            approver?['name'] ??
            approver?['nom'] ??
            (approver?['prenom'] != null && approver?['nom'] != null
                ? '${approver['prenom']} ${approver['nom']}'
                : null),
      );
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'accuracy': accuracy,
      'photo_path': photoPath,
      'notes': notes,
      'status': status,
      'rejection_reason': rejectionReason,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Getters pour l'affichage
  String get typeLabel {
    switch (type) {
      case 'check_in':
        return 'Arrivée';
      case 'check_out':
        return 'Départ';
      default:
        return 'Inconnu';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'approved':
        return 'Approuvé';
      case 'rejected':
        return 'Rejeté';
      default:
        return 'Inconnu';
    }
  }

  String get statusColor {
    switch (status) {
      case 'pending':
        return '#FFA500'; // Orange
      case 'approved':
        return '#28A745'; // Vert
      case 'rejected':
        return '#DC3545'; // Rouge
      default:
        return '#6C757D'; // Gris
    }
  }

  String get typeColor {
    switch (type) {
      case 'check_in':
        return '#007BFF'; // Bleu
      case 'check_out':
        return '#6F42C1'; // Violet
      default:
        return '#6C757D'; // Gris
    }
  }

  String get photoUrl {
    if (photoPath != null && photoPath!.isNotEmpty) {
      // Si le photoPath est déjà une URL complète, le retourner tel quel
      if (photoPath!.startsWith('http://') ||
          photoPath!.startsWith('https://')) {
        return photoPath!;
      }

      // Construire l'URL complète avec la base URL
      // Enlever /api de la fin de baseUrl car storage est à la racine du serveur
      String baseUrlWithoutApi = AppConfig.baseUrl;
      if (baseUrlWithoutApi.endsWith('/api')) {
        baseUrlWithoutApi = baseUrlWithoutApi.substring(
          0,
          baseUrlWithoutApi.length - 4,
        );
      }

      // Nettoyer le photoPath
      String cleanPath = photoPath!;
      if (cleanPath.startsWith('/')) {
        cleanPath = cleanPath.substring(1);
      }

      // Si le photoPath contient déjà storage/, l'utiliser tel quel
      if (cleanPath.contains('storage/')) {
        return '$baseUrlWithoutApi/$cleanPath';
      }

      // Sinon, ajouter storage/ devant
      return '$baseUrlWithoutApi/storage/$cleanPath';
    }
    return '';
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isCheckIn => type == 'check_in';
  bool get isCheckOut => type == 'check_out';

  // Méthodes de validation
  bool get canBeApproved => isPending;
  bool get canBeRejected => isPending;

  // Formatage des dates
  String get formattedTimestamp {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} à ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  String get formattedDate {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  // Distance depuis une position donnée
  double distanceFrom(double lat, double lng) {
    const double earthRadius = 6371000; // Rayon de la Terre en mètres

    final double lat1Rad = latitude * (3.14159265359 / 180);
    final double lat2Rad = lat * (3.14159265359 / 180);
    final double deltaLatRad = (lat - latitude) * (3.14159265359 / 180);
    final double deltaLngRad = (lng - longitude) * (3.14159265359 / 180);

    final double a =
        sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) *
            cos(lat2Rad) *
            sin(deltaLngRad / 2) *
            sin(deltaLngRad / 2);
    final double c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  // Vérifier si le pointage est récent (moins de 24h)
  bool get isRecent {
    return DateTime.now().difference(timestamp).inHours < 24;
  }

  // Vérifier si le pointage est aujourd'hui
  bool get isToday {
    final now = DateTime.now();
    return timestamp.year == now.year &&
        timestamp.month == now.month &&
        timestamp.day == now.day;
  }

  AttendancePunchModel copyWith({
    int? id,
    int? userId,
    String? type,
    DateTime? timestamp,
    double? latitude,
    double? longitude,
    String? address,
    double? accuracy,
    String? photoPath,
    String? notes,
    String? status,
    String? rejectionReason,
    int? approvedBy,
    DateTime? approvedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userName,
    String? approverName,
  }) {
    return AttendancePunchModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      accuracy: accuracy ?? this.accuracy,
      photoPath: photoPath ?? this.photoPath,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userName: userName ?? this.userName,
      approverName: approverName ?? this.approverName,
    );
  }
}

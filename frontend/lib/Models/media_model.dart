/// Modèle pour représenter un fichier média
class MediaItem {
  final String id;
  final String url;
  final String? thumbnailUrl;
  final String fileName;
  final String fileType; // 'image', 'pdf', 'document'
  final String
  category; // 'attendance', 'bon_commande', 'expense', 'salary', 'other'
  final String? entityId;
  final String? entityType;
  final DateTime createdAt;
  final int? fileSize;
  final int? userId; // ID de l'utilisateur qui a créé le média

  const MediaItem({
    required this.id,
    required this.url,
    this.thumbnailUrl,
    required this.fileName,
    required this.fileType,
    required this.category,
    this.entityId,
    this.entityType,
    required this.createdAt,
    this.fileSize,
    this.userId,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'].toString(),
      url: json['url'] ?? json['file_path'] ?? '',
      thumbnailUrl: json['thumbnail_url'],
      fileName: json['file_name'] ?? json['name'] ?? '',
      fileType: json['file_type'] ?? _detectFileType(json['file_name'] ?? ''),
      category: json['category'] ?? 'other',
      entityId: json['entity_id']?.toString(),
      entityType: json['entity_type'],
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
      fileSize: json['file_size'],
      userId:
          json['user_id'] is String
              ? int.tryParse(json['user_id'])
              : json['user_id'],
    );
  }

  static String _detectFileType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
      return 'image';
    } else if (extension == 'pdf') {
      return 'pdf';
    }
    return 'document';
  }

  bool get isImage => fileType == 'image';
  bool get isPdf => fileType == 'pdf';
}

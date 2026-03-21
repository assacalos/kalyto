import 'package:easyconnect/Models/media_model.dart';
import 'package:easyconnect/services/attendance_punch_service.dart';
import 'package:easyconnect/services/bon_commande_service.dart';
import 'package:easyconnect/services/expense_service.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/services/session_service.dart';
import 'package:easyconnect/utils/roles.dart';

/// Service pour récupérer les médias (images et fichiers) de toutes les entités
class MediaService {
  static final MediaService _instance = MediaService._();
  static MediaService get to => _instance;
  factory MediaService() => _instance;

  MediaService._();

  final AttendancePunchService _attendanceService = AttendancePunchService();
  final BonCommandeService _bonCommandeService = BonCommandeService();
  final ExpenseService _expenseService = ExpenseService();

  /// Récupérer tous les médias par catégorie
  /// Filtre automatiquement selon le rôle : patron voit tout, autres utilisateurs voient uniquement leurs médias
  Future<Map<String, List<MediaItem>>> getAllMedia() async {
    try {
      // Récupérer l'ID et le rôle de l'utilisateur connecté
      final currentUserId = SessionService.getUserId();
      final currentUserRole = SessionService.getUserRole();
      final isPatron = currentUserRole == Roles.PATRON;

      AppLogger.info(
        'Chargement des médias - User ID: $currentUserId, Role: $currentUserRole, Is Patron: $isPatron',
        tag: 'MEDIA_SERVICE',
      );

      final Map<String, List<MediaItem>> mediaByCategory = {
        'attendance': [],
        'bon_commande': [],
        'expense': [],
        'salary': [],
        'other': [],
      };

      // Récupérer les médias de chaque catégorie en parallèle
      await Future.wait([
        _loadAttendanceMedia(mediaByCategory, currentUserId, isPatron),
        _loadBonCommandeMedia(mediaByCategory, currentUserId, isPatron),
        _loadExpenseMedia(mediaByCategory, currentUserId, isPatron),
        _loadSalaryMedia(mediaByCategory, currentUserId, isPatron),
      ]);

      return mediaByCategory;
    } catch (e) {
      AppLogger.error(
        'Erreur lors de la récupération des médias: $e',
        tag: 'MEDIA_SERVICE',
      );
      return {
        'attendance': [],
        'bon_commande': [],
        'expense': [],
        'salary': [],
        'other': [],
      };
    }
  }

  /// Charger les médias des pointages
  Future<void> _loadAttendanceMedia(
    Map<String, List<MediaItem>> mediaByCategory,
    int? currentUserId,
    bool isPatron,
  ) async {
    try {
      final attendances = await _attendanceService.getAttendances();
      for (var attendance in attendances) {
        // Filtrer : patron voit tout, autres utilisateurs voient uniquement leurs pointages
        if (!isPatron && attendance.userId != currentUserId) {
          continue;
        }

        if (attendance.photoPath != null && attendance.photoPath!.isNotEmpty) {
          mediaByCategory['attendance']!.add(
            MediaItem(
              id: 'attendance_${attendance.id}',
              url: attendance.photoUrl,
              fileName: 'Pointage_${attendance.id}.jpg',
              fileType: 'image',
              category: 'attendance',
              entityId: attendance.id?.toString(),
              entityType: 'attendance',
              createdAt: attendance.timestamp,
              userId: attendance.userId,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error(
        'Erreur lors du chargement des médias de pointage: $e',
        tag: 'MEDIA_SERVICE',
      );
    }
  }

  /// Charger les médias des bons de commande
  Future<void> _loadBonCommandeMedia(
    Map<String, List<MediaItem>> mediaByCategory,
    int? currentUserId,
    bool isPatron,
  ) async {
    try {
      final bonCommandes = await _bonCommandeService.getBonCommandes();
      for (var bonCommande in bonCommandes) {
        // Filtrer : patron voit tout, autres utilisateurs voient uniquement leurs bons de commande
        if (!isPatron && bonCommande.commercialId != currentUserId) {
          continue;
        }

        for (var fichier in bonCommande.fichiers) {
          if (fichier.isNotEmpty) {
            final isImage = _isImageFile(fichier);
            mediaByCategory['bon_commande']!.add(
              MediaItem(
                id: 'bon_commande_${bonCommande.id}_${fichier.hashCode}',
                url: _buildFileUrl(fichier),
                fileName: fichier.split('/').last,
                fileType: isImage ? 'image' : 'document',
                category: 'bon_commande',
                entityId: bonCommande.id?.toString(),
                entityType: 'bon_commande',
                createdAt: DateTime.now(), // TODO: Récupérer la date réelle
                userId: bonCommande.commercialId,
              ),
            );
          }
        }
      }
    } catch (e) {
      AppLogger.error(
        'Erreur lors du chargement des médias de bon de commande: $e',
        tag: 'MEDIA_SERVICE',
      );
    }
  }

  /// Charger les médias des dépenses
  Future<void> _loadExpenseMedia(
    Map<String, List<MediaItem>> mediaByCategory,
    int? currentUserId,
    bool isPatron,
  ) async {
    try {
      final expenses = await _expenseService.getExpenses();
      for (var expense in expenses) {
        // Filtrer : patron voit tout, autres utilisateurs voient uniquement leurs dépenses
        if (!isPatron && expense.createdBy != currentUserId) {
          continue;
        }

        if (expense.receiptPath != null && expense.receiptPath!.isNotEmpty) {
          final isImage = _isImageFile(expense.receiptPath!);
          mediaByCategory['expense']!.add(
            MediaItem(
              id: 'expense_${expense.id}',
              url: expense.receiptUrl,
              fileName: expense.receiptPath!.split('/').last,
              fileType: isImage ? 'image' : 'document',
              category: 'expense',
              entityId: expense.id?.toString(),
              entityType: 'expense',
              createdAt: expense.createdAt,
              userId: expense.createdBy,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error(
        'Erreur lors du chargement des médias de dépense: $e',
        tag: 'MEDIA_SERVICE',
      );
    }
  }

  /// Charger les médias des salaires
  Future<void> _loadSalaryMedia(
    Map<String, List<MediaItem>> mediaByCategory,
    int? currentUserId,
    bool isPatron,
  ) async {
    try {
      // TODO: Implémenter quand le service de salaire aura une méthode pour récupérer les fichiers
      // Pour l'instant, on laisse vide
      // Note: Quand implémenté, appliquer le même filtrage (isPatron ou userId == currentUserId)
    } catch (e) {
      AppLogger.error(
        'Erreur lors du chargement des médias de salaire: $e',
        tag: 'MEDIA_SERVICE',
      );
    }
  }

  /// Vérifier si un fichier est une image
  bool _isImageFile(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);
  }

  /// Construire l'URL complète d'un fichier
  String _buildFileUrl(String filePath) {
    if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
      return filePath;
    }

    String baseUrlWithoutApi = AppConfig.baseUrl;
    if (baseUrlWithoutApi.endsWith('/api')) {
      baseUrlWithoutApi = baseUrlWithoutApi.substring(
        0,
        baseUrlWithoutApi.length - 4,
      );
    }

    String cleanPath = filePath;
    if (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }

    if (cleanPath.contains('storage/')) {
      return '$baseUrlWithoutApi/$cleanPath';
    }

    return '$baseUrlWithoutApi/storage/$cleanPath';
  }
}

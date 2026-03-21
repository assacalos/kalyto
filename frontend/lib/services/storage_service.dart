import 'package:hive_flutter/hive_flutter.dart';
import 'package:easyconnect/utils/logger.dart';

/// Service de cache local avec Hive pour un affichage instantané (type WhatsApp).
/// Sauvegarde et récupère des listes d'objets JSON par entité.
class HiveStorageService {
  static const String _boxName = 'easyconnect_cache';
  static Box<dynamic>? _box;

  /// Clés des entités (utilisables pour saveEntityList / getEntityList).
  static const String keyClients = 'clients';
  static const String keyDevis = 'devis';
  static const String keyBordereaux = 'bordereaux';
  static const String keyBonCommandes = 'bon_commandes';
  static const String keyFactures = 'factures';
  static const String keyPaiements = 'paiements';
  static const String keyDepenses = 'depenses';
  static const String keySalaires = 'salaires';
  static const String keyReporting = 'reporting';
  static const String keyTaches = 'taches';
  static const String keyInterventions = 'interventions';
  static const String keyEmployees = 'employees';
  static const String keyFournisseurs = 'fournisseurs';
  static const String keyStocks = 'stocks';
  static const String keyContracts = 'contracts';
  static const String keyLeaves = 'leaves';
  static const String keyRecruitments = 'recruitments';
  static const String keyTaxes = 'taxes';
  static const String keyAttendances = 'attendances';
  static const String keyEquipments = 'equipments';
  static const String keyBesoins = 'besoins';
  static const String keyNotifications = 'notifications';

  /// Initialise Hive (à appeler une fois au démarrage, ex. dans main()).
  /// N'efface pas la box : openBox ouvre la box existante sans la formater.
  static Future<void> init() async {
    if (_box != null) return;
    try {
      await Hive.initFlutter();
      _box = await Hive.openBox<dynamic>(_boxName);
      AppLogger.info('Hive initialisé avec succès', tag: 'HIVE_STORAGE');
    } catch (e, st) {
      AppLogger.error(
        'Erreur initialisation Hive: $e',
        tag: 'HIVE_STORAGE',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  static Box<dynamic> get _ensureBox {
    if (_box == null || !_box!.isOpen) {
      throw StateError('HiveStorageService non initialisé. Appelez HiveStorageService.init() dans main().');
    }
    return _box!;
  }

  /// Sauvegarde une liste d'objets (JSON) pour une entité.
  /// [entityKey] : ex. HiveStorageService.keyDevis, keyClients, etc.
  /// [list] : liste de maps (données sérialisables en JSON).
  static Future<void> saveEntityList(
    String entityKey,
    List<Map<String, dynamic>> list,
  ) async {
    try {
      if (_box == null || !_box!.isOpen) return;
      await _box!.put(entityKey, list);
      AppLogger.debug(
        'Hive: sauvegardé ${list.length} éléments pour "$entityKey"',
        tag: 'HIVE_STORAGE',
      );
    } catch (e, st) {
      AppLogger.error(
        'Hive saveEntityList($entityKey): $e',
        tag: 'HIVE_STORAGE',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Récupère la liste d'objets (JSON) pour une entité.
  /// Retourne une liste vide si aucune donnée ou en cas d'erreur.
  static List<Map<String, dynamic>> getEntityList(String entityKey) {
    try {
      if (_box == null || !_box!.isOpen) return [];
      final value = _box!.get(entityKey);
      if (value == null) return [];
      if (value is List) {
        return value
            .map((e) => e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map))
            .toList();
      }
      return [];
    } catch (e, st) {
      AppLogger.error(
        'Hive getEntityList($entityKey): $e',
        tag: 'HIVE_STORAGE',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  /// Supprime le cache d'une entité.
  static Future<void> clearEntity(String entityKey) async {
    try {
      await _ensureBox.delete(entityKey);
    } catch (e, st) {
      AppLogger.error(
        'Hive clearEntity($entityKey): $e',
        tag: 'HIVE_STORAGE',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Vide tout le cache.
  static Future<void> clearAll() async {
    try {
      await _ensureBox.clear();
      AppLogger.info('Hive: cache vidé', tag: 'HIVE_STORAGE');
    } catch (e, st) {
      AppLogger.error(
        'Hive clearAll: $e',
        tag: 'HIVE_STORAGE',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Ferme la box (utile pour les tests ou déinit).
  static Future<void> close() async {
    if (_box != null && _box!.isOpen) {
      await _box!.close();
      _box = null;
    }
  }
}

import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/utils/logger.dart';

/// Helper pour gérer un cache simple en mémoire
class CacheHelper {
  static final Map<String, _CacheEntry> _cache = {};

  /// Récupère une valeur du cache si elle existe et n'est pas expirée
  static T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) {
      AppLogger.debug('Cache miss: $key', tag: 'CACHE');
      return null;
    }

    if (entry.isExpired) {
      AppLogger.debug('Cache expired: $key', tag: 'CACHE');
      _cache.remove(key);
      return null;
    }

    AppLogger.debug('Cache hit: $key', tag: 'CACHE');
    return entry.value as T?;
  }

  /// Stocke une valeur dans le cache.
  /// [duration] : null = 5 min (listes/compteurs), utiliser AppConfig.mediumCacheDuration (15 min)
  /// pour employés/fournisseurs, AppConfig.longCacheDuration (1 h) pour référentiels.
  static void set<T>(String key, T value, {Duration? duration}) {
    final cacheDuration = duration ?? AppConfig.defaultCacheDuration;
    _cache[key] = _CacheEntry(
      value: value,
      expiresAt: DateTime.now().add(cacheDuration),
    );
    AppLogger.debug(
      'Cache set: $key (expires in ${cacheDuration.inSeconds}s)',
      tag: 'CACHE',
    );
  }

  /// Supprime une clé du cache
  static void remove(String key) {
    _cache.remove(key);
    AppLogger.debug('Cache removed: $key', tag: 'CACHE');
  }

  /// Vide tout le cache
  static void clear() {
    final count = _cache.length;
    _cache.clear();
    AppLogger.info('Cache cleared: $count entries removed', tag: 'CACHE');
  }

  /// Vérifie si une clé existe dans le cache et n'est pas expirée
  static bool has(String key) {
    final entry = _cache[key];
    if (entry == null) return false;
    if (entry.isExpired) {
      _cache.remove(key);
      return false;
    }
    return true;
  }

  /// Nettoie les entrées expirées
  static void cleanExpired() {
    final expiredKeys =
        _cache.entries
            .where((entry) => entry.value.isExpired)
            .map((entry) => entry.key)
            .toList();

    for (final key in expiredKeys) {
      _cache.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      AppLogger.debug(
        'Cleaned ${expiredKeys.length} expired cache entries',
        tag: 'CACHE',
      );
    }
  }

  /// Retourne le nombre d'entrées dans le cache
  static int get size => _cache.length;

  /// Supprime toutes les clés qui commencent par un préfixe
  static void clearByPrefix(String prefix) {
    final keysToRemove =
        _cache.keys.where((key) => key.startsWith(prefix)).toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
    if (keysToRemove.isNotEmpty) {
      AppLogger.debug(
        'Cache cleared by prefix "$prefix": ${keysToRemove.length} entries removed',
        tag: 'CACHE',
      );
    }
  }
}

/// Entrée de cache avec expiration
class _CacheEntry {
  final dynamic value;
  final DateTime expiresAt;

  _CacheEntry({required this.value, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

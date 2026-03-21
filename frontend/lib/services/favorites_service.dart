import 'package:get_storage/get_storage.dart';

class FavoritesService {
  static final FavoritesService _instance = FavoritesService._();
  static FavoritesService get to => _instance;
  factory FavoritesService() => _instance;
  FavoritesService._() {
    _loadFavorites();
  }

  final _storage = GetStorage();
  final List<String> favorites = [];
  static const _storageKey = 'favorites';

  void _loadFavorites() {
    final storedFavorites = _storage.read<List?>(_storageKey);
    if (storedFavorites != null) {
      favorites.clear();
      favorites.addAll(List<String>.from(storedFavorites));
    }
  }

  void _saveFavorites() {
    _storage.write(_storageKey, favorites.toList());
  }

  void toggleFavorite(String routeId) {
    if (isFavorite(routeId)) {
      favorites.remove(routeId);
    } else {
      favorites.add(routeId);
    }
    _saveFavorites();
  }

  bool isFavorite(String routeId) {
    return favorites.contains(routeId);
  }
}

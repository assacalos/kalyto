import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';

/// État des favoris (IDs des routes/entités).
class FavoritesState {
  final List<String> ids;

  const FavoritesState({this.ids = const []});

  bool isFavorite(String id) => ids.contains(id);

  FavoritesState copyWith({List<String>? ids}) {
    return FavoritesState(ids: ids ?? this.ids);
  }
}

final _storage = GetStorage();
const _storageKey = 'favorites';

final favoritesProvider =
    NotifierProvider<FavoritesNotifier, FavoritesState>(FavoritesNotifier.new);

class FavoritesNotifier extends Notifier<FavoritesState> {
  @override
  FavoritesState build() {
    final stored = _storage.read<List?>(_storageKey);
    final ids = stored != null ? List<String>.from(stored) : <String>[];
    return FavoritesState(ids: ids);
  }

  void toggleFavorite(String id) {
    final list = List<String>.from(state.ids);
    if (list.contains(id)) {
      list.remove(id);
    } else {
      list.add(id);
    }
    _storage.write(_storageKey, list);
    state = state.copyWith(ids: list);
  }

  bool isFavorite(String id) => state.ids.contains(id);
}

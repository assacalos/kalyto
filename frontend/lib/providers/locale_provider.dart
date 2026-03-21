import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';

const String _kAppLocaleKey = 'app_locale';
const String _kDefaultLocale = 'fr';

/// Locale persistée (GetStorage) et exposée via Riverpod.
/// Français par défaut si aucune valeur sauvegardée.
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(_localeFromCode(GetStorage().read<String>(_kAppLocaleKey) ?? _kDefaultLocale));

  static Locale _localeFromCode(String code) {
    switch (code) {
      case 'en':
        return const Locale('en');
      case 'fr':
      default:
        return const Locale('fr');
    }
  }

  static String _codeFromLocale(Locale locale) {
    if (locale.languageCode == 'en') return 'en';
    return 'fr';
  }

  /// Change la locale et persiste dans GetStorage.
  void setLocale(Locale locale) {
    state = locale;
    GetStorage().write(_kAppLocaleKey, _codeFromLocale(locale));
  }

  /// Récupère le code langue sauvegardé (pour affichage dans les paramètres).
  static String getSavedLocaleCode() {
    return GetStorage().read<String>(_kAppLocaleKey) ?? _kDefaultLocale;
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

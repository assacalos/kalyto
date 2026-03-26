# Politique d’analyse statique (Dart / Flutter)

## Fichier principal

`analysis_options.yaml` à la racine du package `frontend/` inclut `package:flutter_lints/flutter.yaml` et active **quelques règles supplémentaires** sans tout durcir d’un coup.

## Règles actives « en douceur »

| Règle | Intérêt |
|--------|--------|
| `annotate_overrides` | `@override` explicite sur les membres qui masquent la classe parente. |
| `curly_braces_in_flow_control_structures` | Accolades sur `if` / `else` pour éviter les bugs de portée. |
| `unnecessary_import` | Supprime les imports redondants (ex. `dart:ui` si `material.dart` suffit). |
| `unnecessary_string_interpolations` | `'${x}'` → `x` quand c’est équivalent. |
| `prefer_final_fields` | Champs jamais réassignés → `final`. |
| `prefer_conditional_assignment` | `a ??= b` au lieu de `if (a == null) a = b`. |
| `unnecessary_this` | Évite `this.` inutile quand le contexte suffit. |

Ces règles complètent `flutter_lints` sans imposer une migration massive immédiate.

## Roadmap (plus tard)

- **`avoid_print`** : après remplacement progressif par `AppLogger` / `debugPrint`.
- **`deprecated_member_use`** : migration API Flutter (ex. `Color.withOpacity` → `withValues(alpha: …)`).
- **`use_build_context_synchronously`** : sécuriser les `BuildContext` après `async`.
- **`file_names`** : noms de fichiers en `snake_case`.
- **`strict-casts` / `strict-inference`** : optionnel, quand le projet est plus propre.

## Commandes

```bash
cd frontend
dart analyze lib
# ou
flutter analyze
```

# easyconnect (Flutter)

Application mobile / web **Kalyto / Easyconnect**.

## Architecture

- **État** : [Riverpod](https://riverpod.dev) (`Notifier` / `Provider`).
- **Navigation** : [go_router](https://pub.dev/packages/go_router) ; le rafraîchissement des redirections auth passe par `authRefreshNotifier` (`lib/providers/auth_notifier.dart`).
- **Stockage** : `get_storage`, `flutter_secure_storage`, `shared_preferences` selon les cas.
- **Validation** : un seul [`ValidationHelper`](lib/utils/validation_helper.dart) (validateurs de champs + journaux / états vides / snackbars).
- **Pas de GetX** : l’ancien dossier `Controllers/` et les bindings ont été retirés ; la logique métier est dans les services + notifiers.
- **API** : toutes les requêtes métier passent par [`HttpInterceptor`](lib/services/http_interceptor.dart) + [`ApiService.headers`](lib/services/api_service.dart) (refresh token sur 401). Construire les URLs avec [`HttpInterceptor.apiUri`](lib/services/http_interceptor.dart) (segment relatif à [`AppConfig.baseUrl`](lib/utils/app_config.dart)) — y compris les services `*_dashboard_service` (éviter `constant.baseUrl` et un `/api` en double). Éviter `package:http` direct dans les services (sauf `api_service`, `session_service` refresh, et uploads multipart dans `attendance_punch_service` / `company_service`). [`CustomHttpClient`](lib/services/http_client.dart) délègue à l’intercepteur.

## Commandes utiles

```bash
flutter pub get
dart analyze
flutter run
# Tests (auth + LoginPage) :
flutter test test/auth_critical_test.dart
```

## Qualité / lints

La configuration de l’analyseur et la feuille de route des règles (activation « en douceur ») sont décrites dans **[`docs/ANALYSIS.md`](docs/ANALYSIS.md)** (`analysis_options.yaml` à la racine du package).

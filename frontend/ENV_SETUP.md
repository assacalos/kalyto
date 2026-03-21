# Variables d’environnement (build Flutter)

Les secrets ne doivent pas être commités en dur. Utiliser `--dart-define` au build ou au run.

| Variable | Rôle |
|----------|------|
| `PRODUCTION_URL` | URL de l’API en production (ex. `https://votredomaine.com/api`) |
| `PUSHER_APP_KEY` | Clé Pusher (temps réel / WebSocket) — **obligatoire** si vous utilisez le temps réel |
| `PUSHER_APP_CLUSTER` | Cluster Pusher (ex. `eu`) |
| `FIREBASE_WEB_VAPID_KEY` | Clé VAPID pour les notifications push web |

**Exemple (PowerShell, une ligne) :**

```powershell
flutter run -d chrome --dart-define=PUSHER_APP_KEY=votre_cle --dart-define=PUSHER_APP_CLUSTER=eu
```

**Build web :**

```powershell
flutter build web --release --dart-define=PRODUCTION_URL=https://.../api --dart-define=PUSHER_APP_KEY=... --dart-define=PUSHER_APP_CLUSTER=eu
```

Sans `PUSHER_APP_KEY`, le WebSocket reste désactivé (`websocketEnabled` est faux).

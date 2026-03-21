# Configuration Firebase Cloud Messaging (FCM) pour le web

Pour recevoir les notifications push dans le navigateur, suivez ces étapes.

## 1. Firebase Console

### 1.1 Application web (si pas déjà fait)

1. Ouvrez [Firebase Console](https://console.firebase.google.com/) → votre projet **easyconnect-aleb**.
2. **Paramètres du projet** (icône engrenage) → section **Vos applications**.
3. Si une application **Web** n’existe pas, cliquez sur **</>** (Ajouter une application web).
4. Donnez un surnom (ex. « EasyConnect Web »), cochez **Configurer Firebase Hosting** si besoin, puis **Enregistrer l’application**.
5. Notez l’objet `firebaseConfig`, en particulier **`appId`** (ex. `1:17317714210:web:xxxxxxxxxx`). Vous en aurez besoin dans `web/index.html` et `web/firebase-messaging-sw.js`.

### 1.2 Clé VAPID (Web Push)

1. Dans **Paramètres du projet** → onglet **Cloud Messaging**.
2. Descendez jusqu’à **Certificats Web Push** (ou **Web configuration**).
3. Cliquez sur **Générer une paire de clés** (ou utilisez une paire existante).
4. Copiez la **Clé** (chaîne longue commençant souvent par `B...`) — c’est votre **clé VAPID publique**.

Cette clé est nécessaire côté Flutter pour obtenir un token FCM sur le web.

### 1.3 API FCM (si erreur côté Google)

Si vous voyez une erreur du type « FCM Registration API has not been used », activez l’API :

1. [Google Cloud Console](https://console.cloud.google.com/) → projet lié à Firebase.
2. **APIs & Services** → **Enabled APIs** → cherchez **Firebase Cloud Messaging API** et activez-la.

---

## 2. Fichiers du projet

### 2.1 `web/index.html`

- Remplacez **`YOUR_WEB_APP_ID`** par le vrai **appId** de votre application web Firebase (étape 1.1).
- La configuration doit correspondre à celle de la console (apiKey, authDomain, projectId, storageBucket, messagingSenderId, appId).

Exemple :

```html
const firebaseConfig = {
  apiKey: "AIzaSy...",
  authDomain: "easyconnect-aleb.firebaseapp.com",
  projectId: "easyconnect-aleb",
  storageBucket: "easyconnect-aleb.firebasestorage.app",
  messagingSenderId: "17317714210",
  appId: "1:17317714210:web:xxxxxxxxxx"   // ← Remplacer par votre Web App ID
};
```

### 2.2 `web/firebase-messaging-sw.js`

- Remplacez **`YOUR_WEB_APP_ID`** par le **même appId** que dans `index.html`.
- Le service worker doit utiliser exactement la même config Firebase que la page.

### 2.3 Clé VAPID dans l’app Flutter

La clé VAPID doit être fournie à `getToken()` sur le web. Deux possibilités :

**Option A – Variable de compilation (recommandé pour la prod)**

```bash
flutter build web --dart-define=FIREBASE_WEB_VAPID_KEY=VOTRE_CLE_VAPID_ICI
```

**Option B – Défaut dans le code**

Dans `lib/utils/app_config.dart`, vous pouvez remplacer le `defaultValue: ''` par votre clé (éviter de commiter des secrets en clair ; préférer un fichier non versionné ou des variables d’environnement).

Après configuration, au lancement sur le web, le service demandera la permission de notification, obtiendra un token FCM et l’enverra au backend comme sur mobile.

---

## 3. Contraintes techniques

- **HTTPS** : les Service Workers et les push web ne fonctionnent qu’en **HTTPS** (ou `localhost` en dev).
- **Origine** : le domaine qui sert l’app (ex. `https://votredomaine.com`) doit être autorisé dans Firebase (**Authentication** → **Paramètres** → **Domaines autorisés** si vous utilisez l’auth ; pour FCM seul, pas d’étape supplémentaire).
- **Navigateur** : les push sont supportés sur Chrome, Firefox, Edge, Safari (support variable). Le navigateur doit demander la permission « Notifications ».

---

## 4. Vérification rapide

1. Remplir `appId` dans `web/index.html` et `web/firebase-messaging-sw.js`.
2. Configurer la clé VAPID (build ou `app_config.dart`).
3. Lancer `flutter run -d chrome` (ou servir le build web en HTTPS).
4. Se connecter à l’app, accepter les notifications si demandé.
5. Dans les logs (console navigateur / Dart), vous devez voir un message du type « Token FCM obtenu » et éventuellement « Token FCM enregistré avec succès » après envoi au backend.

Si le token n’apparaît pas : vérifier la clé VAPID, l’appId, que l’API FCM est activée et que vous êtes bien en HTTPS (ou localhost).

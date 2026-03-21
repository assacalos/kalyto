# Déploiement Kalyto sur cPanel (test à distance dans un navigateur)

Ce guide permet de déployer le **backend Laravel** et le **frontend Flutter Web** sur un hébergement cPanel, avec **notifications** (Pusher + optionnel FCM pour push navigateur).

---

## Vue d’ensemble

- **Option A – Un seul domaine**  
  Tout sur `https://votredomaine.com` : l’app Flutter (SPA) et l’API Laravel (`/api`, `/sanctum`, `/broadcasting`) sont servis depuis la même racine (dossier `public` Laravel). Idéal pour un test rapide.

- **Option B – Deux sous-domaines**  
  `https://app.votredomaine.com` = Flutter (fichiers statiques), `https://api.votredomaine.com` = Laravel. Plus propre pour la prod.

On décrit les deux. Les notifications (Pusher + FCM) sont les mêmes.

---

## Partie 1 – Backend Laravel sur cPanel

### 1.1 Prérequis

- PHP 8.1+ (avec extensions : curl, mbstring, openssl, pdo_mysql, tokenizer, xml, ctype, json, bcmath)
- MySQL/MariaDB
- Composer (en SSH ou via “PHP Composer” dans cPanel si disponible)
- Accès SSH ou Gestionnaire de fichiers + Terminal en ligne

### 1.2 Structure des dossiers (Option A – un seul domaine)

Sur le serveur, par exemple :

- `~/kalyto-backend/` = racine du projet Laravel (dossier contenant `app/`, `config/`, `public/`, etc.)
- La **racine web (Document Root)** doit pointer vers **`~/kalyto-backend/public`**.

Dans cPanel :

- **Domaines** → le domaine (ou sous-domaine) → **Document Root** : `kalyto-backend/public` (ou le chemin complet vers `public`).

### 1.3 Upload du backend

1. En local, dans le dossier du backend :
   ```bash
   composer install --no-dev --optimize-autoloader
   ```
2. Uploader tout le projet Laravel (y compris `vendor/`) dans `~/kalyto-backend/` **sans** mettre le fichier `.env` (on le crée sur le serveur).
3. Ne pas uploader : `node_modules/`, `.git/`, `storage/logs/*`, `.env` (s’il contient des secrets).

### 1.4 Fichier `.env` sur le serveur

Créer ou éditer `.env` dans `~/kalyto-backend/` (à la racine Laravel, pas dans `public/`) :

```env
APP_NAME=Kalyto
APP_ENV=production
APP_KEY=base64:XXXX   # générer avec: php artisan key:generate
APP_DEBUG=false
APP_URL=https://votredomaine.com

DB_CONNECTION=mysql
DB_HOST=localhost
DB_PORT=3306
DB_DATABASE=xxx
DB_USERNAME=xxx
DB_PASSWORD=xxx

# CORS : autoriser l’origine de l’app (Option A = même domaine, Option B = https://app.votredomaine.com)
CORS_ALLOWED_ORIGINS=https://votredomaine.com
# Ou si sous-domaine app : CORS_ALLOWED_ORIGINS=https://app.votredomaine.com

# Notifications temps réel (Pusher)
BROADCAST_DRIVER=pusher
PUSHER_APP_ID=xxx
PUSHER_APP_KEY=xxx
PUSHER_APP_SECRET=xxx
PUSHER_APP_CLUSTER=eu

# Optionnel : push navigateur (FCM)
# FCM_SERVER_KEY=
# FCM_SERVICE_ACCOUNT_JSON=storage/app/firebase/service-account.json
```

- Créer la base MySQL dans cPanel (MySQL® Databases), puis créer un utilisateur et l’associer à cette base. Utiliser ces identifiants dans `DB_*`.
- Pour **Pusher** : créer une app sur [pusher.com](https://pusher.com) (gratuit), récupérer App ID, Key, Secret, Cluster et les mettre dans `.env`. Les mêmes valeurs serviront pour le build Flutter (voir plus bas).

### 1.5 Commandes Laravel (en SSH ou Terminal cPanel)

Depuis `~/kalyto-backend/` :

```bash
php artisan key:generate
php artisan storage:link
php artisan config:cache
php artisan route:cache
php artisan migrate --force
php artisan db:seed --force
```

- `storage:link` : crée le lien symbolique `public/storage` → `storage/app/public` (pour fichiers uploadés).
- Si la base est vide, `migrate` + `db:seed` créent les tables et les données de démo.

### 1.6 Option B – API sur un sous-domaine

- Créer un sous-domaine (ex. `api.votredomaine.com`) dans cPanel.
- Définir la **Document Root** de ce sous-domaine sur `~/kalyto-backend/public` (ou un dossier dédié qui contient le contenu de `public`).
- Dans `.env` : `APP_URL=https://api.votredomaine.com`.
- CORS : `CORS_ALLOWED_ORIGINS=https://app.votredomaine.com` (URL exacte de l’app Flutter).

---

## Partie 2 – Frontend Flutter Web

### 2.1 Build avec l’URL de ton API

En local, dans le dossier **frontend** :

**Option A (tout sur un domaine)**  
L’API est à `https://votredomaine.com/api` :

```bash
cd frontend
flutter pub get
flutter build web --release \
  --dart-define=PRODUCTION_URL=https://votredomaine.com/api \
  --dart-define=PUSHER_APP_KEY=TA_CLE_PUSHER \
  --dart-define=PUSHER_APP_CLUSTER=eu
```

**Option B (sous-domaine API)**  
L’API est à `https://api.votredomaine.com/api` :

```bash
flutter build web --release \
  --dart-define=PRODUCTION_URL=https://api.votredomaine.com/api \
  --dart-define=PUSHER_APP_KEY=TA_CLE_PUSHER \
  --dart-define=PUSHER_APP_CLUSTER=eu
```

Les fichiers générés sont dans **`build/web/`** (index.html, main.dart.js, assets/, etc.).

### 2.2 Où mettre les fichiers Flutter sur cPanel

**Option A – Un seul domaine**  
- La racine web est déjà `~/kalyto-backend/public`.
- Copier **tout le contenu** de `build/web/` **dans** `public/` (à côté de `index.php` et du `.htaccess` existant).
- Ne pas écraser `index.php` ni `.htaccess` : le `.htaccess` actuel envoie déjà `/api` vers Laravel et le reste vers `index.html` (Flutter). Donc il suffit que `index.html` et les assets Flutter soient dans le même dossier que `index.php`.

**Option B – Sous-domaine app**  
- Créer un sous-domaine `app.votredomaine.com` dont la Document Root pointe vers un dossier dédié (ex. `~/kalyto-app/`).
- Y copier **tout** le contenu de `build/web/` (index.html, main.dart.js, etc.). Pas besoin de PHP ni de Laravel dans ce dossier.

### 2.3 Si tu ne veux pas recompiler pour changer l’URL

L’app permet de définir l’URL de l’API dans **Paramètres**. Après la première ouverture, l’utilisateur peut aller dans Paramètres et saisir l’URL de l’API (ex. `https://api.votredomaine.com/api`). Elle est enregistrée localement. Dans ce cas, tu peux build sans `--dart-define=PRODUCTION_URL=...`.

---

## Partie 3 – Notifications (temps réel + push navigateur)

**Tu n’as pas besoin de créer une nouvelle application.**

- **Pusher** : service séparé (pusher.com). Si tu as déjà une app Pusher (ex. celle dont la clé est dans le code), **réutilise-la** : mêmes identifiants dans le `.env` du serveur et dans le build Flutter. Sinon, crée **une seule** app sur [Pusher](https://dashboard.pusher.com) et utilise-la pour ce déploiement.
- **FCM (Firebase)** : FCM fait partie de ton **projet Firebase existant** (celui déjà utilisé pour l’app mobile). **Pas de nouveau projet Firebase** : utilise le même. Active Cloud Messaging si besoin, ajoute une « app Web » dans ce projet si tu veux le push navigateur, et utilise le même fichier « Compte de service » (JSON) pour le backend Laravel.

### 3.1 Notifications temps réel (Pusher / Laravel Echo)

- Déjà utilisé dans l’app pour les notifications en direct (badge, liste, etc.).
- **Backend** : dans `.env`, remplir `BROADCAST_DRIVER=pusher` et les variables `PUSHER_*` avec les valeurs de ton app [Pusher](https://pusher.com) (celle existante ou la seule que tu crées).
- **Frontend** : compiler avec les mêmes `PUSHER_APP_KEY` et `PUSHER_APP_CLUSTER` (voir commandes `flutter build web` ci-dessus). Ainsi, en ouvrant l’app dans le navigateur, les notifications temps réel fonctionnent sans configuration supplémentaire.

Aucune installation côté cPanel : Pusher est un service hébergé.

### 3.2 Push navigateur (FCM – optionnel)

Pour recevoir des **notifications push** même quand l’onglet est en arrière-plan :

1. **Firebase (même projet que l’app mobile)**  
   - Dans ton **projet Firebase existant** : activer **Cloud Messaging** si ce n’est pas déjà fait.  
   - Pour envoyer les push depuis Laravel : Paramètres du projet → « Comptes de service » → Générer une clé JSON (ou utiliser celle que tu as déjà).  
   - Téléverser ce fichier sur le serveur dans `~/kalyto-backend/storage/app/firebase/service-account.json` (créer le dossier si besoin).  
   - Dans `.env` :  
     `FCM_SERVICE_ACCOUNT_JSON=storage/app/firebase/service-account.json`

2. **Frontend Web**  
   - Dans le **même** projet Firebase, ajouter une « app Web » si tu n’en as pas encore (pour le push navigateur). Récupérer la config (apiKey, projectId, etc.) et l’intégrer dans le projet Flutter (déjà fait si ton Flutter est déjà configuré pour Firebase).  
   - Les notifications push web nécessitent HTTPS et l’autorisation de l’utilisateur dans le navigateur.

Si tu ne configures pas FCM, l’app fonctionne quand même : seules les notifications **push** navigateur seront absentes ; les notifications **temps réel** (Pusher) dans l’app restent actives.

### 3.3 Files de tâches (queue) – optionnel

Si des jobs Laravel (ex. envoi d’e-mails ou de notifications différées) sont utilisés, deux possibilités :

- **Sans worker** : dans `.env`, mettre `QUEUE_CONNECTION=sync`. Les jobs s’exécutent pendant la requête (pas de cron ni worker).
- **Avec worker** : `QUEUE_CONNECTION=database`, puis créer les tables avec `php artisan queue:table` et `php artisan migrate`, et lancer un worker (SSH) ou une cron cPanel qui exécute régulièrement `php artisan queue:work --stop-when-empty`.

Pour un premier test, `sync` suffit.

---

## Partie 4 – Vérifications rapides

1. **API**  
   - Ouvrir dans le navigateur : `https://votredomaine.com/api/` (ou `https://api.votredomaine.com/api/`).  
   - Tu dois avoir une réponse JSON (ou une erreur Laravel type 404), pas une page HTML. Si tu vois du HTML, la racine web pointe peut-être au mauvais endroit.

2. **App**  
   - Ouvrir `https://votredomaine.com` (ou `https://app.votredomaine.com`).  
   - Écran de connexion Kalyto. Se connecter avec un compte démo (ex. `commercial@kalyto-demo.com` / `demo123`).

3. **CORS**  
   - Si la connexion échoue avec une erreur “CORS” ou “blocked by CORS” dans la console (F12), vérifier `CORS_ALLOWED_ORIGINS` dans `.env` : doit contenir exactement l’URL d’origine de l’app (sans slash final), par ex. `https://app.votredomaine.com`.

4. **Notifications**  
   - Une fois connecté, déclencher une action qui envoie une notification (ex. validation d’un document). Vérifier que le badge ou la liste des notifications se met à jour sans recharger la page (Pusher).

---

## Récap des URLs à adapter

| Où | Variable / Endroit | Exemple |
|----|--------------------|--------|
| .env | APP_URL | https://votredomaine.com ou https://api.votredomaine.com |
| .env | CORS_ALLOWED_ORIGINS | https://votredomaine.com ou https://app.votredomaine.com |
| .env | PUSHER_* | Valeurs de ton app Pusher |
| Build Flutter | PRODUCTION_URL | https://votredomaine.com/api ou https://api.votredomaine.com/api |
| Build Flutter | PUSHER_APP_KEY, PUSHER_APP_CLUSTER | Mêmes que .env |

Une fois tout en place, le test à distance dans un navigateur fonctionne, avec les notifications temps réel (Pusher) ; les push navigateur (FCM) sont optionnelles et peuvent être ajoutées ensuite.

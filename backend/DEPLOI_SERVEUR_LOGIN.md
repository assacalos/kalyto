# Erreur 500 au login sur le serveur – Vérifications

Quand l’application affiche « Le serveur rencontre un problème » ou « Erreur interne du serveur » au login, la cause est **côté Laravel** sur le serveur. Voici quoi vérifier.

## 1. Consulter les logs Laravel

Sur le serveur :

```bash
cd /chemin/vers/eeasyconnect_backend
tail -100 storage/logs/laravel.log
```

Ou pour suivre en direct pendant une tentative de connexion :

```bash
tail -f storage/logs/laravel.log
```

La section `Erreur API - Login` indique le message d’erreur exact, le fichier et la ligne.

## 2. Afficher l’erreur dans l’app (temporaire)

Dans le fichier **`.env`** sur le serveur, mettez :

```env
APP_DEBUG=true
```

Puis videz la config :

```bash
php artisan config:clear
```

Refaites une tentative de connexion : l’API renverra le message d’erreur réel (ex. « table doesn’t exist », « Class not found ») et l’app Flutter l’affichera.

**Important :** remettez `APP_DEBUG=false` en production après le diagnostic.

## 3. Causes fréquentes

| Cause | Solution |
|-------|----------|
| **Table `personal_access_tokens` manquante** (Sanctum) | `php artisan migrate` |
| **Connexion BDD** (mauvais `.env`, DB non démarrée) | Vérifier `DB_HOST`, `DB_DATABASE`, `DB_USERNAME`, `DB_PASSWORD` et l’accès MySQL/MariaDB |
| **Clé APP_KEY manquante** | `php artisan key:generate` puis mettre la clé dans `.env` |
| **Droits d’écriture** | `storage/` et `bootstrap/cache/` en écriture pour le serveur web : `chmod -R 775 storage bootstrap/cache` |
| **Cache / session** (driver file, répertoire non writable) | Vérifier `storage/framework/cache`, `storage/framework/sessions` ; ou utiliser un autre driver (redis, database) si configuré |
| **Lien symbolique `storage`** (avatars, etc.) | `php artisan storage:link` |
| **Extension PHP manquante** (ex. pour BDD, JSON, OpenSSL) | Vérifier `php -m` et la config PHP du serveur |

## 4. Vérifications rapides

```bash
# Config et cache
php artisan config:clear
php artisan cache:clear

# Migrations à jour
php artisan migrate --force

# Lien storage (pour les fichiers publics)
php artisan storage:link
```

Après chaque modification du `.env` : `php artisan config:clear`.

En résumé : **consulter `storage/logs/laravel.log`** (et éventuellement activer `APP_DEBUG=true` temporairement) donne la cause exacte de l’erreur 500 au login.

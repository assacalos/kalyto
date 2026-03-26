# EasyConnect Backend API

API backend Laravel pour l'application EasyConnect.

## Prérequis

- PHP >= 8.1
- Composer
- MySQL/MariaDB ou SQLite
- Node.js et NPM (optionnel, pour les assets)

## Installation

1. Cloner le repository
```bash
git clone <repository-url>
cd eeasyconnect_backend
```

2. Installer les dépendances
```bash
composer install
```

3. Configurer l'environnement
```bash
cp .env.example .env
php artisan key:generate
```

4. Configurer la base de données dans `.env`
```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=your_database
DB_USERNAME=your_username
DB_PASSWORD=your_password
```

5. Exécuter les migrations
```bash
php artisan migrate
```

6. (Optionnel) Créer un utilisateur administrateur
```bash
php artisan db:seed --class=AdminSeeder
```

## Démarrage

Démarrer le serveur de développement :
```bash
php artisan serve
```

Pour permettre l'accès depuis d'autres appareils (nécessaire pour les applications mobiles) :
```bash
php artisan serve --host=0.0.0.0 --port=8000
```

L'API sera accessible à : `http://localhost:8000/api`

## Authentification

L'API utilise Laravel Sanctum pour l'authentification par tokens.

### Connexion
```http
POST /api/login
Content-Type: application/json

{
    "email": "user@example.com",
    "password": "password"
}
```

### Utilisation du token
Inclure le token dans les requêtes authentifiées :
```http
Authorization: Bearer {token}
```

## Structure de l'API

### Routes publiques
- `POST /api/login` - Connexion

### Routes authentifiées
Toutes les autres routes nécessitent un token d'authentification.

## Rôles utilisateurs

- 1 : Admin
- 2 : Commercial
- 3 : Comptable
- 4 : RH
- 5 : Technicien
- 6 : Patron

## Configuration CORS

La configuration CORS est optimisée pour les applications mobiles Flutter. Par défaut, toutes les origines sont autorisées (`*`).

Pour la production, configurez dans `.env` :
```env
CORS_ALLOWED_ORIGINS=https://app.example.com
CORS_SUPPORTS_CREDENTIALS=false
```

## Commandes utiles

```bash
# Vider le cache
php artisan config:clear
php artisan cache:clear
php artisan route:clear

# Vérifier les routes
php artisan route:list

# Exécuter les migrations
php artisan migrate

# Créer un utilisateur admin
php artisan db:seed --class=AdminSeeder
```

## Rôles et permissions (évolution)

Voir **[docs/ROLES_ET_PERMISSIONS.md](docs/ROLES_ET_PERMISSIONS.md)** : stratégie **incrémentale** (enum `App\Enums\AppRole` + colonne `users.role` actuelle), et quand envisager **spatie/laravel-permission**.

## Autorisation (ressources sensibles)

Pour les **devis** et **factures**, l’API applique :

- **Policies** (`App\Policies\DevisPolicy`, `FacturePolicy`) : règles métier (société, rôle commercial vs comptable/patron, validation patron, etc.) via `$this->authorize(...)` dans les contrôleurs.
- **Form Requests** — devis : `StoreDevisRequest`, `UpdateDevisRequest`, `RejectDevisRequest` — factures : `StoreFactureRequest`, `UpdateFactureRequest`, `ValidateFactureRequest`, `RejectFactureRequest` (validation + `authorize()` côté serveur).
- **Réponses JSON** : les détails exposés passent par `DevisResource` / `FactureResource` (éviter de renvoyer des modèles bruts dans les nouvelles réponses).

Les **middlewares `role:`** sur les routes restent un premier filtre ; les policies garantissent la cohérence même si une route est mal configurée.

## Technologies utilisées

- Laravel 10+
- Laravel Sanctum (Authentification)
- MySQL/SQLite (Base de données)

## Licence

Propriétaire



# Rôles et permissions — proposition d’évolution (Kalyto / EasyConnect)

## État actuel (système existant)

| Aspect | Détail |
|--------|--------|
| **Stockage** | Colonne entière `users.role` (1–6) |
| **Contrôle d’accès HTTP** | Middleware `role:1,2,3,…` (`App\Http\Middleware\RoleMiddleware`) |
| **Contrôle métier** | Méthodes `User::isAdmin()`, `isCommercial()`, etc. + **Policies** récentes (ex. `DevisPolicy`, `FacturePolicy`) |
| **API / Flutter** | Le client envoie le token ; le rôle est dérivé côté serveur — **cohérent pour une app métier** |

### Points solides

- Un seul entier par utilisateur → simple à indexer et à exposer (`UserResource`).
- Les routes sensibles sont déjà groupées par rôle ; les policies renforcent l’autorisation **hors** simple liste de routes.
- Pas de dépendance externe pour les rôles « métier » alignés sur l’app (commercial, comptable, RH, technicien, patron, admin).

### Limites

- **Nombres magiques** (`2`, `3`, …) dispersés dans contrôleurs et policies → risque d’erreur et refactors pénibles.
- **Pas de permissions nommées** du type `factures.validate` : tout est « rôle + policy » ; pour des règles très fines (ex. comptable junior vs senior), il faudrait dupliquer la logique.
- ~~Le middleware `RoleMiddleware` contournait les restrictions en acceptant tout admin/patron~~ — **corrigé** : accès strict à la liste de rôles déclarée sur la route (inclure explicitement `1` ou `6` si besoin).

---

## Alignement avec l’application (référence)

| ID | Rôle (app) | Slug proposé |
|----|------------|----------------|
| 1 | Administrateur | `admin` |
| 2 | Commercial | `commercial` |
| 3 | Comptable | `comptable` |
| 4 | RH | `rh` |
| 5 | Technicien | `technicien` |
| 6 | Patron | `patron` |

Ces valeurs sont figées dans `App\Enums\AppRole` (voir ci-dessous) pour éviter les constantes éparpillées.

---

## Piste A — Renforcer le système actuel (recommandé en **phase 1**, sans rien casser)

**Objectif :** une seule source de vérité pour les IDs + slugs + libellés, sans migration de schéma.

1. Utiliser **`App\Enums\AppRole`** (int-backed) dans le **nouveau code** (policies, services) à la place de `2`, `3`, etc.
2. Garder `users.role` et le middleware `role:…` **inchangés** pour les routes existantes.
3. Migrer **progressivement** les `if ($user->role == 2)` vers `$user->role === AppRole::Commercial->value` ou une méthode `User::hasAppRole(AppRole $role)`.
4. Optionnel : exposer `role_slug` dans l’API pour le front (en plus de `role` / `role_name`) une fois le front prêt.

**Avantage :** zéro migration BDD, zéro changement Flutter obligatoire, baisse forte du risque de régression.

---

## Piste B — Ajouter `spatie/laravel-permission` (recommandé en **phase 2**, si besoin de permissions fines)

**Quand l’envisager :**

- Besoin de **permissions granulaires** (`devis.reject`, `facture.mark_paid`, `users.impersonate`, …).
- Plusieurs **rôles métiers** qui se chevauchent ou des **rôles dynamiques** (ajout sans déployer du code).

**Principe incrémental (sans tout casser) :**

1. `composer require spatie/laravel-permission` (version compatible Laravel 10 / PHP 8.1).
2. Publier la config + migrations du package ; exécuter `php artisan migrate` (nouvelles tables `roles`, `permissions`, pivots — **sans toucher** à `users.role` au début).
3. **Seeder** : créer 6 rôles Spatie dont les **noms** = slugs (`commercial`, `comptable`, …) et mapper 1:1 avec `AppRole`.
4. **Synchronisation** (une fois par user ou en commande artisan) :
   - `syncRoles([AppRole::from($user->role)->slug()])`  
   - Ou observer sur `User` : à chaque changement de `users.role`, resynchroniser le rôle Spatie.
5. **Source de vérité pendant la transition :** garder **`users.role`** comme canon pour l’app mobile existante ; Spatie est une **couche additionnelle** pour `can()` / `@can` / middleware `permission:`.
6. **Routes :** ne pas remplacer d’un coup `role:1,3,6` par `permission:…`. Ajouter d’abord les `permission:` sur les **nouvelles** routes ou en **doublon** (middleware cumulés) puis déprécier progressivement.

**Risques à maîtriser :**

- Double vérité (`users.role` vs rôle Spatie) → **obligatoire** : un seul flux de mise à jour du rôle (service `UserRoleService::assign(User $user, AppRole $role)` qui met à jour les deux).
- Tests automatisés sur la synchro après chaque `users` update.

---

## Synthèse recommandée

| Phase | Action |
|-------|--------|
| **1 (maintenant)** | Introduire `App\Enums\AppRole` + usages progressifs ; **ne pas** installer Spatie tant que les permissions nommées ne sont pas un besoin clair. |
| **2 (plus tard)** | Spatie si granularité / audit / évolution des rôles le justifient ; migration **additive** avec synchro depuis `users.role`. |

---

## Fichiers ajoutés dans le dépôt

- `app/Enums/AppRole.php` — enum int-backed + labels FR + slugs.
- Ce document — `docs/ROLES_ET_PERMISSIONS.md`.

Aucune migration de base de données n’est requise pour la phase 1.

---

## Implémenté dans le code (phase 1)

- `App\Enums\AppRole` + `User::appRole()`, `hasAppRole()`, **`isAdminOrPatron()`**.
- Les méthodes `isAdmin()`, `isCommercial()`, etc. délèguent à **`hasAppRole(AppRole::…)`** (une seule source pour les IDs).
- **`RoleMiddleware`** : plus de bypass admin/patron implicite.
- **`UserResource`** : champ **`role_slug`** (ex. `commercial`, `comptable`) en complément de `role` / `role_name`.
- Contrôleurs : remplacement progressif des `role == N` par les helpers (`isCommercial()`, `isAdminOrPatron()`, …).

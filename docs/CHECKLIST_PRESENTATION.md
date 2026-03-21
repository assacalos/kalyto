# Checklist avant présentation Kalyto

## 1. Backend (Laravel)

- [ ] **MySQL/MariaDB** démarré
- [ ] **`.env`** configuré (DB_DATABASE, DB_USERNAME, DB_PASSWORD, APP_URL)
- [ ] **Migrations** à jour : `php artisan migrate --force`
- [ ] **Seeders** exécutés (données démo) : `php artisan db:seed --force`  
  - Ou tout effacer et re-seeder : `php artisan migrate:fresh --seed --force`
- [ ] **Serveur API** lancé : `php artisan serve` (ou pointant vers l’URL utilisée par l’app)
- [ ] **CORS** : si l’app tourne sur une autre origine (ex. émulateur, autre machine), vérifier `config/cors.php` et `APP_URL`

### Comptes démo (après seed)

| Rôle        | Email                     | Mot de passe |
|------------|----------------------------|--------------|
| Admin      | admin@kalyto-demo.com     | demo123      |
| Commercial | commercial@kalyto-demo.com| demo123      |
| Comptable  | comptable@kalyto-demo.com  | demo123      |
| Patron     | patron@kalyto-demo.com     | demo123      |
| RH         | rh@kalyto-demo.com         | demo123      |
| Technicien | technicien@kalyto-demo.com | demo123      |

---

## 2. Frontend (Flutter)

- [ ] **URL de l’API** : dans l’app, aller dans **Paramètres** et vérifier que l’URL pointe vers ton backend (ex. `http://10.0.2.2:8000/api` pour l’émulateur Android, `http://localhost:8000/api` pour web, ou l’URL de ton serveur).
- [ ] **Build** : `flutter pub get` puis `flutter run` (ou `flutter run -d chrome` pour le web).
- [ ] Pas d’erreur de compilation (les « info » du linter ne bloquent pas le build).

### Scénario de démo recommandé

1. **Écran de connexion** : se connecter avec **commercial@kalyto-demo.com** / **demo123**.
2. **Dashboard Commercial** : montrer les clients, devis, bordereaux (données seedées).
3. **Comptable** : se déconnecter, reconnecter avec **comptable@kalyto-demo.com** / **demo123** → Factures, Paiements, Journal, Balance.
4. **Patron** : **patron@kalyto-demo.com** → Validations, rapports.
5. **Admin** : **admin@kalyto-demo.com** → Paramètres, Gestion des rôles, Gestion des utilisateurs.
6. **Paramètres** : changer la langue (FR/EN), vérifier la société courante si multi-société.

---

## 3. Points de vigilance

- **Réseau** : téléphone et PC doivent joindre la même API (même réseau ou URL publique).
- **Certificat SSL** : en HTTPS, le serveur doit avoir un certificat valide (éviter les erreurs de certificat en démo).
- **Firebase** : si tu ne montres pas les notifications push, une erreur Firebase au démarrage peut être ignorée (l’app peut quand même tourner).
- **Données vides** : si une liste est vide, vérifier que les seeders ont bien été exécutés et que la **société courante** (paramètres) correspond à celle des données.

---

## 4. En cas de problème rapide

- **« Connexion refusée » / timeout** : vérifier l’URL API dans Paramètres et que le serveur Laravel tourne.
- **401 / Session expirée** : se déconnecter et se reconnecter.
- **Liste vide** : vérifier company_id des données et société sélectionnée dans Paramètres (ou lancer `php artisan db:seed --force`).
- **Crash au lancement** : lancer depuis un terminal avec `flutter run` pour voir les erreurs dans la console.

---

*Dernière mise à jour : avant présentation.*

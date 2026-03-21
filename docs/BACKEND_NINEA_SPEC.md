# Spécification backend – NINEA (conformité ivoirienne)

Le NINEA est le numéro d’identification ivoirien (9 chiffres). Il a été ajouté côté Flutter sur :
- **Entreprise / paramètres société** (écran Paramètres, section « Données société / Entreprise »)
- **Client** (modèle, formulaire, détail)
- **Fournisseur** (modèle, formulaire, détail)

Côté API Laravel, il faut exposer et persister ce champ comme suit.

---

## 1. Clients

- **Modèle** : `App\Models\Client`
- **Table** : `clients`
- **Attribut** : `ninea` (string, nullable, 9 caractères)

### À faire

1. **Migration**
   - Ajouter une colonne `ninea` :
     - `$table->string('ninea', 9)->nullable();`
   - Exemple : `php artisan make:migration add_ninea_to_clients_table --table=clients`

2. **Modèle** `Client.php`
   - Ajouter `'ninea'` dans `$fillable`.

3. **Resource** `ClientResource.php`
   - Dans `toArray()`, ajouter : `'ninea' => $this->ninea,`

4. **Validation** (dans le contrôleur qui crée/met à jour les clients)
   - Règle pour `ninea` : `'nullable|string|size:9|regex:/^\d{9}$/'`  
     (optionnel ; si renseigné : exactement 9 chiffres)

5. **Routes**
   - Aucune nouvelle route. Les routes existantes de type :
     - `POST /api/clients` (création)
     - `PUT/PATCH /api/clients/{id}` (mise à jour)
     - `GET /api/clients-list` (liste avec pagination)
     - `GET /api/clients/{id}` (détail si vous en avez une)
     doivent accepter et renvoyer le champ `ninea` dans le JSON.

6. **Recherche** (optionnel)
   - Dans la recherche clients (ex. `ClientController@index`), inclure `ninea` dans la clause de recherche si vous avez un filtre par texte (ex. `orWhere('ninea', 'like', '%' . $search . '%')`).

---

## 2. Fournisseurs (Suppliers)

- **Modèle** : `App\Models\Fournisseur`
- **Table** : `fournisseurs` (ou nom de table utilisé par le modèle)
- **Attribut** : `ninea` (string, nullable, 9 caractères)

### À faire

1. **Migration**
   - Ajouter une colonne `ninea` :
     - `$table->string('ninea', 9)->nullable();`

2. **Modèle** `Fournisseur.php`
   - Ajouter `'ninea'` dans `$fillable`.

3. **Resource** `SupplierResource.php`
   - Dans `toArray()`, ajouter : `'ninea' => $this->ninea,`

4. **Validation** (dans `FournisseurController` : `store` et `update`)
   - Règle pour `ninea` : `'nullable|string|size:9|regex:/^\d{9}$/'`

5. **Routes**
   - Aucune nouvelle route. Les routes existantes pour les fournisseurs doivent accepter et renvoyer `ninea` (création, mise à jour, liste, détail).

---

## 3. Entreprise / paramètres société (optionnel)

Actuellement, le NINEA entreprise est stocké **uniquement en local** dans l’app Flutter (GetStorage, clé `company_ninea`). Aucun appel API n’est utilisé.

Si vous souhaitez le centraliser côté serveur :

- **Option A – Table / modèle dédiés**
  - Créer une table `entreprise` ou `company_settings` avec au moins :
    - `id`, `ninea` (string, 9, nullable), `updated_at`, etc.
  - Exposer par exemple :
    - `GET /api/entreprise` ou `GET /api/settings/company`
    - `PUT /api/entreprise` ou `PUT /api/settings/company`
  - Corps attendu (ex.) : `{ "ninea": "123456789" }` (optionnel, 9 chiffres si présent).

- **Option B – Table `settings` clé/valeur**
  - Une entrée avec une clé du type `company_ninea` et la valeur (9 chiffres).

Une fois l’API en place, l’app Flutter pourra être adaptée pour lire/écrire le NINEA entreprise via ces endpoints au lieu de GetStorage.

---

## Récapitulatif des attributs API

| Entité       | Attribut | Type   | Règles (Laravel)              | Exemple    |
|-------------|-----------|--------|--------------------------------|------------|
| Client      | `ninea`   | string | nullable, size:9, regex:/^\d{9}$/ | `"123456789"` |
| Fournisseur | `ninea`   | string | nullable, size:9, regex:/^\d{9}$/ | `"123456789"` |
| Entreprise  | `ninea`   | string | nullable, size:9, regex:/^\d{9}$/ | (si vous ajoutez l’API) |

Les réponses JSON (resources) doivent inclure `ninea` pour que l’app Flutter l’affiche en lecture seule sur les pages détail et l’utilise dans les formulaires.

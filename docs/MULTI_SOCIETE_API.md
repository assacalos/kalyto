# Multi-société – Changements API (Kalyto)

Ce document décrit les changements nécessaires **côté API / backend** pour supporter le multi-société (plusieurs sociétés dans la même instance). Le front Flutter envoie déjà un paramètre `company_id` (ou `society_id`) lorsque l’utilisateur a sélectionné une société courante.

## 1. Comportement frontend

- **Sélecteur de société** : dans **Paramètres** et dans le **menu (drawer)** du tableau de bord comptable, l’utilisateur peut choisir une « société courante » ou « Toutes (mono-société) ».
- **Envoi du paramètre** : dès qu’une société est sélectionnée, tous les appels API métier envoient :
  - en **query** (GET) : `company_id=<id>` ;
  - en **body** (POST/PUT/PATCH) : `company_id: <id>`.
- Si aucune société n’est sélectionnée, le front n’envoie pas `company_id` (comportement mono-société / rétrocompatibilité).

## 2. Endpoints concernés et paramètre à prendre en compte

Les endpoints suivants doivent **accepter** `company_id` (query ou body) et **filtrer / scoper** les données par `company_id` lorsque celui-ci est fourni.

### 2.1 Clients

| Méthode | Endpoint (ex.) | Où passer `company_id` | Action backend |
|--------|----------------|------------------------|----------------|
| GET | `/api/clients`, `/api/clients-list` | Query `company_id` | Filtrer les clients par `company_id` |
| POST | `/api/clients`, `/api/clients-create` | Body `company_id` | Créer le client pour cette société |
| PUT/POST | `/api/clients/:id`, `/api/clients-update/:id` | Body ou query | Vérifier que le client appartient à la société (ou mettre à jour dans le scope société) |
| DELETE | `/api/clients/:id`, `/api/clients-delete/:id` | Query `company_id` | Supprimer uniquement si le client appartient à la société |
| GET | `/api/clients/stats` | Query `company_id` | Statistiques limitées à la société |

### 2.2 Devis

| Méthode | Endpoint (ex.) | Où passer `company_id` | Action backend |
|--------|----------------|------------------------|----------------|
| GET | `/api/devis` | Query | Filtrer les devis par `company_id` |
| POST | `/api/devis-create` | Body | Créer le devis pour cette société |

### 2.3 Factures

| Méthode | Endpoint (ex.) | Où passer `company_id` | Action backend |
|--------|----------------|------------------------|----------------|
| GET | `/api/factures-list` | Query | Filtrer les factures par `company_id` |

### 2.4 Paiements

| Méthode | Endpoint (ex.) | Où passer `company_id` | Action backend |
|--------|----------------|------------------------|----------------|
| GET | `/api/payments` | Query | Filtrer les paiements par `company_id` |

### 2.5 Dépenses

| Méthode | Endpoint (ex.) | Où passer `company_id` | Action backend |
|--------|----------------|------------------------|----------------|
| GET | `/api/expenses`, `/api/expenses-list` | Query | Filtrer les dépenses par `company_id` |
| POST | `/api/expenses-create` | Body | Créer la dépense pour cette société |

### 2.6 Salaires

| Méthode | Endpoint (ex.) | Où passer `company_id` | Action backend |
|--------|----------------|------------------------|----------------|
| GET | `/api/salaries-list` | Query | Filtrer les salaires par `company_id` |
| POST | `/api/salaries-create` | Body | Créer le salaire pour cette société |

### 2.7 Journal comptable / Balance

| Méthode | Endpoint (ex.) | Où passer `company_id` | Action backend |
|--------|----------------|------------------------|----------------|
| GET | `/api/journal` | Query | Lignes du journal pour la société |
| GET | `/api/balance` | Query | Balance par compte pour la société |
| GET | `/api/journal-list` | Query | Liste paginée des écritures (société) |
| GET | `/api/journal-show/:id` | Query | Détail écriture (vérifier scope société) |
| POST | `/api/journal-create` | Body | Créer l’écriture pour la société |
| PUT | `/api/journal-update/:id` | Body | Mettre à jour dans le scope société |
| DELETE | `/api/journal-destroy/:id` | Query | Supprimer uniquement si scope société |

### 2.8 Bordereaux

| Méthode | Endpoint (ex.) | Où passer `company_id` | Action backend |
|--------|----------------|------------------------|----------------|
| GET | `/api/bordereaux`, `/api/bordereaux-list` | Query | Filtrer par `company_id` |
| POST | `/api/bordereaux-create` | Body | Créer le bordereau pour la société |

### 2.9 Inventaire physique

| Méthode | Endpoint (ex.) | Où passer `company_id` | Action backend |
|--------|----------------|------------------------|----------------|
| GET | `/api/inventory-sessions` | Query | Lister les sessions pour la société |
| POST | `/api/inventory-sessions` | Body | Créer une session pour la société |
| GET | `/api/inventory-sessions/:id` | Query | Détail (scope société) |
| GET | `/api/inventory-sessions/:id/lines` | Query | Lignes (scope société) |
| POST | `/api/inventory-sessions/:id/lines` | Body | Ajouter des lignes (scope société) |
| PATCH | `/api/inventory-sessions/:id/lines/:lineId` | Body | Mise à jour (scope société) |
| POST | `/api/inventory-sessions/:id/close` | Body | Clôture (scope société) |

## 3. Recommandations backend

1. **Query scope global** : pour chaque ressource métier (clients, factures, journal, etc.), appliquer un **scope par défaut** sur la table (ex. `where('company_id', $companyId)` lorsque `company_id` est présent dans la requête ou dérivé du token / contexte).
2. **Colonne `company_id`** : ajouter une colonne `company_id` (ou `society_id`) sur les tables concernées (clients, factures, paiements, dépenses, salaires, écritures journal, bordereaux, devis, sessions d’inventaire, etc.) et l’utiliser pour tous les `SELECT` / `INSERT` / `UPDATE` / `DELETE`.
3. **Création** : à chaque création (POST), enregistrer le `company_id` reçu dans le body (ou dérivé du contexte utilisateur si l’API gère une société par utilisateur).
4. **Rétrocompatibilité** : si `company_id` n’est pas envoyé, le backend peut soit renvoyer toutes les données (mono-société), soit utiliser une société par défaut selon la stratégie métier.
5. **Endpoint liste des sociétés** (optionnel) : le front appelle `GET /api/companies` pour afficher le sélecteur. Si l’endpoint n’existe pas, le front utilise une liste mockée. Créer `GET /api/companies` qui retourne la liste des sociétés accessibles par l’utilisateur permet de déployer le multi-société sans modifier l’app.

## 4. Résumé

- **Front** : envoie `company_id` en query ou en body pour tous les appels métier listés ci-dessus lorsque une société est sélectionnée.
- **Backend** : filtrer et scoper toutes les requêtes (lecture / écriture) par `company_id` lorsque le paramètre est fourni, et persister `company_id` à la création.

Aucun écran de **gestion des sociétés** (CRUD) n’est demandé pour l’instant ; seul le sélecteur de société courante et le scope des données sont en place côté front.

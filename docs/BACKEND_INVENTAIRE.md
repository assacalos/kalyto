# API Inventaire physique – Spécification backend (Laravel)

## Vue d’ensemble

Module **inventaire physique** pour le stock : sessions d’inventaire, lignes par article (référentiel stock) avec quantité théorique et quantité comptée, calcul des écarts, clôture (mise à jour des quantités ou création de mouvements).

---

## Modèles recommandés

### 1. `inventory_sessions`

| Colonne       | Type         | Contraintes | Description                    |
|---------------|--------------|-------------|--------------------------------|
| id            | bigint       | PK, auto    |                                |
| date          | date         | nullable    | Date de l’inventaire           |
| depot         | string(100)  | nullable    | Dépôt / entrepôt              |
| status        | enum/string  | default     | `in_progress` \| `closed`      |
| closed_at     | timestamp    | nullable    | Date/heure de clôture         |
| created_at    | timestamp    |             |                                |
| updated_at    | timestamp    |             |                                |

### 2. `inventory_lines`

| Colonne         | Type         | Contraintes | Description                          |
|-----------------|--------------|-------------|--------------------------------------|
| id              | bigint       | PK, auto    |                                      |
| inventory_session_id | bigint | FK, NOT NULL | Référence vers `inventory_sessions` |
| stock_id        | bigint       | FK, NOT NULL | Référence vers la table stock (articles) |
| theoretical_qty | decimal(15,2)| NOT NULL    | Quantité théorique (au moment de la création de la ligne) |
| counted_qty     | decimal(15,2)| nullable    | Quantité comptée (saisie par l’utilisateur) |
| created_at      | timestamp    |             |                                      |
| updated_at      | timestamp    |             |                                      |

- Index sur `inventory_session_id`, `stock_id`.
- Contrainte unique optionnelle : `(inventory_session_id, stock_id)` pour éviter les doublons par session/article.

---

## Endpoints

Base URL : `/api` (préfixe des routes API). Toutes les routes sont protégées (auth:sanctum ou équivalent).

### 1. Liste des sessions

**GET** `/inventory-sessions`

**Query (optionnel)**  
- `page` : numéro de page (pagination).  
- `per_page` : nombre d’éléments par page.

**Réponse succès (200)**  
- Format type Laravel Resource ou :

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "date": "2026-03-15",
      "depot": "Principal",
      "status": "in_progress",
      "closed_at": null,
      "lines_count": 12,
      "created_at": "2026-03-15T10:00:00.000000Z",
      "updated_at": "2026-03-15T10:00:00.000000Z"
    }
  ],
  "message": "..."
}
```

Si pagination : `data` peut être un objet `{ "data": [...], "current_page", "last_page", "per_page", "total" }` et le front s’adapte (voir notifier).

---

### 2. Créer une session

**POST** `/inventory-sessions`

**Body (JSON)**  
- `date` (string, optionnel) : format `YYYY-MM-DD`.  
- `depot` (string, optionnel) : libellé dépôt/entrepôt.

**Réponse succès (201)**  
- Retourner la session créée (id, date, depot, status, created_at, updated_at, etc.).

```json
{
  "success": true,
  "data": {
    "id": 1,
    "date": "2026-03-15",
    "depot": "Principal",
    "status": "in_progress",
    "closed_at": null,
    "created_at": "...",
    "updated_at": "..."
  },
  "message": "Session créée"
}
```

---

### 3. Détail d’une session

**GET** `/inventory-sessions/{id}`

**Réponse succès (200)**  
- Un seul objet session (id, date, depot, status, closed_at, lines_count si calculé, etc.).

```json
{
  "success": true,
  "data": {
    "id": 1,
    "date": "2026-03-15",
    "depot": "Principal",
    "status": "in_progress",
    "closed_at": null,
    "lines_count": 12,
    "created_at": "...",
    "updated_at": "..."
  }
}
```

**Erreur**  
- 404 si session inexistante.

---

### 4. Lignes d’une session

**GET** `/inventory-sessions/{id}/lines`

**Réponse succès (200)**  
- Liste des lignes avec infos article (sku, nom, unité) et quantités.

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "session_id": 1,
      "stock_id": 10,
      "sku": "ART-001",
      "product_name": "Article exemple",
      "unit": "pièce",
      "theoretical_qty": 100.00,
      "counted_qty": null,
      "created_at": "...",
      "updated_at": "..."
    }
  ]
}
```

Ou avec clé `lines` : `{ "success": true, "data": { "lines": [ ... ] } }`. Le front gère les deux formes.

Les champs `sku`, `product_name`, `unit` peuvent être dérivés de la table stock (jointure ou attributs calculés).

---

### 5. Ajouter des lignes (à partir du référentiel stock)

**POST** `/inventory-sessions/{id}/lines`

- Réservé aux sessions en statut `in_progress`.  
- Comportement attendu : créer une ligne par article stock sélectionné, avec `theoretical_qty` = quantité actuelle du stock (au moment de l’appel).

**Body (JSON)**  
- `stock_ids` (array d’entiers, optionnel) : liste d’ids d’articles stock à inclure.  
  - Si absent ou vide : ajouter une ligne pour **tous** les articles stock actifs (recommandé pour “Remplir depuis le stock”).

**Réponse succès (200 ou 201)**  
- Retourner la liste des lignes créées (ou la session mise à jour), par exemple :

```json
{
  "success": true,
  "data": {
    "lines": [ { "id": 1, "session_id": 1, "stock_id": 10, "sku": "ART-001", "product_name": "...", "unit": "pièce", "theoretical_qty": 100, "counted_qty": null, ... } ]
  },
  "message": "Lignes ajoutées"
}
```

**Erreurs**  
- 403/400 si session déjà clôturée.  
- 404 si session inexistante.

---

### 6. Mettre à jour la quantité comptée d’une ligne

**PATCH** `/inventory-sessions/{sessionId}/lines/{lineId}`

**Body (JSON)**  
- `counted_qty` (number) : quantité comptée (>= 0).

**Réponse succès (200)**  
- Retourner la ligne mise à jour (id, session_id, stock_id, sku, product_name, unit, theoretical_qty, counted_qty, ...).

**Erreurs**  
- 404 si session ou ligne inexistante.  
- 403/400 si session clôturée.

---

### 7. Clôturer l’inventaire

**POST** `/inventory-sessions/{id}/close`

- Réservé aux sessions en statut `in_progress`.  
- Après clôture : passer la session en `status = closed`, renseigner `closed_at`.  
- **Logique métier** (à implémenter selon ton modèle stock) :  
  - soit mettre à jour directement les quantités des articles stock avec la `counted_qty` de chaque ligne (ou avec écart) ;  
  - soit créer des mouvements de stock (entrées/sorties) pour chaque écart, puis recalculer les quantités.  
- Retourner la session clôturée.

**Réponse succès (200)**  
- Objet session avec `status: "closed"`, `closed_at` renseigné.

```json
{
  "success": true,
  "data": {
    "id": 1,
    "date": "2026-03-15",
    "depot": "Principal",
    "status": "closed",
    "closed_at": "2026-03-15T18:30:00.000000Z",
    "lines_count": 12,
    "created_at": "...",
    "updated_at": "..."
  },
  "message": "Inventaire clôturé"
}
```

**Erreurs**  
- 403/400 si session déjà clôturée.  
- 404 si session inexistante.

---

## Récapitulatif des routes

| Méthode | URI                                          | Description                    |
|---------|-----------------------------------------------|--------------------------------|
| GET     | /api/inventory-sessions                       | Liste des sessions             |
| POST    | /api/inventory-sessions                       | Créer une session              |
| GET     | /api/inventory-sessions/{id}                  | Détail d’une session           |
| GET     | /api/inventory-sessions/{id}/lines            | Lignes de la session           |
| POST    | /api/inventory-sessions/{id}/lines            | Ajouter des lignes (depuis stock) |
| PATCH   | /api/inventory-sessions/{sessionId}/lines/{lineId} | Mettre à jour quantité comptée |
| POST    | /api/inventory-sessions/{id}/close            | Clôturer l’inventaire          |

---

## Frontend (rappel)

- **Liste** : `/stock/inventaire` → `InventorySessionListPage`.  
- **Détail** : `/stock/inventaire/:id` → `InventorySessionDetailPage` (saisie compté, affichage écarts, bouton « Clôturer l’inventaire »).  
- **Menu** : entrée « Inventaire physique » depuis le module Stock (dashboard comptable).  
- Les appels API sont dans `ApiService` (getInventorySessions, createInventorySession, getInventorySession, getInventoryLines, addInventoryLines, updateInventoryLineCounted, closeInventorySession).

Une fois ces endpoints et modèles en place côté Laravel, le module inventaire physique fonctionnera de bout en bout.

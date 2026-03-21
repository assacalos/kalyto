# API Grand livre – Spécification backend Laravel

La page **Grand livre** du module comptable (Kalyto) affiche les mouvements par période avec colonnes : **date**, **libellé**, **débit**, **crédit**, **solde courant**.

Actuellement, l’appel côté Flutter réutilise l’endpoint **Journal** avec un filtre par dates (`date_debut`, `date_fin`). Les écritures sont mappées ainsi :
- **Débit** = champ `entree`
- **Crédit** = champ `sortie`
- **Solde courant** = calculé côté client (solde initial + débits − crédits ligne par ligne)

Pour un vrai **grand livre par compte** (plusieurs comptes, choix du compte en filtre), il faut exposer un endpoint dédié ou étendre le journal.

---

## Option 1 : Réutiliser l’endpoint Journal (déjà en place)

L’app utilise déjà :

- **GET** `/api/journal?date_debut=YYYY-MM-DD&date_fin=YYYY-MM-DD`

Réponse attendue (inchangée) :

```json
{
  "success": true,
  "data": {
    "lignes": [
      {
        "id": 1,
        "date": "2025-03-15",
        "libelle": "Libellé de l'écriture",
        "entree": 100000,
        "sortie": 0,
        "solde": 150000
      }
    ],
    "solde_initial": 50000,
    "solde_final": 150000,
    "total_entrees": 100000,
    "total_sorties": 0
  }
}
```

- **entree** → affiché en colonne **Débit**
- **sortie** → affiché en colonne **Crédit**
- **solde** (optionnel) → peut servir de solde courant ; sinon l’app le recalcule.

Aucune modification backend n’est obligatoire pour la page Grand livre actuelle (une période = un ensemble d’écritures, un seul “compte” implicite type caisse/journal).

---

## Option 2 : Endpoint dédié Grand livre (par compte)

Si vous introduisez un **plan de comptes** et des écritures par **compte**, ajoutez un endpoint dédié pour le grand livre par compte.

### Endpoint proposé

**GET** `/api/grand-livre`

#### Paramètres de requête

| Paramètre    | Type   | Obligatoire | Description |
|-------------|--------|-------------|-------------|
| `date_debut`| string | Oui         | Date début période (YYYY-MM-DD) |
| `date_fin`  | string | Oui         | Date fin période (YYYY-MM-DD) |
| `compte`    | string | Non         | Code ou ID du compte (ex. 512000, 411000). Si absent, renvoyer tous les comptes ou un regroupement par compte. |

#### Réponse attendue (par compte)

Format possible pour **un** compte (ou une section du grand livre) :

```json
{
  "success": true,
  "data": {
    "compte": "512000",
    "libelle_compte": "Caisse",
    "date_debut": "2025-03-01",
    "date_fin": "2025-03-31",
    "solde_initial": 50000,
    "solde_final": 120000,
    "lignes": [
      {
        "id": 1,
        "date": "2025-03-15",
        "libelle": "Libellé de l'écriture",
        "debit": 100000,
        "credit": 0,
        "solde_courant": 150000
      },
      {
        "id": 2,
        "date": "2025-03-20",
        "libelle": "Sortie caisse",
        "debit": 0,
        "credit": 30000,
        "solde_courant": 120000
      }
    ]
  }
}
```

- **debit** : montant au débit (entrée pour un compte d’actif type caisse).
- **credit** : montant au crédit (sortie).
- **solde_courant** : solde après l’écriture (optionnel ; l’app peut le recalculer si absent).

#### Réponse si plusieurs comptes (liste de sections)

Si vous renvoyez plusieurs comptes en un seul appel (sans filtre `compte`) :

```json
{
  "success": true,
  "data": {
    "comptes": [
      {
        "compte": "512000",
        "libelle_compte": "Caisse",
        "solde_initial": 50000,
        "solde_final": 120000,
        "lignes": [ ... ]
      },
      {
        "compte": "411000",
        "libelle_compte": "Clients",
        "solde_initial": 0,
        "solde_final": 250000,
        "lignes": [ ... ]
      }
    ]
  }
}
```

L’app Flutter pourra alors être adaptée pour :
- un filtre **Compte** (dropdown avec la liste des comptes) ;
- une section ou un onglet par compte avec le tableau date / libellé / débit / crédit / solde courant.

---

## Récapitulatif

| Besoin actuel              | Endpoint utilisé | Action backend |
|----------------------------|------------------|----------------|
| Grand livre sur une période (un journal / caisse) | `GET /api/journal?date_debut=&date_fin=` | Aucune (déjà en place). |
| Grand livre par compte (filtre compte + période)   | `GET /api/grand-livre?date_debut=&date_fin=&compte=` | Créer l’endpoint et le modèle/requêtes (écritures par compte, soldes). |

Les colonnes affichées côté Kalyto sont : **Date**, **Libellé**, **Débit**, **Crédit**, **Solde courant**. La devise reste **FCFA** partout.

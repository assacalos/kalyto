# API Balance comptable et plan de comptes

## Vue d’ensemble

- **Plan de comptes** : table `comptes` (code, libellé, type actif/passif/charge/produit).
- **Journal** : chaque écriture est liée à un `compte_id` (défaut : compte 51 Caisse). Entrée = débit, sortie = crédit pour ce compte.
- **Balance** : agrégation par compte sur une période (total débit, total crédit, solde).

## Endpoint Balance

**GET /api/balance**

Paramètres (optionnels) :

- `date_debut`, `date_fin` (YYYY-MM-DD), ou
- `mois`, `annee` (mois courant si absent)

Réponse :

```json
{
  "success": true,
  "data": {
    "date_debut": "2026-03-01",
    "date_fin": "2026-03-31",
    "lignes": [
      {
        "compte": "51",
        "libelle_compte": "Caisse",
        "total_debit": 100000.00,
        "total_credit": 40000.00,
        "solde": 60000.00
      }
    ],
    "total_debit": 100000.00,
    "total_credit": 40000.00,
    "solde_final": 60000.00
  },
  "message": "Balance récupérée avec succès"
}
```

Tous les comptes actifs du plan sont retournés ; les comptes sans mouvement sur la période ont des montants à 0.

## Migrations

1. `create_comptes_table` : crée la table `comptes`.
2. `add_compte_id_to_journal_entries_table` : ajoute la clé étrangère `compte_id` à `journal_entries`.
3. `seed_default_compte_and_assign_journal_entries` : crée le compte 51 Caisse et affecte les écritures existantes à ce compte.

## Modèles

- **Compte** : `code`, `libelle`, `type`, `actif`. Relation `journalEntries()`.
- **JournalEntry** : ajout de `compte_id` et relation `compte()`. Création/mise à jour : `compte_id` optionnel, défaut 51.

## Ajouter des comptes

Insérer dans `comptes` (ex. 411 Clients, 401 Fournisseurs, 6 Charges, 7 Produits). Les écritures peuvent être créées avec `compte_id` pour ventiler par compte.

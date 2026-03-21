# Stratégie de cache – Rapidité et professionnalisme

## Objectifs
- **Rapidité** : affichage instantané des écrans (données en cache) puis rafraîchissement en arrière-plan.
- **Professionnalisme** : expérience fluide, pas d’écrans vides, résistance aux coupures réseau.

---

## 1. Éléments qui DOIVENT être en cache

### 1.1 Données persistantes (GetStorage / stockage local)
| Élément | Clé / usage | Durée | Raison |
|--------|-------------|--------|--------|
| **Token d’authentification** | SessionService | Jusqu’à déconnexion | Connexion persistante, pas de re-login à chaque lancement |
| **Profil utilisateur** (nom, rôle, id, etc.) | `user` | Jusqu’à déconnexion | Affichage immédiat du nom/rôle au démarrage et sur tous les écrans |
| **URL de l’API** | `api_base_url` | Permanent | Choix utilisateur (prod / custom) |

### 1.2 Données métier « listes » (CacheHelper – mémoire)
Affichage immédiat de la dernière liste connue, puis mise à jour en arrière-plan.

| Élément | Clé type | Durée conseillée | Invalidation |
|--------|----------|-------------------|--------------|
| **Liste clients** | `clients_{status}` | 5 min | Création / modification / suppression client |
| **Liste devis** | `devis_{status}` | 5 min | Création / validation / suppression devis |
| **Liste bordereaux** | `bordereaux_{status}` | 5 min | Création / validation / suppression bordereau |
| **Liste bons de commande** | `bon_commandes_{status}` | 5 min | Création / validation / suppression |
| **Liste bons de commande fournisseur** | `bon_de_commandes_fournisseur_{status}` | 5 min | Idem |
| **Liste employés** | `employees_{page}_*` | 5–15 min | Création / modification employé |
| **Liste fournisseurs** | `suppliers_*` | 15 min | Création / modification fournisseur |
| **Liste factures** | idem pattern | 5 min | Création / paiement / annulation |
| **Liste paiements** | idem pattern | 5 min | Création / annulation |
| **Liste dépenses / salaires / interventions / contrats / congés / taxes / stock** | idem pattern | 5 min | Après action CRUD sur l’entité |

### 1.3 Compteurs dashboard (CacheHelper – mémoire)
Pour que le tableau de bord patron s’affiche tout de suite avec les derniers chiffres.

| Élément | Clé type | Durée conseillée |
|--------|----------|-------------------|
| **Compteurs « en attente »** (clients, devis, bordereaux, factures, paiements, inscriptions, etc.) | `dashboard_patron_pending*`, `dashboard_patron_validatedClients`, `dashboard_patron_totalRevenue` | 5 min |

### 1.4 Données de référence (CacheHelper – mémoire)
Peuvent changer rarement → cache plus long.

| Élément | Durée conseillée | Raison |
|--------|-------------------|--------|
| **Liste des rôles** (si chargée depuis l’API) | 1 h | Utilisée dans formulaires (ex. validation inscriptions) |
| **Liste des statuts / types** (si chargée depuis l’API) | 1 h | Listes déroulantes, filtres |
| **Paramètres / configuration métier** (si chargée depuis l’API) | 1 h | Rarement modifiés |

### 1.5 Images / médias
| Élément | Où | Raison |
|--------|-----|--------|
| **Images PDF** (logos, etc.) | `PdfService` (cache interne) | Éviter de recharger les mêmes images à chaque génération de PDF |
| **Avatars / photos utilisateurs** | `CachedNetworkImage` (widget) | Réduire requêtes et délais d’affichage |
| **Images métier** (documents, justificatifs) | Cache HTTP ou `CachedNetworkImage` | Même objectif |

---

## 2. Règles de durée (AppConfig / CacheHelper)

- **Court (5 min)** : listes et compteurs qui changent souvent (devis, factures, bordereaux, clients, dashboard).
- **Moyen (15–30 min)** : listes plus stables (employés, fournisseurs).
- **Long (1 h)** : données de référence (rôles, statuts, config).

À utiliser via `CacheHelper.set(key, value, duration: AppConfig.longCacheDuration)` pour les référentiels.

---

## 3. Invalidation du cache

- **Après création / modification / suppression** : invalider les caches concernés (ex. `CacheHelper.clearByPrefix('clients_')` après sauvegarde client).
- **Après déconnexion** : vider le cache métier (optionnel : `CacheHelper.clear()`) pour ne pas afficher les données d’un autre utilisateur après reconnexion.
- **Pas d’invalidation** pour le token et le profil : gérés par SessionService jusqu’à déconnexion explicite.

---

## 4. Déjà en place dans l’app

- Token + utilisateur : GetStorage (SessionService).
- URL API : GetStorage (AppConfig).
- Chargement utilisateur au démarrage : `AuthBinding` → `loadUserFromStorage()`.
- Listes : clients, devis, bordereaux, bons de commande, employés, fournisseurs, etc. (CacheHelper avec préfixes).
- Compteurs dashboard patron : CacheHelper + `loadCachedData()`.
- Images PDF : cache dans `PdfService`.

---

## 5. À renforcer si besoin

- **Profil utilisateur détaillé** : si une page « Mon profil » appelle l’API à chaque ouverture, mettre en cache la réponse (ex. 5–15 min) et afficher d’abord le cache, puis rafraîchir.
- **Listes encore sans cache** : appliquer le même schéma (cache par clé type `entity_status` ou `entity_page`, invalidation après CRUD).
- **Images réseau** : utiliser systématiquement `CachedNetworkImage` (ou équivalent) pour avatars et pièces jointes.
- **Filtres / préférences** : optionnel – sauvegarder le dernier filtre (ex. statut) par écran dans GetStorage pour réafficher la même vue au retour.

En résumé : **session et config en persistant**, **listes et compteurs en cache court**, **référentiels en cache long**, **invalidation après écriture** et **images via cache dédié** pour un bon équilibre rapidité / professionnalisme.

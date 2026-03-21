# Pattern Cache-First pour les listes d'entités

## Appliqué à
- **Clients** (ClientController / ClientService)
- **Devis** (DevisController / DevisService)
- **Bordereaux** (BordereauxController / BordereauService)
- **Bons de commande** (BonCommandeController / BonCommandeService)

## Comportement
1. **Chargement synchrone** : au premier affichage (page 1), lecture Hive **sans await** via `Service.getCachedXXX(status)`.
2. **Affichage immédiat** : si Hive a des données, on les affiche et `isLoading` reste à `false`.
3. **Sinon** : essai CacheHelper (mémoire), puis si vide `isLoading = true`.
4. **API en arrière-plan** : `Future.microtask(() => _refreshXXXFromApi(...))` sans bloquer l’UI.
5. **Mise à jour** : à la réponse API, si les données diffèrent, mise à jour de la liste et sauvegarde Hive (clé par statut si besoin).

## Pour étendre à d’autres entités
Dans le **service** :
- `_saveXXXToHive(list, int? status)` avec clé `'${key}_${status ?? 'all'}'`.
- `getCachedXXX([int? status])` : lecture synchrone Hive avec la même clé.

Dans le **controller** (méthode loadXXX, bloc `if (page == 1)` ) :
- Appel sync `hiveList = Service.getCachedXXX(status)`.
- Si `hiveList.isNotEmpty` → assigner à la liste, `isLoading.value = false`, lancer `Future.microtask(() => _refreshFromApi(...))`, `return`.
- Sinon CacheHelper, même logique si données.
- Sinon `isLoading.value = true` puis lancer le refresh en arrière-plan ou garder l’await API pour la page 1 (au choix).

## main.dart
- **Bloquant** (avant `runApp`) : `GetStorage.init()`, `HiveStorageService.init()`, `SessionService.initialize()`.
- **Non bloquant** : Firebase + Push initialisés dans `Future(() async { ... })` après `runApp()` pour afficher le premier écran plus tôt.

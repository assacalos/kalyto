<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\Controller;
use App\Services\NotificationService;
use App\Traits\SendsNotifications;
use Illuminate\Http\Request;
use App\Models\BonDeCommande;
use App\Models\BonDeCommandeItem;
use App\Models\Fournisseur;
use App\Models\User;
use App\Http\Resources\BonDeCommandeResource;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class BonDeCommandeController extends Controller
{
    use SendsNotifications;

    protected $notificationService;

    public function __construct(NotificationService $notificationService)
    {
        $this->notificationService = $notificationService;
    }
    /**
     * Liste des bons de commande avec filtres avancés
     * Accessible par Commercial, Comptable, Patron et Admin
     */
    public function index(Request $request)
    {
        try {
            $user = $request->user();
            
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Utilisateur non authentifié'
                ], 401);
            }
            
            $query = BonDeCommande::with(['fournisseur', 'createur', 'items']);
            
            // Filtrage par rôle : Commercial ne voit que ses propres bons de commande
            if ($user->isCommercial()) {
                $query->where('user_id', $user->id);
            }
            
            // Filtrage par user_id (pour les autres rôles)
            if ($request->has('user_id') && ! $user->isCommercial()) {
                $query->where('user_id', $request->user_id);
            }
            
            // Filtrage par statut (support des deux noms : statut et status)
            if ($request->has('statut')) {
                $query->where('statut', $request->statut);
            } elseif ($request->has('status')) {
                $query->where('statut', $request->status);
            }
            
            // Filtrage par date de commande
            if ($request->has('date_debut')) {
                $query->where('date_commande', '>=', $request->date_debut);
            }
            
            if ($request->has('date_fin')) {
                $query->where('date_commande', '<=', $request->date_fin);
            }
            
            // Filtrage par fournisseur
            if ($request->has('fournisseur_id')) {
                $query->where('fournisseur_id', $request->fournisseur_id);
            }
            
            // Filtrage par montant
            if ($request->has('montant_min')) {
                $query->where('montant_total', '>=', $request->montant_min);
            }
            
            if ($request->has('montant_max')) {
                $query->where('montant_total', '<=', $request->montant_max);
            }
            
            // Filtrage par retard (désactivé - date_livraison_prevue supprimée)
            // if ($request->has('en_retard')) {
            //     $query->where('date_livraison_prevue', '<', now())
            //           ->where('statut', '!=', 'livre');
            // }
            
            $perPage = min((int) $request->get('per_page', 20), 100);
            $bons = $query->orderBy('date_commande', 'desc')->paginate($perPage);
            
            return response()->json([
                'success' => true,
                'data' => BonDeCommandeResource::collection($bons),
                'pagination' => [
                    'current_page' => $bons->currentPage(),
                    'last_page' => $bons->lastPage(),
                    'per_page' => $bons->perPage(),
                    'total' => $bons->total(),
                    'from' => $bons->firstItem(),
                    'to' => $bons->lastItem(),
                ],
                'message' => 'Bons de commande récupérés avec succès',
            ], 200, [], JSON_UNESCAPED_UNICODE);
            
        } catch (\Exception $e) {
            \Log::error('Erreur lors de la récupération des bons de commande', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'user_id' => $request->user()?->id,
                'request_params' => $request->all(),
            ]);
            
            return response()->json([
                'success' => false,
                'message' => config('app.debug') 
                    ? 'Erreur lors de la récupération des bons de commande: ' . $e->getMessage()
                    : 'Une erreur est survenue. Veuillez réessayer plus tard.',
                'statusCode' => 500
            ], 500);
        }
    }

    /**
     * Détails d'un bon de commande
     * Accessible par Commercial, Comptable, Patron et Admin
     */
    public function show($id)
    {
        $bon = BonDeCommande::with(['fournisseur', 'createur', 'items'])->findOrFail($id);
        
        return response()->json([
            'success' => true,
            'data' => new BonDeCommandeResource($bon),
            'message' => 'Bon de commande récupéré avec succès'
        ]);
    }

    /**
     * Créer un bon de commande
     * Accessible par Commercial, Comptable et Admin
     */
    public function store(Request $request)
    {
        $request->validate([
            'fournisseur_id' => 'required|exists:fournisseurs,id',
            'numero_commande' => 'required|string|unique:bon_de_commandes',
            'date_commande' => 'required|date',
            'montant_total' => 'nullable|numeric|min:0',
            'description' => 'nullable|string',
            'statut' => 'nullable|in:en_attente,valide,en_cours,livre,annule',
            'commentaire' => 'nullable|string',
            'conditions_paiement' => 'nullable|string',
            'delai_livraison' => 'nullable|integer|min:1',
            'items' => 'nullable|array',
            'items.*.ref' => 'nullable|string',
            'items.*.designation' => 'required_with:items|string',
            'items.*.quantite' => 'required_with:items|integer|min:1',
            'items.*.prix_unitaire' => 'required_with:items|numeric|min:0',
            'items.*.description' => 'nullable|string',
        ]);

        DB::beginTransaction();

        try {
            // Calculer le montant total à partir des items si fournis
            $montantTotal = $request->montant_total;
            if ($request->has('items') && is_array($request->items) && count($request->items) > 0) {
                $montantTotal = 0;
                foreach ($request->items as $item) {
                    $montantTotal += ($item['quantite'] * $item['prix_unitaire']);
                }
            }

            if (!$montantTotal) {
                return response()->json([
                    'success' => false,
                    'message' => 'Le montant total est requis ou des items doivent être fournis'
                ], 422);
            }

            $bon = BonDeCommande::create([
                'fournisseur_id' => $request->fournisseur_id,
                'numero_commande' => $request->numero_commande,
                'date_commande' => $request->date_commande,
                'montant_total' => $montantTotal,
                'description' => $request->description,
                'statut' => $request->statut ?? 'en_attente',
                'commentaire' => $request->commentaire,
                'conditions_paiement' => $request->conditions_paiement,
                'delai_livraison' => $request->delai_livraison,
                'user_id' => auth()->id()
            ]);

            // Créer les items si fournis
            if ($request->has('items') && is_array($request->items)) {
                foreach ($request->items as $itemData) {
                    BonDeCommandeItem::create([
                        'bon_de_commande_id' => $bon->id,
                        'ref' => $itemData['ref'] ?? null,
                        'designation' => $itemData['designation'],
                        'quantite' => $itemData['quantite'],
                        'prix_unitaire' => $itemData['prix_unitaire'],
                        'description' => $itemData['description'] ?? null,
                    ]);
                }
            }

            DB::commit();

            // Notifier le patron si le bon est en attente
            if ($bon->statut === 'en_attente') {
                $this->safeNotify(function () use ($bon) {
                    $bon->load('user');
                    $this->notificationService->notifyNewBonCommandeFournisseur($bon);
                });
            }

            $bon->load(['fournisseur', 'createur', 'items']);

            return response()->json([
                'success' => true,
                'data' => new BonDeCommandeResource($bon),
                'message' => 'Bon de commande créé avec succès'
            ], 201);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la création: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Modifier un bon de commande
     * Accessible par Commercial, Comptable et Admin
     */
    public function update(Request $request, $id)
    {
        $bon = BonDeCommande::findOrFail($id);
        
        // Vérifier que le bon de commande peut être modifié
        if (in_array($bon->statut, ['valide', 'en_cours', 'livre'])) {
            return response()->json([
                'success' => false,
                'message' => 'Impossible de modifier un bon de commande validé ou en cours'
            ], 400);
        }

        $request->validate([
            'numero_commande' => 'nullable|string|unique:bon_de_commandes,numero_commande,' . $bon->id,
            'date_commande' => 'nullable|date',
            'montant_total' => 'nullable|numeric|min:0',
            'description' => 'nullable|string',
            'statut' => 'nullable|in:en_attente,valide,en_cours,livre,annule',
            'commentaire' => 'nullable|string',
            'conditions_paiement' => 'nullable|string',
            'delai_livraison' => 'nullable|integer|min:1',
            'items' => 'nullable|array',
            'items.*.ref' => 'nullable|string',
            'items.*.designation' => 'required_with:items|string',
            'items.*.quantite' => 'required_with:items|integer|min:1',
            'items.*.prix_unitaire' => 'required_with:items|numeric|min:0',
            'items.*.description' => 'nullable|string',
        ]);

        DB::beginTransaction();

        try {
            // Calculer le montant total à partir des items si fournis
            $montantTotal = $request->montant_total ?? $bon->montant_total;
            if ($request->has('items') && is_array($request->items) && count($request->items) > 0) {
                $montantTotal = 0;
                foreach ($request->items as $item) {
                    $montantTotal += ($item['quantite'] * $item['prix_unitaire']);
                }
            }

            // Mettre à jour le bon de commande
            $updateData = $request->only([
                'numero_commande', 'date_commande',
                'description', 'statut', 'commentaire', 'conditions_paiement', 'delai_livraison'
            ]);
            $updateData['montant_total'] = $montantTotal;
            
            $bon->update(array_filter($updateData, function($value) {
                return $value !== null;
            }));

            // Mettre à jour les items si fournis
            if ($request->has('items')) {
                // Supprimer les anciens items
                $bon->items()->delete();

                // Créer les nouveaux items
                foreach ($request->items as $itemData) {
                    BonDeCommandeItem::create([
                        'bon_de_commande_id' => $bon->id,
                        'ref' => $itemData['ref'] ?? null,
                        'designation' => $itemData['designation'],
                        'quantite' => $itemData['quantite'],
                        'prix_unitaire' => $itemData['prix_unitaire'],
                        'description' => $itemData['description'] ?? null,
                    ]);
                }
            }

            DB::commit();

            $bon->load(['fournisseur', 'createur', 'items']);

            return response()->json([
                'success' => true,
                'bon_de_commande' => $bon,
                'message' => 'Bon de commande modifié avec succès'
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la modification: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Valider un bon de commande
     * Accessible par Comptable, Patron et Admin
     */
    public function validateBon($id)
    {
        $bon = BonDeCommande::findOrFail($id);
        
        if ($bon->statut === 'valide') {
            return response()->json([
                'success' => false,
                'message' => 'Ce bon de commande est déjà validé'
            ], 400);
        }
        
        $bon->update([
            'statut' => 'valide',
            'date_validation' => now()
        ]);

        // Notifier l'auteur du bon de commande
        if ($bon->user_id) {
            $this->safeNotify(function () use ($bon) {
                $bon->load('user');
                $this->notificationService->notifyBonCommandeFournisseurValidated($bon);
            });
        }

        return response()->json([
            'success' => true,
            'bon_de_commande' => $bon,
            'message' => 'Bon de commande validé avec succès'
        ]);
    }

    /**
     * Rejeter un bon de commande
     * Accessible par Admin et Patron
     */
    public function reject(Request $request, $id)
    {
        $request->validate([
            'commentaire' => 'required|string|max:500'
        ]);

        $bon = BonDeCommande::findOrFail($id);
        
        // Vérifier que le bon de commande est en attente
        if ($bon->statut !== 'en_attente') {
            return response()->json([
                'success' => false,
                'message' => 'Ce bon de commande ne peut pas être rejeté'
            ], 422);
        }
        
        $bon->update([
            'statut' => 'annule',
            'commentaire' => $request->commentaire,
            'date_annulation' => now()
        ]);

        // Notifier l'auteur du bon de commande
        if ($bon->user_id) {
            $commentaire = $request->commentaire;
            $this->safeNotify(function () use ($bon, $commentaire) {
                $bon->load('user');
                $this->notificationService->notifyBonCommandeFournisseurRejected($bon, $commentaire);
            });
        }

        return response()->json([
            'success' => true,
            'bon_de_commande' => $bon->load(['fournisseur', 'createur', 'items']),
            'message' => 'Bon de commande rejeté avec succès'
        ]);
    }

    /**
     * Marquer comme en cours
     * Accessible par Comptable, Patron et Admin
     */
    public function markInProgress($id)
    {
        $bon = BonDeCommande::findOrFail($id);
        
        if ($bon->statut !== 'valide') {
            return response()->json([
                'success' => false,
                'message' => 'Le bon de commande doit être validé avant d\'être marqué comme en cours'
            ], 400);
        }
        
        $bon->update([
            'statut' => 'en_cours',
            'date_debut_traitement' => now()
        ]);

        return response()->json([
            'success' => true,
            'bon_de_commande' => $bon,
            'message' => 'Bon de commande marqué comme en cours'
        ]);
    }

    /**
     * Marquer comme livré
     * Accessible par Comptable, Patron et Admin
     */
    public function markDelivered($id)
    {
        $bon = BonDeCommande::findOrFail($id);
        
        if ($bon->statut !== 'en_cours') {
            return response()->json([
                'success' => false,
                'message' => 'Le bon de commande doit être en cours avant d\'être marqué comme livré'
            ], 400);
        }
        
        $bon->update([
            'statut' => 'livre',
        ]);

        return response()->json([
            'success' => true,
            'bon_de_commande' => $bon,
            'message' => 'Bon de commande marqué comme livré'
        ]);
    }

    /**
     * Annuler un bon de commande
     * Accessible par Comptable, Patron et Admin
     */
    public function cancel(Request $request, $id)
    {
        $request->validate([
            'commentaire' => 'required|string'
        ]);

        $bon = BonDeCommande::findOrFail($id);
        
        if (in_array($bon->statut, ['livre', 'annule'])) {
            return response()->json([
                'success' => false,
                'message' => 'Impossible d\'annuler un bon de commande livré ou déjà annulé'
            ], 400);
        }
        
        $bon->update([
            'statut' => 'annule',
            'commentaire' => $request->commentaire,
            'date_annulation' => now()
        ]);

        return response()->json([
            'success' => true,
            'bon_de_commande' => $bon,
            'message' => 'Bon de commande annulé avec succès'
        ]);
    }

    /**
     * Supprimer un bon de commande
     * Accessible par Commercial, Comptable, Admin et Patron
     */
    public function destroy($id)
    {
        $bon = BonDeCommande::findOrFail($id);
        
        // Vérifier que le bon de commande peut être supprimé
        if (in_array($bon->statut, ['valide', 'en_cours', 'livre'])) {
            return response()->json([
                'success' => false,
                'message' => 'Impossible de supprimer un bon de commande validé, en cours ou livré'
            ], 400);
        }
        
        $bon->delete();

        return response()->json([
            'success' => true,
            'message' => 'Bon de commande supprimé avec succès'
        ]);
    }

    /**
     * Rapports de bons de commande
     * Accessible par Comptable, Patron et Admin
     */
    public function reports(Request $request)
    {
        $query = BonDeCommande::with(['fournisseur']);
        
        // Filtrage par période
        if ($request->has('date_debut')) {
            $query->where('date_commande', '>=', $request->date_debut);
        }
        
        if ($request->has('date_fin')) {
            $query->where('date_commande', '<=', $request->date_fin);
        }
        
        $bons = $query->get();
        
        $rapport = [
            'total_bons' => $bons->count(),
            'montant_total' => $bons->sum('montant_total'),
            'bons_en_attente' => $bons->where('statut', 'en_attente')->count(),
            'montant_en_attente' => $bons->where('statut', 'en_attente')->sum('montant_total'),
            'bons_valides' => $bons->where('statut', 'valide')->count(),
            'montant_valide' => $bons->where('statut', 'valide')->sum('montant_total'),
            'bons_en_cours' => $bons->where('statut', 'en_cours')->count(),
            'montant_en_cours' => $bons->where('statut', 'en_cours')->sum('montant_total'),
            'bons_livres' => $bons->where('statut', 'livre')->count(),
            'montant_livre' => $bons->where('statut', 'livre')->sum('montant_total'),
            'bons_annules' => $bons->where('statut', 'annule')->count(),
            'montant_annule' => $bons->where('statut', 'annule')->sum('montant_total'),
            'par_fournisseur' => $bons->groupBy('fournisseur_id')->map(function($group, $fournisseurId) {
                $fournisseur = Fournisseur::find($fournisseurId);
                return [
                    'fournisseur' => $fournisseur ? $fournisseur->nom : 'Fournisseur inconnu',
                    'total_bons' => $group->count(),
                    'montant_total' => $group->sum('montant_total')
                ];
            })
        ];
        
        return response()->json([
            'success' => true,
            'rapport' => $rapport,
            'message' => 'Rapport de bons de commande généré avec succès'
        ]);
    }

    /**
     * Dashboard des bons de commande
     * Accessible par Comptable, Patron et Admin
     */
    public function dashboard(Request $request)
    {
        try {
            $user = $request->user();
            $query = BonDeCommande::query();
            
            // Filtrage par période
            if ($request->has('date_debut')) {
                $query->where('date_commande', '>=', $request->date_debut);
            }
            
            if ($request->has('date_fin')) {
                $query->where('date_commande', '<=', $request->date_fin);
            }
            
            $bons = $query->get();
            
            $dashboard = [
                'statistiques' => [
                    'total_bons' => $bons->count(),
                    'montant_total' => $bons->sum('montant_total'),
                    'bons_en_attente' => $bons->where('statut', 'en_attente')->count(),
                    'bons_valides' => $bons->where('statut', 'valide')->count(),
                    'bons_en_cours' => $bons->where('statut', 'en_cours')->count(),
                    'bons_livres' => $bons->where('statut', 'livre')->count(),
                    'bons_annules' => $bons->where('statut', 'annule')->count(),
                ],
                'montants_par_statut' => [
                    'en_attente' => $bons->where('statut', 'en_attente')->sum('montant_total'),
                    'valide' => $bons->where('statut', 'valide')->sum('montant_total'),
                    'en_cours' => $bons->where('statut', 'en_cours')->sum('montant_total'),
                    'livre' => $bons->where('statut', 'livre')->sum('montant_total'),
                    'annule' => $bons->where('statut', 'annule')->sum('montant_total'),
                ],
                'bons_en_retard' => 0, // Désactivé - date_livraison_prevue supprimée
                'bons_recents' => BonDeCommande::with(['fournisseur'])
                    ->orderBy('created_at', 'desc')
                    ->limit(5)
                    ->get()
            ];
            
            return response()->json([
                'success' => true,
                'data' => $dashboard,
                'message' => 'Dashboard généré avec succès'
            ]);
            
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la génération du dashboard: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Statistiques par période
     * Accessible par Comptable, Patron et Admin
     */
    public function statistics(Request $request)
    {
        try {
            $date_debut = $request->get('date_debut', now()->subMonths(6));
            $date_fin = $request->get('date_fin', now());
            
            $bons = BonDeCommande::whereBetween('date_commande', [$date_debut, $date_fin])->get();
            
            $statistiques = [
                'periode' => [
                    'debut' => $date_debut,
                    'fin' => $date_fin
                ],
                'totaux' => [
                    'nombre_bons' => $bons->count(),
                    'montant_total' => $bons->sum('montant_total'),
                    'montant_moyen' => $bons->count() > 0 ? $bons->avg('montant_total') : 0
                ],
                'par_mois' => $bons->groupBy(function($bon) {
                    return $bon->date_commande?->format('Y-m');
                })->map(function($group, $mois) {
                    return [
                        'mois' => $mois,
                        'nombre_bons' => $group->count(),
                        'montant_total' => $group->sum('montant_total')
                    ];
                }),
                'par_statut' => $bons->groupBy('statut')->map(function($group, $statut) {
                    return [
                        'statut' => $statut,
                        'nombre' => $group->count(),
                        'montant' => $group->sum('montant_total')
                    ];
                })
            ];
            
            return response()->json([
                'success' => true,
                'data' => $statistiques,
                'message' => 'Statistiques générées avec succès'
            ]);
            
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la génération des statistiques: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Recherche avancée de bons de commande
     * Accessible par Commercial, Comptable, Patron et Admin
     */
    public function search(Request $request)
    {
        try {
            $user = $request->user();
            $query = BonDeCommande::with(['fournisseur', 'createur']);
            
            // Recherche par numéro de commande
            if ($request->has('numero')) {
                $query->where('numero_commande', 'like', '%' . $request->numero . '%');
            }
            
            // Recherche par nom de fournisseur
            if ($request->has('fournisseur_nom')) {
                $query->whereHas('fournisseur', function($q) use ($request) {
                    $q->where('nom', 'like', '%' . $request->fournisseur_nom . '%');
                });
            }
            
            // Recherche par description
            if ($request->has('description')) {
                $query->where('description', 'like', '%' . $request->description . '%');
            }
            
            
            $bons = $query->orderBy('date_commande', 'desc')->get();
            
            return response()->json([
                'success' => true,
                'data' => $bons,
                'count' => $bons->count(),
                'message' => 'Recherche effectuée avec succès'
            ]);
            
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la recherche: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Dupliquer un bon de commande
     * Accessible par Commercial, Comptable et Admin
     */
    public function duplicate($id)
    {
        try {
            $originalBon = BonDeCommande::findOrFail($id);
            
            // Génération d'un nouveau numéro
            $numero = 'BC-' . date('Y') . '-' . str_pad(BonDeCommande::count() + 1, 4, '0', STR_PAD_LEFT);
            
            $nouveauBon = BonDeCommande::create([
                'fournisseur_id' => $originalBon->fournisseur_id,
                'numero_commande' => $numero,
                'date_commande' => now()->toDateString(),
                'montant_total' => $originalBon->montant_total,
                'description' => $originalBon->description,
                'statut' => 'en_attente',
                'commentaire' => 'Dupliqué depuis ' . $originalBon->numero_commande,
                'conditions_paiement' => $originalBon->conditions_paiement,
                'delai_livraison' => $originalBon->delai_livraison,
                'user_id' => auth()->id()
            ]);
            
            return response()->json([
                'success' => true,
                'data' => $nouveauBon->load(['fournisseur', 'createur']),
                'message' => 'Bon de commande dupliqué avec succès'
            ], 201);
            
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la duplication: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Exporter les bons de commande
     * Accessible par Comptable, Patron et Admin
     */
    public function export(Request $request)
    {
        try {
            $query = BonDeCommande::with(['fournisseur', 'createur']);
            
            // Appliquer les mêmes filtres que l'index
            if ($request->has('statut')) {
                $query->where('statut', $request->statut);
            }
            
            if ($request->has('date_debut')) {
                $query->where('date_commande', '>=', $request->date_debut);
            }
            
            if ($request->has('date_fin')) {
                $query->where('date_commande', '<=', $request->date_fin);
            }
            
            $bons = $query->orderBy('date_commande', 'desc')->get();
            
            // Format pour export
            $exportData = $bons->map(function($bon) {
                return [
                    'Numéro' => $bon->numero_commande,
                    'Date commande' => $bon->date_commande?->format('d/m/Y'),
                    'Fournisseur' => $bon->fournisseur->nom,
                    'Montant' => $bon->montant_total,
                    'Statut' => $bon->statut_libelle,
                    'Description' => $bon->description,
                    'Créé par' => $bon->createur->nom . ' ' . $bon->createur->prenom
                ];
            });
            
            return response()->json([
                'success' => true,
                'data' => $exportData,
                'count' => $exportData->count(),
                'message' => 'Données exportées avec succès'
            ]);
            
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'export: ' . $e->getMessage()
            ], 500);
        }
    }
}
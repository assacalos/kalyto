<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\Controller;
use App\Services\NotificationService;
use App\Traits\CachesData;
use App\Traits\ScopesByCompany;
use App\Traits\SendsNotifications;
use Illuminate\Http\Request;
use App\Models\Devis;
use App\Models\DevisItem;
use App\Models\Client;
use App\Models\User;
use App\Http\Resources\DevisResource;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Str;

class DevisController extends Controller
{
    use CachesData, ScopesByCompany, SendsNotifications;

    protected $notificationService;

    public function __construct(NotificationService $notificationService)
    {
        $this->notificationService = $notificationService;
    }
    /**
     * Liste des devis avec filtres par rôle et statut
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
            
            // Générer une clé de cache unique basée sur les paramètres
            $cacheKey = 'devis_list_' . md5(json_encode([
                'user_id' => $user->id,
                'role' => $user->role,
                'status' => $request->query('status'),
                'client_id' => $request->query('client_id'),
                'user_id_param' => $request->query('user_id'),
                'date_from' => $request->query('date_from'),
                'date_to' => $request->query('date_to'),
                'search' => $request->query('search'),
                'page' => $request->get('page', 1),
                'per_page' => $request->get('per_page', 15),
            ]));

            // Essayer de récupérer depuis le cache (cache de 5 minutes)
            // Si le cache échoue, continuer sans cache
            try {
                $cached = Cache::get($cacheKey);
                if ($cached !== null) {
                    return response()->json($cached, 200);
                }
            } catch (\Exception $e) {
                // En cas d'erreur de cache, continuer sans cache
                Log::warning('DevisController::index - Erreur de cache', [
                    'message' => $e->getMessage()
                ]);
            }
            
            $status = $request->query('status');
            $client_id = $request->query('client_id');
            $user_id = $request->query('user_id');
            $date_from = $request->query('date_from');
            $date_to = $request->query('date_to');
            $search = $request->query('search');

            // Optimiser la requête : charger les relations nécessaires
            // Note: Pour les relations belongsTo, on doit inclure la clé étrangère
            $query = Devis::with([
                'client' => function($q) {
                    $q->select('id', 'nom', 'prenom', 'email', 'nom_entreprise');
                },
                'commercial' => function($q) {
                    $q->select('id', 'nom', 'prenom', 'email');
                },
                'items' => function($q) {
                    $q->select('id', 'devis_id', 'designation', 'quantite', 'prix_unitaire');
                }
            ]);

            // Filtre par statut
            if ($status !== null && $status !== '') {
                $query->where('status', $status);
            }

            // Filtre par client
            if ($client_id) {
                $query->where('client_id', $client_id);
            }

            // Filtre par user_id (commercial)
            if ($user_id) {
                $query->where('user_id', $user_id);
            }

            // Filtre par date (support date_from/date_to et start_date/end_date pour compatibilité)
            $start_date = $request->query('start_date') ?? $date_from;
            $end_date = $request->query('end_date') ?? $date_to;
            
            if ($start_date) {
                $query->whereDate('date_creation', '>=', $start_date);
            }
            if ($end_date) {
                $query->whereDate('date_creation', '<=', $end_date);
            }

            // Recherche par référence
            if ($search) {
                $query->where('reference', 'like', '%' . $search . '%');
            }

            // Filtre par rôle : commercial ne voit que ses devis
            if ($user->role == 2) { // Commercial
                $query->where('user_id', $user->id);
            }
            $this->scopeByCompany($query, $request);

            $perPage = min((int) $request->get('per_page', 20), 100); // 20 par défaut, max 100 par page
            $devis = $query->orderBy('created_at', 'desc')->paginate($perPage);

            $response = [
                'success' => true,
                'data' => DevisResource::collection($devis),
                'pagination' => [
                    'current_page' => $devis->currentPage(),
                    'last_page' => $devis->lastPage(),
                    'per_page' => $devis->perPage(),
                    'total' => $devis->total(),
                    'from' => $devis->firstItem(),
                    'to' => $devis->lastItem(),
                    'has_next_page' => $devis->hasMorePages(),
                    'has_previous_page' => $devis->currentPage() > 1,
                ],
                'message' => 'Liste des devis récupérée avec succès',
            ];

            // Mettre en cache pendant 5 minutes (si possible)
            try {
                Cache::put($cacheKey, $response, 300);
            } catch (\Exception $e) {
                // En cas d'erreur de cache, continuer sans mettre en cache
                Log::warning('DevisController::index - Erreur lors de la mise en cache', [
                    'message' => $e->getMessage()
                ]);
            }

            return response()->json($response, 200);

        } catch (\Exception $e) {
            Log::error('DevisController::index - Erreur', [
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);
            
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des devis: ' . $e->getMessage(),
                'debug' => config('app.debug') ? [
                    'file' => $e->getFile(),
                    'line' => $e->getLine(),
                ] : null,
            ], 500);
        }
    }

    /**
     * Créer un nouveau devis
     */
    public function store(Request $request)
    {
        try {
            $validated = $request->validate([
                'client_id' => 'required|exists:clients,id',
                'date_validite' => 'nullable|date|after:today',
                'notes' => 'nullable|string',
                'remise_globale' => 'nullable|numeric|min:0',
                'tva' => 'nullable|numeric|min:0|max:100',
                'conditions' => 'nullable|string',
                'commentaire' => 'nullable|string',
                'titre' => 'nullable|string|max:255',
                'delai_livraison' => 'nullable|string|max:255',
                'garantie' => 'nullable|string|max:255',
                'status' => 'nullable|integer|in:0,1', // 0 = brouillon, 1 = envoyé
                'items' => 'required|array|min:1',
                'items.*.reference' => 'nullable|string|max:100',
                'items.*.designation' => 'required|string',
                'items.*.quantite' => 'required|integer|min:1',
                'items.*.prix_unitaire' => 'required|numeric|min:0'
            ]);

            DB::beginTransaction();

            // Génération de la référence
            $reference = 'DEV-' . date('Y') . '-' . str_pad(Devis::count() + 1, 4, '0', STR_PAD_LEFT);

            $data = [
                'client_id' => $validated['client_id'],
                'reference' => $reference,
                'date_creation' => now()->toDateString(),
                'date_validite' => $validated['date_validite'],
                'notes' => $validated['notes'],
                'status' => $validated['status'] ?? 0, // Brouillon par défaut, ou envoyé si status=1
                'remise_globale' => $validated['remise_globale'] ?? 0,
                'tva' => $validated['tva'] ?? 0,
                'conditions' => $validated['conditions'],
                'commentaire' => $validated['commentaire'],
                'titre' => $validated['titre'] ?? null,
                'delai_livraison' => $validated['delai_livraison'] ?? null,
                'garantie' => $validated['garantie'] ?? null,
                'user_id' => $request->user()->id
            ];
            if ($this->effectiveCompanyId($request) !== null) {
                $data['company_id'] = $this->effectiveCompanyId($request);
            }
            $devis = Devis::create($data);

            // Création des items
            foreach ($validated['items'] as $item) {
                DevisItem::create([
                    'devis_id' => $devis->id,
                    'reference' => $item['reference'] ?? null,
                    'designation' => $item['designation'],
                    'quantite' => $item['quantite'],
                    'prix_unitaire' => $item['prix_unitaire']
                ]);
            }

            DB::commit();

            $devis->load(['client', 'commercial', 'items']);

            // Notifier le patron si le devis est créé avec status = 1 (envoyé)
            if ($devis->status == 1) {
                $this->safeNotify(function () use ($devis) {
                    $this->notificationService->notifyNewDevis($devis);
                });
            }

            return response()->json([
                'success' => true,
                'message' => 'Devis créé avec succès',
                'data' => new DevisResource($devis)
            ], 201);

        } catch (\Illuminate\Validation\ValidationException $e) {
            DB::rollback();
            return response()->json([
                'success' => false,
                'message' => 'Erreur de validation',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            DB::rollback();
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la création du devis: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Afficher un devis spécifique
     */
    public function show($id)
    {
        try {
            $devis = Devis::with(['client', 'commercial', 'items'])->findOrFail($id);
            
            return response()->json([
                'success' => true,
                'data' => new DevisResource($devis)
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Devis non trouvé: ' . $e->getMessage()
            ], 404);
        }
    }

    /**
     * Modifier un devis (quel que soit le statut)
     */
    public function update(Request $request, $id)
    {
        try {
            $devis = Devis::findOrFail($id);

            $validated = $request->validate([
                'client_id' => 'required|exists:clients,id',
                'date_validite' => 'nullable|date|after:today',
                'notes' => 'nullable|string',
                'remise_globale' => 'nullable|numeric|min:0',
                'tva' => 'nullable|numeric|min:0|max:100',
                'conditions' => 'nullable|string',
                'commentaire' => 'nullable|string',
                'titre' => 'nullable|string|max:255',
                'delai_livraison' => 'nullable|string|max:255',
                'garantie' => 'nullable|string|max:255',
                'items' => 'required|array|min:1',
                'items.*.reference' => 'nullable|string|max:100',
                'items.*.designation' => 'required|string',
                'items.*.quantite' => 'required|integer|min:1',
                'items.*.prix_unitaire' => 'required|numeric|min:0'
            ]);

            DB::beginTransaction();

            $devis->update([
                'client_id' => $validated['client_id'],
                'date_validite' => $validated['date_validite'],
                'notes' => $validated['notes'],
                'remise_globale' => $validated['remise_globale'] ?? 0,
                'tva' => $validated['tva'] ?? 0,
                'conditions' => $validated['conditions'],
                'commentaire' => $validated['commentaire'],
                'titre' => $validated['titre'] ?? null,
                'delai_livraison' => $validated['delai_livraison'] ?? null,
                'garantie' => $validated['garantie'] ?? null
            ]);

            // Supprimer les anciens items et créer les nouveaux
            $devis->items()->delete();
            foreach ($validated['items'] as $item) {
                DevisItem::create([
                    'devis_id' => $devis->id,
                    'reference' => $item['reference'] ?? null,
                    'designation' => $item['designation'],
                    'quantite' => $item['quantite'],
                    'prix_unitaire' => $item['prix_unitaire']
                ]);
            }

            DB::commit();

            $devis->load(['client', 'commercial', 'items']);

            return response()->json([
                'success' => true,
                'message' => 'Devis modifié avec succès',
                'data' => new DevisResource($devis)
            ], 200);

        } catch (\Exception $e) {
            DB::rollback();
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la modification du devis: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Supprimer un devis (uniquement si brouillon)
     */
    public function destroy($id)
    {
        try {
            $devis = Devis::findOrFail($id);

            $devis->delete();

            return response()->json([
                'success' => true,
                'message' => 'Devis supprimé avec succès'
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la suppression du devis: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Envoyer un devis (changer le statut à "envoyé")
     */
    public function send($id)
    {
        try {
            $devis = Devis::findOrFail($id);

            $devis->update(['status' => 1]); // Envoyé
            $devis->load(['client', 'commercial', 'items']);

            // Notifier le patron
            $this->safeNotify(function () use ($devis) {
                $this->notificationService->notifyNewDevis($devis);
            });

            return response()->json([
                'success' => true,
                'message' => 'Devis envoyé avec succès',
                'data' => new DevisResource($devis)
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'envoi du devis: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Accepter un devis
     */
    public function accept($id) {
        try {
            $devis = Devis::findOrFail($id);

            // Accepter/valider le devis (quel que soit le statut actuel)
            $devis->status = 2; // Accepté/Validé
            $devis->save();
            $devis->load(['client', 'commercial', 'items']);
            
            // Notifier l'auteur du devis
            if ($devis->user_id) {
                $this->safeNotify(function () use ($devis) {
                    $this->notificationService->notifyDevisValidated($devis);
                });
            }
            
            return response()->json([
                'success' => true,
                'message' => 'Devis accepté avec succès',
                'data' => new DevisResource($devis)
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'acceptation: ' . $e->getMessage()
            ], 500);
        }
    }
    
    /**
     * Valider un devis (méthode pour les patrons) - alias de accept
     */
    public function validateDevis($id) {
        return $this->accept($id);
    }

    /**
     * Refuser un devis
     */
    public function reject(Request $request, $id)
    {
        try {
            $validated = $request->validate([
                'commentaire' => 'required|string'
            ]);

            $devis = Devis::findOrFail($id);

            $devis->update([
                'status' => 3, // Refusé
                'commentaire' => $validated['commentaire']
            ]);
            $devis->load(['client', 'commercial', 'items']);

            // Notifier l'auteur du devis
            if ($devis->user_id) {
                $this->safeNotify(function () use ($devis, $validated) {
                    $this->notificationService->notifyDevisRejected($devis, $validated['commentaire']);
                });
            }

            return response()->json([
                'success' => true,
                'message' => 'Devis refusé avec succès',
                'data' => new DevisResource($devis)
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du refus du devis: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Calculer les totaux d'un devis
     */
    public function calculateTotals($id)
    {
        try {
            $devis = Devis::with('items')->findOrFail($id);
            
            $sous_total = 0;

            foreach ($devis->items as $item) {
                $prix_item = $item->quantite * $item->prix_unitaire;
                $sous_total += $prix_item;
            }

            $remise_globale = $sous_total * ($devis->remise_globale / 100);
            $total_ht = $sous_total - $remise_globale;
            $tva = $total_ht * ($devis->tva / 100);
            $total_ttc = $total_ht + $tva;

            return response()->json([
                'success' => true,
                'data' => [
                    'sous_total' => round($sous_total, 2),
                    'remise_globale' => round($remise_globale, 2),
                    'total_ht' => round($total_ht, 2),
                    'tva' => round($tva, 2),
                    'total_ttc' => round($total_ttc, 2)
                ]
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du calcul: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Dupliquer un devis
     */
    public function duplicate($id)
    {
        try {
            $originalDevis = Devis::with('items')->findOrFail($id);

            DB::beginTransaction();

            // Génération d'une nouvelle référence
            $reference = 'DEV-' . date('Y') . '-' . str_pad(Devis::count() + 1, 4, '0', STR_PAD_LEFT);

            $newDevis = Devis::create([
                'client_id' => $originalDevis->client_id,
                'reference' => $reference,
                'date_creation' => now()->toDateString(),
                'date_validite' => $originalDevis->date_validite,
                'notes' => $originalDevis->notes,
                'status' => 0, // Brouillon
                'remise_globale' => $originalDevis->remise_globale,
                'tva' => $originalDevis->tva,
                'conditions' => $originalDevis->conditions,
                'commentaire' => $originalDevis->commentaire,
                'user_id' => $originalDevis->user_id
            ]);

            // Dupliquer les items
            foreach ($originalDevis->items as $item) {
                DevisItem::create([
                    'devis_id' => $newDevis->id,
                    'reference' => $item->reference,
                    'designation' => $item->designation,
                    'quantite' => $item->quantite,
                    'prix_unitaire' => $item->prix_unitaire
                ]);
            }

            DB::commit();

            $newDevis->load(['client', 'commercial', 'items']);

            return response()->json([
                'success' => true,
                'message' => 'Devis dupliqué avec succès',
                'data' => new DevisResource($newDevis)
            ], 201);

        } catch (\Exception $e) {
            DB::rollback();
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la duplication: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Rapports et statistiques des devis
     */
    public function reports(Request $request)
    {
        try {
            $date_from = $request->query('date_from');
            $date_to = $request->query('date_to');
            $user_id = $request->query('user_id');

            $query = Devis::query();

            if ($date_from) {
                $query->where('date_creation', '>=', $date_from);
            }
            if ($date_to) {
                $query->where('date_creation', '<=', $date_to);
            }
            if ($user_id) {
                $query->where('user_id', $user_id);
            }

            $devis = $query->get();

            $stats = [
                'total_devis' => $devis->count(),
                'brouillons' => $devis->where('status', 0)->count(),
                'envoyes' => $devis->where('status', 1)->count(),
                'acceptes' => $devis->where('status', 2)->count(),
                'refuses' => $devis->where('status', 3)->count(),
                'taux_acceptation' => $devis->where('status', 1)->count() > 0 
                    ? round(($devis->where('status', 2)->count() / $devis->where('status', 1)->count()) * 100, 2) 
                    : 0
            ];

            return response()->json([
                'success' => true,
                'data' => $stats
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la génération des rapports: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Devis par client
     */
    public function byClient($client_id)
    {
        try {
            $devis = Devis::with(['client', 'commercial', 'items'])
                ->where('client_id', $client_id)
                ->orderBy('created_at', 'desc')
                ->get();

            return response()->json([
                'success' => true,
                'data' => DevisResource::collection($devis)
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Compteur de devis avec filtres
     */
    public function count(Request $request)
    {
        try {
            $user = $request->user();
            
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Utilisateur non authentifié'
                ], 401);
            }
            
            $validated = $request->validate([
                'status' => 'nullable|integer',
                'start_date' => 'nullable|date',
                'end_date' => 'nullable|date|after_or_equal:start_date',
                'client_id' => 'nullable|integer|exists:clients,id',
                'user_id' => 'nullable|integer|exists:users,id',
            ]);
            
            $query = Devis::query();
            
            // Filtre par statut
            if (isset($validated['status'])) {
                $query->where('status', $validated['status']);
            }
            
            // Filtres de date
            if (isset($validated['start_date'])) {
                $query->whereDate('date_creation', '>=', $validated['start_date']);
            }
            if (isset($validated['end_date'])) {
                $query->whereDate('date_creation', '<=', $validated['end_date']);
            }
            
            // Filtre par client
            if (isset($validated['client_id'])) {
                $query->where('client_id', $validated['client_id']);
            }
            
            // Filtre par user_id (commercial)
            if (isset($validated['user_id'])) {
                $query->where('user_id', $validated['user_id']);
            }
            
            // Filtre par rôle : commercial ne voit que ses devis
            if ($user->role == 2) { // Commercial
                $query->where('user_id', $user->id);
            }
            
            return response()->json([
                'success' => true,
                'count' => $query->count(),
            ], 200);
            
        } catch (\Exception $e) {
            Log::error('DevisController::count - Erreur', [
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);
            
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du comptage: ' . $e->getMessage(),
            ], 500);
        }
    }
    
    /**
     * Statistiques agrégées des devis
     */
    public function stats(Request $request)
    {
        try {
            $user = $request->user();
            
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Utilisateur non authentifié'
                ], 401);
            }
            
            $validated = $request->validate([
                'status' => 'nullable|integer',
                'start_date' => 'nullable|date',
                'end_date' => 'nullable|date|after_or_equal:start_date',
                'user_id' => 'nullable|integer|exists:users,id',
            ]);
            
            $query = Devis::query();
            
            // Filtres de date
            if (isset($validated['start_date'])) {
                $query->whereDate('date_creation', '>=', $validated['start_date']);
            }
            if (isset($validated['end_date'])) {
                $query->whereDate('date_creation', '<=', $validated['end_date']);
            }
            
            // Filtre par statut
            if (isset($validated['status'])) {
                $query->where('status', $validated['status']);
            }
            
            // Filtre par user_id (commercial)
            if (isset($validated['user_id'])) {
                $query->where('user_id', $validated['user_id']);
            }
            
            // Filtre par rôle : commercial ne voit que ses devis
            if ($user->role == 2) { // Commercial
                $query->where('user_id', $user->id);
            }
            
            // Calculer les totaux (si le modèle a des colonnes de montant)
            $count = $query->count();
            
            // Statistiques par statut
            $byStatus = Devis::selectRaw('status, count(*) as count')
                ->when(isset($validated['start_date']), function($q) use ($validated) {
                    $q->whereDate('date_creation', '>=', $validated['start_date']);
                })
                ->when(isset($validated['end_date']), function($q) use ($validated) {
                    $q->whereDate('date_creation', '<=', $validated['end_date']);
                })
                ->when(isset($validated['user_id']), function($q) use ($validated) {
                    $q->where('user_id', $validated['user_id']);
                })
                ->when($user->role == 2, function($q) use ($user) {
                    $q->where('user_id', $user->id);
                })
                ->groupBy('status')
                ->get()
                ->pluck('count', 'status');
            
            return response()->json([
                'success' => true,
                'data' => [
                    'count' => $count,
                    'by_status' => $byStatus,
                ],
            ], 200);
            
        } catch (\Exception $e) {
            Log::error('DevisController::stats - Erreur', [
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);
            
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des statistiques: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Endpoint de debug pour vérifier les données
     */
    public function debug(Request $request)
    {
        try {
            $user = $request->user();
            
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Utilisateur non authentifié'
                ], 401);
            }

            $totalDevis = Devis::count();
            $devisByStatus = Devis::selectRaw('status, count(*) as count')
                ->groupBy('status')
                ->get()
                ->pluck('count', 'status');

            $devisByUser = Devis::selectRaw('user_id, count(*) as count')
                ->groupBy('user_id')
                ->get()
                ->pluck('count', 'user_id');

            // Si commercial, compter ses devis
            $userDevisCount = 0;
            if ($user->role == 2) {
                $userDevisCount = Devis::where('user_id', $user->id)->count();
            }

            // Derniers devis (sans filtres)
            $lastDevis = Devis::with(['client', 'commercial'])
                ->orderBy('created_at', 'desc')
                ->limit(5)
                ->get();

            return response()->json([
                'success' => true,
                'debug' => [
                    'user' => [
                        'id' => $user->id,
                        'role' => $user->role,
                        'nom' => $user->nom,
                        'prenom' => $user->prenom,
                    ],
                    'statistics' => [
                        'total_devis' => $totalDevis,
                        'devis_by_status' => $devisByStatus,
                        'devis_by_user' => $devisByUser,
                        'user_devis_count' => $userDevisCount,
                    ],
                    'last_devis' => $lastDevis->map(function ($devis) {
                        return [
                            'id' => $devis->id,
                            'reference' => $devis->reference,
                            'status' => $devis->status,
                            'user_id' => $devis->user_id,
                            'client_id' => $devis->client_id,
                            'created_at' => $devis->created_at,
                        ];
                    }),
                ]
            ], 200);

        } catch (\Exception $e) {
            Log::error('DevisController::debug - Erreur', [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du debug: ' . $e->getMessage()
            ], 500);
        }
    }
}
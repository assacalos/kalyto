<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\Controller;
use App\Services\NotificationService;
use App\Traits\ScopesByCompany;
use App\Traits\SendsNotifications;
use App\Models\Bordereau;
use App\Models\BordereauItem;
use App\Models\User;
use App\Http\Resources\BordereauResource;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;

class BordereauController extends Controller
{
    use SendsNotifications;

    protected $notificationService;

    public function __construct(NotificationService $notificationService)
    {
        $this->notificationService = $notificationService;
    }
    // Récupérer tous les bordereaux (avec filtre status facultatif)
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
            
            $status = $request->query('status'); // facultatif
            $query = Bordereau::with('items', 'client', 'user', 'devis');

            if ($status !== null) {
                $query->where('status', $status);
            }
            
            // Filtres de date
            if ($request->has('start_date')) {
                $query->whereDate('date_creation', '>=', $request->start_date);
            }
            if ($request->has('end_date')) {
                $query->whereDate('date_creation', '<=', $request->end_date);
            }
            $this->scopeByCompany($query, $request);

            $perPage = min((int) $request->get('per_page', 20), 100);
            $bordereaux = $query->orderBy('created_at', 'desc')->paginate($perPage);
            
            return response()->json([
                'success' => true,
                'data' => BordereauResource::collection($bordereaux),
                'pagination' => [
                    'current_page' => $bordereaux->currentPage(),
                    'last_page' => $bordereaux->lastPage(),
                    'per_page' => $bordereaux->perPage(),
                    'total' => $bordereaux->total(),
                    'from' => $bordereaux->firstItem(),
                    'to' => $bordereaux->lastItem(),
                ],
                'message' => 'Liste des bordereaux récupérée avec succès',
            ], 200, [], JSON_UNESCAPED_UNICODE);
            
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des bordereaux: ' . $e->getMessage()
            ], 500);
        }
    }

    // Créer un bordereau (toujours status=1 : soumis)
    public function store(Request $request)
    {
        DB::beginTransaction();
        
        try {
            $validated = $request->validate([
                'reference' => 'required|unique:bordereaus,reference',
                'titre' => 'nullable|string|max:255',
                'client_id' => 'required|exists:clients,id',
                'devis_id' => 'nullable|exists:devis,id',
                'user_id' => 'required|exists:users,id',
                'date_creation' => 'required|date',
                'items' => 'required|array|min:1',
                'items.*.reference' => 'nullable|string|max:100',
                'items.*.designation' => 'required|string',
                'items.*.quantite' => 'required|integer|min:1',
                'etat_livraison' => 'nullable|string|max:100',
                'garantie' => 'nullable|string|max:255',
                'date_livraison' => 'nullable|date',
            ]);

            $data = [
                'reference' => $validated['reference'],
                'titre' => $validated['titre'] ?? null,
                'client_id' => $validated['client_id'],
                'devis_id' => $validated['devis_id'] ?? null,
                'user_id' => $validated['user_id'],
                'date_creation' => $validated['date_creation'],
                'notes' => $request->notes ?? null,
                'status' => 1, // soumis au patron
                'etat_livraison' => $validated['etat_livraison'] ?? null,
                'garantie' => $validated['garantie'] ?? null,
                'date_livraison' => isset($validated['date_livraison']) ? $validated['date_livraison'] : null,
            ];
            if ($this->effectiveCompanyId($request) !== null) {
                $data['company_id'] = $this->effectiveCompanyId($request);
            }
            $bordereau = Bordereau::create($data);

            foreach ($validated['items'] as $item) {
                BordereauItem::create([
                    'bordereau_id' => $bordereau->id,
                    'reference' => $item['reference'] ?? null,
                    'designation' => $item['designation'],
                    'quantite' => $item['quantite'],
                    'description' => $item['description'] ?? null,
                ]);
            }
            
            DB::commit();

            // Charger les relations avec gestion d'erreur
            try {
                $bordereau->load('items', 'client', 'user');
                
                // Charger devis seulement s'il existe
                if ($bordereau->devis_id) {
                    $bordereau->load('devis');
                }
            } catch (\Exception $e) {
                Log::warning('Failed to load bordereau relations', [
                    'bordereau_id' => $bordereau->id,
                    'error' => $e->getMessage()
                ]);
                // Continuer même si les relations ne peuvent pas être chargées
            }

            // Notifier le patron lors de la création (status=1 = soumis)
            $this->safeNotify(function () use ($bordereau) {
                $bordereau->load('user');
                $this->notificationService->notifyNewBordereau($bordereau);
            });

            // Recharger le bordereau pour s'assurer d'avoir toutes les données
            $bordereau->refresh();
            
            return response()->json([
                'success' => true,
                'data' => new BordereauResource($bordereau),
                'message' => 'Bordereau créé avec succès'
            ], 201);
            
        } catch (\Illuminate\Validation\ValidationException $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Erreur de validation',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            DB::rollBack();
            
            Log::error('Bordereau store error', [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
                'request_data' => $request->except(['password', 'token']),
            ]);
            
            $errorMessage = 'Erreur lors de la création du bordereau';
            $errorDetails = null;
            
            if (config('app.debug')) {
                $errorDetails = [
                    'message' => $e->getMessage(),
                    'file' => $e->getFile(),
                    'line' => $e->getLine(),
                ];
                $errorMessage = $e->getMessage();
            }
            
            return response()->json([
                'success' => false,
                'message' => $errorMessage,
                'error' => $errorDetails
            ], 500);
        }
    }

    // Récupérer un bordereau
    public function show($id)
    {
        $bordereau = Bordereau::with('items', 'client', 'user', 'devis')->findOrFail($id);
        return response()->json([
            'success' => true,
            'data' => new BordereauResource($bordereau)
        ]);
    }

    // Mettre à jour un bordereau (quel que soit le statut)
    public function update(Request $request, $id)
    {
        $bordereau = Bordereau::findOrFail($id);

        $bordereau->update($request->only([
            'titre', 'notes', 'status', 'commentaire', 'etat_livraison', 'garantie', 'date_livraison'
        ]));

        // Mise à jour des items si fournis
        if ($request->has('items')) {
            $bordereau->items()->delete(); // supprimer anciens items
            foreach ($request->items as $item) {
                BordereauItem::create([
                    'bordereau_id' => $bordereau->id,
                    'reference' => $item['reference'] ?? null,
                    'designation' => $item['designation'],
                    'quantite' => $item['quantite'],
                    'description' => $item['description'] ?? null,
                ]);
            }
        }

        return response()->json([
            'success' => true,
            'data' => new BordereauResource($bordereau->load('items', 'client', 'user', 'devis'))
        ]);
    }

    // Supprimer un bordereau (quel que soit le statut)
    public function destroy($id)
    {
        $bordereau = Bordereau::findOrFail($id);

        $bordereau->delete();
        return response()->json(['message' => 'Bordereau supprimé']);
    }

    // Valider un bordereau (quel que soit le statut)
    public function validateBordereau(Request $request, $id)
    {
        try {
            $bordereau = Bordereau::findOrFail($id);

            $bordereau->update([
                'status' => 2, // validé
                'date_validation' => now()->toDateString(),
                'commentaire' => null // effacer tout commentaire de rejet
            ]);

            // Notifier l'auteur du bordereau
            if ($bordereau->user_id) {
                $this->safeNotify(function () use ($bordereau) {
                    $bordereau->load('user');
                    $this->notificationService->notifyBordereauValidated($bordereau);
                });
            }

            // Recharger le bordereau avec ses relations
            $bordereau->refresh();
            $bordereau->load(['items', 'client', 'user']);
            
            // Charger devis seulement s'il existe
            if ($bordereau->devis_id) {
                $bordereau->load('devis');
            }

            return response()->json([
                'success' => true,
                'message' => 'Bordereau validé avec succès',
                'data' => new BordereauResource($bordereau)
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la validation: ' . $e->getMessage()
            ], 500);
        }
    }

    // ✅ NOUVELLE MÉTHODE : Rejeter un bordereau
    public function reject(Request $request, $id)
    {
        try {
            $bordereau = Bordereau::findOrFail($id);
            
            // Vérifier que le bordereau est soumis (status = 1)
            if ($bordereau->status != 1) {
                return response()->json([
                    'success' => false,
                    'message' => 'Seuls les bordereaux soumis peuvent être rejetés'
                ], 403);
            }

            $validator = Validator::make($request->all(), [
                'commentaire' => 'required|string|max:1000'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'errors' => $validator->errors()
                ], 422);
            }

            $bordereau->update([
                'status' => 3, // rejeté
                'commentaire' => $request->commentaire
            ]);

            // Notifier l'auteur du bordereau
            if ($bordereau->user_id) {
                $commentaire = $request->commentaire;
                $this->safeNotify(function () use ($bordereau, $commentaire) {
                    $bordereau->load('user');
                    $this->notificationService->notifyBordereauRejected($bordereau, $commentaire);
                });
            }

            return response()->json([
                'success' => true,
                'message' => 'Bordereau rejeté avec succès',
                'data' => new BordereauResource($bordereau->load(['items', 'client', 'user', 'devis']))
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du rejet: ' . $e->getMessage()
            ], 500);
        }
    }
    
    /**
     * Compteur de bordereaux avec filtres
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
                'user_id' => 'nullable|integer|exists:users,id',
            ]);
            
            $query = Bordereau::query();
            
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
            
            // Filtre par user_id
            if (isset($validated['user_id'])) {
                $query->where('user_id', $validated['user_id']);
            }
            
            return response()->json([
                'success' => true,
                'count' => $query->count(),
            ], 200);
            
        } catch (\Exception $e) {
            Log::error('BordereauController::count - Erreur', [
                'message' => $e->getMessage(),
            ]);
            
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du comptage: ' . $e->getMessage(),
            ], 500);
        }
    }
    
    /**
     * Statistiques agrégées des bordereaux
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
            
            $query = Bordereau::query();
            
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
            
            // Filtre par user_id
            if (isset($validated['user_id'])) {
                $query->where('user_id', $validated['user_id']);
            }
            
            $count = $query->count();
            
            // Statistiques par statut
            $byStatus = Bordereau::selectRaw('status, count(*) as count')
                ->when(isset($validated['start_date']), function($q) use ($validated) {
                    $q->whereDate('date_creation', '>=', $validated['start_date']);
                })
                ->when(isset($validated['end_date']), function($q) use ($validated) {
                    $q->whereDate('date_creation', '<=', $validated['end_date']);
                })
                ->when(isset($validated['user_id']), function($q) use ($validated) {
                    $q->where('user_id', $validated['user_id']);
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
            Log::error('BordereauController::stats - Erreur', [
                'message' => $e->getMessage(),
            ]);
            
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des statistiques: ' . $e->getMessage(),
            ], 500);
        }
    }
}
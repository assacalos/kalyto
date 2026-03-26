<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\Controller;
use App\Services\NotificationService;
use App\Traits\SendsNotifications;
use Illuminate\Http\Request;
use App\Models\CommandeEntreprise;
use App\Http\Resources\CommandeEntrepriseResource;
use Illuminate\Support\Facades\Log;

class CommandeEntrepriseController extends Controller
{
    use SendsNotifications;

    protected $notificationService;

    public function __construct(NotificationService $notificationService)
    {
        $this->notificationService = $notificationService;
    }
    /**
     * Liste des commandes entreprise avec filtres
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
            
            $query = CommandeEntreprise::with(['client', 'commercial']);

            // Filtrage par statut
            if ($request->has('status')) {
                $query->where('status', $request->status);
            }

            // Filtrage par client
            if ($request->has('client_id')) {
                $query->where('client_id', $request->client_id);
            }

            // Filtrage par commercial
            if ($request->has('user_id')) {
                $query->where('user_id', $request->user_id);
            }

            // Si commercial → filtre ses propres commandes
            if ($user->isCommercial()) {
                $query->where('user_id', $user->id);
            }

            $perPage = min((int) $request->get('per_page', 20), 100);
            $commandes = $query->orderBy('created_at', 'desc')->paginate($perPage);

            return response()->json([
                'success' => true,
                'data' => CommandeEntrepriseResource::collection($commandes),
                'pagination' => [
                    'current_page' => $commandes->currentPage(),
                    'last_page' => $commandes->lastPage(),
                    'per_page' => $commandes->perPage(),
                    'total' => $commandes->total(),
                    'from' => $commandes->firstItem(),
                    'to' => $commandes->lastItem(),
                ],
                'message' => 'Liste des commandes récupérée avec succès',
            ], 200, [], JSON_UNESCAPED_UNICODE);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des commandes: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Détails d'une commande entreprise
     */
    public function show($id)
    {
        try {
            $commande = CommandeEntreprise::with(['client', 'commercial', 'items'])
                ->findOrFail($id);

            // Vérification des permissions pour les commerciaux
            $user = auth()->user();
            if ($user->isCommercial() && $commande->user_id !== $user->id) {
                return response()->json([
                    'success' => false,
                    'message' => 'Accès refusé à cette commande'
                ], 403);
            }

            return response()->json([
                'success' => true,
                'data' => new CommandeEntrepriseResource($commande),
                'message' => 'Commande récupérée avec succès'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération de la commande: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Créer une commande entreprise
     */
    public function store(Request $request)
    {
        try {
            $request->validate([
                'client_id' => 'required|exists:clients,id',
                'user_id' => 'nullable|exists:users,id',
                'status' => 'nullable|integer|in:1,2,3,4',
                'fichiers_scannes' => 'nullable|array',
                'fichiers_scannes.*' => 'nullable|string', // Tableau de chemins de fichiers
            ]);

            // Créer la commande
            $commande = CommandeEntreprise::create([
                'client_id' => $request->client_id,
                'user_id' => $request->user_id ?? auth()->id(),
                'status' => $request->status ?? 1, // Soumis par défaut
                'fichiers_scannes' => $request->fichiers_scannes ?? [],
            ]);

            $commande->load(['client', 'commercial']);

            return response()->json([
                'success' => true,
                'data' => [
                    'id' => $commande->id,
                    'client_id' => $commande->client_id,
                    'user_id' => $commande->user_id,
                    'status' => $commande->status,
                    'fichiers_scannes' => $commande->fichiers_scannes,
                    'client' => $commande->client,
                    'commercial' => $commande->commercial,
                    'created_at' => $commande->created_at->format('Y-m-d\TH:i:s\Z'),
                    'updated_at' => $commande->updated_at->format('Y-m-d\TH:i:s\Z'),
                ],
                'message' => 'Commande créée avec succès'
            ], 201);

        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur de validation',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la création de la commande: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Modifier une commande entreprise
     */
    public function update(Request $request, $id)
    {
        try {
            $commande = CommandeEntreprise::findOrFail($id);

            // Vérifier que la commande peut être modifiée
            if ($commande->status != 1) { // Seulement si soumis
                return response()->json([
                    'success' => false,
                    'message' => 'Impossible de modifier une commande validée, rejetée ou livrée'
                ], 400);
            }

            $request->validate([
                'client_id' => 'nullable|exists:clients,id',
                'user_id' => 'nullable|exists:users,id',
                'status' => 'nullable|integer|in:1,2,3,4',
                'fichiers_scannes' => 'nullable|array',
                'fichiers_scannes.*' => 'nullable|string',
            ]);

            // Mettre à jour la commande
            $commande->update($request->only([
                'client_id', 'user_id', 'status', 'fichiers_scannes'
            ]));

            $commande->load(['client', 'commercial']);

            return response()->json([
                'success' => true,
                'data' => [
                    'id' => $commande->id,
                    'client_id' => $commande->client_id,
                    'user_id' => $commande->user_id,
                    'status' => $commande->status,
                    'fichiers_scannes' => $commande->fichiers_scannes,
                    'client' => $commande->client,
                    'commercial' => $commande->commercial,
                    'created_at' => $commande->created_at->format('Y-m-d\TH:i:s\Z'),
                    'updated_at' => $commande->updated_at->format('Y-m-d\TH:i:s\Z'),
                ],
                'message' => 'Commande modifiée avec succès'
            ]);

        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur de validation',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la modification de la commande: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Valider une commande
     * Accessible par Patron et Admin
     */
    public function validateCommande($id)
    {
        try {
            $commande = CommandeEntreprise::findOrFail($id);

            if ($commande->status == 2) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette commande est déjà validée'
                ], 400);
            }

            if ($commande->status == 3) {
                return response()->json([
                    'success' => false,
                    'message' => 'Impossible de valider une commande rejetée'
                ], 400);
            }

            if ($commande->status == 4) {
                return response()->json([
                    'success' => false,
                    'message' => 'Impossible de valider une commande déjà livrée'
                ], 400);
            }

            $commande->update([
                'status' => 2,
            ]);

            // Notifier l'auteur de la commande
            if ($commande->user_id) {
                $this->safeNotify(function () use ($commande) {
                    $commande->load('user');
                    $this->notificationService->notifyCommandeEntrepriseValidated($commande);
                });
            }

            $commande->load(['client', 'commercial']);

            return response()->json([
                'success' => true,
                'data' => [
                    'id' => $commande->id,
                    'client_id' => $commande->client_id,
                    'user_id' => $commande->user_id,
                    'status' => $commande->status,
                    'fichiers_scannes' => $commande->fichiers_scannes,
                    'client' => $commande->client,
                    'commercial' => $commande->commercial,
                    'created_at' => $commande->created_at->format('Y-m-d\TH:i:s\Z'),
                    'updated_at' => $commande->updated_at->format('Y-m-d\TH:i:s\Z'),
                ],
                'message' => 'Commande validée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la validation: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Rejeter une commande
     * Accessible par Patron et Admin
     */
    public function rejectCommande(Request $request, $id)
    {
        try {
            $commande = CommandeEntreprise::findOrFail($id);

            if ($commande->status == 3) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette commande est déjà rejetée'
                ], 400);
            }

            if ($commande->status == 4) {
                return response()->json([
                    'success' => false,
                    'message' => 'Impossible de rejeter une commande livrée'
                ], 400);
            }

            $reason = $request->input('reason', $request->input('commentaire', 'Rejeté'));

            $commande->update([
                'status' => 3,
            ]);

            // Notifier l'auteur de la commande
            if ($commande->user_id) {
                $this->safeNotify(function () use ($commande, $reason) {
                    $commande->load('user');
                    $this->notificationService->notifyCommandeEntrepriseRejected($commande, $reason);
                });
            }

            $commande->load(['client', 'commercial']);

            return response()->json([
                'success' => true,
                'data' => [
                    'id' => $commande->id,
                    'client_id' => $commande->client_id,
                    'user_id' => $commande->user_id,
                    'status' => $commande->status,
                    'fichiers_scannes' => $commande->fichiers_scannes,
                    'client' => $commande->client,
                    'commercial' => $commande->commercial,
                    'created_at' => $commande->created_at->format('Y-m-d\TH:i:s\Z'),
                    'updated_at' => $commande->updated_at->format('Y-m-d\TH:i:s\Z'),
                ],
                'message' => 'Commande rejetée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du rejet: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Marquer une commande comme livrée
     */
    public function markAsDelivered($id)
    {
        try {
            $commande = CommandeEntreprise::findOrFail($id);

            if ($commande->status != 2) {
                return response()->json([
                    'success' => false,
                    'message' => 'Seules les commandes validées peuvent être marquées comme livrées'
                ], 400);
            }

            $commande->update([
                'status' => 4,
            ]);

            $commande->load(['client', 'commercial']);

            return response()->json([
                'success' => true,
                'data' => [
                    'id' => $commande->id,
                    'client_id' => $commande->client_id,
                    'user_id' => $commande->user_id,
                    'status' => $commande->status,
                    'fichiers_scannes' => $commande->fichiers_scannes,
                    'client' => $commande->client,
                    'commercial' => $commande->commercial,
                    'created_at' => $commande->created_at->format('Y-m-d\TH:i:s\Z'),
                    'updated_at' => $commande->updated_at->format('Y-m-d\TH:i:s\Z'),
                ],
                'message' => 'Commande marquée comme livrée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la mise à jour: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Marquer une commande comme facturée
     */
    public function markAsInvoiced(Request $request, $id)
    {
        try {
            $commande = CommandeEntreprise::findOrFail($id);

            // Cette méthode n'est plus nécessaire car on n'a plus de champ est_facture
            // On peut simplement retourner un message informatif
            return response()->json([
                'success' => false,
                'message' => 'Cette fonctionnalité n\'est plus disponible. La commande est simplifiée.'
            ], 400);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la mise à jour: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Supprimer une commande
     */
    public function destroy($id)
    {
        try {
            $commande = CommandeEntreprise::findOrFail($id);

            // Vérifier que la commande peut être supprimée
            if ($commande->status != 1) {
                return response()->json([
                    'success' => false,
                    'message' => 'Impossible de supprimer une commande validée, rejetée ou livrée'
                ], 400);
            }

            $commande->delete();

            return response()->json([
                'success' => true,
                'message' => 'Commande supprimée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la suppression: ' . $e->getMessage()
            ], 500);
        }
    }
}
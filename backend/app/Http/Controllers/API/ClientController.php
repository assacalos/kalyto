<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\Controller;
use App\Traits\CachesData;
use App\Traits\ScopesByCompany;
use App\Traits\SendsNotifications;
use App\Services\NotificationService;
use Illuminate\Http\Request;
use App\Models\Client;
use App\Http\Resources\ClientResource;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;

class ClientController extends Controller
{
    use CachesData, ScopesByCompany, SendsNotifications;

    protected $notificationService;

    public function __construct(NotificationService $notificationService)
    {
        $this->notificationService = $notificationService;
    }
    // Liste des clients avec filtre rôle et statut
    // Accessible aux commerciaux, comptables, techniciens, admin et patron
    // Seuls les commerciaux (role 2) voient uniquement leurs propres clients
    // Les autres rôles (comptable role 3, technicien role 5, etc.) voient tous les clients
    public function index(Request $request)
    {
        try {
            $status = $request->query('status'); // optionnel
            $user = $request->user();             // utilisateur connecté
            
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Utilisateur non authentifié'
                ], 401);
            }
            
            $query = Client::with(['user']);

            // Filtre par statut
            if ($status !== null) {
                $query->where('status', $status);
            } else {
                // Par défaut, ne retourner que les clients validés (status = 1) pour faciliter la sélection
                // Sauf si un filtre explicite est demandé
                if (!$request->has('status') && !$request->has('include_pending')) {
                    $query->where('status', 1); // Seulement les clients validés
                }
            }

            // Filtre par recherche (nom, email, entreprise, numero_contribuable)
            if ($request->has('search')) {
                $search = $request->query('search');
                $query->where(function($q) use ($search) {
                    $q->where('nom', 'like', '%' . $search . '%')
                      ->orWhere('prenom', 'like', '%' . $search . '%')
                      ->orWhere('email', 'like', '%' . $search . '%')
                      ->orWhere('nom_entreprise', 'like', '%' . $search . '%')
                      ->orWhere('contact', 'like', '%' . $search . '%')
                      ->orWhere('numero_contribuable', 'like', '%' . $search . '%')
                      ->orWhere('ninea', 'like', '%' . $search . '%');
                });
            }
            // Si commercial (role 2) → filtre uniquement ses clients

            // Les comptables (role 3), techniciens (role 5) et autres voient tous les clients
            if ($user->role == 2) { // 2 = commercial
                $query->where('user_id', $user->id);
            }

            $perPage = min((int) $request->get('per_page', 20), 100);
            $clients = $query->orderBy('nom')->orderBy('prenom')->paginate($perPage);

            return response()->json([
                'success' => true,
                'data' => ClientResource::collection($clients),
                'pagination' => [
                    'current_page' => $clients->currentPage(),
                    'last_page' => $clients->lastPage(),
                    'per_page' => $clients->perPage(),
                    'total' => $clients->total(),
                    'from' => $clients->firstItem(),
                    'to' => $clients->lastItem(),
                ],
                'message' => 'Liste des clients récupérée avec succès',
            ], 200, [], JSON_UNESCAPED_UNICODE);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des clients: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Obtenir le libellé du statut
     */
    private function getStatusLabel($status)
    {
        $statuses = [
            0 => 'En attente',
            1 => 'Validé',
            2 => 'Rejeté'
        ];

        return $statuses[$status] ?? 'Inconnu';
    }

    // Afficher un client
    public function show(Request $request, $id)
    {
        $query = Client::with(['user']);
        $this->scopeByCompany($query, $request);
        $client = $query->findOrFail($id);
        return response()->json([
            'success' => true,
            'data' => new ClientResource($client)
        ], 200);
    }

    // Créer un client
    public function store(Request $request)
    {
        try {
            $validated = $request->validate([
            'nom' => 'required|string|max:255',
            'prenom' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:clients',
            'contact' => 'required|string|max:255',
            'adresse' => 'required|string|max:255',
            'nom_entreprise' => 'required|string|max:255',
            'numero_contribuable' => 'nullable|string|max:255',
            'ninea' => 'nullable|string|size:9|regex:/^\d{9}$/',
            'situation_geographique' => 'required|string|max:255',
            'status' => 'nullable|integer|in:0,1,2'
        ]);

        $client = new Client($validated);
        $client->user_id = $request->user()->id;
        $client->status = $validated['status'] ?? 0; // toujours "en attente" par défaut
        $companyId = $this->effectiveCompanyId($request);
        if ($companyId !== null) {
            $client->company_id = $companyId;
        }
        $client->save();

        $client->load(['user']);

        // Notifier le patron lors de la création (seulement si le statut est "en attente")
        if ($client->status == 0) {
            $this->safeNotify(function () use ($client) {
                $client->load('user');
                $this->notificationService->notifyNewClient($client);
            });
        }

            return response()->json([
                'success' => true,
                'data' => new ClientResource($client),
                'message' => 'Client créé avec succès'
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
                'message' => 'Erreur lors de la création du client: ' . $e->getMessage()
            ], 500);
        }
    }

    // Mettre à jour un client
    public function update(Request $request, $id)
    {
        $client = Client::findOrFail($id);

        // Validation
        $request->validate([
            'nom' => 'required|string|max:255',
            'prenom' => 'required|string|max:255',
            'email' => 'required|email|unique:clients,email,' . $client->id,
            'contact' => 'required|string|max:255',
            'adresse' => 'required|string|max:255',
            'nom_entreprise' => 'required|string|max:255',
            'numero_contribuable' => 'nullable|string|max:255',
            'ninea' => 'nullable|string|size:9|regex:/^\d{9}$/',
            'situation_geographique' => 'required|string|max:255',
        ]);

        $data = $request->all();
        if ($this->effectiveCompanyId($request) !== null) {
            $data['company_id'] = $this->effectiveCompanyId($request);
        }
        $client->update($data);
        $client->load(['user']);

        return response()->json([
            'success' => true,
            'data' => new ClientResource($client),
            'message' => 'Client mis à jour avec succès'
        ], 200);
    }

    // Supprimer un client
    public function destroy(Request $request, $id)
    {
        $query = Client::query();
        $this->scopeByCompany($query, $request);
        $client = $query->findOrFail($id);
        $client->delete();
        return response()->json([
            'success' => true,
            'message' => 'Client supprimé avec succès'
        ], 200);
    }

    // Valider un client (patron)
    public function approve(Request $request, $id)
    {
        $query = Client::query();
        $this->scopeByCompany($query, $request);
        $client = $query->findOrFail($id);
        $client->status = 1; // validé
        $client->save();
        $client->load(['user']);

        // Notifier l'auteur du client (seulement si ce n'est pas le patron qui a créé le client)
        $clientName = $client->nom_entreprise ?? ($client->nom . ' ' . $client->prenom);
        
        // Vérifier que le client a un user_id et que ce n'est pas le patron
        if ($client->user_id) {
            $submitter = \App\Models\User::find($client->user_id);
            $approver = \App\Models\User::where('role', 6)->first(); // Patron
            
            // Ne notifier que si le soumetteur est différent du patron
            if ($submitter && $approver && $submitter->id !== $approver->id) {
                $this->safeNotify(function () use ($client) {
                    $client->load('user');
                    $this->notificationService->notifyClientValidated($client);
                });
            } else {
                \Log::info("Pas de notification d'approbation : le patron a créé le client lui-même", [
                    'client_id' => $client->id,
                    'user_id' => $client->user_id
                ]);
            }
        } else {
            \Log::warning("Client sans user_id, impossible de notifier l'auteur", [
                'client_id' => $client->id
            ]);
        }

        return response()->json([
            'success' => true,
            'data' => new ClientResource($client),
            'message' => 'Client validé avec succès'
        ], 200);
    }

    // Rejeter un client (patron)
    public function reject(Request $request, $id)
    {
        $query = Client::query();
        $this->scopeByCompany($query, $request);
        $client = $query->findOrFail($id);
        $client->status = 2; // rejeté
        $client->commentaire = $request->commentaire;
        $client->save();
        $client->load(['user']);

        // Notifier l'auteur du client
        $this->safeNotify(function () use ($client) {
            $client->load('user');
            $this->notificationService->notifyClientRejected($client);
        });

        return response()->json([
            'success' => true,
            'data' => new ClientResource($client),
            'message' => 'Client rejeté avec succès'
        ], 200);
    }

    // Statistiques des clients
    public function stats(Request $request)
    {
        $user = $request->user();
        $dateKey = Carbon::now()->format('Y-m-d');
        $cacheKey = $user->role == 2 ? "client_stats:{$dateKey}:{$user->id}" : "client_stats:{$dateKey}";

        $data = $this->rememberDailyStats($cacheKey, $dateKey, function () use ($user, $request) {
            $query = Client::with(['user']);

            // Si commercial → filtre uniquement ses clients
            if ($user->role == 2) { // 2 = commercial
                $query->where('user_id', $user->id);
            }
            $this->scopeByCompany($query, $request);

            $totalClients = $query->count();
            $clientsEnAttente = $query->where('status', 0)->count();
            $clientsValides = $query->where('status', 1)->count();
            $clientsRejetes = $query->where('status', 2)->count();

            // Statistiques par mois (derniers 12 mois)
            $clientsParMois = $query->selectRaw('DATE_FORMAT(created_at, "%Y-%m") as mois, COUNT(*) as total')
                ->where('created_at', '>=', now()->subMonths(12))
                ->groupBy('mois')
                ->orderBy('mois')
                ->get();

            // Top 5 des situations géographiques
            $topSituations = $query->selectRaw('situation_geographique, COUNT(*) as total')
                ->groupBy('situation_geographique')
                ->orderBy('total', 'desc')
                ->limit(5)
                ->get();

            // Répartition par statut
            $repartitionStatuts = [
                'en_attente' => $clientsEnAttente,
                'valides' => $clientsValides,
                'rejetes' => $clientsRejetes
            ];

            return [
                'total_clients' => $totalClients,
                'repartition_statuts' => $repartitionStatuts,
                'clients_par_mois' => $clientsParMois,
                'top_situations_geographiques' => $topSituations,
                'taux_validation' => $totalClients > 0 ? round(($clientsValides / $totalClients) * 100, 2) : 0,
                'taux_rejet' => $totalClients > 0 ? round(($clientsRejetes / $totalClients) * 100, 2) : 0
            ];
        });

        return response()->json([
            'success' => true,
            'data' => $data
        ], 200);
    }
}
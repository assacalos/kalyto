<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\Controller;
use App\Services\NotificationService;
use App\Traits\ScopesByCompany;
use App\Traits\SendsNotifications;
use Illuminate\Http\Request;
use App\Models\Facture;
use App\Models\FactureItem;
use App\Models\Client;
use App\Models\User;
use App\Http\Resources\FactureResource;
use Illuminate\Support\Facades\Log;

class FactureController extends Controller
{
    use SendsNotifications;

    protected $notificationService;

    public function __construct(NotificationService $notificationService)
    {
        $this->notificationService = $notificationService;
    }
    /**
     * Liste des factures
     * Accessible par tous les utilisateurs authentifiés
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
            
            // Eager loading pour éviter le N+1 (client avec facture, user/commercial)
            $query = Facture::with([
                'client:id,nom,prenom,email,adresse,nom_entreprise,ninea',
                'items:id,facture_id,description,quantity,unit_price,total_price,unit',
                'user:id,nom,prenom,email',
            ]);
            
            // Filtrage par status si fourni
            if ($request->has('status')) {
                $query->where('status', $request->status);
            }
            
            // Filtrage par client_id si fourni
            if ($request->has('client_id')) {
                $query->where('client_id', $request->client_id);
            }
            
            // Filtrage par commercial_id si fourni
            if ($request->has('commercial_id')) {
                $query->where('user_id', $request->commercial_id);
            }
            
            // Filtrage par date de début (start_date ou date_debut)
            if ($request->has('start_date') || $request->has('date_debut')) {
                $date = $request->start_date ?? $request->date_debut;
                $query->where('date_facture', '>=', $date);
            }
            
            // Filtrage par date de fin (end_date ou date_fin)
            if ($request->has('end_date') || $request->has('date_fin')) {
                $date = $request->end_date ?? $request->date_fin;
                $query->where('date_facture', '<=', $date);
            }
            
            // Si commercial → filtre ses propres factures
            if ($user->isCommercial()) {
                $query->where('user_id', $user->id);
            }

            $this->scopeByCompany($query, $request);
            
            // Pagination : 20 par défaut, max 100 par page
            $perPage = min((int) $request->get('per_page', 20), 100);
            $factures = $query->orderBy('created_at', 'desc')->paginate($perPage);
            
            return response()->json([
                'success' => true,
                'data' => FactureResource::collection($factures),
                'pagination' => [
                    'current_page' => $factures->currentPage(),
                    'last_page' => $factures->lastPage(),
                    'per_page' => $factures->perPage(),
                    'total' => $factures->total(),
                    'from' => $factures->firstItem(),
                    'to' => $factures->lastItem(),
                ],
                'message' => 'Liste des factures récupérée avec succès',
            ], 200, [], JSON_UNESCAPED_UNICODE);
            
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des factures: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Détails d'une facture
     * Accessible par tous les utilisateurs authentifiés
     */
    public function show(Request $request, $id)
    {
        $query = Facture::with(['client', 'items', 'user', 'paiements', 'validator', 'rejector']);
        $this->scopeByCompany($query, $request);
        $facture = $query->findOrFail($id);
        
        // Vérification des permissions pour les commerciaux
        if (auth()->user()->isCommercial() && $facture->user_id !== auth()->id()) {
            return response()->json([
                'success' => false,
                'message' => 'Accès refusé à cette facture'
            ], 403);
        }
        
        return response()->json([
            'success' => true,
            'data' => new FactureResource($facture),
            'message' => 'Facture récupérée avec succès'
        ]);
    }

    /**
     * Créer une facture
     * Accessible par Comptable et Admin
     * Accepte les données du frontend avec items, subtotal, tax_rate, etc.
     */
    public function store(Request $request)
    {
        $request->validate([
            'client_id' => 'required|exists:clients,id',
            'invoice_date' => 'required|date',
            'due_date' => 'required|date',
            'subtotal' => 'required|numeric|min:0',
            'tax_rate' => 'required|numeric|min:0|max:100',
            'tax_amount' => 'required|numeric|min:0',
            'total_amount' => 'required|numeric|min:0',
            'items' => 'required|array|min:1',
            'items.*.description' => 'required|string',
            'items.*.quantity' => 'required|integer|min:1',
            'items.*.unit_price' => 'required|numeric|min:0',
            'items.*.total_price' => 'required|numeric|min:0',
            'items.*.unit' => 'nullable|string',
            'notes' => 'nullable|string',
            'terms' => 'nullable|string',
            'numero_facture' => 'nullable|string|unique:factures,numero_facture'
        ]);

        // Génération automatique du numéro de facture si non fourni
        $numeroFacture = $request->numero_facture;
        if (!$numeroFacture) {
            $numeroFacture = $this->generateInvoiceNumber();
        }

        // Création de la facture
        $data = [
            'client_id' => $request->client_id,
            'numero_facture' => $numeroFacture,
            'date_facture' => $request->invoice_date,
            'date_echeance' => $request->due_date,
            'montant_ht' => $request->subtotal,
            'tva' => $request->tax_rate,
            'montant_ttc' => $request->total_amount,
            'status' => 'en_attente',
            'notes' => $request->notes,
            'terms' => $request->terms,
            'user_id' => $request->user_id ?? auth()->id()
        ];
        if ($this->effectiveCompanyId($request) !== null) {
            $data['company_id'] = $this->effectiveCompanyId($request);
        }
        $facture = Facture::create($data);

        // Création des items de la facture
        foreach ($request->items as $item) {
            FactureItem::create([
                'facture_id' => $facture->id,
                'description' => $item['description'],
                'quantity' => $item['quantity'],
                'unit_price' => $item['unit_price'],
                'total_price' => $item['total_price'],
                'unit' => $item['unit'] ?? null
            ]);
        }

        // Charger la facture avec ses relations
        $facture->load('client', 'items', 'user', 'validator', 'rejector');

        // Notifier le patron lors de la création
        $this->safeNotify(function () use ($facture) {
            $this->notificationService->notifyNewFacture($facture);
        });

        return response()->json([
            'success' => true,
            'data' => new FactureResource($facture),
            'message' => 'Facture créée avec succès'
        ], 201);
    }

    /**
     * Générer un numéro de facture automatique
     */
    private function generateInvoiceNumber()
    {
        $year = date('Y');
        
        // Trouver toutes les factures de l'année avec le format FAC-YYYY-XXXX
        $invoices = Facture::whereYear('created_at', $year)
            ->where('numero_facture', 'like', 'FAC-' . $year . '-%')
            ->get();
        
        $maxNumber = 0;
        foreach ($invoices as $invoice) {
            if (preg_match('/FAC-\d{4}-(\d+)$/', $invoice->numero_facture, $matches)) {
                $num = (int) $matches[1];
                if ($num > $maxNumber) {
                    $maxNumber = $num;
                }
            }
        }
        
        $number = $maxNumber + 1;
        
        return 'FAC-' . $year . '-' . str_pad($number, 4, '0', STR_PAD_LEFT);
    }

    /**
     * Formater une facture pour le frontend
     */
    private function formatFactureForFrontend($facture)
    {
        $client = $facture->client;
        $user = $facture->user;

        return [
            'id' => $facture->id,
            'invoice_number' => $facture->numero_facture,
            'client_id' => $facture->client_id,
            'nom' => $client ? ($client->nomEntreprise ?? ($client->nom . ' ' . $client->prenom)) : '',
            'email' => $client->email ?? '',
            'adresse' => $client->adresse ?? '',
            'user_id' => $facture->user_id,
            'commercial_name' => $user ? ($user->nom . ' ' . $user->prenom) : '',
            'invoice_date' => $facture->date_facture->format('Y-m-d'),
            'due_date' => $facture->date_echeance->format('Y-m-d'),
            'status' => $facture->status,
            'subtotal' => (float) $facture->montant_ht,
            'tax_rate' => (float) $facture->tva,
            'tax_amount' => (float) ($facture->montant_ttc - $facture->montant_ht),
            'total_amount' => (float) $facture->montant_ttc,
            'currency' => 'fcfa',
            'notes' => $facture->notes,
            'terms' => $facture->terms,
            'items' => $facture->items->map(function ($item) {
                return [
                    'id' => $item->id,
                    'description' => $item->description,
                    'quantity' => $item->quantity,
                    'unit_price' => (float) $item->unit_price,
                    'total_price' => (float) $item->total_price,
                    'unit' => $item->unit
                ];
            }),
            'created_at' => $facture->created_at->toDateTimeString(),
            'updated_at' => $facture->updated_at->toDateTimeString()
        ];
    }

    /**
     * Modifier une facture
     * Accessible par Comptable et Admin
     */
    public function update(Request $request, $id)
    {
        $facture = Facture::findOrFail($id);
        
        // Vérification que la facture peut être modifiée
        if ($facture->status === 'payee') {
            return response()->json([
                'success' => false,
                'message' => 'Impossible de modifier une facture payée'
            ], 400);
        }

        $request->validate([
            'numero_facture' => 'required|string|unique:factures,numero_facture,' . $facture->id,
            'montant' => 'required|numeric|min:0',
            'date_facture' => 'required|date',
            'description' => 'nullable|string',
            'status' => 'required|in:en_attente,payee,impayee'
        ]);

        $facture->update($request->all());

        return response()->json([
            'success' => true,
            'facture' => $facture,
            'message' => 'Facture modifiée avec succès'
        ]);
    }

    /**
     * Supprimer une facture
     * Accessible par Admin uniquement
     */
    public function destroy($id)
    {
        $facture = Facture::findOrFail($id);
        
        // Vérification que la facture peut être supprimée
        if ($facture->status === 'payee') {
            return response()->json([
                'success' => false,
                'message' => 'Impossible de supprimer une facture payée'
            ], 400);
        }
        
        $facture->delete();

        return response()->json([
            'success' => true,
            'message' => 'Facture supprimée avec succès'
        ]);
    }

    /**
     * Marquer une facture comme payée
     * Accessible par Comptable et Admin
     */
    public function markAsPaid($id)
    {
        $facture = Facture::findOrFail($id);
        
        if ($facture->status === 'payee') {
            return response()->json([
                'success' => false,
                'message' => 'Cette facture est déjà marquée comme payée'
            ], 400);
        }
        
        $facture->update(['status' => 'payee']);

        return response()->json([
            'success' => true,
            'facture' => $facture,
            'message' => 'Facture marquée comme payée'
        ]);
    }

    /**
     * Valider une facture par le patron
     * Accessible par Patron et Admin uniquement
     */
    public function validateFacture(Request $request, $id)
    {
        $facture = Facture::findOrFail($id);
        
        // Vérification que la facture est en attente de validation
        if ($facture->status !== 'en_attente') {
            return response()->json([
                'success' => false,
                'message' => 'Cette facture ne peut pas être validée dans son état actuel'
            ], 400);
        }
        
        $request->validate([
            'commentaire' => 'nullable|string|max:500'
        ]);
        
        $facture->update([
            'status' => 'valide',
            'validated_by' => auth()->id(),
            'validated_at' => now(),
            'validation_comment' => $request->commentaire ?? $request->comments
        ]);
        
        // Créer la notification pour l'auteur de la facture
        if ($facture->user_id) {
            $this->safeNotify(function () use ($facture) {
                $facture->load('user');
                $this->notificationService->notifyFactureValidated($facture);
            });
        }
        
        // Log de l'action
        \Log::info("Facture {$facture->numero_facture} validée par " . auth()->user()->nom);
        
        return response()->json([
            'success' => true,
            'facture' => $facture->fresh(),
            'message' => 'Facture validée avec succès'
        ]);
    }
    
    /**
     * Rejeter une facture par le patron
     * Accessible par Patron et Admin uniquement
     */
    public function reject(Request $request, $id)
    {
        $facture = Facture::findOrFail($id);
        
        // Vérification que la facture peut être rejetée
        if (!in_array($facture->status, ['en_attente', 'valide'])) {
            return response()->json([
                'success' => false,
                'message' => 'Cette facture ne peut pas être rejetée dans son état actuel'
            ], 400);
        }
        
        $request->validate([
            'raison_rejet' => 'nullable|string|max:500',
            'reason' => 'nullable|string|max:500',
            'commentaire' => 'nullable|string|max:500'
        ]);
        
        $reason = $request->raison_rejet ?? $request->reason ?? 'Aucune raison spécifiée';
        
        $facture->update([
            'status' => 'rejete',
            'rejected_by' => auth()->id(),
            'rejected_at' => now(),
            'rejection_reason' => $reason,
            'rejection_comment' => $request->commentaire
        ]);
        
        // Créer la notification pour l'auteur de la facture
        if ($facture->user_id) {
            $this->safeNotify(function () use ($facture, $reason) {
                $facture->load('user');
                $this->notificationService->notifyFactureRejected($facture, $reason);
            });
        }
        
        // Log de l'action
        \Log::info("Facture {$facture->numero_facture} rejetée par " . auth()->user()->nom . " - Raison: " . $reason);
        
        return response()->json([
            'success' => true,
            'facture' => $facture->fresh(),
            'message' => 'Facture rejetée avec succès'
        ]);
    }
    
    /**
     * Annuler le rejet d'une facture (remettre en attente)
     * Accessible par Patron et Admin uniquement
     */
    public function cancelRejection(Request $request, $id)
    {
        $facture = Facture::findOrFail($id);
        
        if ($facture->status !== 'rejete') {
            return response()->json([
                'success' => false,
                'message' => 'Cette facture n\'est pas rejetée'
            ], 400);
        }
        
        $facture->update([
            'status' => 'en_attente',
            'rejected_by' => null,
            'rejected_at' => null,
            'rejection_reason' => null,
            'rejection_comment' => null
        ]);
        
        // Log de l'action
        \Log::info("Rejet de la facture {$facture->numero_facture} annulé par " . auth()->user()->nom);
        
        return response()->json([
            'success' => true,
            'facture' => $facture->fresh(),
            'message' => 'Rejet de la facture annulé avec succès'
        ]);
    }
    
    /**
     * Obtenir l'historique des validations/rejets d'une facture
     * Accessible par Patron et Admin uniquement
     */
    public function validationHistory($id)
    {
        $facture = Facture::with(['client'])->findOrFail($id);
        
        $history = [];
        
        if ($facture->validated_by) {
            $validator = \App\Models\User::find($facture->validated_by);
            $history[] = [
                'action' => 'validated',
                'user' => $validator ? $validator->nom . ' ' . $validator->prenom : 'Utilisateur supprimé',
                'date' => $facture->validated_at,
                'comment' => $facture->validation_comment
            ];
        }
        
        if ($facture->rejected_by) {
            $rejector = \App\Models\User::find($facture->rejected_by);
            $history[] = [
                'action' => 'rejected',
                'user' => $rejector ? $rejector->nom . ' ' . $rejector->prenom : 'Utilisateur supprimé',
                'date' => $facture->rejected_at,
                'reason' => $facture->rejection_reason,
                'comment' => $facture->rejection_comment
            ];
        }
        
        return response()->json([
            'success' => true,
            'facture' => $facture,
            'history' => $history,
            'message' => 'Historique récupéré avec succès'
        ]);
    }
    
    /**
     * Rapports financiers
     * Accessible par Comptable, Patron et Admin
     */
    public function reports(Request $request)
    {
        $query = Facture::query();
        
        // Filtrage par période
        if ($request->has('date_debut')) {
            $query->where('date_facture', '>=', $request->date_debut);
        }
        
        if ($request->has('date_fin')) {
            $query->where('date_facture', '<=', $request->date_fin);
        }
        
        $factures = $query->get();
        
        $rapport = [
            'total_factures' => $factures->count(),
            'montant_total' => $factures->sum('montant_ttc'),
            'montant_total_ht' => $factures->sum('montant_ht'),
            'factures_en_attente' => $factures->where('status', 'en_attente')->count(),
            'montant_en_attente' => $factures->where('status', 'en_attente')->sum('montant_ttc'),
            'factures_validees' => $factures->where('status', 'valide')->count(),
            'montant_valide' => $factures->where('status', 'valide')->sum('montant_ttc'),
            'factures_rejetees' => $factures->where('status', 'rejete')->count(),
            'montant_rejete' => $factures->where('status', 'rejete')->sum('montant_ttc')
        ];
        
        return response()->json([
            'success' => true,
            'rapport' => $rapport,
            'message' => 'Rapport financier généré avec succès'
        ]);
    }
    
    /**
     * Compteur de factures avec filtres
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
                'status' => 'nullable|string',
                'start_date' => 'nullable|date',
                'end_date' => 'nullable|date|after_or_equal:start_date',
                'client_id' => 'nullable|integer|exists:clients,id',
                'commercial_id' => 'nullable|integer|exists:users,id',
            ]);
            
            $query = Facture::query();
            
            // Filtre par statut
            if (isset($validated['status'])) {
                $query->where('status', $validated['status']);
            }
            
            // Filtres de date
            if (isset($validated['start_date'])) {
                $query->whereDate('date_facture', '>=', $validated['start_date']);
            }
            if (isset($validated['end_date'])) {
                $query->whereDate('date_facture', '<=', $validated['end_date']);
            }
            
            // Filtre par client_id
            if (isset($validated['client_id'])) {
                $query->where('client_id', $validated['client_id']);
            }
            
            // Filtre par commercial_id
            if (isset($validated['commercial_id'])) {
                $query->where('user_id', $validated['commercial_id']);
            }
            
            // Si commercial → filtre ses propres factures
            if ($user->isCommercial()) {
                $query->where('user_id', $user->id);
            }
            
            return response()->json([
                'success' => true,
                'count' => $query->count(),
            ], 200);
            
        } catch (\Exception $e) {
            \Log::error('FactureController::count - Erreur', [
                'message' => $e->getMessage(),
            ]);
            
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du comptage: ' . $e->getMessage(),
            ], 500);
        }
    }
    
    /**
     * Statistiques agrégées des factures
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
                'status' => 'nullable|string',
                'start_date' => 'nullable|date',
                'end_date' => 'nullable|date|after_or_equal:start_date',
                'commercial_id' => 'nullable|integer|exists:users,id',
            ]);
            
            $query = Facture::query();
            
            // Filtres de date
            if (isset($validated['start_date'])) {
                $query->whereDate('date_facture', '>=', $validated['start_date']);
            }
            if (isset($validated['end_date'])) {
                $query->whereDate('date_facture', '<=', $validated['end_date']);
            }
            
            // Filtre par statut
            if (isset($validated['status'])) {
                $query->where('status', $validated['status']);
            }
            
            // Filtre par commercial_id
            if (isset($validated['commercial_id'])) {
                $query->where('user_id', $validated['commercial_id']);
            }
            
            // Si commercial → filtre ses propres factures
            if ($user->isCommercial()) {
                $query->where('user_id', $user->id);
            }
            
            return response()->json([
                'success' => true,
                'data' => [
                    'count' => $query->count(),
                    'total_amount' => $query->sum('montant_ttc'),
                    'average_amount' => $query->avg('montant_ttc'),
                    'min_amount' => $query->min('montant_ttc'),
                    'max_amount' => $query->max('montant_ttc'),
                    'total_ht' => $query->sum('montant_ht'),
                ],
            ], 200);
            
        } catch (\Exception $e) {
            \Log::error('FactureController::stats - Erreur', [
                'message' => $e->getMessage(),
            ]);
            
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des statistiques: ' . $e->getMessage(),
            ], 500);
        }
    }
}
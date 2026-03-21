<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\Controller;
use App\Services\NotificationService;
use App\Traits\ScopesByCompany;
use App\Traits\SendsNotifications;
use Illuminate\Http\Request;
use App\Models\Paiement;
use App\Models\Facture;
use App\Models\Client;
use App\Models\PaymentSchedule;
use App\Http\Resources\PaiementResource;
use Illuminate\Support\Facades\Log;

class PaiementController extends Controller
{
    use ScopesByCompany, SendsNotifications;

    protected $notificationService;

    public function __construct(NotificationService $notificationService)
    {
        $this->notificationService = $notificationService;
    }
    /**
     * Liste des paiements
     * Accessible par Comptable, Patron et Admin
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
            
            $query = Paiement::with(['client', 'comptable', 'facture', 'schedule']);
            
            // Filtrage par statut si fourni
            if ($request->has('status')) {
                $query->where('status', $request->status);
            }
            
            // Filtrage par type
            if ($request->has('type')) {
                $query->where('type', $request->type);
            }
            
            // Filtrage par client_id
            if ($request->has('client_id')) {
                $query->where('client_id', $request->client_id);
            }
            
            // Filtrage par comptable_id
            if ($request->has('comptable_id')) {
                $query->where('comptable_id', $request->comptable_id);
            }
            
            // Filtrage par date (support start_date/end_date du frontend et date_debut/date_fin)
            if ($request->has('start_date') || $request->has('date_debut')) {
                $date = $request->start_date ?? $request->date_debut;
                $query->where('date_paiement', '>=', $date);
            }
            
            if ($request->has('end_date') || $request->has('date_fin')) {
                $date = $request->end_date ?? $request->date_fin;
                $query->where('date_paiement', '<=', $date);
            }
            
            // Si comptable → filtre ses propres paiements
            if ($user->isComptable()) {
                $query->where('comptable_id', $user->id);
            }

            $this->scopeByCompany($query, $request);
            
            $perPage = min((int) $request->get('per_page', 20), 100);
            $paiements = $query->orderBy('created_at', 'desc')->paginate($perPage);
            
            return response()->json([
                'success' => true,
                'data' => PaiementResource::collection($paiements),
                'pagination' => [
                    'current_page' => $paiements->currentPage(),
                    'last_page' => $paiements->lastPage(),
                    'per_page' => $paiements->perPage(),
                    'total' => $paiements->total(),
                    'from' => $paiements->firstItem(),
                    'to' => $paiements->lastItem(),
                ],
                'message' => 'Liste des paiements récupérée avec succès',
            ], 200, [], JSON_UNESCAPED_UNICODE);
            
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des paiements: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Détails d'un paiement
     * Accessible par Comptable, Patron et Admin
     */
    public function show(Request $request, $id)
    {
        $query = Paiement::with(['client', 'comptable', 'facture', 'schedule', 'user']);
        $this->scopeByCompany($query, $request);
        $paiement = $query->findOrFail($id);
        
        // Vérification des permissions pour les comptables
        if (auth()->user()->isComptable() && $paiement->comptable_id !== auth()->id()) {
            return response()->json([
                'success' => false,
                'message' => 'Accès refusé à ce paiement'
            ], 403);
        }
        
        return response()->json([
            'success' => true,
            'data' => new PaiementResource($paiement),
            'message' => 'Paiement récupéré avec succès'
        ]);
    }

    /**
     * Créer un paiement
     * Accessible par Comptable et Admin
     * Accepte les données du frontend (payment_date, amount, payment_method, etc.)
     */
    public function store(Request $request)
    {
        try {
            // Accepter les noms de champs du frontend ET du backend pour compatibilité
            $validated = $request->validate([
                // Format frontend
                'client_id' => 'nullable|integer|exists:clients,id',
                'client_name' => 'required_without:facture_id|string|max:255',
                'client_email' => 'nullable|email|max:255',
                'client_address' => 'nullable|string',
                'comptable_id' => 'required|integer|exists:users,id',
                'comptable_name' => 'required|string|max:255',
                'type' => 'required|in:one_time,monthly',
                'payment_date' => 'required_without:date_paiement|date',
                'due_date' => 'nullable|date',
                'amount' => 'required_without:montant|numeric|min:0.01',
                'payment_method' => 'required_without:type_paiement|in:bank_transfer,check,cash,card,direct_debit,virement,especes,cheque,carte_bancaire,mobile_money',
                'currency' => 'nullable|string|max:4',
                'description' => 'nullable|string',
                'notes' => 'nullable|string',
                'reference' => 'nullable|string|max:255',
                'schedule' => 'nullable|array',
                // Format backend (pour compatibilité)
                'facture_id' => 'nullable|exists:factures,id',
                'montant' => 'required_without:amount|numeric|min:0.01',
                'date_paiement' => 'required_without:payment_date|date',
                'type_paiement' => 'required_without:payment_method|in:especes,cheque,virement,carte_bancaire,mobile_money',
                'commentaire' => 'nullable|string'
            ]);

            // Mapper les noms de champs du frontend vers le backend
            $clientId = $validated['client_id'] ?? null;
            $clientName = $validated['client_name'] ?? null;
            $clientEmail = $validated['client_email'] ?? null;
            $clientAddress = $validated['client_address'] ?? null;
            
            // Si client_id est fourni, récupérer les infos du client
            if ($clientId) {
                $client = Client::find($clientId);
                if ($client) {
                    $clientName = $clientName ?? (trim(($client->nom ?? '') . ' ' . ($client->prenom ?? '')));
                    $clientEmail = $clientEmail ?? ($client->email ?? '');
                    $clientAddress = $clientAddress ?? ($client->adresse ?? '');
                }
            }
            
            // Mapper payment_method du frontend vers type_paiement du backend
            $paymentMethodMapping = [
                'bank_transfer' => 'virement',
                'check' => 'cheque',
                'cash' => 'especes',
                'card' => 'carte_bancaire',
                'direct_debit' => 'virement'
            ];
            $typePaiement = $validated['payment_method'] ?? $validated['type_paiement'] ?? 'virement';
            if (isset($paymentMethodMapping[$typePaiement])) {
                $typePaiement = $paymentMethodMapping[$typePaiement];
            }

            // Gérer le comptable_name de manière sécurisée
            $comptableName = $validated['comptable_name'] ?? null;
            if (!$comptableName) {
                $user = auth()->user();
                $comptableName = trim(($user->nom ?? '') . ' ' . ($user->prenom ?? ''));
            }

            // Convertir la date si nécessaire (format ISO vers date Laravel)
            $paymentDate = $validated['payment_date'] ?? $validated['date_paiement'] ?? now();
            if (is_string($paymentDate)) {
                try {
                    $paymentDate = \Carbon\Carbon::parse($paymentDate)->format('Y-m-d');
                } catch (\Exception $e) {
                    $paymentDate = now()->format('Y-m-d');
                }
            }

            $dueDate = $validated['due_date'] ?? null;
            if ($dueDate && is_string($dueDate)) {
                try {
                    $dueDate = \Carbon\Carbon::parse($dueDate)->format('Y-m-d');
                } catch (\Exception $e) {
                    $dueDate = null;
                }
            }

            // Créer le paiement
            $paiement = Paiement::create([
                'payment_number' => Paiement::generatePaymentNumber(),
                'type' => $validated['type'] ?? 'one_time',
                'facture_id' => $validated['facture_id'] ?? null,
                'client_id' => $clientId,
                'client_name' => $clientName,
                'client_email' => $clientEmail ?? null,
                'client_address' => $clientAddress ?? null,
                'comptable_id' => $validated['comptable_id'] ?? auth()->id(),
                'comptable_name' => $comptableName,
                'date_paiement' => $paymentDate,
                'due_date' => $dueDate,
                'montant' => $validated['amount'] ?? $validated['montant'],
                'currency' => $validated['currency'] ?? 'FCFA',
                'type_paiement' => $typePaiement,
                'status' => 'draft',
                'description' => $validated['description'] ?? null,
                'notes' => $validated['notes'] ?? $validated['commentaire'] ?? null,
                'commentaire' => $validated['commentaire'] ?? null,
                'reference' => $validated['reference'] ?? null,
                'user_id' => auth()->id()
            ]);

            // Si c'est un paiement mensuel avec schedule, créer le schedule
            if (($validated['type'] ?? 'one_time') === 'monthly' && isset($validated['schedule'])) {
                $scheduleData = $validated['schedule'];
                
                // Parser les dates du schedule (format ISO vers Y-m-d)
                $scheduleStartDate = $scheduleData['start_date'] ?? $paiement->date_paiement;
                if (is_string($scheduleStartDate)) {
                    try {
                        $scheduleStartDate = \Carbon\Carbon::parse($scheduleStartDate)->format('Y-m-d');
                    } catch (\Exception $e) {
                        $scheduleStartDate = $paiement->date_paiement;
                    }
                }
                
                $scheduleEndDate = $scheduleData['end_date'] ?? null;
                if ($scheduleEndDate && is_string($scheduleEndDate)) {
                    try {
                        $scheduleEndDate = \Carbon\Carbon::parse($scheduleEndDate)->format('Y-m-d');
                    } catch (\Exception $e) {
                        $scheduleEndDate = null;
                    }
                }
                
                // Calculer le montant de l'échéance et l'arrondir à 2 décimales
                $totalInstallments = $scheduleData['total_installments'] ?? 12;
                $installmentAmount = $scheduleData['installment_amount'] ?? ($paiement->montant / $totalInstallments);
                $installmentAmount = round($installmentAmount, 2);
                
                PaymentSchedule::create([
                    'payment_id' => $paiement->id,
                    'start_date' => $scheduleStartDate,
                    'end_date' => $scheduleEndDate,
                    'frequency' => $scheduleData['frequency'] ?? 30,
                    'total_installments' => $totalInstallments,
                    'paid_installments' => 0,
                    'installment_amount' => $installmentAmount,
                    'status' => 'active',
                    'created_by' => $scheduleData['created_by'] ?? auth()->id()
                ]);
            }

            // Charger les relations
            $paiement->load('client', 'comptable', 'schedule', 'facture', 'user');

            return response()->json([
                'success' => true,
                'data' => new PaiementResource($paiement),
                'message' => 'Paiement créé avec succès'
            ], 201);

        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur de validation',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            \Log::error('Erreur lors de la création du paiement: ' . $e->getMessage(), [
                'trace' => $e->getTraceAsString(),
                'request' => $request->all()
            ]);
            
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la création du paiement: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Formater un paiement pour le frontend
     */
    private function formatPaymentForFrontend($payment)
    {
        // Mapper type_paiement du backend vers payment_method du frontend
        $paymentMethodMapping = [
            'virement' => 'bank_transfer',
            'cheque' => 'check',
            'especes' => 'cash',
            'carte_bancaire' => 'card',
            'mobile_money' => 'direct_debit'
        ];
        $paymentMethod = $paymentMethodMapping[$payment->type_paiement] ?? $payment->type_paiement;

        $formatted = [
            'id' => $payment->id,
            'payment_number' => $payment->payment_number ?? 'N/A',
            'type' => $payment->type ?? 'one_time',
            'client_id' => $payment->client_id ?? 0,
            'client_name' => $payment->client_name ?? ($payment->client ? ($payment->client->nomEntreprise ?? ($payment->client->nom . ' ' . ($payment->client->prenom ?? ''))) : 'Client inconnu'),
            'client_email' => $payment->client_email ?? ($payment->client ? $payment->client->email : ''),
            'client_address' => $payment->client_address ?? ($payment->client ? $payment->client->adresse : ''),
            'comptable_id' => $payment->comptable_id ?? $payment->user_id ?? 0,
            'comptable_name' => $payment->comptable_name ?? ($payment->comptable ? ($payment->comptable->nom . ' ' . ($payment->comptable->prenom ?? '')) : ($payment->user ? ($payment->user->nom . ' ' . ($payment->user->prenom ?? '')) : 'Comptable inconnu')),
            'payment_date' => $payment->date_paiement ? $payment->date_paiement->format('Y-m-d') : null,
            'due_date' => $payment->due_date ? $payment->due_date->format('Y-m-d') : null,
            'status' => $payment->status ?? 'draft',
            'amount' => (float)($payment->montant ?? 0),
            'currency' => $payment->currency ?? 'FCFA',
            'payment_method' => $paymentMethod,
            'description' => $payment->description ?? '',
            'notes' => $payment->notes ?? $payment->commentaire ?? '',
            'reference' => $payment->reference ?? '',
            'submitted_at' => $payment->submitted_at ? $payment->submitted_at->format('Y-m-d H:i:s') : null,
            'approved_at' => $payment->approved_at ? $payment->approved_at->format('Y-m-d H:i:s') : null,
            'paid_at' => $payment->paid_at ? $payment->paid_at->format('Y-m-d H:i:s') : null,
            'created_at' => $payment->created_at ? $payment->created_at->format('Y-m-d H:i:s') : null,
            'updated_at' => $payment->updated_at ? $payment->updated_at->format('Y-m-d H:i:s') : null,
        ];

        // Ajouter le schedule si existe
        if ($payment->schedule) {
            $formatted['schedule'] = [
                'id' => $payment->schedule->id,
                'start_date' => $payment->schedule->start_date ? $payment->schedule->start_date->format('Y-m-d') : null,
                'end_date' => $payment->schedule->end_date ? $payment->schedule->end_date->format('Y-m-d') : null,
                'frequency' => $payment->schedule->frequency ?? 30,
                'total_installments' => $payment->schedule->total_installments ?? 12,
                'paid_installments' => $payment->schedule->paid_installments ?? 0,
                'installment_amount' => (float)($payment->schedule->installment_amount ?? 0),
                'status' => $payment->schedule->status ?? 'active',
                'next_payment_date' => $payment->schedule->next_payment_date ? $payment->schedule->next_payment_date->format('Y-m-d') : null,
            ];
        }

        return $formatted;
    }

    /**
     * Modifier un paiement
     * Accessible par Comptable et Admin
     */
    public function update(Request $request, $id)
    {
        $paiement = Paiement::findOrFail($id);
        
        // Vérifier que le paiement peut être modifié
        if ($paiement->statut === 'valide') {
            return response()->json([
                'success' => false,
                'message' => 'Impossible de modifier un paiement validé'
            ], 400);
        }

        $request->validate([
            'montant' => 'required|numeric|min:0.01',
            'date_paiement' => 'required|date',
            'mode_paiement' => 'required|in:especes,cheque,virement,carte_bancaire',
            'reference' => 'nullable|string|max:255',
            'statut' => 'required|in:en_attente,valide,rejete',
            'commentaire' => 'nullable|string'
        ]);

        $paiement->update($request->all());

        // Si le paiement est validé, marquer la facture comme payée
        if ($request->statut === 'valide') {
            $paiement->facture->update(['statut' => 'payee']);
        }

        return response()->json([
            'success' => true,
            'paiement' => $paiement,
            'message' => 'Paiement modifié avec succès'
        ]);
    }

    /**
     * Valider un paiement
     * Accessible par Comptable et Admin
     */
    public function validatePaiement(Request $request, $id)
    {
        try {
            $paiement = Paiement::findOrFail($id);
            
            // Vérifier que le paiement peut être validé
            if ($paiement->status === 'approved') {
                return response()->json([
                    'success' => false,
                    'message' => 'Ce paiement est déjà validé'
                ], 400);
            }

            // Si le paiement est en draft, le soumettre d'abord
            if ($paiement->status === 'draft') {
                $paiement->submit();
            }

            // Utiliser la méthode approve du modèle qui gère correctement la validation
            if ($paiement->approve(auth()->id(), $request->get('comment'))) {
                // Marquer la facture comme payée si elle existe
                if ($paiement->facture_id && $paiement->facture) {
                    $paiement->facture->update(['statut' => 'payee']);
                }

                // Notifier l'auteur du paiement
                if ($paiement->comptable_id) {
                    $this->safeNotify(function () use ($paiement) {
                        $paiement->load('comptable');
                        $this->notificationService->notifyPaiementValidated($paiement);
                    });
                }

                // Recharger le paiement avec ses relations
                $paiement->refresh();
                $paiement->load('client', 'comptable', 'facture', 'schedule');

                return response()->json([
                    'success' => true,
                    'data' => $this->formatPaymentForFrontend($paiement),
                    'message' => 'Paiement validé avec succès'
                ]);
            } else {
                return response()->json([
                    'success' => false,
                    'message' => 'Ce paiement ne peut pas être validé. Statut actuel: ' . $paiement->status
                ], 400);
            }
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la validation: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Rejeter un paiement
     * Accessible par Comptable et Admin
     */
    public function reject(Request $request, $id)
    {
        $request->validate([
            'commentaire' => 'nullable|string',
            'reason' => 'nullable|string', // Support pour compatibilité Flutter
            'comment' => 'nullable|string' // Support pour compatibilité Flutter
        ]);

        $paiement = Paiement::findOrFail($id);
        
        // Accepter reason, comment ou commentaire (compatibilité)
        $reason = $request->reason ?? $request->comment ?? $request->commentaire ?? 'Rejeté';
        $comment = $request->comment ?? $request->commentaire ?? null;

        // Utiliser la méthode du modèle si disponible
        if (method_exists($paiement, 'reject')) {
            if ($paiement->reject(auth()->id(), $reason, $comment)) {
                // Notifier le comptable
                if ($paiement->comptable_id) {
                    $this->safeNotify(function () use ($paiement, $reason) {
                        $paiement->load('comptable');
                        $this->notificationService->notifyPaiementRejected($paiement, $reason);
                    });
                }
                
                $paiement->load('client', 'comptable', 'schedule');
                return response()->json([
                    'success' => true,
                    'data' => $this->formatPaymentForFrontend($paiement),
                    'message' => 'Paiement rejeté avec succès'
                ]);
            }
        }

        // Fallback pour l'ancienne logique
        $paiement->update([
            'status' => 'rejected',
            'rejection_reason' => $reason,
            'rejection_comment' => $comment,
            'rejected_by' => auth()->id(),
            'rejected_at' => now()
        ]);

        // Notifier l'auteur du paiement
        if ($paiement->comptable_id) {
            $this->safeNotify(function () use ($paiement, $reason) {
                $paiement->load('comptable');
                $this->notificationService->notifyPaiementRejected($paiement, $reason);
            });
        }

        $paiement->load('client', 'comptable', 'schedule');
        return response()->json([
            'success' => true,
            'data' => $this->formatPaymentForFrontend($paiement),
            'message' => 'Paiement rejeté avec succès'
        ]);
    }

    /**
     * Supprimer un paiement
     * Accessible par Admin uniquement
     */
    public function destroy($id)
    {
        $paiement = Paiement::findOrFail($id);
        
        // Vérifier que le paiement peut être supprimé
        if ($paiement->statut === 'valide') {
            return response()->json([
                'success' => false,
                'message' => 'Impossible de supprimer un paiement validé'
            ], 400);
        }
        
        $paiement->delete();

        return response()->json([
            'success' => true,
            'message' => 'Paiement supprimé avec succès'
        ]);
    }

    /**
     * Rapports de paiements
     * Accessible par Comptable, Patron et Admin
     */
    public function reports(Request $request)
    {
        $query = Paiement::query();
        
        // Filtrage par période
        if ($request->has('date_debut')) {
            $query->where('date_paiement', '>=', $request->date_debut);
        }
        
        if ($request->has('date_fin')) {
            $query->where('date_paiement', '<=', $request->date_fin);
        }
        
        $paiements = $query->get();
        
        $rapport = [
            'total_paiements' => $paiements->count(),
            'montant_total' => $paiements->sum('montant'),
            'paiements_valides' => $paiements->where('statut', 'valide')->count(),
            'montant_valide' => $paiements->where('statut', 'valide')->sum('montant'),
            'paiements_en_attente' => $paiements->where('statut', 'en_attente')->count(),
            'montant_en_attente' => $paiements->where('statut', 'en_attente')->sum('montant'),
            'paiements_rejetes' => $paiements->where('statut', 'rejete')->count(),
            'montant_rejete' => $paiements->where('statut', 'rejete')->sum('montant'),
            'par_mode_paiement' => $paiements->groupBy('mode_paiement')->map(function($group) {
                return [
                    'count' => $group->count(),
                    'montant' => $group->sum('montant')
                ];
            })
        ];
        
        return response()->json([
            'success' => true,
            'rapport' => $rapport,
            'message' => 'Rapport de paiements généré avec succès'
        ]);
    }

    /**
     * Soumettre un paiement
     */
    public function submit($id)
    {
        $paiement = Paiement::findOrFail($id);

        if ($paiement->submit()) {
            // Notifier le patron
            $this->safeNotify(function () use ($paiement) {
                $this->notificationService->notifyNewPaiement($paiement);
            });

            return response()->json([
                'success' => true,
                'paiement' => $paiement,
                'message' => 'Paiement soumis avec succès'
            ]);
        }

        return response()->json([
            'success' => false,
            'message' => 'Impossible de soumettre ce paiement'
        ], 400);
    }

    /**
     * Approuver un paiement
     */
    public function approve(Request $request, $id)
    {
        $paiement = Paiement::findOrFail($id);

        $request->validate([
            'comment' => 'nullable|string',
            'comments' => 'nullable|string' // Support pour compatibilité Flutter
        ]);

        // Accepter comment ou comments (compatibilité)
        $comment = $request->comment ?? $request->comments;

        if ($paiement->approve(auth()->id(), $comment)) {
            // Notifier l'auteur du paiement (comptable)
            if ($paiement->comptable_id) {
                $this->safeNotify(function () use ($paiement) {
                    $paiement->load('comptable');
                    $this->notificationService->notifyPaiementValidated($paiement);
                });
            }

            return response()->json([
                'success' => true,
                'paiement' => $paiement,
                'message' => 'Paiement approuvé avec succès'
            ]);
        }

        return response()->json([
            'success' => false,
            'message' => 'Impossible d\'approuver ce paiement'
        ], 400);
    }

    /**
     * Marquer comme payé
     */
    public function markAsPaid(Request $request, $id)
    {
        $paiement = Paiement::findOrFail($id);

        // Accepter les paramètres optionnels du service Flutter
        $request->validate([
            'payment_reference' => 'nullable|string|max:255',
            'notes' => 'nullable|string'
        ]);

        if ($paiement->pay(auth()->id())) {
            // Mettre à jour les champs optionnels si fournis
            $updates = [];
            if ($request->has('payment_reference')) {
                $updates['reference'] = $request->payment_reference;
            }
            if ($request->has('notes')) {
                $updates['notes'] = $request->notes;
            }
            if (!empty($updates)) {
                $paiement->update($updates);
                $paiement->refresh();
            }

            // Charger les relations pour le formatage
            $paiement->load('client', 'comptable', 'schedule');

            return response()->json([
                'success' => true,
                'data' => $this->formatPaymentForFrontend($paiement),
                'message' => 'Paiement marqué comme payé avec succès'
            ]);
        }

        return response()->json([
            'success' => false,
            'message' => 'Impossible de marquer ce paiement comme payé'
        ], 400);
    }

    /**
     * Marquer comme en retard
     */
    public function markAsOverdue($id)
    {
        $paiement = Paiement::findOrFail($id);

        if ($paiement->markAsOverdue()) {
            return response()->json([
                'success' => true,
                'paiement' => $paiement,
                'message' => 'Paiement marqué comme en retard avec succès'
            ]);
        }

        return response()->json([
            'success' => false,
            'message' => 'Impossible de marquer ce paiement comme en retard'
        ], 400);
    }

    /**
     * Réactiver un paiement rejeté
     * Remet le paiement en statut draft pour permettre une nouvelle soumission
     */
    public function reactivate($id)
    {
        $paiement = Paiement::findOrFail($id);

        // Vérifier que le paiement est rejeté
        if ($paiement->status !== 'rejected' && $paiement->status !== 'rejete') {
            return response()->json([
                'success' => false,
                'message' => 'Seuls les paiements rejetés peuvent être réactivés'
            ], 400);
        }

        // Réactiver le paiement en le remettant en draft
        $paiement->update([
            'status' => 'draft',
            'rejected_by' => null,
            'rejected_at' => null,
            'rejection_reason' => null,
            'rejection_comment' => null
        ]);

        // Charger les relations pour le formatage
        $paiement->load('client', 'comptable', 'schedule');

        return response()->json([
            'success' => true,
            'data' => $this->formatPaymentForFrontend($paiement),
            'message' => 'Paiement réactivé avec succès'
        ]);
    }

    /**
     * Créer un paiement avec numéro automatique
     */
    public function createWithNumber(Request $request)
    {
        $request->validate([
            'facture_id' => 'required|exists:factures,id',
            'montant' => 'required|numeric|min:0.01',
            'date_paiement' => 'required|date',
            'due_date' => 'nullable|date|after:date_paiement',
            'type' => 'required|in:one_time,monthly',
            'type_paiement' => 'required|in:especes,virement,cheque,carte_bancaire,mobile_money',
            'currency' => 'nullable|string|max:3',
            'description' => 'nullable|string',
            'commentaire' => 'nullable|string',
            'reference' => 'nullable|string|max:255'
        ]);

        $paiement = Paiement::create([
            'payment_number' => Paiement::generatePaymentNumber(),
            'type' => $request->type,
            'facture_id' => $request->facture_id,
            'montant' => $request->montant,
            'date_paiement' => $request->date_paiement,
            'due_date' => $request->due_date,
            'currency' => $request->currency ?? 'FCFA',
            'type_paiement' => $request->type_paiement,
            'status' => 'draft',
            'description' => $request->description,
            'commentaire' => $request->commentaire,
            'reference' => $request->reference,
            'user_id' => auth()->id()
        ]);

        return response()->json([
            'success' => true,
            'paiement' => $paiement,
            'message' => 'Paiement créé avec succès'
        ], 201);
    }
    
    /**
     * Compteur de paiements avec filtres
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
                'comptable_id' => 'nullable|integer|exists:users,id',
            ]);
            
            $query = Paiement::query();
            
            // Filtre par statut
            if (isset($validated['status'])) {
                $query->where('status', $validated['status']);
            }
            
            // Filtres de date
            if (isset($validated['start_date'])) {
                $query->whereDate('date_paiement', '>=', $validated['start_date']);
            }
            if (isset($validated['end_date'])) {
                $query->whereDate('date_paiement', '<=', $validated['end_date']);
            }
            
            // Filtre par client_id
            if (isset($validated['client_id'])) {
                $query->where('client_id', $validated['client_id']);
            }
            
            // Filtre par comptable_id
            if (isset($validated['comptable_id'])) {
                $query->where('comptable_id', $validated['comptable_id']);
            }
            
            // Si comptable → filtre ses propres paiements
            if ($user->isComptable()) {
                $query->where('comptable_id', $user->id);
            }
            
            return response()->json([
                'success' => true,
                'count' => $query->count(),
            ], 200);
            
        } catch (\Exception $e) {
            \Log::error('PaiementController::count - Erreur', [
                'message' => $e->getMessage(),
            ]);
            
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du comptage: ' . $e->getMessage(),
            ], 500);
        }
    }
    
    /**
     * Statistiques agrégées des paiements
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
                'comptable_id' => 'nullable|integer|exists:users,id',
            ]);
            
            $query = Paiement::query();
            
            // Filtres de date
            if (isset($validated['start_date'])) {
                $query->whereDate('date_paiement', '>=', $validated['start_date']);
            }
            if (isset($validated['end_date'])) {
                $query->whereDate('date_paiement', '<=', $validated['end_date']);
            }
            
            // Filtre par statut
            if (isset($validated['status'])) {
                $query->where('status', $validated['status']);
            }
            
            // Filtre par comptable_id
            if (isset($validated['comptable_id'])) {
                $query->where('comptable_id', $validated['comptable_id']);
            }
            
            // Si comptable → filtre ses propres paiements
            if ($user->isComptable()) {
                $query->where('comptable_id', $user->id);
            }
            
            return response()->json([
                'success' => true,
                'data' => [
                    'count' => $query->count(),
                    'total_amount' => $query->sum('montant'),
                    'average_amount' => $query->avg('montant'),
                    'min_amount' => $query->min('montant'),
                    'max_amount' => $query->max('montant'),
                ],
            ], 200);
            
        } catch (\Exception $e) {
            \Log::error('PaiementController::stats - Erreur', [
                'message' => $e->getMessage(),
            ]);
            
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des statistiques: ' . $e->getMessage(),
            ], 500);
        }
    }
}
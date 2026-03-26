<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\Controller;
use App\Services\NotificationService;
use App\Traits\CachesData;
use App\Traits\SendsNotifications;
use App\Models\Intervention;
use App\Models\Equipment;
use App\Models\InterventionReport;
use App\Models\Client;
use App\Http\Resources\InterventionResource;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class InterventionController extends Controller
{
    use CachesData, SendsNotifications;

    protected $notificationService;

    public function __construct(NotificationService $notificationService)
    {
        $this->notificationService = $notificationService;
    }
    /**
     * Afficher la liste des interventions
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
            
            $query = Intervention::with(['creator', 'approver', 'client', 'reports.technician']);

            // Filtrage par statut
            if ($request->has('status')) {
                $query->where('status', $request->status);
            }

            // Filtrage par type
            if ($request->has('type')) {
                $query->where('type', $request->type);
            }

            // Filtrage par priorité
            if ($request->has('priority')) {
                $query->where('priority', $request->priority);
            }

            // Filtrage par créateur
            if ($request->has('created_by')) {
                $query->where('created_by', $request->created_by);
            }

            // Filtrage par date
            if ($request->has('date_debut')) {
                $query->where('scheduled_date', '>=', $request->date_debut);
            }

            if ($request->has('date_fin')) {
                $query->where('scheduled_date', '<=', $request->date_fin);
            }

            // Filtrage par lieu
            if ($request->has('location')) {
                $query->where('location', 'like', '%' . $request->location . '%');
            }

            // Si technicien → filtre ses interventions
            if ($user->isTechnicien()) {
                $query->where('created_by', $user->id);
            }

            $perPage = min((int) $request->get('per_page', 20), 100);
            $interventions = $query->orderBy('scheduled_date', 'desc')->paginate($perPage);

            return response()->json([
                'success' => true,
                'data' => InterventionResource::collection($interventions),
                'pagination' => [
                    'current_page' => $interventions->currentPage(),
                    'last_page' => $interventions->lastPage(),
                    'per_page' => $interventions->perPage(),
                    'total' => $interventions->total(),
                    'from' => $interventions->firstItem(),
                    'to' => $interventions->lastItem(),
                ],
                'message' => 'Liste des interventions récupérée avec succès',
            ], 200, [], JSON_UNESCAPED_UNICODE);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des interventions: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Afficher une intervention spécifique
     */
    public function show($id)
    {
        try {
            $intervention = Intervention::with(['creator', 'approver', 'client', 'reports.technician'])->find($id);

            if (!$intervention) {
                return response()->json([
                    'success' => false,
                    'message' => 'Intervention non trouvée'
                ], 404);
            }

            return response()->json([
                'success' => true,
                'data' => new InterventionResource($intervention),
                'message' => 'Intervention récupérée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération de l\'intervention: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Créer une nouvelle intervention
     */
    public function store(Request $request)
    {
        try {
            $validated = $request->validate([
                'title' => 'required|string|max:255',
                'description' => 'required|string',
                'type' => 'required|in:external,on_site',
                'priority' => 'required|in:low,medium,high,urgent',
                'scheduled_date' => 'required|date', // Retiré after:now pour permettre les dates passées
                'location' => 'nullable|string|max:255',
                // Accepter client_id (recommandé) ou client_name/client_phone/client_email (ancien format)
                'client_id' => 'nullable|integer|exists:clients,id',
                'client_name' => 'nullable|string|max:255',
                'client_phone' => 'nullable|string|max:20',
                'client_email' => 'nullable|email|max:255',
                'equipment' => 'nullable|string|max:255',
                'problem_description' => 'nullable|string',
                'estimated_duration' => 'nullable|numeric|min:0',
                'cost' => 'nullable|numeric|min:0',
                'notes' => 'nullable|string',
                'attachments' => 'nullable|array',
                // Ignorer les champs créés automatiquement par le backend
                'created_at' => 'nullable',
                'updated_at' => 'nullable',
                'created_by' => 'nullable',
            ]);

            DB::beginTransaction();

            // Si client_id est fourni, récupérer les infos du client et remplir automatiquement
            $clientId = $validated['client_id'] ?? null;
            $clientName = $validated['client_name'] ?? null;
            $clientPhone = $validated['client_phone'] ?? null;
            $clientEmail = $validated['client_email'] ?? null;

            if ($clientId) {
                $client = Client::find($clientId);
                if ($client) {
                    // Utiliser les infos du client existant pour remplir les champs texte
                    $clientName = $client->nom . ' ' . ($client->prenom ?? '');
                    $clientPhone = $client->contact ?? $clientPhone;
                    $clientEmail = $client->email ?? $clientEmail;
                }
            }

            $intervention = Intervention::create([
                'title' => $validated['title'],
                'description' => $validated['description'],
                'type' => $validated['type'],
                'priority' => $validated['priority'],
                'scheduled_date' => $validated['scheduled_date'],
                'location' => $validated['location'] ?? null,
                'client_id' => $clientId, // Sauvegarder l'ID du client sélectionné
                'client_name' => $clientName, // Rempli automatiquement si client_id fourni
                'client_phone' => $clientPhone, // Rempli automatiquement si client_id fourni
                'client_email' => $clientEmail, // Rempli automatiquement si client_id fourni
                'equipment' => $validated['equipment'] ?? null,
                'problem_description' => $validated['problem_description'] ?? null,
                'estimated_duration' => $validated['estimated_duration'] ?? null,
                'cost' => $validated['cost'] ?? null,
                'notes' => $validated['notes'] ?? null,
                'attachments' => $validated['attachments'] ?? null,
                'created_by' => $request->user()->id,
                'status' => 'pending'
            ]);

            DB::commit();

            // Notifier le patron lors de la création
            $this->safeNotify(function () use ($intervention) {
                $this->notificationService->notifyNewIntervention($intervention);
            });

            return response()->json([
                'success' => true,
                'data' => $this->transformInterventionForFlutter($intervention->load(['creator', 'client'])),
                'message' => 'Intervention créée avec succès'
            ], 201);

        } catch (\Exception $e) {
            DB::rollback();
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la création de l\'intervention: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Mettre à jour une intervention
     */
    public function update(Request $request, $id)
    {
        try {
            $intervention = Intervention::find($id);

            if (!$intervention) {
                return response()->json([
                    'success' => false,
                    'message' => 'Intervention non trouvée'
                ], 404);
            }

            if (!$intervention->canBeEdited()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette intervention ne peut plus être modifiée'
                ], 400);
            }

            $validated = $request->validate([
                'title' => 'sometimes|string|max:255',
                'description' => 'sometimes|string',
                'type' => 'sometimes|in:external,on_site',
                'priority' => 'sometimes|in:low,medium,high,urgent',
                'scheduled_date' => 'sometimes|date',
                'location' => 'nullable|string|max:255',
                // Accepter client_id (recommandé) ou client_name/client_phone/client_email (ancien format)
                'client_id' => 'nullable|integer|exists:clients,id',
                'client_name' => 'nullable|string|max:255',
                'client_phone' => 'nullable|string|max:20',
                'client_email' => 'nullable|email|max:255',
                'equipment' => 'nullable|string|max:255',
                'problem_description' => 'nullable|string',
                'estimated_duration' => 'nullable|numeric|min:0',
                'cost' => 'nullable|numeric|min:0',
                'notes' => 'nullable|string',
                'attachments' => 'nullable|array'
            ]);

            // Si client_id est fourni, récupérer les infos du client et remplir automatiquement
            $clientId = $validated['client_id'] ?? null;
            if ($clientId) {
                $client = Client::find($clientId);
                if ($client) {
                    $validated['client_name'] = $client->nom . ' ' . ($client->prenom ?? '');
                    $validated['client_phone'] = $client->contact ?? $validated['client_phone'] ?? null;
                    $validated['client_email'] = $client->email ?? $validated['client_email'] ?? null;
                }
            }
            // Garder client_id dans validated car il existe maintenant dans la table interventions

            $intervention->update($validated);

            return response()->json([
                'success' => true,
                'data' => $this->transformInterventionForFlutter($intervention->fresh()->load(['creator', 'approver', 'client'])),
                'message' => 'Intervention mise à jour avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la mise à jour de l\'intervention: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Supprimer une intervention
     */
    public function destroy($id)
    {
        try {
            $intervention = Intervention::find($id);

            if (!$intervention) {
                return response()->json([
                    'success' => false,
                    'message' => 'Intervention non trouvée'
                ], 404);
            }

            if (!$intervention->canBeEdited()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette intervention ne peut plus être supprimée'
                ], 400);
            }

            $intervention->delete();

            return response()->json([
                'success' => true,
                'message' => 'Intervention supprimée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la suppression de l\'intervention: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Approuver une intervention
     */
    public function approve(Request $request, $id)
    {
        try {
            $intervention = Intervention::find($id);

            if (!$intervention) {
                return response()->json([
                    'success' => false,
                    'message' => 'Intervention non trouvée'
                ], 404);
            }

            $notes = $request->get('notes');

            if ($intervention->approve($request->user()->id, $notes)) {
                // Notifier le créateur de l'intervention
                if ($intervention->created_by) {
                    $this->safeNotify(function () use ($intervention) {
                        $intervention->load('creator');
                        $this->notificationService->notifyInterventionValidated($intervention);
                    });
                }

                return response()->json([
                    'success' => true,
                    'data' => $this->transformInterventionForFlutter($intervention->fresh()->load(['creator', 'approver', 'client'])),
                    'message' => 'Intervention approuvée avec succès'
                ]);
            } else {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette intervention ne peut pas être approuvée'
                ], 400);
            }

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'approbation: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Rejeter une intervention
     */
    public function reject(Request $request, $id)
    {
        try {
            $intervention = Intervention::find($id);

            if (!$intervention) {
                return response()->json([
                    'success' => false,
                    'message' => 'Intervention non trouvée'
                ], 404);
            }

            // Accepter 'reason' (Flutter) ou 'rejection_reason' (backend)
            $reason = $request->get('reason') ?? $request->get('rejection_reason');
            
            $validated = $request->validate([
                'reason' => 'required_without:rejection_reason|string|max:1000',
                'rejection_reason' => 'required_without:reason|string|max:1000'
            ]);

            $rejectionReason = $reason ?? $validated['rejection_reason'] ?? $validated['reason'];

            if ($intervention->reject($rejectionReason)) {
                // Notifier le créateur de l'intervention
                if ($intervention->created_by) {
                    $this->safeNotify(function () use ($intervention, $rejectionReason) {
                        $intervention->load('creator');
                        $this->notificationService->notifyInterventionRejected($intervention, $rejectionReason);
                    });
                }

                return response()->json([
                    'success' => true,
                    'data' => $this->transformInterventionForFlutter($intervention->fresh()->load(['creator', 'approver', 'client'])),
                    'message' => 'Intervention rejetée avec succès'
                ]);
            } else {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette intervention ne peut pas être rejetée'
                ], 400);
            }

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du rejet: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Démarrer une intervention
     */
    public function start(Request $request, $id)
    {
        try {
            $intervention = Intervention::find($id);

            if (!$intervention) {
                return response()->json([
                    'success' => false,
                    'message' => 'Intervention non trouvée'
                ], 404);
            }

            // Accepter notes optionnel (envoyé par Flutter)
            $notes = $request->get('notes');
            if ($notes && $intervention->canBeStarted()) {
                $intervention->update(['notes' => $notes]);
            }

            if ($intervention->start()) {
                return response()->json([
                    'success' => true,
                    'data' => $this->transformInterventionForFlutter($intervention->fresh()->load(['creator', 'approver', 'client'])),
                    'message' => 'Intervention démarrée avec succès'
                ]);
            } else {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette intervention ne peut pas être démarrée'
                ], 400);
            }

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du démarrage: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Terminer une intervention
     */
    public function complete(Request $request, $id)
    {
        try {
            $intervention = Intervention::find($id);

            if (!$intervention) {
                return response()->json([
                    'success' => false,
                    'message' => 'Intervention non trouvée'
                ], 404);
            }

            $validated = $request->validate([
                'solution' => 'nullable|string|max:1000', // Champ envoyé par Flutter
                'completion_notes' => 'nullable|string|max:1000',
                'actual_duration' => 'nullable|numeric|min:0',
                'cost' => 'nullable|numeric|min:0'
            ]);

            // Utiliser solution si fourni, sinon completion_notes
            $completionNotes = $validated['solution'] ?? $validated['completion_notes'] ?? null;

            if ($intervention->complete(
                $completionNotes,
                $validated['actual_duration'] ?? null,
                $validated['cost'] ?? null
            )) {
                return response()->json([
                    'success' => true,
                    'data' => $this->transformInterventionForFlutter($intervention->fresh()->load(['creator', 'approver', 'client'])),
                    'message' => 'Intervention terminée avec succès'
                ]);
            } else {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette intervention ne peut pas être terminée'
                ], 400);
            }

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la finalisation: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Statistiques des interventions
     */
    public function statistics(Request $request)
    {
        try {
            $startDate = $request->get('date_debut');
            $endDate = $request->get('date_fin');

            $dateKey = Carbon::parse($startDate)->format('Y-m-d');
            $stats = $this->rememberDailyStats('intervention_stats', $dateKey, function () use ($startDate, $endDate) {
                return Intervention::getInterventionStats($startDate, $endDate);
            });

            return response()->json([
                'success' => true,
                'data' => $stats,
                'message' => 'Statistiques récupérées avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des statistiques: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les interventions en retard
     */
    public function overdue()
    {
        try {
            $interventions = Intervention::getOverdueInterventions();

            return response()->json([
                'success' => true,
                'data' => $interventions,
                'message' => 'Interventions en retard récupérées avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des interventions en retard: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les interventions dues bientôt
     */
    public function dueSoon()
    {
        try {
            $interventions = Intervention::getDueSoonInterventions();

            return response()->json([
                'success' => true,
                'data' => $interventions,
                'message' => 'Interventions dues bientôt récupérées avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des interventions dues bientôt: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les interventions en attente
     */
    public function pending()
    {
        try {
            $perPage = request()->get('per_page', 15);
            $interventions = Intervention::where('status', 'pending')
                ->with(['creator', 'approver', 'client'])
                ->orderBy('scheduled_date', 'asc')
                ->paginate($perPage);

            return response()->json([
                'success' => true,
                'data' => InterventionResource::collection($interventions->items()),
                'pagination' => [
                    'current_page' => $interventions->currentPage(),
                    'last_page' => $interventions->lastPage(),
                    'per_page' => $interventions->perPage(),
                    'total' => $interventions->total(),
                ],
                'message' => 'Interventions en attente récupérées avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des interventions en attente: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Transformer une intervention au format attendu par Flutter
     */
    private function transformInterventionForFlutter($intervention)
    {
        return [
            'id' => $intervention->id,
            'title' => $intervention->title,
            'description' => $intervention->description,
            'type' => $intervention->type,
            'status' => $intervention->status,
            'priority' => $intervention->priority,
            'scheduled_date' => $intervention->scheduled_date->format('Y-m-d H:i:s'),
            'start_date' => $intervention->start_date?->format('Y-m-d H:i:s'),
            'end_date' => $intervention->end_date?->format('Y-m-d H:i:s'),
            'location' => $intervention->location,
            'client_id' => $intervention->client_id, // ID du client sélectionné
            'client_name' => $intervention->client_name,
            'client_phone' => $intervention->client_phone,
            'client_email' => $intervention->client_email,
            'equipment' => $intervention->equipment,
            'problem_description' => $intervention->problem_description,
            'solution' => $intervention->completion_notes, // Mapper completion_notes vers solution pour Flutter
            'notes' => $intervention->notes,
            'attachments' => $intervention->attachments,
            'estimated_duration' => $intervention->estimated_duration,
            'actual_duration' => $intervention->actual_duration,
            'cost' => $intervention->cost,
            'created_at' => $intervention->created_at->format('Y-m-d H:i:s'),
            'updated_at' => $intervention->updated_at->format('Y-m-d H:i:s'),
            'created_by' => $intervention->created_by,
            'approved_by' => $intervention->approved_by,
            'approved_at' => $intervention->approved_at?->format('Y-m-d H:i:s'),
            'rejection_reason' => $intervention->rejection_reason,
            'completion_notes' => $intervention->completion_notes,
        ];
    }

    /**
     * Récupérer les types d'interventions
     */
    public function types()
    {
        try {
            $types = $this->rememberStatic('intervention_types', function () {
                return [
                    [
                        'value' => 'external',
                        'label' => 'Externe',
                        'icon' => 'location_on',
                        'color' => '#3B82F6'
                    ],
                    [
                        'value' => 'on_site',
                        'label' => 'Sur place',
                        'icon' => 'home',
                        'color' => '#10B981'
                    ]
                ];
            });

            return response()->json([
                'success' => true,
                'data' => $types,
                'message' => 'Types d\'interventions récupérés avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des types: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les équipements
     */
    public function equipment()
    {
        try {
            $equipment = Equipment::getActiveEquipment();

            return response()->json([
                'success' => true,
                'data' => $equipment,
                'message' => 'Équipements récupérés avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des équipements: ' . $e->getMessage()
            ], 500);
        }
    }
}
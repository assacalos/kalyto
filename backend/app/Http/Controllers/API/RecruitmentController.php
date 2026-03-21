<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\Controller;
use App\Services\NotificationService;
use App\Traits\SendsNotifications;
use App\Models\RecruitmentRequest;
use App\Models\RecruitmentApplication;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class RecruitmentController extends Controller
{
    use SendsNotifications;

    protected $notificationService;

    public function __construct(NotificationService $notificationService)
    {
        $this->notificationService = $notificationService;
    }
    /**
     * Afficher la liste des demandes de recrutement
     */
    public function index(Request $request)
    {
        try {
            $query = RecruitmentRequest::with(['creator', 'publisher', 'approver', 'applications'])
                ->withCount(['applications']);

            // Filtrage par statut
            if ($request->has('status')) {
                $query->where('status', $request->status);
            }

            // Filtrage par département
            if ($request->has('department')) {
                $query->where('department', $request->department);
            }

            // Filtrage par poste
            if ($request->has('position')) {
                $query->where('position', $request->position);
            }

            // Filtrage par type d'emploi
            if ($request->has('employment_type')) {
                $query->where('employment_type', $request->employment_type);
            }

            // Filtrage par niveau d'expérience
            if ($request->has('experience_level')) {
                $query->where('experience_level', $request->experience_level);
            }

            // Filtrage par titre
            if ($request->has('title')) {
                $query->where('title', 'like', '%' . $request->title . '%');
            }

            // Filtrage par localisation
            if ($request->has('location')) {
                $query->where('location', 'like', '%' . $request->location . '%');
            }

            // Filtrage par date limite
            if ($request->has('deadline_from')) {
                $query->where('application_deadline', '>=', $request->deadline_from);
            }

            if ($request->has('deadline_to')) {
                $query->where('application_deadline', '<=', $request->deadline_to);
            }

            // Filtrage par expirant
            if ($request->has('expiring')) {
                if ($request->expiring === 'true') {
                    $query->expiring();
                }
            }

            // Filtrage par expiré
            if ($request->has('expired')) {
                if ($request->expired === 'true') {
                    $query->expired();
                }
            }

            $perPage = min((int) $request->get('per_page', $request->get('limit', 20)), 100);
            $requests = $query->orderBy('created_at', 'desc')->paginate($perPage);

            $data = $requests->getCollection()->map(function ($item) {
                return $this->formatRecruitmentRequest($item);
            })->values();

            return response()->json([
                'success' => true,
                'data' => $data,
                'pagination' => [
                    'current_page' => $requests->currentPage(),
                    'last_page' => $requests->lastPage(),
                    'per_page' => $requests->perPage(),
                    'total' => $requests->total(),
                    'from' => $requests->firstItem(),
                    'to' => $requests->lastItem(),
                ],
                'message' => 'Liste des demandes de recrutement récupérée avec succès',
            ], 200, [], JSON_UNESCAPED_UNICODE);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des demandes: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Afficher une demande de recrutement spécifique
     */
    public function show($id)
    {
        try {
            $request = RecruitmentRequest::with(['creator', 'publisher', 'approver', 'applications.documents', 'applications.interviews'])->find($id);

            if (!$request) {
                return response()->json([
                    'success' => false,
                    'message' => 'Demande de recrutement non trouvée'
                ], 404);
            }

            return response()->json([
                'success' => true,
                'data' => $this->formatRecruitmentRequest($request, true),
                'message' => 'Demande de recrutement récupérée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération de la demande: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Créer une nouvelle demande de recrutement
     */
    public function store(Request $request)
    {
        try {
            $validated = $request->validate([
                'title' => 'required|string|max:255',
                'department' => 'required|string|max:100',
                'position' => 'required|string|max:100',
                'description' => 'required|string|min:50',
                'requirements' => 'required|string|min:20',
                'responsibilities' => 'required|string|min:20',
                'number_of_positions' => 'required|integer|min:1|max:100',
                'employment_type' => 'required|in:full_time,part_time,contract,internship',
                'experience_level' => 'required|in:entry,junior,mid,senior,expert',
                'salary_range' => 'required|string|max:100',
                'location' => 'required|string|max:255',
                'application_deadline' => 'required|date|after:now'
            ]);

            DB::beginTransaction();

            $recruitmentRequest = RecruitmentRequest::create([
                'title' => $validated['title'],
                'department' => $validated['department'],
                'position' => $validated['position'],
                'description' => $validated['description'],
                'requirements' => $validated['requirements'],
                'responsibilities' => $validated['responsibilities'],
                'number_of_positions' => $validated['number_of_positions'],
                'employment_type' => $validated['employment_type'],
                'experience_level' => $validated['experience_level'],
                'salary_range' => $validated['salary_range'],
                'location' => $validated['location'],
                'application_deadline' => $validated['application_deadline'],
                'status' => 'draft',
                'created_by' => $request->user()->id
            ]);

            DB::commit();

            return response()->json([
                'success' => true,
                'data' => $this->formatRecruitmentRequest($recruitmentRequest->load(['creator'])),
                'message' => 'Demande de recrutement créée avec succès'
            ], 201);

        } catch (\Exception $e) {
            DB::rollback();
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la création de la demande: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Mettre à jour une demande de recrutement
     */
    public function update(Request $request, $id)
    {
        try {
            $recruitmentRequest = RecruitmentRequest::find($id);

            if (!$recruitmentRequest) {
                return response()->json([
                    'success' => false,
                    'message' => 'Demande de recrutement non trouvée'
                ], 404);
            }

            if (!$recruitmentRequest->can_edit) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette demande ne peut pas être modifiée'
                ], 403);
            }

            $validated = $request->validate([
                'title' => 'sometimes|string|max:255',
                'department' => 'sometimes|string|max:100',
                'position' => 'sometimes|string|max:100',
                'description' => 'sometimes|string|min:50',
                'requirements' => 'sometimes|string|min:20',
                'responsibilities' => 'sometimes|string|min:20',
                'number_of_positions' => 'sometimes|integer|min:1|max:100',
                'employment_type' => 'sometimes|in:full_time,part_time,contract,internship',
                'experience_level' => 'sometimes|in:entry,junior,mid,senior,expert',
                'salary_range' => 'sometimes|string|max:100',
                'location' => 'sometimes|string|max:255',
                'application_deadline' => 'sometimes|date|after:now'
            ]);

            $recruitmentRequest->update(array_merge($validated, [
                'updated_by' => $request->user()->id
            ]));

            return response()->json([
                'success' => true,
                'data' => $this->formatRecruitmentRequest($recruitmentRequest->load(['creator', 'updater'])),
                'message' => 'Demande de recrutement mise à jour avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la mise à jour de la demande: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Supprimer une demande de recrutement
     */
    public function destroy($id)
    {
        try {
            $recruitmentRequest = RecruitmentRequest::find($id);

            if (!$recruitmentRequest) {
                return response()->json([
                    'success' => false,
                    'message' => 'Demande de recrutement non trouvée'
                ], 404);
            }

            if (!$recruitmentRequest->can_edit) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette demande ne peut pas être supprimée'
                ], 403);
            }

            $recruitmentRequest->delete();

            return response()->json([
                'success' => true,
                'message' => 'Demande de recrutement supprimée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la suppression de la demande: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Publier une demande de recrutement
     */
    public function publish($id)
    {
        try {
            $recruitmentRequest = RecruitmentRequest::find($id);

            if (!$recruitmentRequest) {
                return response()->json([
                    'success' => false,
                    'message' => 'Demande de recrutement non trouvée'
                ], 404);
            }

            if (!$recruitmentRequest->can_publish) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette demande ne peut pas être publiée'
                ], 403);
            }

            $recruitmentRequest->publish(request()->user()->id);

            // Notifier le patron lors de la publication
            $this->safeNotify(function () use ($recruitmentRequest) {
                $this->notificationService->notifyNewRecrutement($recruitmentRequest);
            });

            return response()->json([
                'success' => true,
                'message' => 'Demande de recrutement publiée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la publication: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Fermer une demande de recrutement
     */
    public function close($id)
    {
        try {
            $recruitmentRequest = RecruitmentRequest::find($id);

            if (!$recruitmentRequest) {
                return response()->json([
                    'success' => false,
                    'message' => 'Demande de recrutement non trouvée'
                ], 404);
            }

            if (!$recruitmentRequest->can_close) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette demande ne peut pas être fermée'
                ], 403);
            }

            $recruitmentRequest->close();

            return response()->json([
                'success' => true,
                'message' => 'Demande de recrutement fermée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la fermeture: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Annuler une demande de recrutement
     */
    public function cancel(Request $request, $id)
    {
        try {
            $recruitmentRequest = RecruitmentRequest::find($id);

            if (!$recruitmentRequest) {
                return response()->json([
                    'success' => false,
                    'message' => 'Demande de recrutement non trouvée'
                ], 404);
            }

            if (!$recruitmentRequest->can_cancel) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette demande ne peut pas être annulée'
                ], 403);
            }

            $validated = $request->validate([
                'reason' => 'nullable|string|max:1000'
            ]);

            $recruitmentRequest->cancel($validated['reason']);

            return response()->json([
                'success' => true,
                'message' => 'Demande de recrutement annulée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'annulation: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Rejeter une demande de recrutement
     */
    public function reject(Request $request, $id)
    {
        try {
            $recruitmentRequest = RecruitmentRequest::find($id);

            if (!$recruitmentRequest) {
                return response()->json([
                    'success' => false,
                    'message' => 'Demande de recrutement non trouvée'
                ], 404);
            }

            // Vérifier que la demande peut être rejetée (draft ou published)
            if (!in_array($recruitmentRequest->status, ['draft', 'published'])) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette demande ne peut pas être rejetée'
                ], 403);
            }

            $validated = $request->validate([
                'reason' => 'nullable|string|max:1000',
                'rejection_reason' => 'nullable|string|max:1000'
            ]);

            // Accepter 'reason' (Flutter) ou 'rejection_reason' (backend)
            $rejectionReason = $validated['reason'] ?? $validated['rejection_reason'] ?? null;

            $recruitmentRequest->cancel($rejectionReason);

            // Notifier le créateur de la demande
            $reason = $rejectionReason ?? 'Rejeté';
            if ($recruitmentRequest->created_by) {
                $this->safeNotify(function () use ($recruitmentRequest, $reason) {
                    $recruitmentRequest->load('creator');
                    $this->notificationService->notifyRecrutementRejected($recruitmentRequest, $reason);
                });
            }

            return response()->json([
                'success' => true,
                'data' => $this->formatRecruitmentRequest($recruitmentRequest->load(['creator', 'updater'])),
                'message' => 'Demande de recrutement rejetée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du rejet: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Approuver une demande de recrutement
     */
    public function approve($id)
    {
        try {
            $recruitmentRequest = RecruitmentRequest::find($id);

            if (!$recruitmentRequest) {
                return response()->json([
                    'success' => false,
                    'message' => 'Demande de recrutement non trouvée'
                ], 404);
            }

            $recruitmentRequest->approve(request()->user()->id);

            // Notifier le créateur de la demande
            if ($recruitmentRequest->created_by) {
                $this->safeNotify(function () use ($recruitmentRequest) {
                    $recruitmentRequest->load('creator');
                    $this->notificationService->notifyRecrutementValidated($recruitmentRequest);
                });
            }

            return response()->json([
                'success' => true,
                'message' => 'Demande de recrutement approuvée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'approbation: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Statistiques des recrutements
     */
    public function statistics(Request $request)
    {
        try {
            $stats = RecruitmentRequest::getRecruitmentStats();
            
            // Formater les statistiques au format Flutter
            $formattedStats = [
                'total' => $stats['total_requests'] ?? 0,
                'draft' => $stats['draft_requests'] ?? 0,
                'published' => $stats['published_requests'] ?? 0,
                'closed' => $stats['closed_requests'] ?? 0,
                'cancelled' => $stats['cancelled_requests'] ?? 0,
                // Garder aussi les clés détaillées pour compatibilité
                'total_requests' => $stats['total_requests'] ?? 0,
                'draft_requests' => $stats['draft_requests'] ?? 0,
                'published_requests' => $stats['published_requests'] ?? 0,
                'closed_requests' => $stats['closed_requests'] ?? 0,
                'cancelled_requests' => $stats['cancelled_requests'] ?? 0,
                'total_applications' => $stats['total_applications'] ?? 0,
                'pending_applications' => $stats['pending_applications'] ?? 0,
                'shortlisted_applications' => $stats['shortlisted_applications'] ?? 0,
                'interviewed_applications' => $stats['interviewed_applications'] ?? 0,
                'hired_applications' => $stats['hired_applications'] ?? 0,
                'rejected_applications' => $stats['rejected_applications'] ?? 0,
                'average_application_time' => $stats['average_application_time'] ?? 0,
                'applications_by_department' => isset($stats['applications_by_department']) ? $stats['applications_by_department']->toArray() : [],
                'applications_by_position' => isset($stats['applications_by_position']) ? $stats['applications_by_position']->toArray() : [],
                'recent_applications' => isset($stats['recent_applications']) ? $stats['recent_applications']->map(function ($application) {
                    return $this->formatRecruitmentApplication($application);
                })->toArray() : [],
            ];

            return response()->json([
                'success' => true,
                'data' => $formattedStats,
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
     * Récupérer les demandes par département
     */
    public function byDepartment($department)
    {
        try {
            $requests = RecruitmentRequest::getRequestsByDepartment($department);

            return response()->json([
                'success' => true,
                'data' => $requests->map(function ($request) {
                    return $this->formatRecruitmentRequest($request);
                }),
                'message' => 'Demandes du département récupérées avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des demandes du département: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les demandes par poste
     */
    public function byPosition($position)
    {
        try {
            $requests = RecruitmentRequest::getRequestsByPosition($position);

            return response()->json([
                'success' => true,
                'data' => $requests->map(function ($request) {
                    return $this->formatRecruitmentRequest($request);
                }),
                'message' => 'Demandes du poste récupérées avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des demandes du poste: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les demandes expirant
     */
    public function expiring()
    {
        try {
            $requests = RecruitmentRequest::getExpiringRequests();

            return response()->json([
                'success' => true,
                'data' => $requests->map(function ($request) {
                    return $this->formatRecruitmentRequest($request);
                }),
                'message' => 'Demandes expirant récupérées avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des demandes expirant: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les demandes expirées
     */
    public function expired()
    {
        try {
            $requests = RecruitmentRequest::getExpiredRequests();

            return response()->json([
                'success' => true,
                'data' => $requests->map(function ($request) {
                    return $this->formatRecruitmentRequest($request);
                }),
                'message' => 'Demandes expirées récupérées avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des demandes expirées: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les demandes publiées
     */
    public function published()
    {
        try {
            $requests = RecruitmentRequest::getPublishedRequests();

            return response()->json([
                'success' => true,
                'data' => $requests->map(function ($request) {
                    return $this->formatRecruitmentRequest($request);
                }),
                'message' => 'Demandes publiées récupérées avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des demandes publiées: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les demandes brouillons
     */
    public function drafts()
    {
        try {
            $requests = RecruitmentRequest::getDraftRequests();

            return response()->json([
                'success' => true,
                'data' => $requests->map(function ($request) {
                    return $this->formatRecruitmentRequest($request);
                }),
                'message' => 'Demandes brouillons récupérées avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des demandes brouillons: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les départements disponibles
     */
    public function departments()
    {
        try {
            $departments = RecruitmentRequest::distinct()
                ->whereNotNull('department')
                ->where('department', '!=', '')
                ->orderBy('department')
                ->pluck('department')
                ->toArray();

            // Si aucun département n'existe, retourner une liste par défaut
            if (empty($departments)) {
                $departments = [
                    'Ressources Humaines',
                    'Commercial',
                    'Comptabilité',
                    'Technique',
                    'Support',
                    'Direction'
                ];
            }

            return response()->json([
                'success' => true,
                'data' => $departments,
                'message' => 'Liste des départements récupérée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des départements: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les postes disponibles
     */
    public function positions()
    {
        try {
            $positions = RecruitmentRequest::distinct()
                ->whereNotNull('position')
                ->where('position', '!=', '')
                ->orderBy('position')
                ->pluck('position')
                ->toArray();

            // Si aucun poste n'existe, retourner une liste par défaut
            if (empty($positions)) {
                $positions = [
                    'Développeur',
                    'Chef de projet',
                    'Comptable',
                    'Commercial',
                    'Technicien',
                    'Assistant RH',
                    'Manager'
                ];
            }

            return response()->json([
                'success' => true,
                'data' => $positions,
                'message' => 'Liste des postes récupérée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des postes: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les candidatures d'une demande de recrutement
     */
    public function applications($id, Request $request)
    {
        try {
            $recruitmentRequest = RecruitmentRequest::find($id);

            if (!$recruitmentRequest) {
                return response()->json([
                    'success' => false,
                    'message' => 'Demande de recrutement non trouvée'
                ], 404);
            }

            $query = $recruitmentRequest->applications()->with(['reviewer', 'documents']);

            // Filtrage par statut
            if ($request->has('status')) {
                $query->where('status', $request->status);
            }

            $applications = $query->orderBy('created_at', 'desc')->get();

            return response()->json([
                'success' => true,
                'data' => $applications->map(function ($application) {
                    return $this->formatRecruitmentApplication($application, true);
                }),
                'message' => 'Candidatures récupérées avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des candidatures: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Formater une demande de recrutement au format Flutter
     */
    private function formatRecruitmentRequest($request, $includeFullDetails = false)
    {
        $data = [
            'id' => $request->id,
            'title' => $request->title,
            'department' => $request->department,
            'position' => $request->position,
            'description' => $request->description,
            'requirements' => $request->requirements,
            'responsibilities' => $request->responsibilities,
            'number_of_positions' => $request->number_of_positions,
            'employment_type' => $request->employment_type,
            'experience_level' => $request->experience_level,
            'salary_range' => $request->salary_range,
            'location' => $request->location,
            'application_deadline' => $request->application_deadline?->format('Y-m-d\TH:i:s\Z'),
            'status' => $request->status,
            'rejection_reason' => $request->rejection_reason,
            'published_at' => $request->published_at?->format('Y-m-d\TH:i:s\Z'),
            'published_by' => $request->published_by,
            'published_by_name' => $request->publisher_name ?? null,
            'approved_at' => $request->approved_at?->format('Y-m-d\TH:i:s\Z'),
            'approved_by' => $request->approved_by,
            'approved_by_name' => $request->approver_name ?? null,
            'created_by' => $request->created_by,
            'created_at' => $request->created_at->format('Y-m-d\TH:i:s\Z'),
            'updated_at' => $request->updated_at->format('Y-m-d\TH:i:s\Z'),
        ];

        // Inclure les applications si demandé
        if ($includeFullDetails && $request->relationLoaded('applications')) {
            $data['applications'] = $request->applications->map(function ($application) {
                return $this->formatRecruitmentApplication($application, true);
            });
        } else {
            $data['applications'] = [];
        }

        // Inclure les stats si demandé
        if ($includeFullDetails) {
            $data['stats'] = [
                'total_applications' => $request->applications_count ?? 0,
                'pending_applications' => $request->pending_applications_count ?? 0,
                'shortlisted_applications' => $request->shortlisted_applications_count ?? 0,
                'hired_applications' => $request->hired_applications_count ?? 0,
            ];
        }

        return $data;
    }

    /**
     * Formater une candidature au format Flutter
     */
    private function formatRecruitmentApplication($application, $includeDocuments = false)
    {
        $data = [
            'id' => $application->id,
            'recruitment_request_id' => $application->recruitment_request_id,
            'candidate_name' => $application->candidate_name,
            'candidate_email' => $application->candidate_email,
            'candidate_phone' => $application->candidate_phone,
            'candidate_address' => $application->candidate_address,
            'cover_letter' => $application->cover_letter,
            'resume_path' => $application->resume_path,
            'portfolio_url' => $application->portfolio_url,
            'linkedin_url' => $application->linkedin_url,
            'status' => $application->status,
            'notes' => $application->notes,
            'rejection_reason' => $application->rejection_reason,
            'reviewed_at' => $application->reviewed_at?->format('Y-m-d\TH:i:s'),
            'reviewed_by' => $application->reviewed_by,
            'reviewed_by_name' => $application->reviewer_name,
            'interview_scheduled_at' => $application->interview_scheduled_at?->format('Y-m-d\TH:i:s'),
            'interview_completed_at' => $application->interview_completed_at?->format('Y-m-d\TH:i:s'),
            'interview_notes' => $application->interview_notes,
            'created_at' => $application->created_at->format('Y-m-d\TH:i:s'),
            'updated_at' => $application->updated_at->format('Y-m-d\TH:i:s'),
        ];

        if ($includeDocuments && $application->relationLoaded('documents')) {
            $data['documents'] = $application->documents->map(function ($document) {
                return [
                    'id' => $document->id,
                    'application_id' => $document->application_id,
                    'file_name' => $document->file_name,
                    'file_path' => $document->file_path,
                    'file_type' => $document->file_type,
                    'file_size' => $document->file_size,
                    'uploaded_at' => $document->uploaded_at->format('Y-m-d\TH:i:s'),
                ];
            });
        } else {
            $data['documents'] = [];
        }

        return $data;
    }
}
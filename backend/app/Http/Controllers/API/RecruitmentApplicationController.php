<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\Controller;
use App\Services\NotificationService;
use App\Traits\SendsNotifications;
use App\Models\RecruitmentApplication;
use App\Models\RecruitmentRequest;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class RecruitmentApplicationController extends Controller
{
    use SendsNotifications;

    protected $notificationService;

    public function __construct(NotificationService $notificationService)
    {
        $this->notificationService = $notificationService;
    }
    /**
     * Liste des candidatures
     */
    public function index(Request $request)
    {
        try {
            $query = RecruitmentApplication::with(['recruitmentRequest', 'reviewer', 'documents', 'interviews']);

            // Filtrage par demande de recrutement
            if ($request->has('recruitment_request_id')) {
                $query->where('recruitment_request_id', $request->recruitment_request_id);
            }

            // Filtrage par statut
            if ($request->has('status')) {
                $query->where('status', $request->status);
            }

            // Filtrage par candidat
            if ($request->has('candidate_email')) {
                $query->where('candidate_email', $request->candidate_email);
            }

            $perPage = min((int) $request->get('per_page', 20), 100);
            $applications = $query->orderBy('created_at', 'desc')->paginate($perPage);

            $data = $applications->getCollection()->map(function ($application) {
                return $this->formatApplication($application, true);
            })->values();

            return response()->json([
                'success' => true,
                'data' => $data,
                'pagination' => [
                    'current_page' => $applications->currentPage(),
                    'last_page' => $applications->lastPage(),
                    'per_page' => $applications->perPage(),
                    'total' => $applications->total(),
                    'from' => $applications->firstItem(),
                    'to' => $applications->lastItem(),
                ],
                'message' => 'Liste des candidatures récupérée avec succès',
            ], 200, [], JSON_UNESCAPED_UNICODE);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des candidatures: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Afficher une candidature spécifique
     */
    public function show($id)
    {
        try {
            $application = RecruitmentApplication::with(['recruitmentRequest', 'reviewer', 'documents', 'interviews'])->find($id);

            if (!$application) {
                return response()->json([
                    'success' => false,
                    'message' => 'Candidature non trouvée'
                ], 404);
            }

            return response()->json([
                'success' => true,
                'data' => $this->formatApplication($application, true),
                'message' => 'Candidature récupérée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération de la candidature: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Créer une nouvelle candidature
     */
    public function store(Request $request)
    {
        try {
            $validated = $request->validate([
                'recruitment_request_id' => 'required|exists:recruitment_requests,id',
                'candidate_name' => 'required|string|max:255',
                'candidate_email' => 'required|email|max:255',
                'candidate_phone' => 'required|string|max:50',
                'candidate_address' => 'nullable|string',
                'cover_letter' => 'nullable|string',
                'resume_path' => 'nullable|string|max:500',
                'portfolio_url' => 'nullable|url|max:500',
                'linkedin_url' => 'nullable|url|max:500',
            ]);

            // Vérifier que la demande de recrutement est publiée
            $recruitmentRequest = RecruitmentRequest::find($validated['recruitment_request_id']);
            if (!$recruitmentRequest || $recruitmentRequest->status !== 'published') {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette demande de recrutement n\'est pas disponible pour les candidatures'
                ], 403);
            }

            DB::beginTransaction();

            $application = RecruitmentApplication::create([
                'recruitment_request_id' => $validated['recruitment_request_id'],
                'candidate_name' => $validated['candidate_name'],
                'candidate_email' => $validated['candidate_email'],
                'candidate_phone' => $validated['candidate_phone'],
                'candidate_address' => $validated['candidate_address'] ?? null,
                'cover_letter' => $validated['cover_letter'] ?? null,
                'resume_path' => $validated['resume_path'] ?? null,
                'portfolio_url' => $validated['portfolio_url'] ?? null,
                'linkedin_url' => $validated['linkedin_url'] ?? null,
                'status' => 'pending'
            ]);

            DB::commit();

            // Notifier le patron pour validation de la candidature
            $this->safeNotify(function () use ($recruitmentRequest) {
                $recruitmentRequest->load('user');
                if ($recruitmentRequest->user) {
                    $this->notificationService->notifyNewRecrutement($recruitmentRequest);
                }
            });

            return response()->json([
                'success' => true,
                'data' => $this->formatApplication($application->load(['recruitmentRequest'])),
                'message' => 'Candidature créée avec succès'
            ], 201);

        } catch (\Exception $e) {
            DB::rollback();
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la création de la candidature: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Mettre à jour une candidature
     */
    public function update(Request $request, $id)
    {
        try {
            $application = RecruitmentApplication::find($id);

            if (!$application) {
                return response()->json([
                    'success' => false,
                    'message' => 'Candidature non trouvée'
                ], 404);
            }

            $validated = $request->validate([
                'candidate_name' => 'sometimes|string|max:255',
                'candidate_email' => 'sometimes|email|max:255',
                'candidate_phone' => 'sometimes|string|max:50',
                'candidate_address' => 'nullable|string',
                'cover_letter' => 'nullable|string',
                'resume_path' => 'nullable|string|max:500',
                'portfolio_url' => 'nullable|url|max:500',
                'linkedin_url' => 'nullable|url|max:500',
                'notes' => 'nullable|string',
            ]);

            $application->update($validated);

            return response()->json([
                'success' => true,
                'data' => $this->formatApplication($application->load(['recruitmentRequest', 'reviewer'])),
                'message' => 'Candidature mise à jour avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la mise à jour de la candidature: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Examiner une candidature
     */
    public function review(Request $request, $id)
    {
        try {
            $application = RecruitmentApplication::find($id);

            if (!$application) {
                return response()->json([
                    'success' => false,
                    'message' => 'Candidature non trouvée'
                ], 404);
            }

            if (!$application->can_review) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette candidature ne peut pas être examinée'
                ], 403);
            }

            $validated = $request->validate([
                'notes' => 'nullable|string',
            ]);

            $application->review($request->user()->id, $validated['notes'] ?? null);

            return response()->json([
                'success' => true,
                'data' => $this->formatApplication($application->load(['reviewer'])),
                'message' => 'Candidature examinée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'examen de la candidature: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Pré-sélectionner une candidature
     */
    public function shortlist(Request $request, $id)
    {
        try {
            $application = RecruitmentApplication::find($id);

            if (!$application) {
                return response()->json([
                    'success' => false,
                    'message' => 'Candidature non trouvée'
                ], 404);
            }

            if (!$application->can_shortlist) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette candidature ne peut pas être pré-sélectionnée'
                ], 403);
            }

            $validated = $request->validate([
                'notes' => 'nullable|string',
            ]);

            $application->shortlist($request->user()->id, $validated['notes'] ?? null);

            return response()->json([
                'success' => true,
                'data' => $this->formatApplication($application->load(['reviewer'])),
                'message' => 'Candidature pré-sélectionnée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la pré-sélection: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Rejeter une candidature
     */
    public function reject(Request $request, $id)
    {
        try {
            $application = RecruitmentApplication::find($id);

            if (!$application) {
                return response()->json([
                    'success' => false,
                    'message' => 'Candidature non trouvée'
                ], 404);
            }

            if (!$application->can_reject) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette candidature ne peut pas être rejetée'
                ], 403);
            }

            $validated = $request->validate([
                'rejection_reason' => 'required|string|max:1000',
            ]);

            $application->reject($request->user()->id, $validated['rejection_reason']);

            // Notifier le créateur de la demande de recrutement
            $reason = $validated['rejection_reason'];
            $this->safeNotify(function () use ($application, $reason) {
                $application->load('recruitmentRequest.user');
                if ($application->recruitmentRequest && $application->recruitmentRequest->user_id) {
                    $recruitmentRequest = $application->recruitmentRequest;
                    $this->notificationService->notifyRecrutementRejected($recruitmentRequest, $reason);
                }
            });

            return response()->json([
                'success' => true,
                'data' => $this->formatApplication($application->load(['reviewer'])),
                'message' => 'Candidature rejetée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du rejet: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Embaucher un candidat
     */
    public function hire(Request $request, $id)
    {
        try {
            $application = RecruitmentApplication::find($id);

            if (!$application) {
                return response()->json([
                    'success' => false,
                    'message' => 'Candidature non trouvée'
                ], 404);
            }

            if (!$application->can_hire) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette candidature ne peut pas être embauchée'
                ], 403);
            }

            $validated = $request->validate([
                'notes' => 'nullable|string',
            ]);

            $application->hire($request->user()->id, $validated['notes'] ?? null);

            return response()->json([
                'success' => true,
                'data' => $this->formatApplication($application->load(['reviewer'])),
                'message' => 'Candidat embauché avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'embauche: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Mettre à jour le statut d'une candidature
     */
    public function updateStatus(Request $request, $id)
    {
        try {
            $application = RecruitmentApplication::find($id);

            if (!$application) {
                return response()->json([
                    'success' => false,
                    'message' => 'Candidature non trouvée'
                ], 404);
            }

            $validated = $request->validate([
                'status' => 'required|in:pending,reviewed,shortlisted,interviewed,rejected,hired',
                'notes' => 'nullable|string',
                'rejection_reason' => 'nullable|string|required_if:status,rejected',
            ]);

            DB::beginTransaction();

            $updateData = [
                'status' => $validated['status'],
            ];

            // Mettre à jour les notes si fournies
            if (isset($validated['notes'])) {
                $updateData['notes'] = $validated['notes'];
            }

            // Mettre à jour la raison de rejet si le statut est rejected
            if ($validated['status'] === 'rejected') {
                $updateData['rejection_reason'] = $validated['rejection_reason'] ?? null;
            }

            // Mettre à jour reviewed_at et reviewed_by si le statut change de pending
            if ($application->status === 'pending' && $validated['status'] !== 'pending') {
                $updateData['reviewed_at'] = now();
                $updateData['reviewed_by'] = $request->user()->id;
            }

            $application->update($updateData);

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Statut mis à jour avec succès',
                'data' => $this->formatApplication($application->load(['reviewer', 'documents']), true)
            ]);

        } catch (\Exception $e) {
            DB::rollback();
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la mise à jour du statut: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Formater une candidature au format Flutter
     */
    private function formatApplication($application, $includeDocuments = false)
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


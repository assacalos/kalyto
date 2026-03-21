<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\Controller;
use App\Models\RecruitmentInterview;
use App\Models\RecruitmentApplication;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class RecruitmentInterviewController extends Controller
{
    /**
     * Liste des entretiens
     */
    public function index(Request $request)
    {
        try {
            $query = RecruitmentInterview::with(['application', 'interviewer']);

            // Filtrage par candidature
            if ($request->has('application_id')) {
                $query->where('application_id', $request->application_id);
            }

            // Filtrage par statut
            if ($request->has('status')) {
                $query->where('status', $request->status);
            }

            // Filtrage par intervieweur
            if ($request->has('interviewer_id')) {
                $query->where('interviewer_id', $request->interviewer_id);
            }

            // Filtrage par type
            if ($request->has('type')) {
                $query->where('type', $request->type);
            }

            $perPage = min((int) $request->get('per_page', 20), 100);
            $interviews = $query->orderBy('scheduled_at', 'desc')->paginate($perPage);

            $data = $interviews->getCollection()->map(function ($interview) {
                return $this->formatInterview($interview);
            })->values();

            return response()->json([
                'success' => true,
                'data' => $data,
                'pagination' => [
                    'current_page' => $interviews->currentPage(),
                    'last_page' => $interviews->lastPage(),
                    'per_page' => $interviews->perPage(),
                    'total' => $interviews->total(),
                    'from' => $interviews->firstItem(),
                    'to' => $interviews->lastItem(),
                ],
                'message' => 'Liste des entretiens récupérée avec succès',
            ], 200, [], JSON_UNESCAPED_UNICODE);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des entretiens: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Afficher un entretien spécifique
     */
    public function show($id)
    {
        try {
            $interview = RecruitmentInterview::with(['application', 'interviewer'])->find($id);

            if (!$interview) {
                return response()->json([
                    'success' => false,
                    'message' => 'Entretien non trouvé'
                ], 404);
            }

            return response()->json([
                'success' => true,
                'data' => $this->formatInterview($interview),
                'message' => 'Entretien récupéré avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération de l\'entretien: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Créer un nouvel entretien
     */
    public function store(Request $request)
    {
        try {
            $validated = $request->validate([
                'application_id' => 'required|exists:recruitment_applications,id',
                'scheduled_at' => 'required|date|after:now',
                'location' => 'required|string|max:255',
                'type' => 'required|in:phone,video,in_person',
                'meeting_link' => 'nullable|url|max:500',
                'notes' => 'nullable|string',
                'interviewer_id' => 'nullable|exists:users,id',
            ]);

            // Vérifier que la candidature peut être interviewée
            $application = RecruitmentApplication::find($validated['application_id']);
            if (!$application || !$application->can_interview) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette candidature ne peut pas être interviewée'
                ], 403);
            }

            DB::beginTransaction();

            $interview = RecruitmentInterview::create([
                'application_id' => $validated['application_id'],
                'scheduled_at' => $validated['scheduled_at'],
                'location' => $validated['location'],
                'type' => $validated['type'],
                'meeting_link' => $validated['meeting_link'] ?? null,
                'notes' => $validated['notes'] ?? null,
                'status' => 'scheduled',
                'interviewer_id' => $validated['interviewer_id'] ?? $request->user()->id,
            ]);

            // Mettre à jour la candidature
            $application->update([
                'interview_scheduled_at' => $validated['scheduled_at'],
                'status' => 'shortlisted'
            ]);

            DB::commit();

            return response()->json([
                'success' => true,
                'data' => $this->formatInterview($interview->load(['application', 'interviewer'])),
                'message' => 'Entretien créé avec succès'
            ], 201);

        } catch (\Exception $e) {
            DB::rollback();
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la création de l\'entretien: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Mettre à jour un entretien
     */
    public function update(Request $request, $id)
    {
        try {
            $interview = RecruitmentInterview::find($id);

            if (!$interview) {
                return response()->json([
                    'success' => false,
                    'message' => 'Entretien non trouvé'
                ], 404);
            }

            $validated = $request->validate([
                'scheduled_at' => 'sometimes|date|after:now',
                'location' => 'sometimes|string|max:255',
                'type' => 'sometimes|in:phone,video,in_person',
                'meeting_link' => 'nullable|url|max:500',
                'notes' => 'nullable|string',
                'interviewer_id' => 'nullable|exists:users,id',
            ]);

            $interview->update($validated);

            return response()->json([
                'success' => true,
                'data' => $this->formatInterview($interview->load(['application', 'interviewer'])),
                'message' => 'Entretien mis à jour avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la mise à jour de l\'entretien: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Compléter un entretien
     */
    public function complete(Request $request, $id)
    {
        try {
            $interview = RecruitmentInterview::find($id);

            if (!$interview) {
                return response()->json([
                    'success' => false,
                    'message' => 'Entretien non trouvé'
                ], 404);
            }

            if ($interview->status !== 'scheduled') {
                return response()->json([
                    'success' => false,
                    'message' => 'Cet entretien ne peut pas être complété'
                ], 403);
            }

            $validated = $request->validate([
                'feedback' => 'nullable|string',
            ]);

            $interview->complete($request->user()->id, $validated['feedback'] ?? null);

            // Mettre à jour la candidature
            $application = $interview->application;
            $application->completeInterview($request->user()->id, $validated['feedback'] ?? null);

            return response()->json([
                'success' => true,
                'data' => $this->formatInterview($interview->load(['application', 'interviewer'])),
                'message' => 'Entretien complété avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la complétion de l\'entretien: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Annuler un entretien
     */
    public function cancel(Request $request, $id)
    {
        try {
            $interview = RecruitmentInterview::find($id);

            if (!$interview) {
                return response()->json([
                    'success' => false,
                    'message' => 'Entretien non trouvé'
                ], 404);
            }

            if ($interview->status !== 'scheduled') {
                return response()->json([
                    'success' => false,
                    'message' => 'Cet entretien ne peut pas être annulé'
                ], 403);
            }

            $validated = $request->validate([
                'reason' => 'nullable|string|max:1000',
            ]);

            $interview->cancel($validated['reason'] ?? null);

            return response()->json([
                'success' => true,
                'data' => $this->formatInterview($interview->load(['application', 'interviewer'])),
                'message' => 'Entretien annulé avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'annulation de l\'entretien: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Replanifier un entretien
     */
    public function reschedule(Request $request, $id)
    {
        try {
            $interview = RecruitmentInterview::find($id);

            if (!$interview) {
                return response()->json([
                    'success' => false,
                    'message' => 'Entretien non trouvé'
                ], 404);
            }

            $validated = $request->validate([
                'scheduled_at' => 'required|date|after:now',
                'location' => 'sometimes|string|max:255',
                'type' => 'sometimes|in:phone,video,in_person',
                'meeting_link' => 'nullable|url|max:500',
            ]);

            $interview->reschedule(
                $validated['scheduled_at'],
                $validated['location'] ?? null,
                $validated['type'] ?? null,
                $validated['meeting_link'] ?? null
            );

            return response()->json([
                'success' => true,
                'data' => $this->formatInterview($interview->load(['application', 'interviewer'])),
                'message' => 'Entretien replanifié avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la replanification: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Formater un entretien au format Flutter
     */
    private function formatInterview($interview)
    {
        return [
            'id' => $interview->id,
            'application_id' => $interview->application_id,
            'scheduled_at' => $interview->scheduled_at->format('Y-m-d\TH:i:s'),
            'location' => $interview->location,
            'type' => $interview->type,
            'meeting_link' => $interview->meeting_link,
            'notes' => $interview->notes,
            'status' => $interview->status,
            'feedback' => $interview->feedback,
            'interviewer_id' => $interview->interviewer_id,
            'interviewer_name' => $interview->interviewer_name,
            'completed_at' => $interview->completed_at?->format('Y-m-d\TH:i:s'),
            'created_at' => $interview->created_at->format('Y-m-d\TH:i:s'),
            'updated_at' => $interview->updated_at->format('Y-m-d\TH:i:s'),
        ];
    }
}


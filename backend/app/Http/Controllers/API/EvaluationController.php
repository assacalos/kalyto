<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\Controller;
use Illuminate\Http\Request;
use App\Models\Evaluation;
use App\Models\User;
use App\Models\Notification;
use App\Http\Resources\EvaluationResource;
use Carbon\Carbon;

class EvaluationController extends Controller
{
    /**
     * Liste des évaluations
     * Accessible par RH, Patron et Admin
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
            
            $query = Evaluation::with(['user', 'evaluateur']);
        
        // Filtrage par statut si fourni
        if ($request->has('statut')) {
            $query->where('statut', $request->statut);
        }
        
        // Filtrage par type si fourni
        if ($request->has('type_evaluation')) {
            $query->where('type_evaluation', $request->type_evaluation);
        }
        
        // Filtrage par période si fourni
        if ($request->has('date_debut')) {
            $query->where('date_evaluation', '>=', $request->date_debut);
        }
        
        if ($request->has('date_fin')) {
            $query->where('date_evaluation', '<=', $request->date_fin);
        }
        
        // Filtrage par utilisateur si fourni
        if ($request->has('user_id')) {
            $query->where('user_id', $request->user_id);
        }
        
        // Filtrage par évaluateur si fourni
        if ($request->has('evaluateur_id')) {
            $query->where('evaluateur_id', $request->evaluateur_id);
        }
        
        // Si technicien → filtre ses propres évaluations
        if ($user->isTechnicien()) {
            $query->where('user_id', $user->id);
        }
        
        $perPage = min((int) $request->get('per_page', 20), 100);
        $evaluations = $query->orderBy('date_evaluation', 'desc')->paginate($perPage);
        
        return response()->json([
            'success' => true,
            'data' => EvaluationResource::collection($evaluations),
            'pagination' => [
                'current_page' => $evaluations->currentPage(),
                'last_page' => $evaluations->lastPage(),
                'per_page' => $evaluations->perPage(),
                'total' => $evaluations->total(),
                'from' => $evaluations->firstItem(),
                'to' => $evaluations->lastItem(),
            ],
            'message' => 'Liste des évaluations récupérée avec succès',
        ], 200, [], JSON_UNESCAPED_UNICODE);
        
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des évaluations: ' . $e->getMessage()
            ], 500);
        }
        
        return response()->json([
            'success' => true,
            'data' => EvaluationResource::collection($evaluations->items()),
            'pagination' => [
                'current_page' => $evaluations->currentPage(),
                'last_page' => $evaluations->lastPage(),
                'per_page' => $evaluations->perPage(),
                'total' => $evaluations->total(),
            ],
            'message' => 'Liste des évaluations récupérée avec succès'
        ]);
    }

    /**
     * Détails d'une évaluation
     * Accessible par RH, Patron et Admin
     */
    public function show($id)
    {
        $evaluation = Evaluation::with(['user', 'evaluateur'])->findOrFail($id);
        
        // Vérification des permissions pour les techniciens
        if (auth()->user()->isTechnicien() && $evaluation->user_id !== auth()->id()) {
            return response()->json([
                'success' => false,
                'message' => 'Accès refusé à cette évaluation'
            ], 403);
        }
        
        return response()->json([
            'success' => true,
            'data' => new EvaluationResource($evaluation),
            'message' => 'Évaluation récupérée avec succès'
        ]);
    }

    /**
     * Créer une évaluation
     * Accessible par RH, Patron et Admin
     */
    public function store(Request $request)
    {
        $request->validate([
            'user_id' => 'required|exists:users,id',
            'type_evaluation' => 'required|in:annuelle,trimestrielle,probation,performance,objectifs',
            'date_evaluation' => 'required|date',
            'periode_debut' => 'required|date',
            'periode_fin' => 'required|date|after:periode_debut',
            'criteres_evaluation' => 'required|array',
            'note_globale' => 'required|numeric|min:0|max:20',
            'commentaires_evaluateur' => 'required|string|max:2000',
            'objectifs_futurs' => 'nullable|string|max:2000',
            'confidentiel' => 'boolean'
        ]);

        $evaluation = Evaluation::create([
            'user_id' => $request->user_id,
            'evaluateur_id' => auth()->id(),
            'type_evaluation' => $request->type_evaluation,
            'date_evaluation' => $request->date_evaluation,
            'periode_debut' => $request->periode_debut,
            'periode_fin' => $request->periode_fin,
            'criteres_evaluation' => $request->criteres_evaluation,
            'note_globale' => $request->note_globale,
            'commentaires_evaluateur' => $request->commentaires_evaluateur,
            'objectifs_futurs' => $request->objectifs_futurs,
            'confidentiel' => $request->confidentiel ?? true
        ]);

        // Créer une notification pour l'employé
        $this->creerNotificationEmploye($evaluation);

        return response()->json([
            'success' => true,
            'evaluation' => $evaluation,
            'message' => 'Évaluation créée avec succès'
        ], 201);
    }

    /**
     * Modifier une évaluation
     * Accessible par l'évaluateur et Admin
     */
    public function update(Request $request, $id)
    {
        $evaluation = Evaluation::findOrFail($id);
        
        // Vérifier les permissions
        if ($evaluation->evaluateur_id !== auth()->id() && !auth()->user()->isAdmin()) {
            return response()->json([
                'success' => false,
                'message' => 'Accès refusé à cette évaluation'
            ], 403);
        }
        
        // Vérifier que l'évaluation peut être modifiée
        if ($evaluation->statut === 'finalisee') {
            return response()->json([
                'success' => false,
                'message' => 'Impossible de modifier une évaluation finalisée'
            ], 400);
        }

        $request->validate([
            'type_evaluation' => 'required|in:annuelle,trimestrielle,probation,performance,objectifs',
            'date_evaluation' => 'required|date',
            'periode_debut' => 'required|date',
            'periode_fin' => 'required|date|after:periode_debut',
            'criteres_evaluation' => 'required|array',
            'note_globale' => 'required|numeric|min:0|max:20',
            'commentaires_evaluateur' => 'required|string|max:2000',
            'objectifs_futurs' => 'nullable|string|max:2000',
            'confidentiel' => 'boolean'
        ]);

        $evaluation->update($request->all());

        return response()->json([
            'success' => true,
            'evaluation' => $evaluation,
            'message' => 'Évaluation modifiée avec succès'
        ]);
    }

    /**
     * Ajouter les commentaires de l'employé
     * Accessible par l'employé évalué
     */
    public function addEmployeeComments(Request $request, $id)
    {
        $request->validate([
            'commentaires_employe' => 'required|string|max:2000'
        ]);

        $evaluation = Evaluation::findOrFail($id);
        
        // Vérifier que l'employé peut commenter
        if ($evaluation->user_id !== auth()->id()) {
            return response()->json([
                'success' => false,
                'message' => 'Accès refusé à cette évaluation'
            ], 403);
        }
        
        $evaluation->update([
            'commentaires_employe' => $request->commentaires_employe
        ]);

        return response()->json([
            'success' => true,
            'evaluation' => $evaluation,
            'message' => 'Commentaires ajoutés avec succès'
        ]);
    }

    /**
     * Signer l'évaluation (employé)
     * Accessible par l'employé évalué
     */
    public function signByEmployee($id)
    {
        $evaluation = Evaluation::findOrFail($id);
        
        // Vérifier que l'employé peut signer
        if ($evaluation->user_id !== auth()->id()) {
            return response()->json([
                'success' => false,
                'message' => 'Accès refusé à cette évaluation'
            ], 403);
        }
        
        $evaluation->update([
            'date_signature_employe' => Carbon::now()
        ]);

        // Créer une notification pour l'évaluateur
        $this->creerNotificationEvaluateur($evaluation, 'signature_employe');

        return response()->json([
            'success' => true,
            'evaluation' => $evaluation,
            'message' => 'Évaluation signée avec succès'
        ]);
    }

    /**
     * Signer l'évaluation (évaluateur)
     * Accessible par l'évaluateur
     */
    public function signByEvaluator($id)
    {
        $evaluation = Evaluation::findOrFail($id);
        
        // Vérifier que l'évaluateur peut signer
        if ($evaluation->evaluateur_id !== auth()->id()) {
            return response()->json([
                'success' => false,
                'message' => 'Accès refusé à cette évaluation'
            ], 403);
        }
        
        $evaluation->update([
            'date_signature_evaluateur' => Carbon::now(),
            'statut' => 'finalisee'
        ]);

        // Créer une notification pour l'employé
        $this->creerNotificationEmploye($evaluation, 'finalisee');

        return response()->json([
            'success' => true,
            'evaluation' => $evaluation,
            'message' => 'Évaluation finalisée avec succès'
        ]);
    }

    /**
     * Finaliser une évaluation
     * Accessible par RH, Patron et Admin
     */
    public function finalize($id)
    {
        $evaluation = Evaluation::findOrFail($id);
        
        if ($evaluation->statut === 'finalisee') {
            return response()->json([
                'success' => false,
                'message' => 'Cette évaluation est déjà finalisée'
            ], 400);
        }
        
        $evaluation->update([
            'statut' => 'finalisee',
            'date_signature_evaluateur' => Carbon::now()
        ]);

        return response()->json([
            'success' => true,
            'evaluation' => $evaluation,
            'message' => 'Évaluation finalisée avec succès'
        ]);
    }

    /**
     * Supprimer une évaluation
     * Accessible par Admin uniquement
     */
    public function destroy($id)
    {
        $evaluation = Evaluation::findOrFail($id);
        
        // Vérifier que l'évaluation peut être supprimée
        if ($evaluation->statut === 'finalisee') {
            return response()->json([
                'success' => false,
                'message' => 'Impossible de supprimer une évaluation finalisée'
            ], 400);
        }
        
        $evaluation->delete();

        return response()->json([
            'success' => true,
            'message' => 'Évaluation supprimée avec succès'
        ]);
    }

    /**
     * Statistiques des évaluations
     * Accessible par RH, Patron et Admin
     */
    public function statistics(Request $request)
    {
        $dateDebut = $request->get('date_debut', Carbon::now()->startOfYear());
        $dateFin = $request->get('date_fin', Carbon::now()->endOfYear());
        
        $query = Evaluation::whereBetween('date_evaluation', [$dateDebut, $dateFin]);
        
        if ($request->has('user_id')) {
            $query->where('user_id', $request->user_id);
        }
        
        $evaluations = $query->get();
        
        $statistiques = [
            'periode' => [
                'debut' => $dateDebut,
                'fin' => $dateFin
            ],
            'total_evaluations' => $evaluations->count(),
            'evaluations_en_cours' => $evaluations->where('statut', 'en_cours')->count(),
            'evaluations_finalisees' => $evaluations->where('statut', 'finalisee')->count(),
            'evaluations_archivees' => $evaluations->where('statut', 'archivee')->count(),
            'note_moyenne' => $evaluations->avg('note_globale'),
            'note_maximale' => $evaluations->max('note_globale'),
            'note_minimale' => $evaluations->min('note_globale'),
            'evaluations_signees' => $evaluations->whereNotNull('date_signature_employe')->whereNotNull('date_signature_evaluateur')->count(),
            'par_type' => $evaluations->groupBy('type_evaluation')->map(function($group) {
                return [
                    'type' => $group->first()->getTypeLibelle(),
                    'count' => $group->count(),
                    'note_moyenne' => round($group->avg('note_globale'), 2)
                ];
            }),
            'par_utilisateur' => $evaluations->groupBy('user_id')->map(function($group, $userId) {
                $user = User::find($userId);
                return [
                    'utilisateur' => $user ? $user->nom . ' ' . $user->prenom : 'Inconnu',
                    'total_evaluations' => $group->count(),
                    'note_moyenne' => round($group->avg('note_globale'), 2),
                    'derniere_evaluation' => $group->sortByDesc('date_evaluation')->first()
                ];
            })
        ];
        
        return response()->json([
            'success' => true,
            'statistiques' => $statistiques,
            'message' => 'Statistiques des évaluations récupérées avec succès'
        ]);
    }

    /**
     * Créer une notification pour l'employé
     */
    private function creerNotificationEmploye($evaluation, $action = 'nouvelle')
    {
        $messages = [
            'nouvelle' => 'Une nouvelle évaluation vous a été assignée',
            'finalisee' => 'Votre évaluation a été finalisée'
        ];
        
        $titres = [
            'nouvelle' => 'Nouvelle évaluation',
            'finalisee' => 'Évaluation finalisée'
        ];
        
        \App\Jobs\SendNotificationJob::dispatch([
            'user_id' => $evaluation->user_id,
            'type' => 'evaluation',
            'titre' => $titres[$action],
            'message' => $messages[$action],
            'data' => [
                'evaluation_id' => $evaluation->id,
                'type_evaluation' => $evaluation->type_evaluation,
                'note_globale' => $evaluation->note_globale,
                'action' => $action
            ],
            'priorite' => 'normale'
        ]);
    }

    /**
     * Créer une notification pour l'évaluateur
     */
    private function creerNotificationEvaluateur($evaluation, $action)
    {
        $message = $action === 'signature_employe' 
            ? "L'employé a signé son évaluation"
            : "L'évaluation nécessite votre attention";
            
        \App\Jobs\SendNotificationJob::dispatch([
            'user_id' => $evaluation->evaluateur_id,
            'type' => 'evaluation',
            'titre' => 'Évaluation - Action requise',
            'message' => $message,
            'data' => [
                'evaluation_id' => $evaluation->id,
                'user_id' => $evaluation->user_id,
                'action' => $action
            ],
            'priorite' => 'normale'
        ]);
    }
}

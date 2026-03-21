<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\Controller;
use App\Services\NotificationService;
use App\Traits\SendsNotifications;
use App\Models\Reporting;
use App\Http\Resources\ReportingResource;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class UserReportingController extends Controller
{
    use SendsNotifications;

    protected $notificationService;

    public function __construct(NotificationService $notificationService)
    {
        $this->notificationService = $notificationService;
    }

    /**
     * Afficher la liste des reportings
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
            
            $query = Reporting::with(['user', 'approver', 'rejector']);

            // Filtrage par statut
            if ($request->has('status')) {
                $query->where('status', $request->status);
            }

            // Filtrage par date (accepter date_debut/date_fin ou start_date/end_date)
            $dateDebut = $request->get('date_debut', $request->get('start_date'));
            $dateFin = $request->get('date_fin', $request->get('end_date'));
            if ($dateDebut) {
                $query->where('report_date', '>=', $dateDebut);
            }
            if ($dateFin) {
                $query->where('report_date', '<=', $dateFin);
            }

            // Filtrage par utilisateur
            if ($request->has('user_id')) {
                $query->where('user_id', $request->user_id);
            }

            // Filtrage par nature
            if ($request->has('nature')) {
                $query->where('nature', $request->nature);
            }

            // Si commercial/comptable/technicien → filtre ses propres reportings
            if (in_array($user->role, [2, 3, 5])) {
                $query->where('user_id', $user->id);
            }

            $perPage = min((int) $request->get('per_page', 20), 100);
            $reportings = $query->orderBy('report_date', 'desc')->orderBy('created_at', 'desc')->paginate($perPage);

            return response()->json([
                'success' => true,
                'data' => ReportingResource::collection($reportings),
                'pagination' => [
                    'current_page' => $reportings->currentPage(),
                    'last_page' => $reportings->lastPage(),
                    'per_page' => $reportings->perPage(),
                    'total' => $reportings->total(),
                    'from' => $reportings->firstItem(),
                    'to' => $reportings->lastItem(),
                ],
                'message' => 'Liste des reportings récupérée avec succès',
            ], 200, [], JSON_UNESCAPED_UNICODE);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des reportings: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Afficher un reporting spécifique
     */
    public function show(Request $request, $id)
    {
        try {
            $reporting = Reporting::with(['user', 'approver', 'rejector'])->find($id);

            if (!$reporting) {
                return response()->json([
                    'success' => false,
                    'message' => 'Reporting non trouvé'
                ], 404);
            }

            return response()->json([
                'success' => true,
                'data' => new ReportingResource($reporting),
                'message' => 'Reporting récupéré avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération du reporting: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Créer un nouveau reporting
     */
    public function store(Request $request)
    {
        try {
            $user = $request->user();
            
            // Validation pour le nouveau formulaire de reporting
            $request->validate([
                'nature' => 'required|in:echange_telephonique,visite,depannage_visite,depannage_bureau,depannage_telephonique,programmation',
                'nom_societe' => 'required|string|max:255',
                'contact_societe' => 'nullable|string|max:255',
                'nom_personne' => 'required|string|max:255',
                'contact_personne' => 'nullable|string|max:255',
                'moyen_contact' => 'required|in:mail,whatsapp,linkedin',
                'produit_demarche' => 'nullable|string|max:255',
                'commentaire' => 'nullable|string',
                'type_relance' => 'nullable|in:telephonique,mail,rdv,relance_rdv',
                'relance_date_heure' => 'nullable|date|required_if:type_relance,rdv|required_if:type_relance,relance_rdv',
                'report_date' => 'nullable|date',
            ]);

            $reporting = new Reporting();
            $reporting->user_id = $user->id;
            $reporting->report_date = $request->report_date ?? now()->format('Y-m-d');
            $reporting->status = 'submitted';
            $reporting->submitted_at = now();
            
            // Nouveaux champs du formulaire (relance_rdv côté app = rdv en base)
            $reporting->nature = $request->nature;
            $reporting->nom_societe = $request->nom_societe;
            $reporting->contact_societe = $request->contact_societe;
            $reporting->nom_personne = $request->nom_personne;
            $reporting->contact_personne = $request->contact_personne;
            $reporting->moyen_contact = $request->moyen_contact;
            $reporting->produit_demarche = $request->produit_demarche;
            $reporting->commentaire = $request->commentaire;
            $reporting->type_relance = ($request->type_relance === 'relance_rdv') ? 'rdv' : $request->type_relance;
            $reporting->relance_date_heure = $request->relance_date_heure;
            
            $reporting->save();

            // Notifier le patron pour validation
            $this->safeNotify(function () use ($reporting) {
                $reporting->load('user');
                $this->notificationService->notifyNewReporting($reporting);
            });

            return response()->json([
                'success' => true,
                'data' => new ReportingResource($reporting->load(['user', 'approver'])),
                'message' => 'Reporting créé et soumis avec succès'
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la création du reporting: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Mettre à jour un reporting
     */
    public function update(Request $request, $id)
    {
        try {
            $user = $request->user();
            $reporting = Reporting::findOrFail($id);
            
            // Vérifier les permissions
            if ($reporting->user_id !== $user->id && !in_array($user->role, [1, 6])) {
                return response()->json([
                    'success' => false,
                    'message' => 'Accès refusé à ce reporting'
                ], 403);
            }
            
            // Vérifier que le reporting peut être modifié
            if (!$reporting->canBeEdited()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Ce reporting ne peut plus être modifié'
                ], 400);
            }

            $request->validate([
                'nature' => 'nullable|in:echange_telephonique,visite,depannage_visite,depannage_bureau,depannage_telephonique,programmation',
                'nom_societe' => 'nullable|string|max:255',
                'contact_societe' => 'nullable|string|max:255',
                'nom_personne' => 'nullable|string|max:255',
                'contact_personne' => 'nullable|string|max:255',
                'moyen_contact' => 'nullable|in:mail,whatsapp,linkedin',
                'produit_demarche' => 'nullable|string|max:255',
                'commentaire' => 'nullable|string',
                'type_relance' => 'nullable|in:telephonique,mail,rdv,relance_rdv',
                'relance_date_heure' => 'nullable|date|required_if:type_relance,rdv|required_if:type_relance,relance_rdv',
            ]);

            // Mettre à jour les champs si fournis
            if ($request->has('nature')) {
                $reporting->nature = $request->nature;
            }
            if ($request->has('nom_societe')) {
                $reporting->nom_societe = $request->nom_societe;
            }
            if ($request->has('contact_societe')) {
                $reporting->contact_societe = $request->contact_societe;
            }
            if ($request->has('nom_personne')) {
                $reporting->nom_personne = $request->nom_personne;
            }
            if ($request->has('contact_personne')) {
                $reporting->contact_personne = $request->contact_personne;
            }
            if ($request->has('moyen_contact')) {
                $reporting->moyen_contact = $request->moyen_contact;
            }
            if ($request->has('produit_demarche')) {
                $reporting->produit_demarche = $request->produit_demarche;
            }
            if ($request->has('commentaire')) {
                $reporting->commentaire = $request->commentaire;
            }
            if ($request->has('type_relance')) {
                $reporting->type_relance = ($request->type_relance === 'relance_rdv') ? 'rdv' : $request->type_relance;
            }
            if ($request->has('relance_date_heure')) {
                $reporting->relance_date_heure = $request->relance_date_heure;
            }
            
            $reporting->save();

            return response()->json([
                'success' => true,
                'data' => new ReportingResource($reporting->load(['user', 'approver'])),
                'message' => 'Reporting mis à jour avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la mise à jour du reporting: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Approuver un reporting
     */
    public function approve(Request $request, $id)
    {
        try {
            $user = request()->user();
            $reporting = Reporting::findOrFail($id);
            
            // Vérifier les permissions (seuls les admins et patrons peuvent approuver)
            if (!in_array($user->role, [1, 6])) {
                return response()->json([
                    'success' => false,
                    'message' => 'Accès refusé pour approuver ce reporting'
                ], 403);
            }
            
            $request->validate([
                'patron_note' => 'nullable|string|max:1000'
            ]);
            
            if ($reporting->approve($user->id, $request->patron_note)) {
                // Notifier l'auteur du reporting
                $this->safeNotify(function () use ($reporting) {
                    $this->notificationService->notifyReportingValidated($reporting);
                });

                return response()->json([
                    'success' => true,
                    'data' => new ReportingResource($reporting->load(['user', 'approver'])),
                    'message' => 'Reporting approuvé avec succès'
                ]);
            } else {
                return response()->json([
                    'success' => false,
                    'message' => 'Impossible d\'approuver ce reporting'
                ], 400);
            }

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'approbation du reporting: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Rejeter un reporting
     */
    public function reject(Request $request, $id)
    {
        try {
            $user = request()->user();
            $reporting = Reporting::findOrFail($id);
            
            // Vérifier les permissions (seuls les admins et patrons peuvent rejeter)
            if (!in_array($user->role, [1, 6])) {
                return response()->json([
                    'success' => false,
                    'message' => 'Accès refusé pour rejeter ce reporting'
                ], 403);
            }
            
            $request->validate([
                'reason' => 'required|string|max:1000'
            ]);
            
            if ($reporting->reject($user->id, $request->reason)) {
                // Notifier l'auteur du reporting
                $reason = $request->reason;
                $this->safeNotify(function () use ($reporting, $reason) {
                    $this->notificationService->notifyReportingRejected($reporting, $reason);
                });

                return response()->json([
                    'success' => true,
                    'data' => new ReportingResource($reporting->load(['user', 'approver', 'rejector'])),
                    'message' => 'Reporting rejeté avec succès'
                ]);
            } else {
                return response()->json([
                    'success' => false,
                    'message' => 'Impossible de rejeter ce reporting'
                ], 400);
            }

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du rejet du reporting: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Ajouter ou modifier la note du patron sur un rapport
     */
    public function addPatronNote(Request $request, $id)
    {
        try {
            $user = $request->user();
            
            // Vérifier les permissions (Patron ou Admin uniquement)
            if (!in_array($user->role, [1, 6])) {
                return response()->json([
                    'success' => false,
                    'message' => 'Accès non autorisé'
                ], 403);
            }

            // Valider les données
            $request->validate([
                'patron_note' => 'nullable|string|max:1000'
            ]);

            // Récupérer le rapport
            $reporting = Reporting::findOrFail($id);

            // Vérifier que le rapport est en attente de validation
            if ($reporting->status !== 'submitted') {
                return response()->json([
                    'success' => false,
                    'message' => 'La note ne peut être ajoutée que sur les rapports en attente de validation'
                ], 422);
            }

            // Mettre à jour la note (null ou chaîne vide supprime la note)
            $patronNote = $request->input('patron_note');
            if ($patronNote === '' || $patronNote === null) {
                $reporting->patron_note = null;
            } else {
                $reporting->patron_note = $patronNote;
            }
            $reporting->save();

            // Recharger avec les relations
            $reporting->refresh();
            $reporting->load(['user', 'approver']);

            return response()->json([
                'success' => true,
                'message' => 'Note enregistrée avec succès',
                'data' => [
                    'id' => $reporting->id,
                    'user_id' => $reporting->user_id,
                    'user_name' => $reporting->user_name,
                    'user_role' => $reporting->user_role,
                    'report_date' => $reporting->report_date?->format('Y-m-d\TH:i:s\Z'),
                    'status' => $reporting->status,
                    'patron_note' => $reporting->patron_note,
                    'updated_at' => $reporting->updated_at->format('Y-m-d\TH:i:s\Z')
                ]
            ], 200);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Rapport non trouvé'
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'enregistrement de la note: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Supprimer un reporting
     */
    public function destroy($id)
    {
        try {
            $user = request()->user();
            $reporting = Reporting::findOrFail($id);
            
            // Vérifier les permissions (seul l'auteur ou admin/patron peut supprimer)
            if ($reporting->user_id !== $user->id && !in_array($user->role, [1, 6])) {
                return response()->json([
                    'success' => false,
                    'message' => 'Accès refusé pour supprimer ce reporting'
                ], 403);
            }
            
            // Seuls les reportings soumis peuvent être supprimés (pas les approuvés)
            if ($reporting->status === 'approved') {
                return response()->json([
                    'success' => false,
                    'message' => 'Impossible de supprimer un reporting approuvé'
                ], 400);
            }
            
            $reporting->delete();

            return response()->json([
                'success' => true,
                'message' => 'Reporting supprimé avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la suppression du reporting: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Soumettre un reporting (obsolète - les reportings sont maintenant soumis automatiquement)
     * Gardée pour compatibilité avec l'API existante
     */
    public function submit($id)
    {
        try {
            $reporting = Reporting::findOrFail($id);
            
            if ($reporting->status === 'submitted') {
                return response()->json([
                    'success' => true,
                    'data' => new ReportingResource($reporting->load(['user', 'approver'])),
                    'message' => 'Ce reporting est déjà soumis (les reportings sont soumis automatiquement lors de leur création)'
                ]);
            }
            
            return response()->json([
                'success' => false,
                'message' => 'Impossible de soumettre ce reporting'
            ], 400);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la soumission du reporting: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Générer un reporting (obsolète - méthode supprimée avec la nouvelle logique)
     */
    public function generate(Request $request)
    {
        return response()->json([
            'success' => false,
            'message' => 'Cette méthode n\'est plus disponible. Utilisez la création de reporting avec le formulaire.'
        ], 410);
    }

    /**
     * Statistiques des reportings
     */
    public function statistics(Request $request)
    {
        try {
            $user = $request->user();
            
            $query = Reporting::query();
            
            // Si commercial/comptable/technicien → filtre ses propres reportings
            if (in_array($user->role, [2, 3, 5])) {
                $query->where('user_id', $user->id);
            }
            
            $stats = [
                'total' => $query->count(),
                'submitted' => (clone $query)->where('status', 'submitted')->count(),
                'approved' => (clone $query)->where('status', 'approved')->count(),
                'rejected' => (clone $query)->where('status', 'rejected')->count(),
                'par_nature' => [
                    'echange_telephonique' => (clone $query)->where('nature', 'echange_telephonique')->count(),
                    'visite' => (clone $query)->where('nature', 'visite')->count(),
                ],
                'par_moyen_contact' => [
                    'mail' => (clone $query)->where('moyen_contact', 'mail')->count(),
                    'whatsapp' => (clone $query)->where('moyen_contact', 'whatsapp')->count(),
                    'linkedin' => (clone $query)->where('moyen_contact', 'linkedin')->count(),
                ],
            ];

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
}

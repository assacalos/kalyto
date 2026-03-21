<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\Controller;
use App\Traits\ScopesByCompany;
use App\Models\JournalEntry;
use App\Models\Compte;
use App\Http\Resources\JournalEntryResource;
use Illuminate\Http\Request;
use Carbon\Carbon;

class JournalController extends Controller
{
    use ScopesByCompany;

    /**
     * Journal des entrées et sorties par mois.
     * Retourne: date, reference, libelle, categorie, mode_paiement, entree (CFA), sortie (CFA), solde (CFA).
     * Query: mois, annee (ex: mois=2, annee=2026) ou date_debut + date_fin
     */
    public function index(Request $request)
    {
        try {
            $user = $request->user();
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Utilisateur non authentifié',
                ], 401);
            }

            $query = JournalEntry::with('user');
            $this->scopeByCompany($query, $request);

            // Filtre par mois/année ou par plage de dates (obligatoire pour éviter de charger tout le journal)
            if ($request->filled('annee') && $request->filled('mois')) {
                $annee = (int) $request->annee;
                $mois = (int) $request->mois;
                $debut = Carbon::createFromDate($annee, $mois, 1)->startOfDay();
                $fin = $debut->copy()->endOfMonth();
                $query->byDateRange($debut->toDateString(), $fin->toDateString());
            } elseif ($request->filled('date_debut') && $request->filled('date_fin')) {
                $query->byDateRange($request->date_debut, $request->date_fin);
            } else {
                // Par défaut: mois courant si aucun filtre
                $now = Carbon::now();
                $query->byDateRange($now->copy()->startOfMonth()->toDateString(), $now->copy()->endOfMonth()->toDateString());
            }

            $query->ordered();

            $companyId = $this->effectiveCompanyId($request);
            // Solde initial = solde cumulé avant la période
            $soldeInitial = 0;
            if ($request->filled('annee') && $request->filled('mois')) {
                $avant = Carbon::createFromDate((int) $request->annee, (int) $request->mois, 1)->subDay();
                $soldeInitial = JournalEntry::soldeAu($avant->toDateString(), $companyId);
            } elseif ($request->filled('date_debut')) {
                $avant = Carbon::parse($request->date_debut)->subDay();
                $soldeInitial = JournalEntry::soldeAu($avant->toDateString(), $companyId);
            } else {
                $avant = Carbon::now()->startOfMonth()->subDay();
                $soldeInitial = JournalEntry::soldeAu($avant->toDateString(), $companyId);
            }

            $perPage = min((int) $request->get('per_page', 20), 100);
            $page = (int) $request->get('page', 1);
            $total = (clone $query)->count();

            // Solde au début de la page = solde_initial + sum(entree-sortie) des entrées précédentes dans la période
            $soldeDebutPage = (float) $soldeInitial;
            if ($page > 1) {
                $prevEntries = (clone $query)->skip(0)->take(($page - 1) * $perPage)->get();
                foreach ($prevEntries as $e) {
                    $soldeDebutPage += (float) $e->entree - (float) $e->sortie;
                }
            }

            $entries = (clone $query)->skip(($page - 1) * $perPage)->take($perPage)->get();

            $solde = round($soldeDebutPage, 2);
            $lignes = $entries->map(function ($entry) use (&$solde) {
                $solde = $solde + (float) $entry->entree - (float) $entry->sortie;
                return [
                    'id' => $entry->id,
                    'date' => $entry->date->format('Y-m-d'),
                    'reference' => $entry->reference,
                    'libelle' => $entry->libelle,
                    'categorie' => $entry->categorie,
                    'mode_paiement' => $entry->mode_paiement,
                    'mode_paiement_libelle' => $entry->mode_paiement_libelle,
                    'entree' => (float) $entry->entree,
                    'sortie' => (float) $entry->sortie,
                    'solde' => round($solde, 2),
                    'notes' => $entry->notes,
                    'created_at' => $entry->created_at?->format('Y-m-d H:i:s'),
                ];
            });

            $totalsPeriod = (clone $query)->selectRaw('COALESCE(SUM(entree), 0) as total_entrees, COALESCE(SUM(sortie), 0) as total_sorties')->first();

            return response()->json([
                'success' => true,
                'data' => [
                    'solde_initial' => round($soldeInitial, 2),
                    'lignes' => $lignes,
                    'solde_final' => round($solde, 2),
                    'total_entrees' => round((float) ($totalsPeriod->total_entrees ?? 0), 2),
                    'total_sorties' => round((float) ($totalsPeriod->total_sorties ?? 0), 2),
                ],
                'pagination' => [
                    'current_page' => $page,
                    'last_page' => (int) ceil($total / $perPage) ?: 1,
                    'per_page' => $perPage,
                    'total' => $total,
                    'from' => $total > 0 ? ($page - 1) * $perPage + 1 : null,
                    'to' => $total > 0 ? min($page * $perPage, $total) : null,
                ],
                'message' => 'Journal récupéré avec succès',
            ], 200, [], JSON_UNESCAPED_UNICODE);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération du journal: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Liste simple des écritures (sans solde cumulé) pour édition / suppression.
     */
    public function list(Request $request)
    {
        try {
            $user = $request->user();
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Utilisateur non authentifié',
                ], 401);
            }

            $query = JournalEntry::with('user')->ordered();
            $this->scopeByCompany($query, $request);

            if ($request->filled('annee') && $request->filled('mois')) {
                $query->byMonth((int) $request->annee, (int) $request->mois);
            }
            if ($request->filled('date_debut') && $request->filled('date_fin')) {
                $query->byDateRange($request->date_debut, $request->date_fin);
            }

            $perPage = min($request->get('per_page', 50), 200);
            $paginated = $query->paginate($perPage);

            return response()->json([
                'success' => true,
                'data' => JournalEntryResource::collection($paginated->items()),
                'pagination' => [
                    'current_page' => $paginated->currentPage(),
                    'last_page' => $paginated->lastPage(),
                    'per_page' => $paginated->perPage(),
                    'total' => $paginated->total(),
                ],
                'message' => 'Liste des écritures récupérée avec succès',
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Créer une écriture journal.
     */
    public function store(Request $request)
    {
        try {
            $user = $request->user();
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Utilisateur non authentifié',
                ], 401);
            }

            $request->validate([
                'compte_id' => 'nullable|exists:comptes,id',
                'date' => 'required|date',
                'reference' => 'nullable|string|max:100',
                'libelle' => 'required|string|max:500',
                'categorie' => 'nullable|string|max:100',
                'mode_paiement' => 'required|in:especes,virement,cheque,carte_bancaire,mobile_money,autre',
                'entree' => 'nullable|numeric|min:0',
                'sortie' => 'nullable|numeric|min:0',
                'notes' => 'nullable|string',
            ]);

            $entree = (float) ($request->input('entree', 0));
            $sortie = (float) ($request->input('sortie', 0));
            if ($entree < 0 || $sortie < 0) {
                return response()->json([
                    'success' => false,
                    'message' => 'Les montants entrée et sortie doivent être positifs.',
                ], 422);
            }

            $compteId = $request->input('compte_id');
            if (empty($compteId)) {
                $compteId = Compte::where('code', '51')->value('id');
            }

            $entry = new JournalEntry();
            $companyId = $this->effectiveCompanyId($request);
            if ($companyId !== null) {
                $entry->company_id = $companyId;
            }
            $entry->compte_id = $compteId;
            $entry->date = $request->date;
            $entry->reference = $request->reference;
            $entry->libelle = $request->libelle;
            $entry->categorie = $request->categorie;
            $entry->mode_paiement = $request->mode_paiement;
            $entry->entree = $entree;
            $entry->sortie = $sortie;
            $entry->user_id = $user->id;
            $entry->notes = $request->notes;
            $entry->save();

            return response()->json([
                'success' => true,
                'data' => new JournalEntryResource($entry->load('user')),
                'message' => 'Écriture enregistrée avec succès',
            ], 201);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Données invalides',
                'errors' => $e->errors(),
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'enregistrement: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Afficher une écriture.
     */
    public function show(Request $request, $id)
    {
        try {
            $query = JournalEntry::with('user');
            $this->scopeByCompany($query, $request);
            $entry = $query->find($id);
            if (!$entry) {
                return response()->json([
                    'success' => false,
                    'message' => 'Écriture non trouvée',
                ], 404);
            }
            return response()->json([
                'success' => true,
                'data' => new JournalEntryResource($entry),
                'message' => 'Écriture récupérée avec succès',
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Mettre à jour une écriture.
     */
    public function update(Request $request, $id)
    {
        try {
            $user = $request->user();
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Utilisateur non authentifié',
                ], 401);
            }

            $query = JournalEntry::query();
            $this->scopeByCompany($query, $request);
            $entry = $query->find($id);
            if (!$entry) {
                return response()->json([
                    'success' => false,
                    'message' => 'Écriture non trouvée',
                ], 404);
            }

            $request->validate([
                'compte_id' => 'nullable|exists:comptes,id',
                'date' => 'sometimes|date',
                'reference' => 'nullable|string|max:100',
                'libelle' => 'sometimes|string|max:500',
                'categorie' => 'nullable|string|max:100',
                'mode_paiement' => 'sometimes|in:especes,virement,cheque,carte_bancaire,mobile_money,autre',
                'entree' => 'nullable|numeric|min:0',
                'sortie' => 'nullable|numeric|min:0',
                'notes' => 'nullable|string',
            ]);

            if (array_key_exists('compte_id', $request->all())) {
                $entry->compte_id = $request->compte_id ?: Compte::where('code', '51')->value('id');
            }
            if ($request->has('date')) {
                $entry->date = $request->date;
            }
            if ($request->has('reference')) {
                $entry->reference = $request->reference;
            }
            if ($request->has('libelle')) {
                $entry->libelle = $request->libelle;
            }
            if ($request->has('categorie')) {
                $entry->categorie = $request->categorie;
            }
            if ($request->has('mode_paiement')) {
                $entry->mode_paiement = $request->mode_paiement;
            }
            if ($request->has('entree')) {
                $entry->entree = (float) $request->entree;
            }
            if ($request->has('sortie')) {
                $entry->sortie = (float) $request->sortie;
            }
            if (array_key_exists('notes', $request->all())) {
                $entry->notes = $request->notes;
            }
            $entry->save();

            return response()->json([
                'success' => true,
                'data' => new JournalEntryResource($entry->load('user')),
                'message' => 'Écriture mise à jour avec succès',
            ]);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Données invalides',
                'errors' => $e->errors(),
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Supprimer une écriture.
     */
    public function destroy(Request $request, $id)
    {
        try {
            $query = JournalEntry::query();
            $this->scopeByCompany($query, $request);
            $entry = $query->find($id);
            if (!$entry) {
                return response()->json([
                    'success' => false,
                    'message' => 'Écriture non trouvée',
                ], 404);
            }
            $entry->delete();
            return response()->json([
                'success' => true,
                'message' => 'Écriture supprimée avec succès',
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur: ' . $e->getMessage(),
            ], 500);
        }
    }
}

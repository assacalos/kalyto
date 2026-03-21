<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\Controller;
use App\Traits\ScopesByCompany;
use App\Models\Compte;
use App\Models\JournalEntry;
use Illuminate\Http\Request;
use Carbon\Carbon;

class BalanceController extends Controller
{
    /**
     * Balance comptable par compte sur une période.
     * GET /api/balance?date_debut=YYYY-MM-DD&date_fin=YYYY-MM-DD
     * ou ?mois=1&annee=2026
     * Retourne pour chaque compte ayant des mouvements : code, libelle, total_debit, total_credit, solde.
     */
    public function index(Request $request)
    {
        try {
            if (!$request->user()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Utilisateur non authentifié',
                ], 401);
            }

            if ($request->filled('annee') && $request->filled('mois')) {
                $debut = Carbon::createFromDate((int) $request->annee, (int) $request->mois, 1)->startOfDay();
                $fin = $debut->copy()->endOfMonth();
            } elseif ($request->filled('date_debut') && $request->filled('date_fin')) {
                $debut = Carbon::parse($request->date_debut)->startOfDay();
                $fin = Carbon::parse($request->date_fin)->endOfDay();
            } else {
                $now = Carbon::now();
                $debut = $now->copy()->startOfMonth();
                $fin = $now->copy()->endOfMonth();
            }

            $aggregatesQuery = JournalEntry::query()
                ->selectRaw('compte_id, COALESCE(SUM(entree), 0) as total_debit, COALESCE(SUM(sortie), 0) as total_credit')
                ->whereBetween('date', [$debut->toDateString(), $fin->toDateString()])
                ->whereNotNull('compte_id');
            $this->scopeByCompany($aggregatesQuery, $request);
            $aggregates = $aggregatesQuery->groupBy('compte_id')->get()->keyBy('compte_id');

            $comptes = Compte::actifs()->orderBy('code')->get();
            $rows = [];
            $totalDebit = 0;
            $totalCredit = 0;

            foreach ($comptes as $compte) {
                $agg = $aggregates->get($compte->id);
                $debit = $agg ? (float) $agg->total_debit : 0.0;
                $credit = $agg ? (float) $agg->total_credit : 0.0;
                $solde = $debit - $credit;
                $totalDebit += $debit;
                $totalCredit += $credit;
                $rows[] = [
                    'compte' => $compte->code,
                    'libelle_compte' => $compte->libelle,
                    'total_debit' => round($debit, 2),
                    'total_credit' => round($credit, 2),
                    'solde' => round($solde, 2),
                ];
            }

            return response()->json([
                'success' => true,
                'data' => [
                    'date_debut' => $debut->toDateString(),
                    'date_fin' => $fin->toDateString(),
                    'lignes' => $rows,
                    'total_debit' => round($totalDebit, 2),
                    'total_credit' => round($totalCredit, 2),
                    'solde_final' => round($totalDebit - $totalCredit, 2),
                ],
                'message' => 'Balance récupérée avec succès',
            ], 200, [], JSON_UNESCAPED_UNICODE);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur: ' . $e->getMessage(),
            ], 500);
        }
    }
}

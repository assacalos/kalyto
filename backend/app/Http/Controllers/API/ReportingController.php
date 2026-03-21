<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\Controller;
use App\Traits\CachesData;
use Illuminate\Http\Request;
use App\Models\Client;
use App\Models\Facture;
use App\Models\Paiement;
use App\Models\Attendance;
use App\Models\BonDeCommande;
use App\Models\Fournisseur;
use App\Models\User;
use Carbon\Carbon;

class ReportingController extends Controller
{
    use CachesData;
    /**
     * Tableau de bord général
     * Accessible par Patron et Admin
     */
    public function dashboard(Request $request)
    {
        $dateDebut = $request->get('date_debut', Carbon::now()->startOfMonth());
        $dateFin = $request->get('date_fin', Carbon::now()->endOfMonth());
        $dateKey = Carbon::parse($dateDebut)->format('Y-m-d');
        
        $dashboard = $this->rememberDailyStats('dashboard_stats', $dateKey, function () use ($dateDebut, $dateFin) {
            // Statistiques des clients
            $clients = Client::whereBetween('created_at', [$dateDebut, $dateFin])->get();
            $clientsApprouves = $clients->where('statut', 'approved')->count();
            $clientsEnAttente = $clients->where('statut', 'en_attente')->count();
            $clientsRejetes = $clients->where('statut', 'rejected')->count();
            
            // Statistiques des factures
            $factures = Facture::whereBetween('date_facture', [$dateDebut, $dateFin])->get();
            $montantTotalFactures = $factures->sum('montant');
            $facturesPayees = $factures->where('statut', 'payee')->count();
            $montantFacturesPayees = $factures->where('statut', 'payee')->sum('montant');
            
            // Statistiques des paiements
            $paiements = Paiement::whereBetween('date_paiement', [$dateDebut, $dateFin])->get();
            $montantTotalPaiements = $paiements->sum('montant');
            $paiementsValides = $paiements->where('statut', 'valide')->count();
            
            // Statistiques des pointages (attendances)
            $pointages = Attendance::where(function($q) use ($dateDebut, $dateFin) {
                $q->whereBetween('check_in_time', [$dateDebut, $dateFin])
                  ->orWhereBetween('check_out_time', [$dateDebut, $dateFin]);
            })->get();
            $pointagesValides = $pointages->where('status', 'valide')->count();
            
            // Statistiques des bons de commande
            $bonsDeCommande = BonDeCommande::whereBetween('date_commande', [$dateDebut, $dateFin])->get();
            $montantTotalCommandes = $bonsDeCommande->sum('montant_total');
            $bonsLivres = $bonsDeCommande->where('statut', 'livre')->count();
            
            return [
                'periode' => [
                    'debut' => $dateDebut,
                    'fin' => $dateFin
                ],
                'clients' => [
                    'total' => $clients->count(),
                    'approuves' => $clientsApprouves,
                    'en_attente' => $clientsEnAttente,
                    'rejetes' => $clientsRejetes,
                    'taux_approbation' => $clients->count() > 0 ? round(($clientsApprouves / $clients->count()) * 100, 2) : 0
                ],
                'factures' => [
                    'total' => $factures->count(),
                    'montant_total' => $montantTotalFactures,
                    'payees' => $facturesPayees,
                    'montant_payee' => $montantFacturesPayees,
                    'taux_paiement' => $montantTotalFactures > 0 ? round(($montantFacturesPayees / $montantTotalFactures) * 100, 2) : 0
                ],
                'paiements' => [
                    'total' => $paiements->count(),
                    'montant_total' => $montantTotalPaiements,
                    'valides' => $paiementsValides,
                    'taux_validation' => $paiements->count() > 0 ? round(($paiementsValides / $paiements->count()) * 100, 2) : 0
                ],
                'pointages' => [
                    'total' => $pointages->count(),
                    'valides' => $pointagesValides,
                    'taux_validation' => $pointages->count() > 0 ? round(($pointagesValides / $pointages->count()) * 100, 2) : 0
                ],
                'commandes' => [
                    'total' => $bonsDeCommande->count(),
                    'montant_total' => $montantTotalCommandes,
                    'livrees' => $bonsLivres,
                    'taux_livraison' => $bonsDeCommande->count() > 0 ? round(($bonsLivres / $bonsDeCommande->count()) * 100, 2) : 0
                ]
            ];
        });
        
        return response()->json([
            'success' => true,
            'dashboard' => $dashboard,
            'message' => 'Tableau de bord généré avec succès'
        ]);
    }

    /**
     * Rapports financiers
     * Accessible par Comptable, Patron et Admin
     */
    public function financial(Request $request)
    {
        $dateDebut = $request->get('date_debut', Carbon::now()->startOfMonth());
        $dateFin = $request->get('date_fin', Carbon::now()->endOfMonth());
        $dateKey = Carbon::parse($dateDebut)->format('Y-m-d');
        
        $rapport = $this->rememberDailyStats('financial_report', $dateKey, function () use ($dateDebut, $dateFin) {
            $factures = Facture::whereBetween('date_facture', [$dateDebut, $dateFin])->get();
            $paiements = Paiement::whereBetween('date_paiement', [$dateDebut, $dateFin])->get();
            
            return [
                'periode' => [
                    'debut' => $dateDebut,
                    'fin' => $dateFin
                ],
                'factures' => [
                    'total' => $factures->count(),
                    'montant_total' => $factures->sum('montant'),
                    'en_attente' => $factures->where('statut', 'en_attente')->count(),
                    'montant_en_attente' => $factures->where('statut', 'en_attente')->sum('montant'),
                    'payees' => $factures->where('statut', 'payee')->count(),
                    'montant_payee' => $factures->where('statut', 'payee')->sum('montant'),
                    'impayees' => $factures->where('statut', 'impayee')->count(),
                    'montant_impaye' => $factures->where('statut', 'impayee')->sum('montant')
                ],
                'paiements' => [
                    'total' => $paiements->count(),
                    'montant_total' => $paiements->sum('montant'),
                    'en_attente' => $paiements->where('statut', 'en_attente')->count(),
                    'montant_en_attente' => $paiements->where('statut', 'en_attente')->sum('montant'),
                    'valides' => $paiements->where('statut', 'valide')->count(),
                    'montant_valide' => $paiements->where('statut', 'valide')->sum('montant'),
                    'rejetes' => $paiements->where('statut', 'rejete')->count(),
                    'montant_rejete' => $paiements->where('statut', 'rejete')->sum('montant')
                ],
                'par_mode_paiement' => $paiements->groupBy('mode_paiement')->map(function($group) {
                    return [
                        'count' => $group->count(),
                        'montant' => $group->sum('montant')
                    ];
                })
            ];
        });
        
        return response()->json([
            'success' => true,
            'rapport' => $rapport,
            'message' => 'Rapport financier généré avec succès'
        ]);
    }

    /**
     * Rapports RH
     * Accessible par RH, Patron et Admin
     */
    public function hr(Request $request)
    {
        $dateDebut = $request->get('date_debut', Carbon::now()->startOfMonth());
        $dateFin = $request->get('date_fin', Carbon::now()->endOfMonth());
        $dateKey = Carbon::parse($dateDebut)->format('Y-m-d');
        
        $rapport = $this->rememberDailyStats('hr_report', $dateKey, function () use ($dateDebut, $dateFin) {
            $pointages = Pointage::whereBetween('date_pointage', [$dateDebut, $dateFin])->get();
            $users = User::all();
            
            return [
                'periode' => [
                    'debut' => $dateDebut,
                    'fin' => $dateFin
                ],
                'pointages' => [
                    'total' => $pointages->count(),
                    'valides' => $pointages->where('statut', 'valide')->count(),
                    'en_attente' => $pointages->where('statut', 'en_attente')->count(),
                    'rejetes' => $pointages->where('statut', 'rejete')->count()
                ],
                'par_utilisateur' => $users->map(function($user) use ($pointages) {
                    $userPointages = $pointages->where('user_id', $user->id);
                    return [
                        'user' => trim(($user->nom ?? '') . ' ' . ($user->prenom ?? '')),
                        'role' => $user->getRoleName(),
                        'total_pointages' => $userPointages->count(),
                        'pointages_valides' => $userPointages->where('status', 'valide')->count(),
                        'taux_presence' => $userPointages->count() > 0 ? round(($userPointages->where('status', 'valide')->count() / $userPointages->count()) * 100, 2) : 0
                    ];
                }),
                'par_type_pointage' => [
                    'check_in' => [
                        'count' => $pointages->whereNotNull('check_in_time')->count(),
                        'valides' => $pointages->whereNotNull('check_in_time')->where('status', 'valide')->count()
                    ],
                    'check_out' => [
                        'count' => $pointages->whereNotNull('check_out_time')->count(),
                        'valides' => $pointages->whereNotNull('check_out_time')->where('status', 'valide')->count()
                    ]
                ]
            ];
        });
        
        return response()->json([
            'success' => true,
            'rapport' => $rapport,
            'message' => 'Rapport RH généré avec succès'
        ]);
    }

    /**
     * Rapports commerciaux
     * Accessible par Commercial, Patron et Admin
     */
    public function commercial(Request $request)
    {
        $dateDebut = $request->get('date_debut', Carbon::now()->startOfMonth());
        $dateFin = $request->get('date_fin', Carbon::now()->endOfMonth());
        $dateKey = Carbon::parse($dateDebut)->format('Y-m-d');
        
        $rapport = $this->rememberDailyStats('commercial_report', $dateKey, function () use ($dateDebut, $dateFin) {
            $clients = Client::whereBetween('created_at', [$dateDebut, $dateFin])->get();
            $factures = Facture::whereBetween('date_facture', [$dateDebut, $dateFin])->get();
            
            return [
                'periode' => [
                    'debut' => $dateDebut,
                    'fin' => $dateFin
                ],
                'clients' => [
                    'total' => $clients->count(),
                    'approuves' => $clients->where('statut', 'approved')->count(),
                    'en_attente' => $clients->where('statut', 'en_attente')->count(),
                    'rejetes' => $clients->where('statut', 'rejected')->count()
                ],
                'factures' => [
                    'total' => $factures->count(),
                    'montant_total' => $factures->sum('montant'),
                    'moyenne_par_facture' => $factures->count() > 0 ? round($factures->avg('montant'), 2) : 0
                ],
                'par_commercial' => $clients->groupBy('user_id')->map(function($group, $userId) {
                    $user = User::find($userId);
                    return [
                        'commercial' => $user ? $user->nom . ' ' . $user->prenom : 'Commercial inconnu',
                        'clients_crees' => $group->count(),
                        'clients_approuves' => $group->where('statut', 'approved')->count(),
                        'taux_approbation' => $group->count() > 0 ? round(($group->where('statut', 'approved')->count() / $group->count()) * 100, 2) : 0
                    ];
                })
            ];
        });
        
        return response()->json([
            'success' => true,
            'rapport' => $rapport,
            'message' => 'Rapport commercial généré avec succès'
        ]);
    }
}
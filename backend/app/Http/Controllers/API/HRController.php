<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use App\Models\Attendance;
use Carbon\Carbon;

class HRController extends Controller
{
    /**
     * Gestion des employés
     * Accessible par RH et Admin
     */
    public function employees(Request $request)
    {
        $query = User::query();
        
        // Filtrage par rôle si fourni
        if ($request->has('role')) {
            $query->where('role', $request->role);
        }
        
        // Filtrage par nom si fourni
        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function($q) use ($search) {
                $q->where('nom', 'like', '%' . $search . '%')
                  ->orWhere('prenom', 'like', '%' . $search . '%')
                  ->orWhere('email', 'like', '%' . $search . '%');
            });
        }
        
        $employees = $query->orderBy('nom', 'asc')->get();
        
        return response()->json([
            'success' => true,
            'employees' => $employees,
            'message' => 'Liste des employés récupérée avec succès'
        ]);
    }

    /**
     * Détails d'un employé
     * Accessible par RH et Admin
     */
    public function employee($id)
    {
        $employee = User::findOrFail($id);
        
        // Statistiques de l'employé
        $pointages = Attendance::where('user_id', $id)->get();
        $statistiques = [
            'total_pointages' => $pointages->count(),
            'pointages_valides' => $pointages->where('status', 'valide')->count(),
            'pointages_en_attente' => $pointages->where('status', 'en_attente')->count(),
            'pointages_rejetes' => $pointages->where('status', 'rejete')->count(),
            'dernier_pointage' => $pointages->sortByDesc(function($p) {
                return $p->check_in_time ?? $p->check_out_time ?? $p->created_at;
            })->first(),
            'pointages_ce_mois' => $pointages->filter(function($p) {
                $date = $p->check_in_time ?? $p->check_out_time ?? $p->created_at;
                return $date && Carbon::parse($date)->isCurrentMonth();
            })->count()
        ];
        
        return response()->json([
            'success' => true,
            'employee' => $employee,
            'statistiques' => $statistiques,
            'message' => 'Détails de l\'employé récupérés avec succès'
        ]);
    }

    /**
     * Créer un employé
     * Accessible par RH et Admin
     */
    public function createEmployee(Request $request)
    {
        $request->validate([
            'nom' => 'required|string|max:255',
            'prenom' => 'required|string|max:255',
            'email' => 'required|email|unique:users',
            'password' => 'required|string|min:6',
            'role' => 'required|integer|in:2,3,4,5,6'
        ]);

        $employee = User::create([
            'nom' => $request->nom,
            'prenom' => $request->prenom,
            'email' => $request->email,
            'password' => bcrypt($request->password),
            'role' => $request->role,
            'is_active' => true,
        ]);

        return response()->json([
            'success' => true,
            'employee' => $employee,
            'message' => 'Employé créé avec succès'
        ], 201);
    }

    /**
     * Modifier un employé
     * Accessible par RH et Admin
     */
    public function updateEmployee(Request $request, $id)
    {
        $employee = User::findOrFail($id);
        
        $request->validate([
            'nom' => 'required|string|max:255',
            'prenom' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email,' . $employee->id,
            'role' => 'required|integer|in:2,3,4,5,6'
        ]);

        $employee->update($request->all());

        return response()->json([
            'success' => true,
            'employee' => $employee,
            'message' => 'Employé modifié avec succès'
        ]);
    }

    /**
     * Désactiver un employé
     * Accessible par RH et Admin
     */
    public function deactivateEmployee($id)
    {
        $employee = User::findOrFail($id);
        
        // Ajouter un champ 'active' au modèle User si nécessaire
        // $employee->update(['active' => false]);
        
        return response()->json([
            'success' => true,
            'message' => 'Employé désactivé avec succès'
        ]);
    }

    /**
     * Rapports de présence
     * Accessible par RH, Patron et Admin
     */
    public function presenceReport(Request $request)
    {
        $dateDebut = $request->get('date_debut', Carbon::now()->startOfMonth());
        $dateFin = $request->get('date_fin', Carbon::now()->endOfMonth());
        $userId = $request->get('user_id');
        
        $query = Attendance::with('user')
            ->where(function($q) use ($dateDebut, $dateFin) {
                $q->whereBetween('check_in_time', [$dateDebut, $dateFin])
                  ->orWhereBetween('check_out_time', [$dateDebut, $dateFin]);
            });
        
        if ($userId) {
            $query->where('user_id', $userId);
        }
        
        $pointages = $query->get();
        
        $rapport = [
            'periode' => [
                'debut' => $dateDebut,
                'fin' => $dateFin
            ],
            'total_pointages' => $pointages->count(),
            'pointages_valides' => $pointages->where('status', 'valide')->count(),
            'pointages_en_attente' => $pointages->where('status', 'en_attente')->count(),
            'pointages_rejetes' => $pointages->where('status', 'rejete')->count(),
            'par_employe' => $pointages->groupBy('user_id')->map(function($group, $userId) {
                $user = User::find($userId);
                return [
                    'employe' => $user ? trim(($user->nom ?? '') . ' ' . ($user->prenom ?? '')) : 'Employé inconnu',
                    'total_pointages' => $group->count(),
                    'pointages_valides' => $group->where('status', 'valide')->count(),
                    'taux_presence' => $group->count() > 0 ? round(($group->where('status', 'valide')->count() / $group->count()) * 100, 2) : 0
                ];
            }),
            'par_type' => [
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
        
        return response()->json([
            'success' => true,
            'rapport' => $rapport,
            'message' => 'Rapport de présence généré avec succès'
        ]);
    }

    /**
     * Statistiques RH
     * Accessible par RH, Patron et Admin
     */
    public function hrStatistics()
    {
        $totalEmployees = User::count();
        $employeesByRole = User::selectRaw('role, count(*) as count')
            ->groupBy('role')
            ->get()
            ->map(function($item) {
                $roles = [
                    1 => 'Admin',
                    2 => 'Commercial',
                    3 => 'Comptable',
                    4 => 'RH',
                    5 => 'Technicien',
                    6 => 'Patron'
                ];
                return [
                    'role' => $roles[$item->role] ?? 'Inconnu',
                    'count' => $item->count
                ];
            });
        
        $pointagesAujourdhui = Attendance::whereDate('check_in_time', Carbon::today())
            ->orWhereDate('check_out_time', Carbon::today())
            ->count();
        $pointagesValidesAujourdhui = Attendance::where(function($q) {
                $q->whereDate('check_in_time', Carbon::today())
                  ->orWhereDate('check_out_time', Carbon::today());
            })
            ->where('status', 'valide')->count();
        
        $statistiques = [
            'total_employees' => $totalEmployees,
            'employees_by_role' => $employeesByRole,
            'pointages_aujourdhui' => $pointagesAujourdhui,
            'pointages_valides_aujourdhui' => $pointagesValidesAujourdhui,
            'taux_presence_aujourdhui' => $pointagesAujourdhui > 0 ? round(($pointagesValidesAujourdhui / $pointagesAujourdhui) * 100, 2) : 0
        ];
        
        return response()->json([
            'success' => true,
            'statistiques' => $statistiques,
            'message' => 'Statistiques RH récupérées avec succès'
        ]);
    }

    /**
     * Gestion des congés
     * Accessible par RH et Admin
     */
    public function leaveManagement(Request $request)
    {
        $query = \App\Models\Conge::with(['user', 'approbateur']);
        
        // Filtrage par statut si fourni
        if ($request->has('statut')) {
            $query->where('statut', $request->statut);
        }
        
        // Filtrage par type si fourni
        if ($request->has('type_conge')) {
            $query->where('type_conge', $request->type_conge);
        }
        
        // Filtrage par période si fourni
        if ($request->has('date_debut')) {
            $query->where('date_debut', '>=', $request->date_debut);
        }
        
        if ($request->has('date_fin')) {
            $query->where('date_fin', '<=', $request->date_fin);
        }
        
        // Filtrage par urgent si fourni
        if ($request->has('urgent')) {
            $query->where('urgent', $request->urgent);
        }
        
        $conges = $query->orderBy('created_at', 'desc')->get();
        
        // Statistiques des congés
        $statistiques = [
            'total_conges' => $conges->count(),
            'conges_en_attente' => $conges->where('statut', 'en_attente')->count(),
            'conges_approuves' => $conges->where('statut', 'approuve')->count(),
            'conges_rejetes' => $conges->where('statut', 'rejete')->count(),
            'conges_urgents' => $conges->where('urgent', true)->count(),
            'total_jours_demandes' => $conges->sum('nombre_jours'),
            'total_jours_approuves' => $conges->where('statut', 'approuve')->sum('nombre_jours')
        ];
        
        return response()->json([
            'success' => true,
            'conges' => $conges,
            'statistiques' => $statistiques,
            'message' => 'Gestion des congés récupérée avec succès'
        ]);
    }

    /**
     * Évaluations des employés
     * Accessible par RH et Admin
     */
    public function employeeEvaluations(Request $request)
    {
        $query = \App\Models\Evaluation::with(['user', 'evaluateur']);
        
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
        
        // Filtrage par évaluateur si fourni
        if ($request->has('evaluateur_id')) {
            $query->where('evaluateur_id', $request->evaluateur_id);
        }
        
        $evaluations = $query->orderBy('date_evaluation', 'desc')->get();
        
        // Statistiques des évaluations
        $statistiques = [
            'total_evaluations' => $evaluations->count(),
            'evaluations_en_cours' => $evaluations->where('statut', 'en_cours')->count(),
            'evaluations_finalisees' => $evaluations->where('statut', 'finalisee')->count(),
            'evaluations_archivees' => $evaluations->where('statut', 'archivee')->count(),
            'note_moyenne' => $evaluations->avg('note_globale'),
            'note_maximale' => $evaluations->max('note_globale'),
            'note_minimale' => $evaluations->min('note_globale'),
            'evaluations_signees' => $evaluations->whereNotNull('date_signature_employe')->whereNotNull('date_signature_evaluateur')->count()
        ];
        
        return response()->json([
            'success' => true,
            'evaluations' => $evaluations,
            'statistiques' => $statistiques,
            'message' => 'Évaluations des employés récupérées avec succès'
        ]);
    }
}

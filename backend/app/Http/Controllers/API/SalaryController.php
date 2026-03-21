<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\Controller;
use App\Services\NotificationService;
use App\Traits\ScopesByCompany;
use App\Traits\SendsNotifications;
use App\Models\Salary;
use App\Models\SalaryComponent;
use App\Models\SalaryItem;
use App\Models\Payroll;
use App\Models\PayrollSetting;
use App\Models\User;
use App\Models\Employee;
use App\Http\Resources\SalaryResource;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class SalaryController extends Controller
{
    use ScopesByCompany, SendsNotifications;

    protected $notificationService;

    public function __construct(NotificationService $notificationService)
    {
        $this->notificationService = $notificationService;
    }
    /**
     * Afficher la liste des salaires
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
            
            $query = Salary::with(['employee', 'hr', 'salaryItems.salaryComponent']);

            // Filtrage par statut
            if ($request->has('status')) {
                $query->where('status', $request->status);
            }

            // Filtrage par employé (via employee_id)
            if ($request->has('employee_id') || $request->has('hr_id')) {
                $employeeId = $request->get('employee_id') ?? $request->get('hr_id');
                $query->where('employee_id', $employeeId);
            }

            // Filtrage par période
            if ($request->has('period')) {
                $query->where('period', $request->period);
            }

            // Filtrage par date (support date_debut/date_fin et start_date/end_date)
            $start_date = $request->get('start_date') ?? $request->get('date_debut');
            $end_date = $request->get('end_date') ?? $request->get('date_fin');
            
            if ($start_date) {
                $query->whereDate('salary_date', '>=', $start_date);
            }

            if ($end_date) {
                $query->whereDate('salary_date', '<=', $end_date);
            }

            // Si employé → filtre ses propres salaires (recherche dans la table employees)
            if ($user->role == 4) { // Employé
                $employee = Employee::where('email', $user->email)->first();
                if ($employee) {
                    $query->where('employee_id', $employee->id);
                }
            }
            $this->scopeByCompany($query, $request);

            $perPage = min((int) $request->get('per_page', 20), 100);
            $salaries = $query->orderBy('salary_date', 'desc')->paginate($perPage);

            return response()->json([
                'success' => true,
                'data' => SalaryResource::collection($salaries),
                'pagination' => [
                    'current_page' => $salaries->currentPage(),
                    'last_page' => $salaries->lastPage(),
                    'per_page' => $salaries->perPage(),
                    'total' => $salaries->total(),
                    'from' => $salaries->firstItem(),
                    'to' => $salaries->lastItem(),
                ],
                'message' => 'Liste des salaires récupérée avec succès',
            ], 200, [], JSON_UNESCAPED_UNICODE);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des salaires: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Afficher un salaire spécifique
     */
    public function show(Request $request, $id)
    {
        try {
            $query = Salary::with(['employee', 'hr', 'approver', 'payer', 'salaryItems.salaryComponent']);
            $this->scopeByCompany($query, $request);
            $salary = $query->find($id);

            if (!$salary) {
                return response()->json([
                    'success' => false,
                    'message' => 'Salaire non trouvé'
                ], 404);
            }

            // Extraire month et year de period
            $month = null;
            $year = null;
            if ($salary->period) {
                $parts = explode('-', $salary->period);
                if (count($parts) === 2) {
                    $year = (int)$parts[0];
                    $month = $parts[1];
                }
            }

            // Mapper le status pour compatibilité Flutter
            $statusFlutter = $salary->status;
            if ($salary->status === 'draft' || $salary->status === 'calculated') {
                $statusFlutter = 'pending';
            } elseif ($salary->status === 'cancelled') {
                $statusFlutter = 'rejected';
            }

            // Formater les données avec compatibilité Flutter
            $data = [
                'id' => $salary->id,
                'employee_id' => $salary->employee_id,
                'hr_id' => $salary->employee_id, // Compatibilité Flutter (alias)
                'employee_name' => $salary->employee_name,
                'employee_email' => $salary->employee?->email ?? null,
                'salary_number' => $salary->salary_number,
                'period' => $salary->period,
                'period_start' => $salary->period_start?->format('Y-m-d'),
                'period_end' => $salary->period_end?->format('Y-m-d'),
                'salary_date' => $salary->salary_date?->format('Y-m-d'),
                'base_salary' => $salary->base_salary,
                'gross_salary' => $salary->gross_salary,
                'net_salary' => $salary->net_salary,
                'total_allowances' => $salary->total_allowances,
                'total_deductions' => $salary->total_deductions,
                'bonus' => $salary->total_allowances ?? 0.0,
                'deductions' => $salary->total_deductions ?? 0.0,
                'month' => $month,
                'year' => $year,
                'status' => $statusFlutter,
                'status_libelle' => $salary->status_libelle,
                'notes' => $salary->notes,
                'justificatif' => $salary->justificatif ?? [],
                'created_by' => $salary->employee_id,
                'approved_by' => $salary->approved_by,
                'approved_at' => $salary->approved_at?->format('Y-m-d H:i:s'),
                'paid_at' => $salary->paid_at?->format('Y-m-d H:i:s'),
                'paid_by' => $salary->paid_by,
                'rejection_reason' => $salary->status === 'cancelled' ? $salary->notes : null,
                'calculated_at' => $salary->calculated_at?->format('Y-m-d H:i:s'),
                'created_at' => $salary->created_at->format('Y-m-d H:i:s'),
                'updated_at' => $salary->updated_at->format('Y-m-d H:i:s'),
            ];

            return response()->json([
                'success' => true,
                'data' => new SalaryResource($salary),
                'message' => 'Salaire récupéré avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération du salaire: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Créer un nouveau salaire
     */
    public function store(Request $request)
    {
        try {
            // Normaliser les champs camelCase vers snake_case (compatibilité Flutter)
            $data = $request->all();
            
            // Convertir employeeId/hr_id -> employee_id
            if (isset($data['employeeId']) && !isset($data['employee_id'])) {
                $data['employee_id'] = $data['employeeId'];
            } elseif (isset($data['hr_id']) && !isset($data['employee_id'])) {
                $data['employee_id'] = $data['hr_id'];
            }
            
            // Convertir baseSalary -> base_salary
            if (isset($data['baseSalary']) && !isset($data['base_salary'])) {
                $data['base_salary'] = $data['baseSalary'];
            }
            
            // Convertir netSalary -> net_salary
            if (isset($data['netSalary']) && !isset($data['net_salary'])) {
                $data['net_salary'] = $data['netSalary'];
            }
            
            // Mettre à jour la request avec les données normalisées
            $request->merge($data);
            
            // Log pour debug (peut être supprimé en production)
            \Log::info('Salary creation request data:', $data);

            // Validation flexible : accepter soit les champs backend, soit les champs Flutter
            $rules = [
                'employee_id' => 'required|exists:employees,id',
                'base_salary' => 'required|numeric|min:0',
                'notes' => 'nullable|string|max:1000',
                'justificatif' => 'nullable|array',
                'justificatif.*' => 'nullable|string', // Tableau de chemins de fichiers
                'bonus' => 'nullable|numeric|min:0', // Compatibilité Flutter
                'deductions' => 'nullable|numeric|min:0', // Compatibilité Flutter
                'net_salary' => 'nullable|numeric|min:0', // Compatibilité Flutter (sera recalculé)
            ];

            // Accepter soit period/period_start/period_end/salary_date (backend), soit month/year (Flutter)
            if ($request->has('period') || $request->has('period_start') || $request->has('salary_date')) {
                // Format backend complet
                $rules['period'] = 'sometimes|string';
                $rules['period_start'] = 'sometimes|date';
                $rules['period_end'] = 'sometimes|date|after:period_start';
                $rules['salary_date'] = 'sometimes|date';
            } else {
                // Format Flutter (month/year)
                $rules['month'] = 'required_without:period'; // Peut être string ou int
                $rules['year'] = 'required_without:period|integer|min:2000|max:2100';
            }

            $validated = $request->validate($rules);

            DB::beginTransaction();

            // Générer les valeurs manquantes depuis month/year (compatibilité Flutter)
            $period = null;
            $periodStart = null;
            $periodEnd = null;
            $salaryDate = null;

            if (isset($validated['period'])) {
                // Format backend
                $period = $validated['period'];
                $periodStart = $validated['period_start'] ?? null;
                $periodEnd = $validated['period_end'] ?? null;
                $salaryDate = $validated['salary_date'] ?? null;
            } else {
                // Format Flutter : générer depuis month et year
                // Gérer month comme string ou int
                $monthValue = $validated['month'];
                if (is_numeric($monthValue)) {
                    $month = str_pad((string)(int)$monthValue, 2, '0', STR_PAD_LEFT);
                } else {
                    $month = str_pad($monthValue, 2, '0', STR_PAD_LEFT);
                }
                
                $year = (int)$validated['year'];
                $monthInt = (int)$month;
                
                // Validation : mois entre 1 et 12
                if ($monthInt < 1 || $monthInt > 12) {
                    throw new \Exception('Le mois doit être entre 1 et 12');
                }
                
                // Générer period (format "YYYY-MM")
                $period = $year . '-' . $month;
                
                // Générer period_start (premier jour du mois)
                $periodStart = \Carbon\Carbon::create($year, $monthInt, 1)->format('Y-m-d');
                
                // Générer period_end (dernier jour du mois)
                $periodEnd = \Carbon\Carbon::create($year, $monthInt, 1)->endOfMonth()->format('Y-m-d');
                
                // Générer salary_date (par défaut: fin du mois + 5 jours)
                $salaryDate = \Carbon\Carbon::create($year, $monthInt, 1)
                    ->endOfMonth()
                    ->addDays(5)
                    ->format('Y-m-d');
            }

            // Si period_start ou period_end manquent, les générer depuis period
            if (!$periodStart || !$periodEnd) {
                $parts = explode('-', $period);
                if (count($parts) === 2) {
                    $year = (int)$parts[0];
                    $month = (int)$parts[1];
                    if (!$periodStart) {
                        $periodStart = \Carbon\Carbon::create($year, $month, 1)->format('Y-m-d');
                    }
                    if (!$periodEnd) {
                        $periodEnd = \Carbon\Carbon::create($year, $month, 1)->endOfMonth()->format('Y-m-d');
                    }
                }
            }

            // Si salary_date manque, le générer (fin du mois + 5 jours)
            if (!$salaryDate && $periodEnd) {
                $salaryDate = \Carbon\Carbon::parse($periodEnd)->addDays(5)->format('Y-m-d');
            }

            $data = [
                'employee_id' => $validated['employee_id'],
                'salary_number' => Salary::generateSalaryNumber(),
                'period' => $period,
                'period_start' => $periodStart,
                'period_end' => $periodEnd,
                'salary_date' => $salaryDate,
                'base_salary' => $validated['base_salary'],
                'gross_salary' => 0,
                'net_salary' => $validated['net_salary'] ?? 0, // Accepter net_salary de Flutter (sera recalculé après)
                'status' => 'draft',
                'notes' => $validated['notes'] ?? null,
                'justificatif' => $validated['justificatif'] ?? [],
            ];
if ($this->effectiveCompanyId($request) !== null) {
            $data['company_id'] = $this->effectiveCompanyId($request);
            }
            $salary = Salary::create($data);

            DB::commit();

            // Formater la réponse avec compatibilité Flutter
            $salary = $salary->load(['employee', 'hr']);
            $month = null;
            $year = null;
            if ($salary->period) {
                $parts = explode('-', $salary->period);
                if (count($parts) === 2) {
                    $year = (int)$parts[0];
                    $month = $parts[1];
                }
            }

            $responseData = [
                'id' => $salary->id,
                'employee_id' => $salary->employee_id,
                'hr_id' => $salary->employee_id, // Compatibilité Flutter (alias)
                'employee_name' => $salary->employee_name,
                'employee_email' => $salary->employee?->email ?? null,
                'base_salary' => $salary->base_salary,
                'bonus' => $salary->total_allowances ?? 0.0,
                'deductions' => $salary->total_deductions ?? 0.0,
                'net_salary' => $salary->net_salary,
                'month' => $month,
                'year' => $year,
                'status' => 'pending', // Mappé pour Flutter
                'notes' => $salary->notes,
                'justificatif' => $salary->justificatif ?? [],
                'created_by' => $salary->employee_id,
                'created_at' => $salary->created_at->format('Y-m-d H:i:s'),
                'updated_at' => $salary->updated_at->format('Y-m-d H:i:s'),
                'period' => $salary->period,
                'period_start' => $salary->period_start?->format('Y-m-d'),
                'period_end' => $salary->period_end?->format('Y-m-d'),
                'salary_date' => $salary->salary_date?->format('Y-m-d'),
            ];

            // Notifier le patron lors de la création
            $this->safeNotify(function () use ($salary) {
                $this->notificationService->notifyNewSalaire($salary);
            });

            return response()->json([
                'success' => true,
                'data' => $responseData,
                'message' => 'Salaire créé avec succès'
            ], 201);

        } catch (\Illuminate\Validation\ValidationException $e) {
            DB::rollback();
            return response()->json([
                'success' => false,
                'message' => 'Erreur de validation',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            DB::rollback();
            \Log::error('Salary creation error: ' . $e->getMessage(), [
                'trace' => $e->getTraceAsString(),
                'request_data' => $request->all()
            ]);
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la création du salaire: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Mettre à jour un salaire
     */
    public function update(Request $request, $id)
    {
        try {
            $salary = Salary::find($id);

            if (!$salary) {
                return response()->json([
                    'success' => false,
                    'message' => 'Salaire non trouvé'
                ], 404);
            }

            if (!$salary->canBeEdited()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Ce salaire ne peut plus être modifié'
                ], 400);
            }

            $validated = $request->validate([
                'base_salary' => 'sometimes|numeric|min:0',
                'salary_date' => 'sometimes|date',
                'notes' => 'nullable|string|max:1000',
                'justificatif' => 'nullable|array',
                'justificatif.*' => 'nullable|string', // Tableau de chemins de fichiers
            ]);

            $salary->update($validated);

            return response()->json([
                'success' => true,
                'data' => $salary->load(['employee', 'hr']),
                'message' => 'Salaire mis à jour avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la mise à jour du salaire: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Supprimer un salaire
     */
    public function destroy($id)
    {
        try {
            $salary = Salary::find($id);

            if (!$salary) {
                return response()->json([
                    'success' => false,
                    'message' => 'Salaire non trouvé'
                ], 404);
            }

            if (!$salary->canBeEdited()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Ce salaire ne peut plus être supprimé'
                ], 400);
            }

            $salary->delete();

            return response()->json([
                'success' => true,
                'message' => 'Salaire supprimé avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la suppression du salaire: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Calculer un salaire
     */
    public function calculate($id)
    {
        try {
            $salary = Salary::find($id);

            if (!$salary) {
                return response()->json([
                    'success' => false,
                    'message' => 'Salaire non trouvé'
                ], 404);
            }

            if ($salary->calculateSalary()) {
                return response()->json([
                    'success' => true,
                    'data' => $salary->load(['employee', 'hr', 'salaryItems.salaryComponent']),
                    'message' => 'Salaire calculé avec succès'
                ]);
            } else {
                return response()->json([
                    'success' => false,
                    'message' => 'Ce salaire ne peut pas être calculé'
                ], 400);
            }

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du calcul du salaire: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Approuver un salaire
     */
    public function approve(Request $request, $id)
    {
        try {
            $salary = Salary::find($id);

            if (!$salary) {
                return response()->json([
                    'success' => false,
                    'message' => 'Salaire non trouvé'
                ], 404);
            }

            // Si le salaire est en pending, le calculer d'abord
            if ($salary->status === 'pending' || $salary->status === 'draft') {
                if (!$salary->calculateSalary()) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Impossible de calculer ce salaire pour l\'approbation'
                    ], 400);
                }
                // Recharger le salaire après calcul
                $salary->refresh();
            }

            $notes = $request->get('notes');

            if ($salary->approve($request->user()->id, $notes)) {
                // Notifier l'employé concerné
                if ($salary->employee_id) {
                    $this->safeNotify(function () use ($salary) {
                        $salary->load('employee');
                        $this->notificationService->notifySalaireValidated($salary);
                    });
                }

                // Recharger le salaire avec ses relations
                $salary->refresh();
                $salary->load(['employee', 'hr', 'approver', 'salaryItems.salaryComponent']);

                return response()->json([
                    'success' => true,
                    'data' => $salary,
                    'message' => 'Salaire approuvé avec succès'
                ]);
            } else {
                return response()->json([
                    'success' => false,
                    'message' => 'Ce salaire ne peut pas être approuvé. Statut actuel: ' . $salary->status . '. Les statuts acceptés sont: calculated'
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
     * Marquer un salaire comme payé
     */
    public function markAsPaid(Request $request, $id)
    {
        try {
            $salary = Salary::find($id);

            if (!$salary) {
                return response()->json([
                    'success' => false,
                    'message' => 'Salaire non trouvé'
                ], 404);
            }

            if ($salary->markAsPaid($request->user()->id)) {
                return response()->json([
                    'success' => true,
                    'data' => $salary->load(['employee', 'hr']),
                    'message' => 'Salaire marqué comme payé'
                ]);
            } else {
                return response()->json([
                    'success' => false,
                    'message' => 'Ce salaire ne peut pas être marqué comme payé'
                ], 400);
            }

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du marquage: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Statistiques des salaires
     */
    public function statistics(Request $request)
    {
        try {
            $startDate = $request->get('date_debut');
            $endDate = $request->get('date_fin');

            $stats = Salary::getSalaryStats($startDate, $endDate);

            // Ajouter les champs attendus par Flutter
            $totalEmployees = Employee::where('status', 'active')->count();
            $pendingCount = ($stats['draft_salaries'] ?? 0) + ($stats['calculated_salaries'] ?? 0);
            
            // Calculer les salaires par mois
            $query = Salary::query();
            if ($startDate && $endDate) {
                $query->whereBetween('salary_date', [$startDate, $endDate]);
            }
            
            $salariesByMonth = $query->selectRaw('period, SUM(net_salary) as total')
                ->groupBy('period')
                ->orderBy('period')
                ->get()
                ->mapWithKeys(function ($item) {
                    return [$item->period => (float)$item->total];
                })
                ->toArray();

            $countByMonth = $query->selectRaw('period, COUNT(*) as count')
                ->groupBy('period')
                ->orderBy('period')
                ->get()
                ->mapWithKeys(function ($item) {
                    return [$item->period => (int)$item->count];
                })
                ->toArray();

            // Calculer les montants par statut
            $pendingQuery = Salary::query();
            $approvedQuery = Salary::query();
            $paidQuery = Salary::query();
            
            if ($startDate && $endDate) {
                $pendingQuery->whereBetween('salary_date', [$startDate, $endDate]);
                $approvedQuery->whereBetween('salary_date', [$startDate, $endDate]);
                $paidQuery->whereBetween('salary_date', [$startDate, $endDate]);
            }
            
            $pendingSalariesAmount = (float)$pendingQuery->whereIn('status', ['draft', 'calculated'])->sum('net_salary');
            $approvedSalariesAmount = (float)$approvedQuery->where('status', 'approved')->sum('net_salary');
            $paidSalariesAmount = (float)$paidQuery->where('status', 'paid')->sum('net_salary');
            
            // Ajouter les données compatibles Flutter
            $stats['total_salaries'] = (float)($stats['total_net_salary'] ?? 0);
            $stats['pending_salaries'] = $pendingSalariesAmount;
            $stats['approved_salaries'] = $approvedSalariesAmount;
            $stats['paid_salaries'] = $paidSalariesAmount;
            $stats['total_employees'] = $totalEmployees;
            $stats['pending_count'] = $pendingCount;
            $stats['approved_count'] = (int)$approvedQuery->where('status', 'approved')->count();
            $stats['paid_count'] = (int)$paidQuery->where('status', 'paid')->count();
            $stats['salaries_by_month'] = $salariesByMonth;
            $stats['count_by_month'] = $countByMonth;

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
     * Récupérer les composants de salaire
     */
    public function components()
    {
        try {
            $components = SalaryComponent::getActiveComponents();

            return response()->json([
                'success' => true,
                'data' => $components,
                'message' => 'Composants de salaire récupérés avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des composants: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les paramètres de paie
     */
    public function settings()
    {
        try {
            $settings = PayrollSetting::getAllSettings();

            return response()->json([
                'success' => true,
                'data' => $settings,
                'message' => 'Paramètres de paie récupérés avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des paramètres: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Valider un salaire (alias pour approve - compatibilité Flutter)
     */
    public function validateSalary(Request $request, $id)
    {
        return $this->approve($request, $id);
    }

    /**
     * Rejeter un salaire (compatibilité Flutter)
     */
    public function reject(Request $request, $id)
    {
        try {
            $salary = Salary::find($id);

            if (!$salary) {
                return response()->json([
                    'success' => false,
                    'message' => 'Salaire non trouvé'
                ], 404);
            }

            $validated = $request->validate([
                'reason' => 'nullable|string|max:1000'
            ]);

            if ($salary->cancel($validated['reason'] ?? null)) {
                // Notifier l'employé concerné
                $reason = $validated['reason'] ?? 'Rejeté';
                if ($salary->employee_id) {
                    $this->safeNotify(function () use ($salary, $reason) {
                        $salary->load('employee');
                        $this->notificationService->notifySalaireRejected($salary, $reason);
                    });
                }

                return response()->json([
                    'success' => true,
                    'data' => $salary->load(['employee', 'hr']),
                    'message' => 'Salaire rejeté avec succès'
                ]);
            } else {
                return response()->json([
                    'success' => false,
                    'message' => 'Ce salaire ne peut pas être rejeté'
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
     * Récupérer les salaires en attente (compatibilité Flutter)
     */
    public function pending(Request $request)
    {
        try {
            $query = Salary::with(['employee', 'hr', 'salaryItems.salaryComponent'])
                ->whereIn('status', ['draft', 'calculated']);

            // Filtrage par employé (via employee_id)
            if ($request->has('employee_id') || $request->has('hr_id')) {
                $employeeId = $request->get('employee_id') ?? $request->get('hr_id');
                $query->where('employee_id', $employeeId);
            }

            // Filtrage par période
            if ($request->has('period')) {
                $query->where('period', $request->period);
            }

            // Filtrage par mois et année (compatibilité Flutter)
            if ($request->has('month')) {
                $month = $request->month;
                $year = $request->has('year') ? $request->year : date('Y');
                $query->where('period', $year . '-' . str_pad($month, 2, '0', STR_PAD_LEFT));
            }

            // Pagination
            $perPage = min($request->get('per_page', 15), 100); // Limite max 100 par page
            $salaries = $query->orderBy('salary_date', 'desc')->paginate($perPage);

            // Transformer les données avec compatibilité Flutter (même logique que index)
            $salaries->getCollection()->transform(function ($salary) {
                $month = null;
                $year = null;
                if ($salary->period) {
                    $parts = explode('-', $salary->period);
                    if (count($parts) === 2) {
                        $year = (int)$parts[0];
                        $month = $parts[1];
                    }
                }

                $statusFlutter = 'pending'; // Toujours pending pour cette route

                return [
                    'id' => $salary->id,
                    'employee_id' => $salary->employee_id,
                    'hr_id' => $salary->employee_id, // Compatibilité Flutter (alias)
                    'employee_name' => $salary->employee_name,
                    'employee_email' => $salary->employee?->email ?? null,
                    'base_salary' => $salary->base_salary,
                    'bonus' => $salary->total_allowances ?? 0.0,
                    'deductions' => $salary->total_deductions ?? 0.0,
                    'net_salary' => $salary->net_salary,
                    'month' => $month,
                    'year' => $year,
                    'status' => $statusFlutter,
                    'notes' => $salary->notes,
                    'justificatif' => $salary->justificatif ?? [],
                    'created_by' => $salary->employee_id,
                    'created_at' => $salary->created_at->format('Y-m-d H:i:s'),
                    'updated_at' => $salary->updated_at->format('Y-m-d H:i:s'),
                ];
            });

            return response()->json([
                'success' => true,
                'data' => $salaries,
                'message' => 'Salaires en attente récupérés avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des salaires en attente: ' . $e->getMessage()
            ], 500);
        }
    }
    
    /**
     * Compteur de salaires avec filtres
     */
    public function count(Request $request)
    {
        try {
            $user = $request->user();
            
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Utilisateur non authentifié'
                ], 401);
            }
            
            $validated = $request->validate([
                'status' => 'nullable|string',
                'start_date' => 'nullable|date',
                'end_date' => 'nullable|date|after_or_equal:start_date',
                'employee_id' => 'nullable|integer|exists:employees,id',
            ]);
            
            $query = Salary::query();
            
            // Filtre par statut
            if (isset($validated['status'])) {
                $query->where('status', $validated['status']);
            }
            
            // Filtres de date
            if (isset($validated['start_date'])) {
                $query->whereDate('salary_date', '>=', $validated['start_date']);
            }
            if (isset($validated['end_date'])) {
                $query->whereDate('salary_date', '<=', $validated['end_date']);
            }
            
            // Filtre par employee_id
            if (isset($validated['employee_id'])) {
                $query->where('employee_id', $validated['employee_id']);
            }
            
            // Si employé → filtre ses propres salaires
            if ($user->role == 4) { // Employé
                $employee = Employee::where('email', $user->email)->first();
                if ($employee) {
                    $query->where('employee_id', $employee->id);
                }
            }
            
            return response()->json([
                'success' => true,
                'count' => $query->count(),
            ], 200);
            
        } catch (\Exception $e) {
            \Log::error('SalaryController::count - Erreur', [
                'message' => $e->getMessage(),
            ]);
            
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du comptage: ' . $e->getMessage(),
            ], 500);
        }
    }
    
    /**
     * Statistiques agrégées des salaires (format standardisé)
     */
    public function stats(Request $request)
    {
        try {
            $user = $request->user();
            
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Utilisateur non authentifié'
                ], 401);
            }
            
            $validated = $request->validate([
                'status' => 'nullable|string',
                'start_date' => 'nullable|date',
                'end_date' => 'nullable|date|after_or_equal:start_date',
                'employee_id' => 'nullable|integer|exists:employees,id',
            ]);
            
            $query = Salary::query();
            
            // Filtres de date
            if (isset($validated['start_date'])) {
                $query->whereDate('salary_date', '>=', $validated['start_date']);
            }
            if (isset($validated['end_date'])) {
                $query->whereDate('salary_date', '<=', $validated['end_date']);
            }
            
            // Filtre par statut
            if (isset($validated['status'])) {
                $query->where('status', $validated['status']);
            }
            
            // Filtre par employee_id
            if (isset($validated['employee_id'])) {
                $query->where('employee_id', $validated['employee_id']);
            }
            
            // Si employé → filtre ses propres salaires
            if ($user->role == 4) { // Employé
                $employee = Employee::where('email', $user->email)->first();
                if ($employee) {
                    $query->where('employee_id', $employee->id);
                }
            }
            
            return response()->json([
                'success' => true,
                'data' => [
                    'count' => $query->count(),
                    'total_net_salary' => $query->sum('net_salary'),
                    'average_net_salary' => $query->avg('net_salary'),
                    'min_net_salary' => $query->min('net_salary'),
                    'max_net_salary' => $query->max('net_salary'),
                    'total_gross_salary' => $query->sum('gross_salary'),
                ],
            ], 200);
            
        } catch (\Exception $e) {
            \Log::error('SalaryController::stats - Erreur', [
                'message' => $e->getMessage(),
            ]);
            
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des statistiques: ' . $e->getMessage(),
            ], 500);
        }
    }
}
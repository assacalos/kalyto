<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\Controller;
use App\Traits\CachesData;
use App\Traits\SendsNotifications;
use App\Models\Employee;
use App\Models\EmployeeDocument;
use App\Models\EmployeeLeave;
use App\Models\EmployeePerformance;
use App\Http\Resources\EmployeeResource;
use App\Services\NotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class EmployeeController extends Controller
{
    use CachesData, SendsNotifications;

    protected $notificationService;

    public function __construct(NotificationService $notificationService)
    {
        $this->notificationService = $notificationService;
    }
    /**
     * Afficher la liste des employés
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
            
            // Charger les relations avec gestion d'erreur
            // Utiliser des closures pour s'assurer que les foreign keys sont toujours sélectionnées
            $query = Employee::with([
                'creator' => function($q) {
                    $q->select('id', 'nom', 'prenom');
                },
                'updater' => function($q) {
                    $q->select('id', 'nom', 'prenom');
                },
                'documents',
                'leaves',
                'performances'
            ]);

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

            // Filtrage par genre
            if ($request->has('gender')) {
                $query->where('gender', $request->gender);
            }

            // Filtrage par type de contrat
            if ($request->has('contract_type')) {
                $query->where('contract_type', $request->contract_type);
            }

            // Filtrage par recherche (search) - recherche dans nom, prénom, email, poste
            if ($request->has('search')) {
                $search = $request->search;
                $query->where(function ($q) use ($search) {
                    $q->where('first_name', 'like', '%' . $search . '%')
                      ->orWhere('last_name', 'like', '%' . $search . '%')
                      ->orWhere('email', 'like', '%' . $search . '%')
                      ->orWhere('position', 'like', '%' . $search . '%');
                });
            }

            // Filtrage par nom (pour compatibilité)
            if ($request->has('name')) {
                $query->where(function ($q) use ($request) {
                    $q->where('first_name', 'like', '%' . $request->name . '%')
                      ->orWhere('last_name', 'like', '%' . $request->name . '%');
                });
            }

            // Filtrage par email (pour compatibilité)
            if ($request->has('email')) {
                $query->where('email', 'like', '%' . $request->email . '%');
            }

            // Filtrage par contrat expirant
            if ($request->has('contract_expiring')) {
                if ($request->contract_expiring === 'true') {
                    $query->contractExpiring();
                }
            }

            // Filtrage par contrat expiré
            if ($request->has('contract_expired')) {
                if ($request->contract_expired === 'true') {
                    $query->contractExpired();
                }
            }

            // Filtrage par date d'embauche
            if ($request->has('hire_date_from')) {
                $query->where('hire_date', '>=', $request->hire_date_from);
            }

            if ($request->has('hire_date_to')) {
                $query->where('hire_date', '<=', $request->hire_date_to);
            }

            $perPage = min((int) $request->get('limit', $request->get('per_page', 20)), 100);
            $employees = $query->orderBy('first_name')->paginate($perPage);

            return response()->json([
                'success' => true,
                'data' => EmployeeResource::collection($employees),
                'pagination' => [
                    'current_page' => $employees->currentPage(),
                    'last_page' => $employees->lastPage(),
                    'per_page' => $employees->perPage(),
                    'total' => $employees->total(),
                    'from' => $employees->firstItem(),
                    'to' => $employees->lastItem(),
                ],
                'message' => 'Liste des employés récupérée avec succès',
            ], 200, [], JSON_UNESCAPED_UNICODE);

        } catch (\Exception $e) {
            \Log::error('EmployeeController index error', [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
                'user_id' => $request->user()?->id,
            ]);
            
            $errorMessage = 'Erreur lors de la récupération des employés';
            if (config('app.debug')) {
                $errorMessage .= ': ' . $e->getMessage();
            }
            
            return response()->json([
                'success' => false,
                'message' => $errorMessage
            ], 500);
        }
    }

    /**
     * Afficher un employé spécifique
     */
    public function show($id)
    {
        try {
            $employee = Employee::with(['creator', 'updater', 'documents', 'leaves', 'performances'])->find($id);

            if (!$employee) {
                return response()->json([
                    'success' => false,
                    'message' => 'Employé non trouvé'
                ], 404);
            }

            return response()->json([
                'success' => true,
                'data' => new EmployeeResource($employee),
                'message' => 'Employé récupéré avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération de l\'employé: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Créer un nouvel employé
     */
    public function store(Request $request)
    {
        try {
            $validated = $request->validate([
                'first_name' => 'required|string|max:255',
                'last_name' => 'required|string|max:255',
                'email' => 'required|email|unique:employees,email',
                'phone' => 'nullable|string|max:50',
                'address' => 'nullable|string',
                'birth_date' => 'nullable|date',
                'gender' => 'nullable|in:male,female,other',
                'marital_status' => 'nullable|in:single,married,divorced,widowed',
                'nationality' => 'nullable|string|max:100',
                'id_number' => 'nullable|string|max:50',
                'social_security_number' => 'nullable|string|max:50',
                'position' => 'nullable|string|max:255',
                'department' => 'nullable|string|max:255',
                'manager' => 'nullable|string|max:255',
                'hire_date' => 'nullable|date',
                'contract_start_date' => 'nullable|date',
                'contract_end_date' => 'nullable|date|after:contract_start_date',
                'contract_type' => 'nullable|in:permanent,temporary,internship,consultant',
                'salary' => 'nullable|numeric|min:0',
                'currency' => 'nullable|in:fcfa,eur,usd',
                'work_schedule' => 'nullable|in:full_time,part_time,flexible,shift',
                'status' => 'nullable|in:active,inactive,terminated,on_leave',
                'profile_picture' => 'nullable|string|max:255',
                'notes' => 'nullable|string'
            ]);

            DB::beginTransaction();

            $employee = Employee::create([
                'first_name' => $validated['first_name'],
                'last_name' => $validated['last_name'],
                'email' => $validated['email'],
                'phone' => $validated['phone'] ?? null,
                'address' => $validated['address'] ?? null,
                'birth_date' => $validated['birth_date'] ?? null,
                'gender' => $validated['gender'] ?? null,
                'marital_status' => $validated['marital_status'] ?? null,
                'nationality' => $validated['nationality'] ?? null,
                'id_number' => $validated['id_number'] ?? null,
                'social_security_number' => $validated['social_security_number'] ?? null,
                'position' => $validated['position'] ?? null,
                'department' => $validated['department'] ?? null,
                'manager' => $validated['manager'] ?? null,
                'hire_date' => $validated['hire_date'] ?? null,
                'contract_start_date' => $validated['contract_start_date'] ?? null,
                'contract_end_date' => $validated['contract_end_date'] ?? null,
                'contract_type' => $validated['contract_type'] ?? null,
                'salary' => $validated['salary'] ?? null,
                'currency' => $validated['currency'] ?? 'fcfa',
                'work_schedule' => $validated['work_schedule'] ?? null,
                'status' => $validated['status'] ?? 'active',
                'profile_picture' => $validated['profile_picture'] ?? null,
                'notes' => $validated['notes'] ?? null,
                'created_by' => $request->user()->id
            ]);

            DB::commit();

            // Notifier le patron pour validation
            $this->safeNotify(function () use ($employee) {
                $this->notificationService->notifyNewEmploye($employee);
            });

            return response()->json([
                'success' => true,
                'data' => $this->formatEmployee($employee->load(['creator', 'documents', 'leaves', 'performances'])),
                'message' => 'Employé créé avec succès'
            ], 201);

        } catch (\Exception $e) {
            DB::rollback();
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la création de l\'employé: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Mettre à jour un employé
     */
    public function update(Request $request, $id)
    {
        try {
            $employee = Employee::find($id);

            if (!$employee) {
                return response()->json([
                    'success' => false,
                    'message' => 'Employé non trouvé'
                ], 404);
            }

            $validated = $request->validate([
                'first_name' => 'sometimes|string|max:255',
                'last_name' => 'sometimes|string|max:255',
                'email' => 'sometimes|email|unique:employees,email,' . $id,
                'phone' => 'nullable|string|max:50',
                'address' => 'nullable|string',
                'birth_date' => 'nullable|date',
                'gender' => 'nullable|in:male,female,other',
                'marital_status' => 'nullable|in:single,married,divorced,widowed',
                'nationality' => 'nullable|string|max:100',
                'id_number' => 'nullable|string|max:50',
                'social_security_number' => 'nullable|string|max:50',
                'position' => 'nullable|string|max:255',
                'department' => 'nullable|string|max:255',
                'manager' => 'nullable|string|max:255',
                'hire_date' => 'nullable|date',
                'contract_start_date' => 'nullable|date',
                'contract_end_date' => 'nullable|date|after:contract_start_date',
                'contract_type' => 'nullable|in:permanent,temporary,internship,consultant',
                'salary' => 'nullable|numeric|min:0',
                'currency' => 'nullable|in:fcfa,eur,usd',
                'work_schedule' => 'nullable|in:full_time,part_time,flexible,shift',
                'status' => 'sometimes|in:active,inactive,terminated,on_leave',
                'profile_picture' => 'nullable|string|max:255',
                'notes' => 'nullable|string'
            ]);

            $employee->update(array_merge($validated, [
                'updated_by' => $request->user()->id
            ]));

            return response()->json([
                'success' => true,
                'data' => $employee->load(['creator', 'updater']),
                'message' => 'Employé mis à jour avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la mise à jour de l\'employé: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Supprimer un employé
     */
    public function destroy($id)
    {
        try {
            $employee = Employee::find($id);

            if (!$employee) {
                return response()->json([
                    'success' => false,
                    'message' => 'Employé non trouvé'
                ], 404);
            }

            $employee->delete();

            return response()->json([
                'success' => true,
                'message' => 'Employé supprimé avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la suppression de l\'employé: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Activer un employé
     */
    public function activate($id)
    {
        try {
            $employee = Employee::find($id);

            if (!$employee) {
                return response()->json([
                    'success' => false,
                    'message' => 'Employé non trouvé'
                ], 404);
            }

            $employee->activate();

            return response()->json([
                'success' => true,
                'message' => 'Employé activé avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'activation de l\'employé: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Désactiver un employé
     */
    public function deactivate($id)
    {
        try {
            $employee = Employee::find($id);

            if (!$employee) {
                return response()->json([
                    'success' => false,
                    'message' => 'Employé non trouvé'
                ], 404);
            }

            $employee->deactivate();

            return response()->json([
                'success' => true,
                'message' => 'Employé désactivé avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la désactivation de l\'employé: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Terminer un employé
     */
    public function terminate(Request $request, $id)
    {
        try {
            $employee = Employee::find($id);

            if (!$employee) {
                return response()->json([
                    'success' => false,
                    'message' => 'Employé non trouvé'
                ], 404);
            }

            $validated = $request->validate([
                'reason' => 'nullable|string|max:1000'
            ]);

            $employee->terminate($validated['reason']);

            return response()->json([
                'success' => true,
                'message' => 'Employé terminé avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la termination de l\'employé: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Mettre en congé un employé
     */
    public function putOnLeave($id)
    {
        try {
            $employee = Employee::find($id);

            if (!$employee) {
                return response()->json([
                    'success' => false,
                    'message' => 'Employé non trouvé'
                ], 404);
            }

            $employee->putOnLeave();

            return response()->json([
                'success' => true,
                'message' => 'Employé mis en congé avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la mise en congé de l\'employé: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Mettre à jour le salaire
     */
    public function updateSalary(Request $request, $id)
    {
        try {
            $employee = Employee::find($id);

            if (!$employee) {
                return response()->json([
                    'success' => false,
                    'message' => 'Employé non trouvé'
                ], 404);
            }

            $validated = $request->validate([
                'salary' => 'required|numeric|min:0',
                'currency' => 'nullable|string|max:10'
            ]);

            $employee->updateSalary($validated['salary'], $request->user()->id);

            if (isset($validated['currency'])) {
                $employee->update(['currency' => $validated['currency']]);
            }

            return response()->json([
                'success' => true,
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
     * Mettre à jour le contrat
     */
    public function updateContract(Request $request, $id)
    {
        try {
            $employee = Employee::find($id);

            if (!$employee) {
                return response()->json([
                    'success' => false,
                    'message' => 'Employé non trouvé'
                ], 404);
            }

            $validated = $request->validate([
                'contract_start_date' => 'required|date',
                'contract_end_date' => 'required|date|after:contract_start_date',
                'contract_type' => 'required|in:permanent,temporary,intern,consultant'
            ]);

            $employee->updateContract(
                $validated['contract_start_date'],
                $validated['contract_end_date'],
                $validated['contract_type'],
                $request->user()->id
            );

            return response()->json([
                'success' => true,
                'message' => 'Contrat mis à jour avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la mise à jour du contrat: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Statistiques des employés
     */
    public function statistics(Request $request)
    {
        try {
            $dateKey = \Carbon\Carbon::now()->format('Y-m-d');
            $stats = $this->rememberDailyStats('employee_stats', $dateKey, function () {
                return Employee::getEmployeeStats();
            });

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
     * Récupérer les employés par département
     */
    public function byDepartment($department)
    {
        try {
            $employees = Employee::getEmployeesByDepartment($department);

            return response()->json([
                'success' => true,
                'data' => $employees,
                'message' => 'Employés du département récupérés avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des employés du département: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les employés par poste
     */
    public function byPosition($position)
    {
        try {
            $employees = Employee::getEmployeesByPosition($position);

            return response()->json([
                'success' => true,
                'data' => $employees,
                'message' => 'Employés du poste récupérés avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des employés du poste: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les employés avec contrat expirant
     */
    public function contractExpiring()
    {
        try {
            $employees = Employee::getContractExpiringEmployees();

            return response()->json([
                'success' => true,
                'data' => $employees,
                'message' => 'Employés avec contrat expirant récupérés avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des employés avec contrat expirant: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les employés avec contrat expiré
     */
    public function contractExpired()
    {
        try {
            $employees = Employee::getContractExpiredEmployees();

            return response()->json([
                'success' => true,
                'data' => $employees,
                'message' => 'Employés avec contrat expiré récupérés avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des employés avec contrat expiré: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Formater un employé au format attendu par le frontend
     */
    private function formatEmployee($employee)
    {
        return [
            'id' => $employee->id,
            'first_name' => $employee->first_name,
            'last_name' => $employee->last_name,
            'email' => $employee->email,
            'phone' => $employee->phone,
            'address' => $employee->address,
            'birth_date' => $employee->birth_date?->format('Y-m-d\TH:i:s\Z'),
            'gender' => $employee->gender,
            'marital_status' => $employee->marital_status,
            'nationality' => $employee->nationality,
            'id_number' => $employee->id_number,
            'social_security_number' => $employee->social_security_number,
            'position' => $employee->position,
            'department' => $employee->department,
            'manager' => $employee->manager,
            'hire_date' => $employee->hire_date?->format('Y-m-d\TH:i:s\Z'),
            'contract_start_date' => $employee->contract_start_date?->format('Y-m-d\TH:i:s\Z'),
            'contract_end_date' => $employee->contract_end_date?->format('Y-m-d\TH:i:s\Z'),
            'contract_type' => $employee->contract_type,
            'salary' => $employee->salary ? (float)$employee->salary : null,
            'currency' => $employee->currency ?? 'fcfa',
            'work_schedule' => $employee->work_schedule,
            'status' => $employee->status,
            'profile_picture' => $employee->profile_picture,
            'notes' => $employee->notes,
            'created_at' => $employee->created_at->format('Y-m-d\TH:i:s\Z'),
            'updated_at' => $employee->updated_at->format('Y-m-d\TH:i:s\Z'),
            'documents' => $employee->relationLoaded('documents') ? $employee->documents->map(function ($document) {
                return [
                    'id' => $document->id,
                    'employee_id' => $document->employee_id,
                    'name' => $document->name,
                    'type' => $document->type,
                    'description' => $document->description,
                    'file_path' => $document->file_path,
                    'file_size' => $document->file_size,
                    'expiry_date' => $document->expiry_date?->format('Y-m-d\TH:i:s\Z'),
                    'is_required' => $document->is_required,
                    'created_at' => $document->created_at->format('Y-m-d\TH:i:s\Z'),
                    'created_by' => $document->creator_name ?? 'N/A'
                ];
            }) : [],
            'leaves' => $employee->relationLoaded('leaves') ? $employee->leaves->map(function ($leave) {
                return [
                    'id' => $leave->id,
                    'employee_id' => $leave->employee_id,
                    'type' => $leave->type,
                    'type_libelle' => $leave->type_libelle ?? null,
                    'start_date' => $leave->start_date?->format('Y-m-d\TH:i:s\Z'),
                    'end_date' => $leave->end_date?->format('Y-m-d\TH:i:s\Z'),
                    'total_days' => $leave->total_days,
                    'duration' => $leave->duration ?? null,
                    'reason' => $leave->reason,
                    'status' => $leave->status,
                    'status_libelle' => $leave->status_libelle ?? null,
                    'approved_by' => $leave->approved_by ? (string)$leave->approved_by : null,
                    'approver_name' => $leave->approver_name ?? null,
                    'approved_at' => $leave->approved_at?->format('Y-m-d\TH:i:s\Z'),
                    'rejection_reason' => $leave->rejection_reason,
                    'comments' => $leave->comments ?? null,
                    'is_pending' => $leave->is_pending ?? false,
                    'is_approved' => $leave->is_approved ?? false,
                    'is_rejected' => $leave->is_rejected ?? false,
                    'is_current' => $leave->is_current ?? false,
                    'is_upcoming' => $leave->is_upcoming ?? false,
                    'is_past' => $leave->is_past ?? false,
                    'creator_name' => $leave->creator_name ?? null,
                    'created_by' => $leave->created_by ? (string)$leave->created_by : null,
                    'created_at' => $leave->created_at->format('Y-m-d\TH:i:s\Z')
                ];
            }) : [],
            'performances' => $employee->relationLoaded('performances') ? $employee->performances->map(function ($performance) {
                return [
                    'id' => $performance->id,
                    'employee_id' => $performance->employee_id,
                    'period' => $performance->period,
                    'rating' => $performance->rating ? (float)$performance->rating : null,
                    'comments' => $performance->comments,
                    'goals' => $performance->goals,
                    'achievements' => $performance->achievements,
                    'areas_for_improvement' => $performance->areas_for_improvement,
                    'status' => $performance->status,
                    'reviewed_by' => $performance->reviewed_by,
                    'reviewed_at' => $performance->reviewed_at?->format('Y-m-d\TH:i:s\Z'),
                    'created_at' => $performance->created_at->format('Y-m-d\TH:i:s\Z'),
                    'created_by' => $performance->creator_name ?? 'N/A'
                ];
            }) : []
        ];
    }

    /**
     * Recherche d'employés
     */
    public function search(Request $request)
    {
        try {
            $query = $request->get('q', '');
            
            if (empty($query)) {
                return response()->json([
                    'success' => true,
                    'data' => []
                ]);
            }

            $employees = Employee::where(function ($q) use ($query) {
                $q->where('first_name', 'like', '%' . $query . '%')
                  ->orWhere('last_name', 'like', '%' . $query . '%')
                  ->orWhere('email', 'like', '%' . $query . '%')
                  ->orWhere('position', 'like', '%' . $query . '%');
            })
            ->select('id', 'first_name', 'last_name', 'email', 'position', 'department')
            ->limit(20)
            ->get();

            return response()->json([
                'success' => true,
                'data' => $employees->map(function ($employee) {
                    return [
                        'id' => $employee->id,
                        'first_name' => $employee->first_name,
                        'last_name' => $employee->last_name,
                        'email' => $employee->email,
                        'position' => $employee->position,
                        'department' => $employee->department
                    ];
                })
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la recherche: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les départements
     */
    public function departments()
    {
        try {
            $departments = Employee::whereNotNull('department')
                ->distinct()
                ->orderBy('department')
                ->pluck('department')
                ->filter()
                ->values();

            // Si aucun département n'existe, retourner une liste par défaut
            if ($departments->isEmpty()) {
                $departments = collect([
                    'Technique',
                    'Ressources Humaines',
                    'Commercial',
                    'Comptabilité',
                    'Direction',
                    'Support'
                ]);
            }

            return response()->json([
                'success' => true,
                'data' => $departments
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des départements: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les postes
     */
    public function positions()
    {
        try {
            $positions = Employee::whereNotNull('position')
                ->distinct()
                ->orderBy('position')
                ->pluck('position')
                ->filter()
                ->values();

            // Si aucun poste n'existe, retourner une liste par défaut
            if ($positions->isEmpty()) {
                $positions = collect([
                    'Développeur',
                    'Chef de projet',
                    'Manager RH',
                    'Comptable',
                    'Directeur',
                    'Commercial'
                ]);
            }

            return response()->json([
                'success' => true,
                'data' => $positions
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des postes: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Statistiques des employés (alias pour /employees/stats)
     */
    public function stats(Request $request)
    {
        return $this->statistics($request);
    }

    /**
     * Approuver un congé
     */
    public function approveLeave(Request $request, $leaveId)
    {
        try {
            $leave = EmployeeLeave::find($leaveId);

            if (!$leave) {
                return response()->json([
                    'success' => false,
                    'message' => 'Congé non trouvé'
                ], 404);
            }

            if ($leave->status !== 'pending') {
                return response()->json([
                    'success' => false,
                    'message' => 'Ce congé a déjà été traité'
                ], 400);
            }

            $validated = $request->validate([
                'comments' => 'nullable|string|max:1000'
            ]);

            $leave->approve($request->user()->id, $validated['comments'] ?? null);

            return response()->json([
                'success' => true,
                'message' => 'Congé approuvé avec succès',
                'data' => [
                    'id' => $leave->id,
                    'status' => $leave->status,
                    'approved_by' => $leave->approved_by,
                    'approved_at' => $leave->approved_at?->format('Y-m-d\TH:i:s\Z')
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'approbation du congé: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Rejeter un congé
     */
    public function rejectLeave(Request $request, $leaveId)
    {
        try {
            $leave = EmployeeLeave::find($leaveId);

            if (!$leave) {
                return response()->json([
                    'success' => false,
                    'message' => 'Congé non trouvé'
                ], 404);
            }

            if ($leave->status !== 'pending') {
                return response()->json([
                    'success' => false,
                    'message' => 'Ce congé a déjà été traité'
                ], 400);
            }

            $validated = $request->validate([
                'reason' => 'required|string|max:1000'
            ]);

            $leave->reject($request->user()->id, $validated['reason']);

            return response()->json([
                'success' => true,
                'message' => 'Congé rejeté',
                'data' => [
                    'id' => $leave->id,
                    'status' => $leave->status,
                    'rejection_reason' => $leave->rejection_reason,
                    'approved_by' => $leave->approved_by,
                    'approved_at' => $leave->approved_at?->format('Y-m-d\TH:i:s\Z')
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du rejet du congé: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Ajouter un document à un employé
     */
    public function addDocument(Request $request, $employeeId)
    {
        try {
            $employee = Employee::find($employeeId);

            if (!$employee) {
                return response()->json([
                    'success' => false,
                    'message' => 'Employé non trouvé'
                ], 404);
            }

            $validated = $request->validate([
                'name' => 'required|string|max:255',
                'type' => 'required|in:contract,id_card,passport,diploma,certificate,medical,other',
                'description' => 'nullable|string',
                'file_path' => 'nullable|string|max:500',
                'file_size' => 'nullable|string|max:50',
                'expiry_date' => 'nullable|date',
                'is_required' => 'nullable|boolean'
            ]);

            $document = EmployeeDocument::create([
                'employee_id' => $employee->id,
                'name' => $validated['name'],
                'type' => $validated['type'],
                'description' => $validated['description'] ?? null,
                'file_path' => $validated['file_path'] ?? null,
                'file_size' => $validated['file_size'] ?? null,
                'expiry_date' => $validated['expiry_date'] ?? null,
                'is_required' => $validated['is_required'] ?? false,
                'created_by' => $request->user()->id ?? null
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Document ajouté avec succès',
                'data' => [
                    'id' => $document->id,
                    'employee_id' => $document->employee_id,
                    'name' => $document->name,
                    'type' => $document->type,
                    'description' => $document->description,
                    'file_path' => $document->file_path,
                    'file_size' => $document->file_size,
                    'expiry_date' => $document->expiry_date?->format('Y-m-d\TH:i:s\Z'),
                    'is_required' => $document->is_required,
                    'created_at' => $document->created_at->format('Y-m-d\TH:i:s\Z'),
                    'created_by' => $document->creator_name ?? 'N/A'
                ]
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'ajout du document: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Ajouter un congé à un employé
     */
    public function addLeave(Request $request, $employeeId)
    {
        try {
            $employee = Employee::find($employeeId);

            if (!$employee) {
                return response()->json([
                    'success' => false,
                    'message' => 'Employé non trouvé'
                ], 404);
            }

            $validated = $request->validate([
                'type' => 'required|in:annual,sick,maternity,paternity,personal,unpaid',
                'start_date' => 'required|date',
                'end_date' => 'required|date|after_or_equal:start_date',
                'reason' => 'nullable|string'
            ]);

            // Calculer le nombre total de jours
            $startDate = \Carbon\Carbon::parse($validated['start_date']);
            $endDate = \Carbon\Carbon::parse($validated['end_date']);
            $totalDays = $startDate->diffInDays($endDate) + 1;

            $leave = EmployeeLeave::create([
                'employee_id' => $employee->id,
                'type' => $validated['type'],
                'start_date' => $validated['start_date'],
                'end_date' => $validated['end_date'],
                'total_days' => $totalDays,
                'reason' => $validated['reason'] ?? null,
                'status' => 'pending',
                'created_by' => $request->user()->id ?? null
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Congé ajouté avec succès',
                'data' => [
                    'id' => $leave->id,
                    'employee_id' => $leave->employee_id,
                    'type' => $leave->type,
                    'start_date' => $leave->start_date->format('Y-m-d\TH:i:s\Z'),
                    'end_date' => $leave->end_date->format('Y-m-d\TH:i:s\Z'),
                    'total_days' => $leave->total_days,
                    'reason' => $leave->reason,
                    'status' => $leave->status,
                    'created_at' => $leave->created_at->format('Y-m-d\TH:i:s\Z')
                ]
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'ajout du congé: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Ajouter une performance à un employé
     */
    public function addPerformance(Request $request, $employeeId)
    {
        try {
            $employee = Employee::find($employeeId);

            if (!$employee) {
                return response()->json([
                    'success' => false,
                    'message' => 'Employé non trouvé'
                ], 404);
            }

            $validated = $request->validate([
                'period' => 'required|string|max:100',
                'rating' => 'required|numeric|min:0|max:5',
                'comments' => 'nullable|string',
                'goals' => 'nullable|string',
                'achievements' => 'nullable|string',
                'areas_for_improvement' => 'nullable|string'
            ]);

            $performance = EmployeePerformance::create([
                'employee_id' => $employee->id,
                'period' => $validated['period'],
                'rating' => $validated['rating'],
                'comments' => $validated['comments'] ?? null,
                'goals' => $validated['goals'] ?? null,
                'achievements' => $validated['achievements'] ?? null,
                'areas_for_improvement' => $validated['areas_for_improvement'] ?? null,
                'status' => 'draft',
                'created_by' => $request->user()->id ?? null
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Performance ajoutée avec succès',
                'data' => [
                    'id' => $performance->id,
                    'employee_id' => $performance->employee_id,
                    'period' => $performance->period,
                    'rating' => (float)$performance->rating,
                    'comments' => $performance->comments,
                    'goals' => $performance->goals,
                    'achievements' => $performance->achievements,
                    'areas_for_improvement' => $performance->areas_for_improvement,
                    'status' => $performance->status,
                    'created_at' => $performance->created_at->format('Y-m-d\TH:i:s\Z'),
                    'created_by' => $performance->creator_name ?? 'N/A'
                ]
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'ajout de la performance: ' . $e->getMessage()
            ], 500);
        }
    }
}
<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\Controller;
use App\Services\NotificationService;
use App\Traits\CachesData;
use App\Traits\SendsNotifications;
use App\Models\EmployeeLeave;
use App\Models\Employee;
use App\Http\Resources\EmployeeLeaveResource;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;

class LeaveRequestController extends Controller
{
    use CachesData, SendsNotifications;

    protected $notificationService;

    public function __construct(NotificationService $notificationService)
    {
        $this->notificationService = $notificationService;
    }
    /**
     * Liste de toutes les demandes de congé
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
            
            $query = EmployeeLeave::with(['employee', 'approver', 'creator']);

            // Filtrage par statut
            if ($request->has('status')) {
                $query->where('status', $request->status);
            }

            // Filtrage par type de congé
            if ($request->has('leave_type')) {
                $query->where('type', $request->leave_type);
            }
            
            // Alias pour 'type'
            if ($request->has('type')) {
                $query->where('type', $request->type);
            }

            // Filtrage par employé
            if ($request->has('employee_id')) {
                $query->where('employee_id', $request->employee_id);
            }

            // Filtrage par date de début
            if ($request->has('start_date')) {
                $query->where('start_date', '>=', $request->start_date);
            }

            // Filtrage par date de fin
            if ($request->has('end_date')) {
                $query->where('end_date', '<=', $request->end_date);
            }

            $perPage = min((int) $request->get('per_page', 20), 100);
            $leaves = $query->orderBy('created_at', 'desc')->paginate($perPage);

            return response()->json([
                'success' => true,
                'data' => EmployeeLeaveResource::collection($leaves),
                'pagination' => [
                    'current_page' => $leaves->currentPage(),
                    'last_page' => $leaves->lastPage(),
                    'per_page' => $leaves->perPage(),
                    'total' => $leaves->total(),
                    'from' => $leaves->firstItem(),
                    'to' => $leaves->lastItem(),
                ],
                'message' => 'Liste des demandes de congé récupérée avec succès',
            ], 200, [], JSON_UNESCAPED_UNICODE);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des demandes: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les demandes d'un employé
     */
    public function getEmployeeRequests(Request $request, $employeeId)
    {
        try {
            $query = EmployeeLeave::with(['employee', 'approver', 'creator'])
                ->where('employee_id', $employeeId);

            // Filtrage par statut
            if ($request->has('status')) {
                $query->where('status', $request->status);
            }

            // Filtrage par date de début
            if ($request->has('start_date')) {
                $query->where('start_date', '>=', $request->start_date);
            }

            // Filtrage par date de fin
            if ($request->has('end_date')) {
                $query->where('end_date', '<=', $request->end_date);
            }

            $perPage = $request->get('per_page', 15);
            $leaves = $query->orderBy('created_at', 'desc')->paginate($perPage);

            return response()->json([
                'success' => true,
                'data' => EmployeeLeaveResource::collection($leaves->items()),
                'pagination' => [
                    'current_page' => $leaves->currentPage(),
                    'last_page' => $leaves->lastPage(),
                    'per_page' => $leaves->perPage(),
                    'total' => $leaves->total(),
                ],
                'message' => 'Demandes de congé récupérées avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des demandes: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Détails d'une demande de congé
     */
    public function show($id)
    {
        try {
            $leave = EmployeeLeave::with(['employee', 'approver', 'creator'])->find($id);

            if (!$leave) {
                return response()->json([
                    'success' => false,
                    'message' => 'Demande de congé non trouvée'
                ], 404);
            }

            return response()->json([
                'success' => true,
                'data' => new EmployeeLeaveResource($leave),
                'message' => 'Demande de congé récupérée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération de la demande: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Créer une nouvelle demande de congé
     */
    public function store(Request $request)
    {
        try {
            $validated = $request->validate([
                'employee_id' => 'required|exists:employees,id',
                'leave_type' => 'required|in:annual,sick,maternity,paternity,personal,emergency,unpaid',
                'start_date' => 'required|date|after_or_equal:today',
                'end_date' => 'required|date|after:start_date',
                'reason' => 'required|string|min:10|max:1000',
                'comments' => 'nullable|string|max:2000',
                'attachment_paths' => 'nullable|array',
                'attachment_paths.*' => 'string|max:500'
            ]);

            // Normaliser leave_type en type pour le modèle
            $validated['type'] = $validated['leave_type'];
            unset($validated['leave_type']);

            DB::beginTransaction();

            // Calculer le nombre de jours ouvrés
            $startDate = Carbon::parse($validated['start_date']);
            $endDate = Carbon::parse($validated['end_date']);
            $totalDays = $this->calculateWorkingDays($startDate, $endDate);

            // Vérifier les conflits
            $conflicts = $this->checkDateConflicts($validated['employee_id'], $startDate, $endDate);
            if ($conflicts['has_conflicts']) {
                DB::rollBack();
                return response()->json([
                    'success' => false,
                    'message' => 'Conflit de dates détecté',
                    'data' => $conflicts
                ], 400);
            }

            $leave = EmployeeLeave::create([
                'employee_id' => $validated['employee_id'],
                'type' => $validated['type'],
                'start_date' => $validated['start_date'],
                'end_date' => $validated['end_date'],
                'total_days' => $totalDays,
                'reason' => $validated['reason'],
                'comments' => $validated['comments'] ?? null,
                'status' => 'pending',
                'created_by' => $request->user()->id
            ]);

            // Gérer les pièces jointes si fournies
            if (isset($validated['attachment_paths']) && is_array($validated['attachment_paths'])) {
                foreach ($validated['attachment_paths'] as $path) {
                    // TODO: Créer les enregistrements dans leave_attachments
                }
            }

            DB::commit();

            $leave->load(['employee', 'creator']);

            // Notifier le patron lors de la création
            $this->safeNotify(function () use ($leave) {
                $this->notificationService->notifyNewLeaveRequest($leave);
            });

            return response()->json([
                'success' => true,
                'message' => 'Demande de congé créée avec succès',
                'data' => new EmployeeLeaveResource($leave)
            ], 201);

        } catch (\Illuminate\Validation\ValidationException $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'The given data was invalid.',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la création de la demande: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Mettre à jour une demande de congé
     */
    public function update(Request $request, $id)
    {
        try {
            $leave = EmployeeLeave::find($id);

            if (!$leave) {
                return response()->json([
                    'success' => false,
                    'message' => 'Demande de congé non trouvée'
                ], 404);
            }

            // Vérifier les permissions (seulement pending peut être modifié)
            if ($leave->status !== 'pending') {
                return response()->json([
                    'success' => false,
                    'message' => 'Seules les demandes en attente peuvent être modifiées'
                ], 403);
            }

            $validated = $request->validate([
                'leave_type' => 'nullable|in:annual,sick,maternity,paternity,personal,emergency,unpaid',
                'start_date' => 'nullable|date|after_or_equal:today',
                'end_date' => 'nullable|date|after:start_date',
                'reason' => 'nullable|string|min:10|max:1000',
                'comments' => 'nullable|string|max:2000'
            ]);

            // Normaliser leave_type en type
            if (isset($validated['leave_type'])) {
                $validated['type'] = $validated['leave_type'];
                unset($validated['leave_type']);
            }

            DB::beginTransaction();

            // Recalculer total_days si les dates changent
            if (isset($validated['start_date']) || isset($validated['end_date'])) {
                $startDate = isset($validated['start_date']) 
                    ? Carbon::parse($validated['start_date']) 
                    : Carbon::parse($leave->start_date);
                $endDate = isset($validated['end_date']) 
                    ? Carbon::parse($validated['end_date']) 
                    : Carbon::parse($leave->end_date);
                
                $validated['total_days'] = $this->calculateWorkingDays($startDate, $endDate);

                // Vérifier les conflits
                $conflicts = $this->checkDateConflicts($leave->employee_id, $startDate, $endDate, $leave->id);
                if ($conflicts['has_conflicts']) {
                    DB::rollBack();
                    return response()->json([
                        'success' => false,
                        'message' => 'Conflit de dates détecté',
                        'data' => $conflicts
                    ], 400);
                }
            }

            $leave->update($validated);

            DB::commit();

            $leave->load(['employee', 'approver', 'creator']);

            return response()->json([
                'success' => true,
                'message' => 'Demande de congé mise à jour avec succès',
                'data' => new EmployeeLeaveResource($leave)
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la mise à jour: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Supprimer une demande de congé
     */
    public function destroy($id)
    {
        try {
            $leave = EmployeeLeave::find($id);

            if (!$leave) {
                return response()->json([
                    'success' => false,
                    'message' => 'Demande de congé non trouvée'
                ], 404);
            }

            // Seules les demandes pending ou cancelled peuvent être supprimées
            if (!in_array($leave->status, ['pending', 'cancelled'])) {
                return response()->json([
                    'success' => false,
                    'message' => 'Seules les demandes en attente ou annulées peuvent être supprimées'
                ], 403);
            }

            $leave->delete();

            return response()->json([
                'success' => true,
                'message' => 'Demande de congé supprimée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la suppression: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Approuver une demande de congé
     */
    public function approve(Request $request, $id)
    {
        try {
            $leave = EmployeeLeave::with(['employee', 'approver', 'creator'])->find($id);

            if (!$leave) {
                return response()->json([
                    'success' => false,
                    'message' => 'Demande de congé non trouvée'
                ], 404);
            }

            if ($leave->status !== 'pending') {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette demande ne peut pas être approuvée'
                ], 400);
            }

            $validated = $request->validate([
                'comments' => 'nullable|string|max:2000'
            ]);

            DB::beginTransaction();

            $leave->approve($request->user()->id, $validated['comments'] ?? null);

            // TODO: Mettre à jour le solde de congés

            // Notifier l'employé concerné
            if ($leave->employee_id || $leave->created_by) {
                $this->safeNotify(function () use ($leave) {
                    if ($leave->employee_id) {
                        $leave->load('employee');
                    }
                    $this->notificationService->notifyLeaveRequestApproved($leave);
                });
            }

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Demande de congé approuvée avec succès',
                'data' => new EmployeeLeaveResource($leave)
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'approbation: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Rejeter une demande de congé
     */
    public function reject(Request $request, $id)
    {
        try {
            $leave = EmployeeLeave::with(['employee', 'approver', 'creator'])->find($id);

            if (!$leave) {
                return response()->json([
                    'success' => false,
                    'message' => 'Demande de congé non trouvée'
                ], 404);
            }

            if ($leave->status !== 'pending') {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette demande ne peut pas être rejetée'
                ], 400);
            }

            $validated = $request->validate([
                'rejection_reason' => 'required|string|min:10|max:1000'
            ]);

            $leave->reject($request->user()->id, $validated['rejection_reason']);

            // Notifier l'employé concerné
            if ($leave->employee_id || $leave->created_by) {
                $reason = $validated['rejection_reason'];
                $this->safeNotify(function () use ($leave, $reason) {
                    if ($leave->employee_id) {
                        $leave->load('employee');
                    }
                    $this->notificationService->notifyLeaveRequestRejected($leave, $reason);
                });
            }

            return response()->json([
                'success' => true,
                'message' => 'Demande de congé rejetée',
                'data' => new EmployeeLeaveResource($leave)
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du rejet: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Annuler une demande de congé
     */
    public function cancel(Request $request, $id)
    {
        try {
            $leave = EmployeeLeave::with(['employee', 'approver', 'creator'])->find($id);

            if (!$leave) {
                return response()->json([
                    'success' => false,
                    'message' => 'Demande de congé non trouvée'
                ], 404);
            }

            // Seules les demandes pending ou approved peuvent être annulées
            if (!in_array($leave->status, ['pending', 'approved'])) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette demande ne peut pas être annulée'
                ], 400);
            }

            DB::beginTransaction();

            // Si approuvée, remettre les jours dans le solde
            if ($leave->status === 'approved') {
                // TODO: Remettre les jours dans le solde
            }

            $leave->update([
                'status' => 'cancelled',
                'rejection_reason' => 'Annulée par l\'utilisateur'
            ]);

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Demande de congé annulée',
                'data' => new EmployeeLeaveResource($leave)
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'annulation: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Vérifier les conflits de dates
     */
    public function checkConflicts(Request $request)
    {
        try {
            $validated = $request->validate([
                'employee_id' => 'required|exists:employees,id',
                'start_date' => 'required|date',
                'end_date' => 'required|date|after:start_date',
                'exclude_request_id' => 'nullable|exists:employee_leaves,id'
            ]);

            $conflicts = $this->checkDateConflicts(
                $validated['employee_id'],
                Carbon::parse($validated['start_date']),
                Carbon::parse($validated['end_date']),
                $validated['exclude_request_id'] ?? null
            );

            return response()->json([
                'success' => true,
                'data' => $conflicts
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la vérification: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Statistiques des congés
     */
    public function statistics(Request $request)
    {
        try {
            $startDate = $request->get('start_date', Carbon::now()->startOfMonth());
            $endDate = $request->get('end_date', Carbon::now()->endOfMonth());
            $dateKey = Carbon::parse($startDate)->format('Y-m-d');
            $employeeId = $request->get('employee_id');
            $cacheKey = $employeeId ? "leave_stats:{$dateKey}:{$employeeId}" : "leave_stats:{$dateKey}";

            $formattedStats = $this->rememberDailyStats($cacheKey, $dateKey, function () use ($request, $startDate, $endDate) {
                $query = EmployeeLeave::query();

                // Filtrage par date
                if ($request->has('start_date')) {
                    $query->where('start_date', '>=', $startDate);
                }

                if ($request->has('end_date')) {
                    $query->where('start_date', '<=', $endDate);
                }

                // Filtrage par employé
                if ($request->has('employee_id')) {
                    $query->where('employee_id', $request->employee_id);
                }

                $leaves = $query->get();
                $stats = EmployeeLeave::getLeaveStats($startDate, $endDate);

                // Formater les statistiques
                return [
                    'total_requests' => $stats['total_leaves'] ?? 0,
                    'pending_requests' => $stats['pending_leaves'] ?? 0,
                    'approved_requests' => $stats['approved_leaves'] ?? 0,
                    'rejected_requests' => $stats['rejected_leaves'] ?? 0,
                    'cancelled_requests' => $leaves->where('status', 'cancelled')->count(),
                    'average_approval_time' => 0, // TODO: Calculer le temps moyen d'approbation
                    'requests_by_type' => [
                        'annual' => $stats['annual_leaves'] ?? 0,
                        'sick' => $stats['sick_leaves'] ?? 0,
                        'maternity' => $stats['maternity_leaves'] ?? 0,
                        'paternity' => $stats['paternity_leaves'] ?? 0,
                        'personal' => $stats['personal_leaves'] ?? 0,
                        'emergency' => $leaves->where('type', 'emergency')->count(),
                        'unpaid' => $stats['unpaid_leaves'] ?? 0
                    ],
                    'requests_by_month' => $this->getRequestsByMonth($leaves),
                    'recent_requests' => $leaves->sortByDesc('created_at')->take(10)->map(function ($leave) {
                        return [
                            'id' => $leave->id,
                            'employee_name' => $leave->employee->full_name ?? 'N/A',
                            'leave_type' => $leave->type,
                            'start_date' => $leave->start_date->format('Y-m-d\TH:i:s\Z'),
                            'end_date' => $leave->end_date->format('Y-m-d\TH:i:s\Z'),
                            'status' => $leave->status
                        ];
                    })->values()->toArray()
                ];
            });

            return response()->json([
                'success' => true,
                'data' => $formattedStats,
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
     * Types de congés disponibles
     */
    public function getLeaveTypes()
    {
        $types = $this->rememberStatic('leave_types', function () {
            return [
                [
                    'value' => 'annual',
                    'label' => 'Congés payés',
                    'description' => 'Congés annuels payés',
                    'requires_approval' => true,
                    'max_days' => 30,
                    'is_paid' => true
                ],
                [
                    'value' => 'sick',
                    'label' => 'Congé maladie',
                    'description' => 'Congé pour maladie',
                    'requires_approval' => true,
                    'max_days' => 90,
                    'is_paid' => true
                ],
                [
                    'value' => 'maternity',
                    'label' => 'Congé maternité',
                    'description' => 'Congé de maternité',
                    'requires_approval' => true,
                    'max_days' => 98,
                    'is_paid' => true
                ],
                [
                    'value' => 'paternity',
                    'label' => 'Congé paternité',
                    'description' => 'Congé de paternité',
                    'requires_approval' => true,
                    'max_days' => 11,
                    'is_paid' => true
                ],
                [
                    'value' => 'personal',
                    'label' => 'Congé personnel',
                    'description' => 'Congé pour affaires personnelles',
                    'requires_approval' => true,
                    'max_days' => 5,
                    'is_paid' => false
                ],
                [
                    'value' => 'emergency',
                    'label' => 'Congé d\'urgence',
                    'description' => 'Congé pour urgence familiale',
                    'requires_approval' => true,
                    'max_days' => 3,
                    'is_paid' => false
                ],
                [
                    'value' => 'unpaid',
                    'label' => 'Congé sans solde',
                    'description' => 'Congé non rémunéré',
                    'requires_approval' => true,
                    'max_days' => 30,
                    'is_paid' => false
                ]
            ];
        });

        return response()->json([
            'success' => true,
            'data' => $types
        ]);
    }

    /**
     * Formater une demande de congé
     */
    private function formatLeaveRequest($leave, $includeFullDetails = false)
    {
        $employee = $leave->relationLoaded('employee') ? $leave->employee : null;
        
        $data = [
            'id' => $leave->id,
            'employee_id' => $leave->employee_id,
            'employee_name' => $employee ? $employee->full_name : 'N/A',
            'leave_type' => $leave->type,
            'start_date' => $leave->start_date->format('Y-m-d\TH:i:s\Z'),
            'end_date' => $leave->end_date->format('Y-m-d\TH:i:s\Z'),
            'total_days' => $leave->total_days,
            'reason' => $leave->reason,
            'status' => $leave->status,
            'comments' => $leave->comments ?? null,
            'rejection_reason' => $leave->rejection_reason ?? null,
            'approved_at' => $leave->approved_at?->format('Y-m-d\TH:i:s\Z'),
            'approved_by' => $leave->approved_by,
            'approved_by_name' => $leave->approver_name ?? null,
            'created_at' => $leave->created_at->format('Y-m-d\TH:i:s\Z'),
            'updated_at' => $leave->updated_at->format('Y-m-d\TH:i:s\Z'),
            'attachments' => [] // TODO: Charger les pièces jointes
        ];

        if ($includeFullDetails) {
            // Ajouter le solde de congés
            $data['leave_balance'] = $this->getLeaveBalance($leave->employee_id);
        }

        return $data;
    }

    /**
     * Calculer les jours ouvrés (excluant weekends)
     */
    private function calculateWorkingDays($startDate, $endDate)
    {
        $days = 0;
        $current = $startDate->copy();

        while ($current->lte($endDate)) {
            // Exclure les weekends (samedi = 6, dimanche = 0)
            if ($current->dayOfWeek !== Carbon::SATURDAY && $current->dayOfWeek !== Carbon::SUNDAY) {
                $days++;
            }
            $current->addDay();
        }

        return $days;
    }

    /**
     * Vérifier les conflits de dates (méthode privée)
     */
    private function checkDateConflicts($employeeId, $startDate, $endDate, $excludeRequestId = null)
    {
        $query = EmployeeLeave::where('employee_id', $employeeId)
            ->where('status', 'approved')
            ->where(function ($q) use ($startDate, $endDate) {
                $q->whereBetween('start_date', [$startDate, $endDate])
                  ->orWhereBetween('end_date', [$startDate, $endDate])
                  ->orWhere(function ($q2) use ($startDate, $endDate) {
                      $q2->where('start_date', '<=', $startDate)
                        ->where('end_date', '>=', $endDate);
                  });
            });

        if ($excludeRequestId) {
            $query->where('id', '!=', $excludeRequestId);
        }

        $conflictingRequests = $query->get();

        return [
            'has_conflicts' => $conflictingRequests->count() > 0,
            'conflicting_requests' => $conflictingRequests->map(function ($request) {
                return [
                    'id' => $request->id,
                    'start_date' => $request->start_date->format('Y-m-d\TH:i:s\Z'),
                    'end_date' => $request->end_date->format('Y-m-d\TH:i:s\Z'),
                    'status' => $request->status
                ];
            })->toArray()
        ];
    }

    /**
     * Récupérer le solde de congés d'un employé
     */
    private function getLeaveBalance($employeeId)
    {
        // TODO: Implémenter la récupération du solde depuis leave_balances
        // Pour l'instant, calculer depuis les congés approuvés
        $employee = Employee::find($employeeId);
        if (!$employee) {
            return null;
        }

        $approvedLeaves = EmployeeLeave::where('employee_id', $employeeId)
            ->where('status', 'approved')
            ->get();

        return [
            'employee_id' => $employeeId,
            'employee_name' => $employee->first_name . ' ' . $employee->last_name,
            'annual_leave_days' => 25, // Par défaut
            'used_annual_leave' => $approvedLeaves->where('type', 'annual')->sum('total_days'),
            'remaining_annual_leave' => 25 - $approvedLeaves->where('type', 'annual')->sum('total_days'),
            'sick_leave_days' => 10,
            'used_sick_leave' => $approvedLeaves->where('type', 'sick')->sum('total_days'),
            'remaining_sick_leave' => 10 - $approvedLeaves->where('type', 'sick')->sum('total_days'),
            'personal_leave_days' => 5,
            'used_personal_leave' => $approvedLeaves->where('type', 'personal')->sum('total_days'),
            'remaining_personal_leave' => 5 - $approvedLeaves->where('type', 'personal')->sum('total_days'),
            'last_updated' => now()->format('Y-m-d\TH:i:s\Z')
        ];
    }

    /**
     * Obtenir les demandes par mois
     */
    private function getRequestsByMonth($leaves)
    {
        return $leaves->groupBy(function ($leave) {
            return $leave->created_at->format('Y-m');
        })->map->count()->toArray();
    }
}
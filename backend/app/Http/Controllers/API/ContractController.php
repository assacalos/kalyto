<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\Controller;
use App\Services\NotificationService;
use App\Traits\SendsNotifications;
use App\Models\Contract;
use App\Models\ContractClause;
use App\Models\ContractAttachment;
use App\Models\ContractTemplate;
use App\Models\ContractAmendment;
use App\Models\User;
use App\Http\Resources\ContractResource;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Log;

class ContractController extends Controller
{
    use SendsNotifications;

    protected $notificationService;

    public function __construct(NotificationService $notificationService)
    {
        $this->notificationService = $notificationService;
    }
    /**
     * Afficher la liste des contrats
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
            
            $query = Contract::with(['employee', 'creator', 'approver', 'clauses', 'attachments', 'amendments']);

            // Filtrage par statut
            if ($request->has('status')) {
                $query->where('status', $request->status);
            }

            // Filtrage par type de contrat
            if ($request->has('contract_type')) {
                $query->where('contract_type', $request->contract_type);
            }

            // Filtrage par département
            if ($request->has('department')) {
                $query->where('department', $request->department);
            }

            // Filtrage par employé
            if ($request->has('employee_id')) {
                $query->where('employee_id', $request->employee_id);
            }

            // Filtrage par numéro de contrat
            if ($request->has('contract_number')) {
                $query->where('contract_number', 'like', '%' . $request->contract_number . '%');
            }

            // Filtrage par date de début
            if ($request->has('start_date_from')) {
                $query->where('start_date', '>=', $request->start_date_from);
            }

            if ($request->has('start_date_to')) {
                $query->where('start_date', '<=', $request->start_date_to);
            }

            // Filtrage par date de fin
            if ($request->has('end_date_from')) {
                $query->where('end_date', '>=', $request->end_date_from);
            }

            if ($request->has('end_date_to')) {
                $query->where('end_date', '<=', $request->end_date_to);
            }

            // Filtrage par expirant
            if ($request->has('expiring_soon')) {
                if ($request->expiring_soon === 'true') {
                    $query->expiringSoon();
                }
            }

            // Filtrage par expiré
            if ($request->has('expired')) {
                if ($request->expired === 'true') {
                    $query->expired();
                }
            }

            $perPage = min((int) $request->get('per_page', 20), 100);
            $contracts = $query->orderBy('created_at', 'desc')->paginate($perPage);
            
            return response()->json([
                'success' => true,
                'data' => ContractResource::collection($contracts),
                'pagination' => [
                    'current_page' => $contracts->currentPage(),
                    'last_page' => $contracts->lastPage(),
                    'per_page' => $contracts->perPage(),
                    'total' => $contracts->total(),
                    'from' => $contracts->firstItem(),
                    'to' => $contracts->lastItem(),
                ],
                'message' => 'Liste des contrats récupérée avec succès',
            ], 200, [], JSON_UNESCAPED_UNICODE);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des contrats: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Afficher un contrat spécifique
     */
    public function show($id)
    {
        try {
            $contract = Contract::with(['employee', 'creator', 'approver', 'clauses', 'attachments', 'amendments'])->find($id);

            if (!$contract) {
                return response()->json([
                    'success' => false,
                    'message' => 'Contrat non trouvé'
                ], 404);
            }

            return response()->json([
                'success' => true,
                'data' => new ContractResource($contract),
                'message' => 'Contrat récupéré avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération du contrat: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Formater un contrat au format attendu par le frontend
     */
    private function formatContract($contract)
    {
        $employee = $contract->relationLoaded('employee') ? $contract->employee : null;
        
        return [
            'id' => $contract->id,
            'contract_number' => $contract->contract_number,
            'employee_id' => $contract->employee_id,
            'employee_name' => $contract->employee_name,
            'employee_email' => $contract->employee_email,
            'employee_phone' => $employee->phone ?? null,
            'contract_type' => $contract->contract_type,
            'position' => $contract->position,
            'department' => $contract->department,
            'job_title' => $contract->job_title,
            'job_description' => $contract->job_description,
            'gross_salary' => (float)$contract->gross_salary,
            'net_salary' => (float)$contract->net_salary,
            'salary_currency' => $contract->salary_currency,
            'payment_frequency' => $contract->payment_frequency,
            'start_date' => $contract->start_date?->format('Y-m-d\TH:i:s\Z'),
            'end_date' => $contract->end_date?->format('Y-m-d\TH:i:s\Z'),
            'duration_months' => $contract->duration_months,
            'work_location' => $contract->work_location,
            'work_schedule' => $contract->work_schedule,
            'weekly_hours' => $contract->weekly_hours,
            'probation_period' => $contract->probation_period,
            'reporting_manager' => $employee->manager ?? null,
            'health_insurance' => null, // À implémenter si nécessaire
            'retirement_plan' => null, // À implémenter si nécessaire
            'vacation_days' => null, // À calculer selon le type de contrat
            'other_benefits' => null, // À implémenter si nécessaire
            'status' => $contract->status,
            'termination_reason' => $contract->termination_reason,
            'termination_date' => $contract->termination_date?->format('Y-m-d\TH:i:s\Z'),
            'notes' => $contract->notes,
            'contract_template' => $contract->contract_template,
            'approved_at' => $contract->approved_at?->format('Y-m-d\TH:i:s\Z'),
            'approved_by' => $contract->approved_by,
            'approved_by_name' => $contract->approver_name ?? null,
            'rejection_reason' => $contract->rejection_reason,
            'created_at' => $contract->created_at->format('Y-m-d\TH:i:s\Z'),
            'updated_at' => $contract->updated_at->format('Y-m-d\TH:i:s\Z'),
            'clauses' => $contract->relationLoaded('clauses') ? $contract->clauses->map(function ($clause) {
                return [
                    'id' => $clause->id,
                    'contract_id' => $clause->contract_id,
                    'title' => $clause->title,
                    'content' => $clause->content,
                    'type' => $clause->type,
                    'is_mandatory' => $clause->is_mandatory,
                    'order' => $clause->order,
                    'created_at' => $clause->created_at->format('Y-m-d\TH:i:s\Z'),
                    'updated_at' => $clause->updated_at->format('Y-m-d\TH:i:s\Z')
                ];
            }) : [],
            'attachments' => $contract->relationLoaded('attachments') ? $contract->attachments->map(function ($attachment) {
                return [
                    'id' => $attachment->id,
                    'contract_id' => $attachment->contract_id,
                    'file_name' => $attachment->file_name,
                    'file_path' => $attachment->file_path,
                    'file_type' => $attachment->file_type,
                    'file_size' => $attachment->file_size,
                    'attachment_type' => $attachment->attachment_type,
                    'description' => $attachment->description,
                    'uploaded_at' => $attachment->uploaded_at->format('Y-m-d\TH:i:s\Z'),
                    'uploaded_by' => $attachment->uploaded_by,
                    'uploaded_by_name' => $attachment->uploader_name ?? null
                ];
            }) : [],
            'history' => [] // À implémenter si nécessaire
        ];
    }

    /**
     * Créer un nouveau contrat
     */
    public function store(Request $request)
    {
        try {
            $validated = $request->validate([
                'employee_id' => 'required|exists:employees,id',
                'contract_type' => 'required|in:permanent,fixed_term,temporary,internship,consultant',
                'position' => 'required|string|max:100',
                'department' => 'required|string|max:100',
                'job_title' => 'required|string|max:100',
                'job_description' => 'required|string|min:50',
                'gross_salary' => 'required|numeric|min:0',
                'net_salary' => 'required|numeric|min:0',
                'salary_currency' => 'required|string|max:10',
                'payment_frequency' => 'required|in:monthly,weekly,daily,hourly',
                'start_date' => 'required|date',
                'end_date' => 'nullable|date|after:start_date|required_if:contract_type,fixed_term',
                'duration_months' => 'nullable|integer|min:1',
                'work_location' => 'required|string|max:255',
                'work_schedule' => 'required|in:full_time,part_time,flexible',
                'weekly_hours' => 'required|integer|min:1|max:168',
                'probation_period' => 'required|in:none,1_month,3_months,6_months',
                'notes' => 'nullable|string',
                'contract_template' => 'nullable|string|max:255',
                'clauses' => 'nullable|array'
            ]);

            DB::beginTransaction();

            // Générer le numéro de contrat au format CTR-YYYYMMDD-XXXXXX
            $contractNumber = 'CTR-' . date('Ymd') . '-' . str_pad(Contract::count() + 1, 6, '0', STR_PAD_LEFT);

            // Récupérer les informations de l'employé
            $employee = \App\Models\Employee::find($validated['employee_id']);

            $contract = Contract::create([
                'contract_number' => $contractNumber,
                'employee_id' => $validated['employee_id'],
                'employee_name' => $employee->full_name,
                'employee_email' => $employee->email,
                'contract_type' => $validated['contract_type'],
                'position' => $validated['position'],
                'department' => $validated['department'],
                'job_title' => $validated['job_title'],
                'job_description' => $validated['job_description'],
                'gross_salary' => $validated['gross_salary'],
                'net_salary' => $validated['net_salary'],
                'salary_currency' => $validated['salary_currency'],
                'payment_frequency' => $validated['payment_frequency'],
                'start_date' => $validated['start_date'],
                'end_date' => $validated['end_date'],
                'duration_months' => $validated['duration_months'],
                'work_location' => $validated['work_location'],
                'work_schedule' => $validated['work_schedule'],
                'weekly_hours' => $validated['weekly_hours'],
                'probation_period' => $validated['probation_period'],
                'status' => 'pending',
                'notes' => $validated['notes'],
                'contract_template' => $validated['contract_template'],
                'created_by' => $request->user()->id
            ]);

            // Créer les clauses si fournies
            if (isset($validated['clauses']) && is_array($validated['clauses'])) {
                foreach ($validated['clauses'] as $clauseData) {
                    ContractClause::create([
                        'contract_id' => $contract->id,
                        'title' => $clauseData['title'] ?? '',
                        'content' => $clauseData['content'] ?? '',
                        'type' => $clauseData['type'] ?? 'standard',
                        'is_mandatory' => $clauseData['is_mandatory'] ?? false,
                        'order' => $clauseData['order'] ?? 1
                    ]);
                }
            }

            DB::commit();

            // Recharger avec les relations nécessaires
            $contract->load(['employee', 'creator', 'clauses', 'attachments']);

            return response()->json([
                'success' => true,
                'message' => 'Contrat créé avec succès',
                'data' => $this->formatContract($contract)
            ], 201);

        } catch (\Exception $e) {
            DB::rollback();
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la création du contrat: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Mettre à jour un contrat
     */
    public function update(Request $request, $id)
    {
        try {
            $contract = Contract::find($id);

            if (!$contract) {
                return response()->json([
                    'success' => false,
                    'message' => 'Contrat non trouvé'
                ], 404);
            }

            // Seuls les contrats avec le statut "pending" peuvent être modifiés selon la documentation
            if ($contract->status !== 'pending') {
                return response()->json([
                    'success' => false,
                    'message' => 'Ce contrat ne peut pas être modifié'
                ], 403);
            }

            $validated = $request->validate([
                'contract_type' => 'sometimes|in:permanent,fixed_term,temporary,internship,consultant',
                'position' => 'sometimes|string|max:100',
                'department' => 'sometimes|string|max:100',
                'job_title' => 'sometimes|string|max:100',
                'job_description' => 'sometimes|string|min:50',
                'gross_salary' => 'sometimes|numeric|min:0',
                'net_salary' => 'sometimes|numeric|min:0',
                'salary_currency' => 'sometimes|string|max:10',
                'payment_frequency' => 'sometimes|in:monthly,weekly,daily,hourly',
                'start_date' => 'sometimes|date',
                'end_date' => 'nullable|date|after:start_date|required_if:contract_type,fixed_term',
                'duration_months' => 'nullable|integer|min:1',
                'work_location' => 'sometimes|string|max:255',
                'work_schedule' => 'sometimes|in:full_time,part_time,flexible',
                'weekly_hours' => 'sometimes|integer|min:1|max:168',
                'probation_period' => 'sometimes|in:none,1_month,3_months,6_months',
                'notes' => 'nullable|string',
                'contract_template' => 'nullable|string|max:255'
            ]);

            $contract->update(array_merge($validated, [
                'updated_by' => $request->user()->id
            ]));

            return response()->json([
                'success' => true,
                'data' => $contract->load(['employee', 'creator', 'updater']),
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
     * Supprimer un contrat
     */
    public function destroy($id)
    {
        try {
            $contract = Contract::find($id);

            if (!$contract) {
                return response()->json([
                    'success' => false,
                    'message' => 'Contrat non trouvé'
                ], 404);
            }

            // Seuls les contrats avec le statut "pending" ou "cancelled" peuvent être supprimés selon la documentation
            if (!in_array($contract->status, ['pending', 'cancelled'])) {
                return response()->json([
                    'success' => false,
                    'message' => 'Ce contrat ne peut pas être supprimé'
                ], 403);
            }

            $contract->delete();

            return response()->json([
                'success' => true,
                'message' => 'Contrat supprimé avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la suppression du contrat: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Soumettre un contrat
     */
    public function submit($id)
    {
        try {
            $contract = Contract::find($id);

            if (!$contract) {
                return response()->json([
                    'success' => false,
                    'message' => 'Contrat non trouvé'
                ], 404);
            }

            if (!$contract->can_submit) {
                return response()->json([
                    'success' => false,
                    'message' => 'Ce contrat ne peut pas être soumis'
                ], 403);
            }

            $contract->submit();

            // Notifier le patron
            $this->safeNotify(function () use ($contract) {
                $this->notificationService->notifyNewContrat($contract);
            });

            return response()->json([
                'success' => true,
                'message' => 'Contrat soumis avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la soumission du contrat: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Approuver un contrat
     */
    public function approve(Request $request, $id)
    {
        try {
            $contract = Contract::find($id);

            if (!$contract) {
                return response()->json([
                    'success' => false,
                    'message' => 'Contrat non trouvé'
                ], 404);
            }

            if (!$contract->can_approve) {
                return response()->json([
                    'success' => false,
                    'message' => 'Ce contrat ne peut pas être approuvé'
                ], 403);
            }

            $validated = $request->validate([
                'notes' => 'nullable|string'
            ]);

            $contract->approve(request()->user()->id);

            // Notifier l'employé concerné
            if ($contract->employee_id) {
                $this->safeNotify(function () use ($contract) {
                    $contract->load('employee');
                    $this->notificationService->notifyContratValidated($contract);
                });
            }

            return response()->json([
                'success' => true,
                'message' => 'Contrat approuvé avec succès',
                'data' => [
                    'id' => $contract->id,
                    'status' => $contract->status,
                    'approved_at' => $contract->approved_at?->format('Y-m-d\TH:i:s\Z'),
                    'approved_by' => $contract->approved_by,
                    'approved_by_name' => $contract->approver_name,
                    'updated_at' => $contract->updated_at->format('Y-m-d\TH:i:s\Z')
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'approbation du contrat: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Rejeter un contrat
     */
    public function reject(Request $request, $id)
    {
        try {
            $contract = Contract::find($id);

            if (!$contract) {
                return response()->json([
                    'success' => false,
                    'message' => 'Contrat non trouvé'
                ], 404);
            }

            if (!$contract->can_reject) {
                return response()->json([
                    'success' => false,
                    'message' => 'Ce contrat ne peut pas être rejeté'
                ], 403);
            }

            $validated = $request->validate([
                'rejection_reason' => 'required|string|max:1000',
                'reason' => 'nullable|string|max:1000' // Support pour les deux formats
            ]);

            $rejectionReason = $validated['rejection_reason'] ?? $validated['reason'] ?? '';

            $contract->reject(request()->user()->id, $rejectionReason);

            // Notifier l'employé concerné
            if ($contract->employee_id) {
                $this->safeNotify(function () use ($contract, $rejectionReason) {
                    $contract->load('employee');
                    $this->notificationService->notifyContratRejected($contract, $rejectionReason);
                });
            }

            return response()->json([
                'success' => true,
                'message' => 'Contrat rejeté avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du rejet du contrat: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Résilier un contrat
     */
    public function terminate(Request $request, $id)
    {
        try {
            $contract = Contract::find($id);

            if (!$contract) {
                return response()->json([
                    'success' => false,
                    'message' => 'Contrat non trouvé'
                ], 404);
            }

            if (!$contract->can_terminate) {
                return response()->json([
                    'success' => false,
                    'message' => 'Ce contrat ne peut pas être résilié'
                ], 403);
            }

            $validated = $request->validate([
                'termination_reason' => 'required|string|max:1000',
                'termination_date' => 'nullable|date',
                'notes' => 'nullable|string'
            ]);

            $contract->terminate(
                request()->user()->id, 
                $validated['termination_reason'], 
                $validated['termination_date'] ?? null
            );

            return response()->json([
                'success' => true,
                'message' => 'Contrat résilié avec succès',
                'data' => [
                    'id' => $contract->id,
                    'status' => $contract->status,
                    'termination_reason' => $contract->termination_reason,
                    'termination_date' => $contract->termination_date?->format('Y-m-d\TH:i:s\Z'),
                    'updated_at' => $contract->updated_at->format('Y-m-d\TH:i:s\Z')
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la résiliation du contrat: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Annuler un contrat
     */
    public function cancel(Request $request, $id)
    {
        try {
            $contract = Contract::find($id);

            if (!$contract) {
                return response()->json([
                    'success' => false,
                    'message' => 'Contrat non trouvé'
                ], 404);
            }

            if (!$contract->can_cancel) {
                return response()->json([
                    'success' => false,
                    'message' => 'Ce contrat ne peut pas être annulé'
                ], 403);
            }

            $validated = $request->validate([
                'reason' => 'nullable|string|max:1000'
            ]);

            $contract->cancel(request()->user()->id, $validated['reason'] ?? null);

            return response()->json([
                'success' => true,
                'message' => 'Contrat annulé',
                'data' => [
                    'id' => $contract->id,
                    'status' => $contract->status,
                    'updated_at' => $contract->updated_at->format('Y-m-d\TH:i:s\Z')
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'annulation du contrat: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Mettre à jour le salaire
     */
    public function updateSalary(Request $request, $id)
    {
        try {
            $contract = Contract::find($id);

            if (!$contract) {
                return response()->json([
                    'success' => false,
                    'message' => 'Contrat non trouvé'
                ], 404);
            }

            $validated = $request->validate([
                'gross_salary' => 'required|numeric|min:0',
                'net_salary' => 'required|numeric|min:0'
            ]);

            $contract->updateSalary($validated['gross_salary'], $validated['net_salary'], $request->user()->id);

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
     * Prolonger un contrat
     */
    public function extend(Request $request, $id)
    {
        try {
            $contract = Contract::find($id);

            if (!$contract) {
                return response()->json([
                    'success' => false,
                    'message' => 'Contrat non trouvé'
                ], 404);
            }

            $validated = $request->validate([
                'end_date' => 'required|date|after:today'
            ]);

            $contract->extendContract($validated['end_date'], $request->user()->id);

            return response()->json([
                'success' => true,
                'message' => 'Contrat prolongé avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la prolongation du contrat: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Statistiques des contrats
     */
    public function statistics(Request $request)
    {
        try {
            $query = Contract::query();

            // Filtrage par date
            if ($request->has('start_date')) {
                $query->where('start_date', '>=', $request->start_date);
            }

            if ($request->has('end_date')) {
                $query->where('start_date', '<=', $request->end_date);
            }

            // Filtrage par département
            if ($request->has('department')) {
                $query->where('department', $request->department);
            }

            // Filtrage par type de contrat
            if ($request->has('contract_type')) {
                $query->where('contract_type', $request->contract_type);
            }

            $contracts = $query->get();

            $stats = [
                // Clés courtes pour le frontend
                'total' => $contracts->count(),
                'pending' => $contracts->where('status', 'pending')->count(),
                'active' => $contracts->where('status', 'active')->count(),
                'expired' => $contracts->where('status', 'expired')->count(),
                'terminated' => $contracts->where('status', 'terminated')->count(),
                'cancelled' => $contracts->where('status', 'cancelled')->count(),
                // Clés détaillées pour compatibilité
                'total_contracts' => $contracts->count(),
                'pending_contracts' => $contracts->where('status', 'pending')->count(),
                'active_contracts' => $contracts->where('status', 'active')->count(),
                'expired_contracts' => $contracts->where('status', 'expired')->count(),
                'terminated_contracts' => $contracts->where('status', 'terminated')->count(),
                'cancelled_contracts' => $contracts->where('status', 'cancelled')->count(),
                'contracts_expiring_soon' => $contracts->filter(function ($contract) {
                    return $contract->is_expiring_soon;
                })->count(),
                'average_salary' => $contracts->where('status', 'active')->avg('gross_salary') ?? 0,
                'contracts_by_type' => $contracts->groupBy('contract_type')->map->count()->toArray(),
                'contracts_by_department' => $contracts->groupBy('department')->map->count()->toArray(),
                'recent_contracts' => $contracts->sortByDesc('created_at')->take(10)->map(function ($contract) {
                    return [
                        'id' => $contract->id,
                        'contract_number' => $contract->contract_number,
                        'employee_name' => $contract->employee_name,
                        'contract_type' => $contract->contract_type,
                        'status' => $contract->status,
                        'created_at' => $contract->created_at->format('Y-m-d\TH:i:s\Z')
                    ];
                })->values()->toArray()
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

    /**
     * Récupérer les contrats par employé
     */
    public function byEmployee($employeeId)
    {
        try {
            $contracts = Contract::getContractsByEmployee($employeeId);

            return response()->json([
                'success' => true,
                'data' => $contracts,
                'message' => 'Contrats de l\'employé récupérés avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des contrats de l\'employé: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les contrats par département
     */
    public function byDepartment($department)
    {
        try {
            $contracts = Contract::getContractsByDepartment($department);

            return response()->json([
                'success' => true,
                'data' => $contracts,
                'message' => 'Contrats du département récupérés avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des contrats du département: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les contrats par type
     */
    public function byType($contractType)
    {
        try {
            $contracts = Contract::getContractsByType($contractType);

            return response()->json([
                'success' => true,
                'data' => $contracts,
                'message' => 'Contrats du type récupérés avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des contrats du type: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les employés disponibles pour un contrat
     */
    public function getAvailableEmployees()
    {
        try {
            // Récupérer tous les employés
            $allEmployees = \App\Models\Employee::all();
            
            $availableEmployees = $allEmployees->map(function ($employee) {
                // Récupérer le contrat actif de l'employé
                $currentContract = Contract::where('employee_id', $employee->id)
                    ->where('status', 'active')
                    ->latest('start_date')
                    ->first();

                // L'employé est disponible si :
                // - Il n'a pas de contrat actif
                // - Son contrat actif est expiré
                $isAvailable = !$currentContract || 
                              ($currentContract->end_date && $currentContract->end_date < now());

                if ($isAvailable) {
                    return [
                        'id' => $employee->id,
                        'name' => $employee->full_name ?? ($employee->first_name . ' ' . $employee->last_name),
                        'email' => $employee->email,
                        'phone' => $employee->phone ?? null,
                        'position' => $employee->position ?? null,
                        'department' => $employee->department ?? null,
                        'current_contract' => $currentContract ? [
                            'id' => $currentContract->id,
                            'contract_number' => $currentContract->contract_number,
                            'status' => $currentContract->status,
                            'end_date' => $currentContract->end_date?->format('Y-m-d\TH:i:s\Z')
                        ] : null
                    ];
                }
                return null;
            })->filter();

            return response()->json([
                'success' => true,
                'data' => $availableEmployees->values()
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des employés disponibles: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les contrats expirant bientôt (avec paramètre days_ahead)
     */
    public function expiringSoon(Request $request)
    {
        try {
            $daysAhead = $request->get('days_ahead', 30);
            $contracts = Contract::expiringSoon($daysAhead)
                ->with(['employee', 'creator', 'approver'])
                ->get();

            return response()->json([
                'success' => true,
                'data' => $contracts->map(function ($contract) {
                    return [
                        'id' => $contract->id,
                        'contract_number' => $contract->contract_number,
                        'employee_name' => $contract->employee_name,
                        'contract_type' => $contract->contract_type,
                        'end_date' => $contract->end_date?->format('Y-m-d\TH:i:s\Z'),
                        'days_until_expiry' => $contract->remaining_days,
                        'status' => $contract->status
                    ];
                })
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des contrats expirant: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les contrats expirés
     */
    public function expired()
    {
        try {
            $contracts = Contract::getExpiredContracts();

            return response()->json([
                'success' => true,
                'data' => $contracts,
                'message' => 'Contrats expirés récupérés avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des contrats expirés: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les contrats actifs
     */
    public function active()
    {
        try {
            $contracts = Contract::getActiveContracts();

            return response()->json([
                'success' => true,
                'data' => $contracts,
                'message' => 'Contrats actifs récupérés avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des contrats actifs: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les contrats en attente
     */
    public function pending()
    {
        try {
            $contracts = Contract::getPendingContracts();

            return response()->json([
                'success' => true,
                'data' => $contracts,
                'message' => 'Contrats en attente récupérés avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des contrats en attente: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les contrats brouillons
     */
    public function drafts()
    {
        try {
            $contracts = Contract::getDraftContracts();

            return response()->json([
                'success' => true,
                'data' => $contracts,
                'message' => 'Contrats brouillons récupérés avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des contrats brouillons: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les clauses d'un contrat
     */
    public function getClauses($id)
    {
        try {
            $contract = Contract::find($id);

            if (!$contract) {
                return response()->json([
                    'success' => false,
                    'message' => 'Contrat non trouvé'
                ], 404);
            }

            $clauses = $contract->clauses()->orderBy('order')->get();

            return response()->json([
                'success' => true,
                'data' => $clauses->map(function ($clause) {
                    return [
                        'id' => $clause->id,
                        'contract_id' => $clause->contract_id,
                        'title' => $clause->title,
                        'content' => $clause->content,
                        'type' => $clause->type,
                        'is_mandatory' => $clause->is_mandatory,
                        'order' => $clause->order,
                        'created_at' => $clause->created_at->format('Y-m-d\TH:i:s\Z'),
                        'updated_at' => $clause->updated_at->format('Y-m-d\TH:i:s\Z')
                    ];
                })
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des clauses: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Ajouter une clause à un contrat
     */
    public function addClause(Request $request, $id)
    {
        try {
            $contract = Contract::find($id);

            if (!$contract) {
                return response()->json([
                    'success' => false,
                    'message' => 'Contrat non trouvé'
                ], 404);
            }

            $validated = $request->validate([
                'title' => 'required|string|max:255',
                'content' => 'required|string',
                'type' => 'required|in:standard,custom,legal,benefit',
                'is_mandatory' => 'nullable|boolean',
                'order' => 'nullable|integer|min:1'
            ]);

            $clause = ContractClause::create([
                'contract_id' => $contract->id,
                'title' => $validated['title'],
                'content' => $validated['content'],
                'type' => $validated['type'],
                'is_mandatory' => $validated['is_mandatory'] ?? false,
                'order' => $validated['order'] ?? (($contract->clauses()->max('order') ?? 0) + 1)
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Clause ajoutée avec succès',
                'data' => [
                    'id' => $clause->id,
                    'contract_id' => $clause->contract_id,
                    'title' => $clause->title,
                    'content' => $clause->content,
                    'type' => $clause->type,
                    'is_mandatory' => $clause->is_mandatory,
                    'order' => $clause->order,
                    'created_at' => $clause->created_at->format('Y-m-d\TH:i:s\Z'),
                    'updated_at' => $clause->updated_at->format('Y-m-d\TH:i:s\Z')
                ]
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'ajout de la clause: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les pièces jointes d'un contrat
     */
    public function getAttachments($id)
    {
        try {
            $contract = Contract::find($id);

            if (!$contract) {
                return response()->json([
                    'success' => false,
                    'message' => 'Contrat non trouvé'
                ], 404);
            }

            $attachments = $contract->attachments()->orderBy('uploaded_at', 'desc')->get();

            return response()->json([
                'success' => true,
                'data' => $attachments->map(function ($attachment) {
                    return [
                        'id' => $attachment->id,
                        'contract_id' => $attachment->contract_id,
                        'file_name' => $attachment->file_name,
                        'file_path' => $attachment->file_path,
                        'file_type' => $attachment->file_type,
                        'file_size' => $attachment->file_size,
                        'attachment_type' => $attachment->attachment_type,
                        'description' => $attachment->description,
                        'uploaded_at' => $attachment->uploaded_at->format('Y-m-d\TH:i:s\Z'),
                        'uploaded_by' => $attachment->uploaded_by,
                        'uploaded_by_name' => $attachment->uploader_name ?? 'N/A'
                    ];
                })
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des pièces jointes: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Ajouter une pièce jointe à un contrat
     */
    public function addAttachment(Request $request, $id)
    {
        try {
            $contract = Contract::findOrFail($id);

            // Validation avec support pour multipart/form-data
            $validated = $request->validate([
                'file' => 'required|file|max:10240|mimes:pdf,jpg,jpeg,png,gif,webp,doc,docx,txt',
                'attachment_type' => 'required|in:contract,addendum,amendment,termination,other',
                'description' => 'nullable|string|max:500'
            ]);

            // Récupérer le fichier
            $file = $request->file('file');
            
            // Générer un nom de fichier unique
            $originalName = $file->getClientOriginalName();
            $fileName = time() . '_' . preg_replace('/[^a-zA-Z0-9._-]/', '_', $originalName);
            
            // Stocker le fichier dans storage/app/public/contracts/{id}/
            $filePath = $file->storeAs('contracts/' . $id, $fileName, 'public');
            
            // Créer l'enregistrement de la pièce jointe
            $attachment = ContractAttachment::create([
                'contract_id' => $contract->id,
                'file_name' => $originalName,
                'file_path' => '/storage/' . $filePath,
                'file_type' => $file->getMimeType(),
                'file_size' => $file->getSize(),
                'attachment_type' => $validated['attachment_type'],
                'description' => $validated['description'] ?? null,
                'uploaded_at' => now(),
                'uploaded_by' => $request->user()->id
            ]);

            // Charger la relation uploader pour le nom
            $attachment->load('uploader');

            return response()->json([
                'success' => true,
                'message' => 'Pièce jointe ajoutée avec succès',
                'data' => [
                    'id' => $attachment->id,
                    'contract_id' => $attachment->contract_id,
                    'file_name' => $attachment->file_name,
                    'file_path' => $attachment->file_path,
                    'file_type' => $attachment->file_type,
                    'file_size' => $attachment->file_size,
                    'attachment_type' => $attachment->attachment_type,
                    'description' => $attachment->description,
                    'uploaded_at' => $attachment->uploaded_at->format('Y-m-d\TH:i:s\Z'),
                    'uploaded_by' => $attachment->uploaded_by,
                    'uploaded_by_name' => $attachment->uploader_name ?? null
                ]
            ], 201);

        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'The given data was invalid.',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'ajout de la pièce jointe: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Télécharger une pièce jointe
     */
    public function downloadAttachment($contractId, $attachmentId)
    {
        try {
            $contract = Contract::findOrFail($contractId);
            $attachment = ContractAttachment::where('contract_id', $contractId)
                ->findOrFail($attachmentId);
            
            // Utiliser Storage pour éviter les problèmes de chemin
            $filePath = str_replace('/storage/', '', $attachment->file_path);
            
            if (!Storage::disk('public')->exists($filePath)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Fichier non trouvé'
                ], 404);
            }
            
            // Utiliser streamDownload pour éviter les problèmes de mémoire
            return Storage::disk('public')->download($filePath, $attachment->file_name, [
                'Content-Type' => $attachment->file_type ?? 'application/octet-stream',
                'Content-Disposition' => 'attachment; filename="' . $attachment->file_name . '"',
            ]);
            
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Contrat ou pièce jointe non trouvé(e)'
            ], 404);
        } catch (\Exception $e) {
            Log::error('Contract attachment download error', [
                'contract_id' => $contractId,
                'attachment_id' => $attachmentId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du téléchargement: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les modèles de contrat
     */
    public function getTemplates(Request $request)
    {
        try {
            $query = ContractTemplate::where('is_active', true);

            if ($request->has('contract_type')) {
                $query->where('contract_type', $request->contract_type);
            }

            if ($request->has('department')) {
                $query->where('department', $request->department);
            }

            $templates = $query->orderBy('name')->get();

            return response()->json([
                'success' => true,
                'data' => $templates->map(function ($template) {
                    return [
                        'id' => $template->id,
                        'name' => $template->name,
                        'description' => $template->description,
                        'contract_type' => $template->contract_type,
                        'department' => $template->department,
                        'content' => $template->content,
                        'is_active' => $template->is_active,
                        'default_clauses' => [], // À implémenter si nécessaire (peut être stocké en JSON ou dans une table séparée)
                        'created_at' => $template->created_at->format('Y-m-d\TH:i:s\Z'),
                        'updated_at' => $template->updated_at->format('Y-m-d\TH:i:s\Z')
                    ];
                })
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des modèles: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Générer un numéro de contrat unique
     */
    public function generateNumber()
    {
        try {
            $contractNumber = 'CTR-' . date('Ymd') . '-' . str_pad(Contract::count() + 1, 6, '0', STR_PAD_LEFT);

            return response()->json([
                'success' => true,
                'contract_number' => $contractNumber
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la génération du numéro: ' . $e->getMessage()
            ], 500);
        }
    }

}
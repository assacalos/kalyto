<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\Controller;
use Illuminate\Http\Request;
use App\Models\PaymentSchedule;
use App\Models\PaymentInstallment;
use App\Models\Paiement;
use App\Http\Resources\PaymentScheduleResource;
use Illuminate\Support\Facades\Validator;
use Carbon\Carbon;

class PaymentScheduleController extends Controller
{
    /**
     * Liste des plannings de paiement
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
            
            $query = PaymentSchedule::with(['payment.facture.client', 'installments', 'creator']);

        // Filtrage par statut
        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        // Filtrage par type de paiement
        if ($request->has('payment_type')) {
            $query->whereHas('payment', function($q) use ($request) {
                $q->where('type', $request->payment_type);
            });
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
        $schedules = $query->orderBy('created_at', 'desc')->paginate($perPage);

        return response()->json([
            'success' => true,
            'data' => PaymentScheduleResource::collection($schedules),
            'pagination' => [
                'current_page' => $schedules->currentPage(),
                'last_page' => $schedules->lastPage(),
                'per_page' => $schedules->perPage(),
                'total' => $schedules->total(),
                'from' => $schedules->firstItem(),
                'to' => $schedules->lastItem(),
            ],
            'message' => 'Liste des plannings récupérée avec succès',
        ], 200, [], JSON_UNESCAPED_UNICODE);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des plannings',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Détails d'un planning
     */
    public function show($id)
    {
        $schedule = PaymentSchedule::with([
            'payment.facture.client',
            'installments',
            'creator',
            'updater'
        ])->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => new PaymentScheduleResource($schedule),
            'message' => 'Planning récupéré avec succès'
        ]);
    }

    /**
     * Créer un planning de paiement
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'payment_id' => 'required|exists:paiements,id',
            'start_date' => 'required|date|after_or_equal:today',
            'end_date' => 'required|date|after:start_date',
            'frequency' => 'required|integer|min:1',
            'total_installments' => 'required|integer|min:1',
            'installment_amount' => 'required|numeric|min:0.01',
            'notes' => 'nullable|string'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur de validation',
                'errors' => $validator->errors()
            ], 422);
        }

        // Vérifier que le paiement peut avoir un planning
        $payment = Paiement::findOrFail($request->payment_id);
        if ($payment->type !== 'monthly') {
            return response()->json([
                'success' => false,
                'message' => 'Seuls les paiements mensuels peuvent avoir un planning'
            ], 400);
        }

        $schedule = PaymentSchedule::create([
            'payment_id' => $request->payment_id,
            'start_date' => $request->start_date,
            'end_date' => $request->end_date,
            'frequency' => $request->frequency,
            'total_installments' => $request->total_installments,
            'installment_amount' => $request->installment_amount,
            'notes' => $request->notes,
            'created_by' => auth()->id()
        ]);

        // Générer les échéances
        $schedule->generateInstallments();

        return response()->json([
            'success' => true,
            'schedule' => $schedule->load(['installments', 'payment']),
            'message' => 'Planning créé avec succès'
        ], 201);
    }

    /**
     * Modifier un planning
     */
    public function update(Request $request, $id)
    {
        $schedule = PaymentSchedule::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'start_date' => 'sometimes|date|after_or_equal:today',
            'end_date' => 'sometimes|date|after:start_date',
            'frequency' => 'sometimes|integer|min:1',
            'installment_amount' => 'sometimes|numeric|min:0.01',
            'notes' => 'nullable|string'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur de validation',
                'errors' => $validator->errors()
            ], 422);
        }

        // Vérifier que le planning peut être modifié
        if ($schedule->status === 'completed') {
            return response()->json([
                'success' => false,
                'message' => 'Impossible de modifier un planning terminé'
            ], 400);
        }

        $schedule->update(array_merge($request->only([
            'start_date', 'end_date', 'frequency', 'installment_amount', 'notes'
        ]), [
            'updated_by' => auth()->id()
        ]));

        return response()->json([
            'success' => true,
            'schedule' => $schedule,
            'message' => 'Planning modifié avec succès'
        ]);
    }

    /**
     * Mettre en pause un planning
     */
    public function pause($id)
    {
        $schedule = PaymentSchedule::findOrFail($id);

        if ($schedule->pause()) {
            return response()->json([
                'success' => true,
                'message' => 'Planning mis en pause avec succès'
            ]);
        }

        return response()->json([
            'success' => false,
            'message' => 'Impossible de mettre en pause ce planning'
        ], 400);
    }

    /**
     * Reprendre un planning
     */
    public function resume($id)
    {
        $schedule = PaymentSchedule::findOrFail($id);

        if ($schedule->resume()) {
            return response()->json([
                'success' => true,
                'message' => 'Planning repris avec succès'
            ]);
        }

        return response()->json([
            'success' => false,
            'message' => 'Impossible de reprendre ce planning'
        ], 400);
    }

    /**
     * Annuler un planning
     */
    public function cancel($id)
    {
        $schedule = PaymentSchedule::findOrFail($id);

        if ($schedule->cancel()) {
            return response()->json([
                'success' => true,
                'message' => 'Planning annulé avec succès'
            ]);
        }

        return response()->json([
            'success' => false,
            'message' => 'Impossible d\'annuler ce planning'
        ], 400);
    }

    /**
     * Marquer une échéance comme payée
     */
    public function markInstallmentPaid(Request $request, $id, $installmentId)
    {
        $schedule = PaymentSchedule::findOrFail($id);
        $installment = PaymentInstallment::where('schedule_id', $id)
                                       ->findOrFail($installmentId);

        $validator = Validator::make($request->all(), [
            'notes' => 'nullable|string'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur de validation',
                'errors' => $validator->errors()
            ], 422);
        }

        if ($installment->markAsPaid(auth()->id(), $request->notes)) {
            return response()->json([
                'success' => true,
                'message' => 'Échéance marquée comme payée avec succès'
            ]);
        }

        return response()->json([
            'success' => false,
            'message' => 'Impossible de marquer cette échéance comme payée'
        ], 400);
    }

    /**
     * Statistiques des plannings
     */
    public function stats()
    {
        $stats = [
            'total_schedules' => PaymentSchedule::count(),
            'active_schedules' => PaymentSchedule::active()->count(),
            'paused_schedules' => PaymentSchedule::paused()->count(),
            'completed_schedules' => PaymentSchedule::completed()->count(),
            'cancelled_schedules' => PaymentSchedule::cancelled()->count(),
            'total_installments' => PaymentInstallment::count(),
            'paid_installments' => PaymentInstallment::paid()->count(),
            'pending_installments' => PaymentInstallment::pending()->count(),
            'overdue_installments' => PaymentInstallment::overdue()->count(),
            'total_amount' => PaymentInstallment::sum('amount'),
            'paid_amount' => PaymentInstallment::paid()->sum('amount'),
            'pending_amount' => PaymentInstallment::pending()->sum('amount'),
            'overdue_amount' => PaymentInstallment::overdue()->sum('amount')
        ];

        return response()->json([
            'success' => true,
            'stats' => $stats,
            'message' => 'Statistiques récupérées avec succès'
        ]);
    }
}

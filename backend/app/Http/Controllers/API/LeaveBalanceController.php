<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\Controller;
use App\Models\Employee;
use App\Models\EmployeeLeave;
use Illuminate\Http\Request;

class LeaveBalanceController extends Controller
{
    /**
     * Récupérer le solde de congés d'un employé
     */
    public function show($employeeId)
    {
        try {
            $employee = Employee::find($employeeId);

            if (!$employee) {
                return response()->json([
                    'success' => false,
                    'message' => 'Employé non trouvé'
                ], 404);
            }

            // Calculer le solde depuis les congés approuvés
            $approvedLeaves = EmployeeLeave::where('employee_id', $employeeId)
                ->where('status', 'approved')
                ->get();

            $balance = [
                'employee_id' => $employeeId,
                'employee_name' => $employee->full_name,
                'annual_leave_days' => 25, // Par défaut, peut être récupéré depuis leave_balances
                'used_annual_leave' => $approvedLeaves->where('type', 'annual')->sum('total_days'),
                'remaining_annual_leave' => max(0, 25 - $approvedLeaves->where('type', 'annual')->sum('total_days')),
                'sick_leave_days' => 10,
                'used_sick_leave' => $approvedLeaves->where('type', 'sick')->sum('total_days'),
                'remaining_sick_leave' => max(0, 10 - $approvedLeaves->where('type', 'sick')->sum('total_days')),
                'personal_leave_days' => 5,
                'used_personal_leave' => $approvedLeaves->where('type', 'personal')->sum('total_days'),
                'remaining_personal_leave' => max(0, 5 - $approvedLeaves->where('type', 'personal')->sum('total_days')),
                'last_updated' => now()->format('Y-m-d\TH:i:s\Z')
            ];

            return response()->json([
                'success' => true,
                'data' => $balance
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération du solde: ' . $e->getMessage()
            ], 500);
        }
    }
}


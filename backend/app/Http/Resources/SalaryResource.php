<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SalaryResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        // Extraire month et year de period (format "YYYY-MM")
        $month = null;
        $year = null;
        if ($this->period) {
            $parts = explode('-', $this->period);
            if (count($parts) === 2) {
                $year = (int)$parts[0];
                $month = $parts[1];
            }
        }

        // Mapper le status pour compatibilité Flutter
        $statusFlutter = $this->status;
        if ($this->status === 'draft' || $this->status === 'calculated') {
            $statusFlutter = 'pending';
        } elseif ($this->status === 'cancelled') {
            $statusFlutter = 'rejected';
        }

        return [
            'id' => $this->id,
            'employee_id' => $this->employee_id,
            'hr_id' => $this->employee_id, // Compatibilité Flutter
            'employee_name' => $this->employee_name,
            'employee_email' => $this->whenLoaded('employee', fn() => $this->employee->email),
            'salary_number' => $this->salary_number,
            'hr_name' => $this->hr_name,
            'period' => $this->period,
            'period_start' => $this->period_start?->format('Y-m-d'),
            'period_end' => $this->period_end?->format('Y-m-d'),
            'salary_date' => $this->salary_date?->format('Y-m-d'),
            'payment_date' => $this->salary_date?->format('Y-m-d'),
            'base_salary' => $this->base_salary ? (float)$this->base_salary : null,
            'gross_salary' => $this->gross_salary ? (float)$this->gross_salary : null,
            'net_salary' => $this->net_salary ? (float)$this->net_salary : null,
            'total_allowances' => $this->total_allowances ? (float)$this->total_allowances : null,
            'total_deductions' => $this->total_deductions ? (float)$this->total_deductions : null,
            'total_taxes' => $this->total_taxes ? (float)$this->total_taxes : null,
            'total_social_security' => $this->total_social_security ? (float)$this->total_social_security : null,
            'status' => $this->status,
            'status_flutter' => $statusFlutter,
            'notes' => $this->notes,
            'justificatif' => $this->justificatif,
            'salary_breakdown' => $this->salary_breakdown,
            'components' => $this->components,
            'calculated_at' => $this->calculated_at?->format('Y-m-d H:i:s'),
            'approved_at' => $this->approved_at?->format('Y-m-d H:i:s'),
            'paid_at' => $this->paid_at?->format('Y-m-d H:i:s'),
            'month' => $month,
            'year' => $year,
            'created_at' => $this->created_at?->format('Y-m-d H:i:s'),
            'updated_at' => $this->updated_at?->format('Y-m-d H:i:s'),
            // Relations
            'employee' => $this->whenLoaded('employee', function () {
                return new EmployeeResource($this->employee);
            }),
            'hr' => $this->whenLoaded('hr', function () {
                return new EmployeeResource($this->hr);
            }),
            'approver' => $this->whenLoaded('approver', function () {
                return [
                    'id' => $this->approver->id,
                    'nom' => $this->approver->nom,
                    'prenom' => $this->approver->prenom,
                ];
            }),
            'payer' => $this->whenLoaded('payer', function () {
                return [
                    'id' => $this->payer->id,
                    'nom' => $this->payer->nom,
                    'prenom' => $this->payer->prenom,
                ];
            }),
            'salary_items' => $this->whenLoaded('salaryItems', function () {
                return $this->salaryItems->map(function ($item) {
                    return [
                        'id' => $item->id,
                        'component_id' => $item->component_id,
                        'component_name' => $item->salaryComponent?->name,
                        'amount' => (float)$item->amount,
                        'type' => $item->type,
                    ];
                });
            }),
        ];
    }
}

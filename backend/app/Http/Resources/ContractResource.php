<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ContractResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'contract_number' => $this->contract_number,
            'employee_id' => $this->employee_id,
            'employee_name' => $this->employee_name,
            'employee_email' => $this->employee_email,
            'contract_type' => $this->contract_type,
            'position' => $this->position,
            'department' => $this->department,
            'job_title' => $this->job_title,
            'job_description' => $this->job_description,
            'gross_salary' => $this->gross_salary ? (float)$this->gross_salary : null,
            'net_salary' => $this->net_salary ? (float)$this->net_salary : null,
            'salary_currency' => $this->salary_currency,
            'payment_frequency' => $this->payment_frequency,
            'start_date' => $this->start_date?->format('Y-m-d'),
            'end_date' => $this->end_date?->format('Y-m-d'),
            'duration_months' => $this->duration_months,
            'work_location' => $this->work_location,
            'work_schedule' => $this->work_schedule,
            'weekly_hours' => $this->weekly_hours,
            'probation_period' => $this->probation_period,
            'status' => $this->status,
            'termination_reason' => $this->termination_reason,
            'termination_date' => $this->termination_date?->format('Y-m-d'),
            'notes' => $this->notes,
            'contract_template' => $this->contract_template,
            'approved_at' => $this->approved_at?->format('Y-m-d H:i:s'),
            'rejection_reason' => $this->rejection_reason,
            'created_at' => $this->created_at?->format('Y-m-d H:i:s'),
            'updated_at' => $this->updated_at?->format('Y-m-d H:i:s'),
            // Relations
            'employee' => $this->whenLoaded('employee', function () {
                return new EmployeeResource($this->employee);
            }),
            'creator' => $this->whenLoaded('creator', function () {
                return [
                    'id' => $this->creator->id,
                    'nom' => $this->creator->nom,
                    'prenom' => $this->creator->prenom,
                ];
            }),
            'approver' => $this->whenLoaded('approver', function () {
                return [
                    'id' => $this->approver->id,
                    'nom' => $this->approver->nom,
                    'prenom' => $this->approver->prenom,
                ];
            }),
            'clauses' => $this->whenLoaded('clauses', function () {
                return $this->clauses->map(function ($clause) {
                    return [
                        'id' => $clause->id,
                        'title' => $clause->title,
                        'content' => $clause->content,
                        'order' => $clause->order,
                    ];
                });
            }),
            'attachments' => $this->whenLoaded('attachments', function () {
                return $this->attachments->map(function ($attachment) {
                    return [
                        'id' => $attachment->id,
                        'name' => $attachment->name,
                        'file_path' => $attachment->file_path,
                        'file_size' => $attachment->file_size,
                    ];
                });
            }),
            'amendments' => $this->whenLoaded('amendments', function () {
                return $this->amendments->map(function ($amendment) {
                    return [
                        'id' => $amendment->id,
                        'amendment_date' => $amendment->amendment_date?->format('Y-m-d'),
                        'description' => $amendment->description,
                        'status' => $amendment->status,
                    ];
                });
            }),
        ];
    }
}

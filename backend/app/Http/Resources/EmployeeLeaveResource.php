<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class EmployeeLeaveResource extends JsonResource
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
            'employee_id' => $this->employee_id,
            'leave_type' => $this->type,
            'type' => $this->type,
            'start_date' => $this->start_date?->format('Y-m-d\TH:i:s\Z'),
            'end_date' => $this->end_date?->format('Y-m-d\TH:i:s\Z'),
            'total_days' => $this->total_days,
            'reason' => $this->reason,
            'status' => $this->status,
            'comments' => $this->comments,
            'rejection_reason' => $this->rejection_reason,
            'approved_by' => $this->approved_by,
            'approved_at' => $this->approved_at?->format('Y-m-d\TH:i:s\Z'),
            'approved_by_name' => $this->approver_name ?? null,
            'created_at' => $this->created_at?->format('Y-m-d\TH:i:s\Z'),
            'updated_at' => $this->updated_at?->format('Y-m-d\TH:i:s\Z'),
            // Relations
            'employee' => $this->whenLoaded('employee', function () {
                return [
                    'id' => $this->employee->id,
                    'full_name' => $this->employee->full_name,
                    'email' => $this->employee->email,
                ];
            }),
            'approver' => $this->whenLoaded('approver', function () {
                return [
                    'id' => $this->approver->id,
                    'nom' => $this->approver->nom,
                    'prenom' => $this->approver->prenom,
                ];
            }),
            'creator' => $this->whenLoaded('creator', function () {
                return [
                    'id' => $this->creator->id,
                    'nom' => $this->creator->nom,
                    'prenom' => $this->creator->prenom,
                ];
            }),
        ];
    }
}

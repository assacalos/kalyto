<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ExpenseResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        // Déterminer le statut pour le frontend
        $status = $this->status;
        if (in_array($status, ['draft', 'submitted', 'under_review'])) {
            $status = 'pending';
        }

        // Déterminer la catégorie pour le frontend
        $category = 'other';
        if ($this->relationLoaded('expenseCategory') && $this->expenseCategory) {
            if ($this->expenseCategory->code) {
                $category = $this->expenseCategory->code;
            } else {
                $category = strtolower(str_replace(' ', '_', $this->expenseCategory->name));
            }
        }

        return [
            'id' => $this->id,
            'title' => $this->description,
            'description' => $this->description,
            'amount' => (float)$this->amount,
            'category' => $category,
            'status' => $status,
            'expense_date' => $this->expense_date?->format('Y-m-d'),
            'expenseDate' => $this->expense_date?->format('Y-m-d\TH:i:s.u\Z'),
            'receipt_path' => $this->receipt_path,
            'receiptPath' => $this->receipt_path,
            'receipt_url' => $this->receipt_url,
            'receiptUrl' => $this->receipt_url,
            'notes' => $this->justification,
            'created_at' => $this->created_at?->format('Y-m-d H:i:s'),
            'updated_at' => $this->updated_at?->format('Y-m-d H:i:s'),
            'created_by' => $this->employee_id,
            'approved_by' => $this->approved_by,
            'rejection_reason' => $this->rejection_reason,
            'rejectionReason' => $this->rejection_reason,
            'approved_at' => $this->approved_at?->format('Y-m-d H:i:s'),
            'approvedAt' => $this->approved_at?->format('Y-m-d H:i:s'),
            'currency' => $this->currency,
            'expense_number' => $this->expense_number,
            // Relations
            'expense_category' => $this->whenLoaded('expenseCategory', function () {
                return [
                    'id' => $this->expenseCategory->id,
                    'name' => $this->expenseCategory->name,
                    'code' => $this->expenseCategory->code,
                ];
            }),
            'employee' => $this->whenLoaded('employee', function () {
                return [
                    'id' => $this->employee->id,
                    'nom' => $this->employee->nom,
                    'prenom' => $this->employee->prenom,
                    'email' => $this->employee->email,
                ];
            }),
            'comptable' => $this->whenLoaded('comptable', function () {
                return [
                    'id' => $this->comptable->id,
                    'nom' => $this->comptable->nom,
                    'prenom' => $this->comptable->prenom,
                ];
            }),
            'approvals' => $this->whenLoaded('approvals', function () {
                return $this->approvals->map(function ($approval) {
                    return [
                        'id' => $approval->id,
                        'status' => $approval->status,
                        'comments' => $approval->comments,
                        'approved_at' => $approval->approved_at?->format('Y-m-d H:i:s'),
                        'approver' => $approval->whenLoaded('approver', function () {
                            return [
                                'id' => $approval->approver->id,
                                'nom' => $approval->approver->nom,
                                'prenom' => $approval->approver->prenom,
                            ];
                        }),
                    ];
                });
            }),
        ];
    }
}

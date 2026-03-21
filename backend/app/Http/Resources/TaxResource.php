<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class TaxResource extends JsonResource
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
            'category' => $this->category,
            'reference' => $this->reference,
            'period' => $this->period,
            'period_start' => $this->period_start?->format('Y-m-d'),
            'period_end' => $this->period_end?->format('Y-m-d'),
            'due_date' => $this->due_date?->format('Y-m-d'),
            'base_amount' => (float)$this->base_amount,
            'tax_rate' => (float)$this->tax_rate,
            'tax_amount' => (float)$this->tax_amount,
            'total_amount' => (float)$this->total_amount,
            'status' => $this->status,
            'description' => $this->description,
            'notes' => $this->notes,
            'calculation_details' => $this->calculation_details,
            'declared_at' => $this->declared_at?->format('Y-m-d H:i:s'),
            'paid_at' => $this->paid_at?->format('Y-m-d H:i:s'),
            'validated_at' => $this->validated_at?->format('Y-m-d H:i:s'),
            'rejected_at' => $this->rejected_at?->format('Y-m-d H:i:s'),
            'validation_comment' => $this->validation_comment,
            'rejection_reason' => $this->rejection_reason,
            'rejection_comment' => $this->rejection_comment,
            'created_at' => $this->created_at?->format('Y-m-d H:i:s'),
            'updated_at' => $this->updated_at?->format('Y-m-d H:i:s'),
            // Relations
            'comptable' => $this->whenLoaded('comptable', function () {
                return [
                    'id' => $this->comptable->id,
                    'nom' => $this->comptable->nom,
                    'prenom' => $this->comptable->prenom,
                    'email' => $this->comptable->email,
                ];
            }),
            'validated_by' => $this->whenLoaded('validatedBy', function () {
                return [
                    'id' => $this->validatedBy->id,
                    'nom' => $this->validatedBy->nom,
                    'prenom' => $this->validatedBy->prenom,
                ];
            }),
            'rejected_by' => $this->whenLoaded('rejectedBy', function () {
                return [
                    'id' => $this->rejectedBy->id,
                    'nom' => $this->rejectedBy->nom,
                    'prenom' => $this->rejectedBy->prenom,
                ];
            }),
            'payments' => $this->whenLoaded('payments', function () {
                return $this->payments->map(function ($payment) {
                    return [
                        'id' => $payment->id,
                        'amount' => (float)$payment->amount,
                        'payment_date' => $payment->payment_date?->format('Y-m-d'),
                        'status' => $payment->status,
                    ];
                });
            }),
        ];
    }
}

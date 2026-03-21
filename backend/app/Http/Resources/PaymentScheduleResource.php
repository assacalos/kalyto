<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PaymentScheduleResource extends JsonResource
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
            'payment_id' => $this->payment_id,
            'start_date' => $this->start_date?->format('Y-m-d'),
            'end_date' => $this->end_date?->format('Y-m-d'),
            'frequency' => $this->frequency,
            'total_installments' => $this->total_installments,
            'paid_installments' => $this->paid_installments,
            'installment_amount' => $this->installment_amount ? (float)$this->installment_amount : null,
            'status' => $this->status,
            'next_payment_date' => $this->next_payment_date?->format('Y-m-d'),
            'notes' => $this->notes,
            'created_by' => $this->created_by,
            'updated_by' => $this->updated_by,
            'created_at' => $this->created_at?->format('Y-m-d H:i:s'),
            'updated_at' => $this->updated_at?->format('Y-m-d H:i:s'),
            // Relations
            'payment' => $this->whenLoaded('payment', function () {
                return new PaiementResource($this->payment);
            }),
            'installments' => $this->whenLoaded('installments', function () {
                return $this->installments->map(function ($installment) {
                    return [
                        'id' => $installment->id,
                        'installment_number' => $installment->installment_number,
                        'due_date' => $installment->due_date?->format('Y-m-d'),
                        'amount' => (float)$installment->amount,
                        'status' => $installment->status,
                        'paid_at' => $installment->paid_at?->format('Y-m-d H:i:s'),
                    ];
                });
            }),
            'creator' => $this->whenLoaded('creator', function () {
                return [
                    'id' => $this->creator->id,
                    'nom' => $this->creator->nom,
                    'prenom' => $this->creator->prenom,
                ];
            }),
            'updater' => $this->whenLoaded('updater', function () {
                return [
                    'id' => $this->updater->id,
                    'nom' => $this->updater->nom,
                    'prenom' => $this->updater->prenom,
                ];
            }),
        ];
    }
}

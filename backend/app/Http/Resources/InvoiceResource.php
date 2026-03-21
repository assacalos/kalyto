<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class InvoiceResource extends JsonResource
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
            'invoice_number' => $this->invoice_number,
            'client_id' => $this->client_id,
            'client_name' => $this->client_name,
            'client_email' => $this->client_email,
            'client_address' => $this->client_address,
            'commercial_id' => $this->commercial_id,
            'commercial_name' => $this->commercial_name,
            'invoice_date' => $this->invoice_date?->format('Y-m-d'),
            'due_date' => $this->due_date?->format('Y-m-d'),
            'status' => $this->status,
            'subtotal' => $this->subtotal ? (float)$this->subtotal : null,
            'tax_rate' => $this->tax_rate ? (float)$this->tax_rate : null,
            'tax_amount' => $this->tax_amount ? (float)$this->tax_amount : null,
            'total_amount' => $this->total_amount ? (float)$this->total_amount : null,
            'currency' => $this->currency,
            'notes' => $this->notes,
            'terms' => $this->terms,
            'payment_info' => $this->payment_info,
            'sent_at' => $this->sent_at?->format('Y-m-d H:i:s'),
            'paid_at' => $this->paid_at?->format('Y-m-d H:i:s'),
            'is_overdue' => $this->is_overdue,
            'days_until_due' => $this->days_until_due,
            'created_at' => $this->created_at?->format('Y-m-d H:i:s'),
            'updated_at' => $this->updated_at?->format('Y-m-d H:i:s'),
            // Relations
            'client' => $this->whenLoaded('client', function () {
                return new ClientResource($this->client);
            }),
            'commercial' => $this->whenLoaded('commercial', function () {
                return [
                    'id' => $this->commercial->id,
                    'nom' => $this->commercial->nom,
                    'prenom' => $this->commercial->prenom,
                    'email' => $this->commercial->email,
                ];
            }),
            'items' => $this->whenLoaded('items', function () {
                return $this->items->map(function ($item) {
                    return [
                        'id' => $item->id,
                        'description' => $item->description,
                        'quantity' => (float)$item->quantity,
                        'unit_price' => (float)$item->unit_price,
                        'total_price' => (float)$item->total_price,
                        'unit' => $item->unit,
                    ];
                });
            }),
        ];
    }
}

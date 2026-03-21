<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class StockResource extends JsonResource
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
            'name' => $this->name,
            'description' => $this->description,
            'category' => $this->category,
            'sku' => $this->sku,
            'quantity' => $this->quantity ?? $this->current_quantity,
            'current_quantity' => $this->current_quantity,
            'minimum_quantity' => $this->minimum_quantity,
            'maximum_quantity' => $this->maximum_quantity,
            'reorder_point' => $this->reorder_point,
            'unit_price' => $this->unit_price ?? $this->unit_cost,
            'unit_cost' => $this->unit_cost,
            'commentaire' => $this->commentaire ?? $this->notes,
            'notes' => $this->notes,
            'status' => $this->status,
            'status_libelle' => $this->status_libelle,
            'formatted_current_quantity' => $this->formatQuantity($this->current_quantity),
            'formatted_minimum_quantity' => $this->formatQuantity($this->minimum_quantity),
            'formatted_maximum_quantity' => $this->maximum_quantity ? $this->formatQuantity($this->maximum_quantity) : 'N/A',
            'formatted_reorder_point' => $this->formatQuantity($this->reorder_point),
            'formatted_unit_cost' => $this->formatCost($this->unit_cost),
            'stock_value' => $this->stock_value,
            'formatted_stock_value' => $this->formatCost($this->stock_value),
            'is_low_stock' => $this->is_low_stock,
            'is_out_of_stock' => $this->is_out_of_stock,
            'is_overstock' => $this->is_overstock,
            'needs_reorder' => $this->needs_reorder,
            'created_at' => $this->created_at?->format('Y-m-d H:i:s'),
            'updated_at' => $this->updated_at?->format('Y-m-d H:i:s'),
            // Relations
            'movements' => $this->whenLoaded('movements', function () {
                return $this->movements->map(function ($movement) {
                    return [
                        'id' => $movement->id,
                        'type' => $movement->type,
                        'quantity' => $movement->quantity,
                        'reason' => $movement->reason,
                        'status' => $movement->status ?? 'en_attente',
                        'created_at' => $movement->created_at?->format('Y-m-d H:i:s')
                    ];
                });
            }),
            'alerts' => $this->whenLoaded('alerts', function () {
                return $this->alerts->map(function ($alert) {
                    return [
                        'id' => $alert->id,
                        'type' => $alert->type,
                        'status' => $alert->status,
                        'message' => $alert->message,
                        'created_at' => $alert->created_at?->format('Y-m-d H:i:s')
                    ];
                });
            }),
        ];
    }

    private function formatQuantity($quantity)
    {
        return $quantity ? number_format($quantity, 2, ',', ' ') : '0';
    }

    private function formatCost($cost)
    {
        return $cost ? number_format($cost, 2, ',', ' ') . ' FCFA' : '0 FCFA';
    }
}

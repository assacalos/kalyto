<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class EquipmentResource extends JsonResource
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
            'status' => $this->status,
            'status_libelle' => $this->status_libelle,
            'condition' => $this->condition,
            'condition_libelle' => $this->condition_libelle,
            'serial_number' => $this->serial_number,
            'model' => $this->model,
            'brand' => $this->brand,
            'location' => $this->location,
            'department' => $this->department,
            'assigned_to' => $this->assigned_to,
            'purchase_date' => $this->purchase_date?->toIso8601String(),
            'warranty_expiry' => $this->warranty_expiry?->toIso8601String(),
            'last_maintenance' => $this->last_maintenance?->toIso8601String(),
            'next_maintenance' => $this->next_maintenance?->toIso8601String(),
            'purchase_price' => $this->purchase_price,
            'current_value' => $this->current_value,
            'formatted_purchase_price' => $this->formatted_purchase_price,
            'formatted_current_value' => $this->formatted_current_value,
            'supplier' => $this->supplier,
            'notes' => $this->notes,
            'attachments' => $this->attachments,
            'created_by' => $this->created_by,
            'updated_by' => $this->updated_by,
            'is_warranty_expired' => $this->is_warranty_expired,
            'is_warranty_expiring_soon' => $this->is_warranty_expiring_soon,
            'needs_maintenance' => $this->needs_maintenance,
            'age_in_years' => $this->age_in_years,
            'depreciation_rate' => $this->depreciation_rate,
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
            // Relations
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
            'maintenance' => $this->whenLoaded('maintenance', function () {
                return $this->maintenance->map(function ($maintenance) {
                    return [
                        'id' => $maintenance->id,
                        'type' => $maintenance->type,
                        'type_libelle' => $maintenance->type_libelle,
                        'status' => $maintenance->status,
                        'status_libelle' => $maintenance->status_libelle,
                        'description' => $maintenance->description,
                        'scheduled_date' => $maintenance->scheduled_date?->toIso8601String(),
                        'start_date' => $maintenance->start_date?->toIso8601String(),
                        'end_date' => $maintenance->end_date?->toIso8601String(),
                        'technician' => $maintenance->technician,
                        'cost' => $maintenance->cost,
                        'formatted_cost' => $maintenance->formatted_cost,
                        'duration' => $maintenance->duration,
                        'is_overdue' => $maintenance->is_overdue,
                        'created_at' => $maintenance->created_at?->toIso8601String()
                    ];
                });
            }),
            'assignments' => $this->whenLoaded('assignments', function () {
                return $this->assignments->map(function ($assignment) {
                    return [
                        'id' => $assignment->id,
                        'user_id' => $assignment->user_id,
                        'assigned_at' => $assignment->assigned_at?->toIso8601String(),
                        'returned_at' => $assignment->returned_at?->toIso8601String(),
                        'notes' => $assignment->notes,
                    ];
                });
            }),
        ];
    }
}

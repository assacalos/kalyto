<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class TaskResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'titre' => $this->titre,
            'description' => $this->description,
            'assigned_to' => $this->assigned_to,
            'assigned_by' => $this->assigned_by,
            'status' => $this->status,
            'status_libelle' => $this->status_libelle,
            'priority' => $this->priority,
            'priority_libelle' => $this->priority_libelle,
            'due_date' => $this->due_date?->format('Y-m-d'),
            'completed_at' => $this->completed_at?->format('Y-m-d H:i:s'),
            'created_at' => $this->created_at?->format('Y-m-d H:i:s'),
            'updated_at' => $this->updated_at?->format('Y-m-d H:i:s'),
            'assigned_to_user' => $this->whenLoaded('assignedTo', function () {
                return $this->assignedTo ? [
                    'id' => $this->assignedTo->id,
                    'nom' => $this->assignedTo->nom,
                    'prenom' => $this->assignedTo->prenom,
                    'email' => $this->assignedTo->email,
                ] : null;
            }),
            'assigned_by_user' => $this->whenLoaded('assignedBy', function () {
                return $this->assignedBy ? [
                    'id' => $this->assignedBy->id,
                    'nom' => $this->assignedBy->nom,
                    'prenom' => $this->assignedBy->prenom,
                ] : null;
            }),
        ];
    }
}

<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class InterventionResource extends JsonResource
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
            'type' => $this->type,
            'title' => $this->title,
            'description' => $this->description,
            'scheduled_date' => $this->scheduled_date?->format('Y-m-d H:i:s'),
            'start_date' => $this->start_date?->format('Y-m-d H:i:s'),
            'end_date' => $this->end_date?->format('Y-m-d H:i:s'),
            'status' => $this->status,
            'priority' => $this->priority,
            'location' => $this->location,
            'client_id' => $this->client_id,
            'client_name' => $this->client_name,
            'client_phone' => $this->client_phone,
            'client_email' => $this->client_email,
            'equipment' => $this->equipment,
            'problem_description' => $this->problem_description,
            'solution' => $this->solution,
            'notes' => $this->notes,
            'estimated_duration' => (float)($this->estimated_duration ?? 0),
            'actual_duration' => (float)($this->actual_duration ?? 0),
            'cost' => (float)($this->cost ?? 0),
            'created_by' => $this->created_by,
            'approved_by' => $this->approved_by,
            'approved_at' => $this->approved_at?->format('Y-m-d H:i:s'),
            'rejection_reason' => $this->rejection_reason,
            'completion_notes' => $this->completion_notes,
            'created_at' => $this->created_at?->format('Y-m-d H:i:s'),
            'updated_at' => $this->updated_at?->format('Y-m-d H:i:s'),
            // Relations
            'client' => $this->whenLoaded('client', function () {
                return new ClientResource($this->client);
            }),
            'creator' => $this->whenLoaded('creator', function () {
                return [
                    'id' => $this->creator->id,
                    'nom' => $this->creator->nom,
                    'prenom' => $this->creator->prenom,
                    'email' => $this->creator->email,
                ];
            }),
            'approver' => $this->whenLoaded('approver', function () {
                return [
                    'id' => $this->approver->id,
                    'nom' => $this->approver->nom,
                    'prenom' => $this->approver->prenom,
                ];
            }),
            'reports' => $this->whenLoaded('reports', function () {
                return $this->reports->map(function ($report) {
                    return [
                        'id' => $report->id,
                        'technician_id' => $report->technician_id,
                        'report_date' => $report->report_date?->format('Y-m-d'),
                        'notes' => $report->notes,
                    ];
                });
            }),
        ];
    }
}

<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class EmployeeResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        // Utiliser try-catch pour les accessors qui pourraient échouer
        try {
            $fullName = $this->full_name ?? ($this->first_name . ' ' . $this->last_name);
            $initials = $this->initials ?? strtoupper(substr($this->first_name ?? '', 0, 1) . substr($this->last_name ?? '', 0, 1));
            $age = $this->age ?? null;
        } catch (\Exception $e) {
            $fullName = ($this->first_name ?? '') . ' ' . ($this->last_name ?? '');
            $initials = strtoupper(substr($this->first_name ?? '', 0, 1) . substr($this->last_name ?? '', 0, 1));
            $age = null;
        }
        
        return [
            'id' => $this->id,
            'first_name' => $this->first_name ?? null,
            'last_name' => $this->last_name ?? null,
            'full_name' => $fullName,
            'initials' => $initials,
            'email' => $this->email ?? null,
            'phone' => $this->phone ?? null,
            'address' => $this->address ?? null,
            'birth_date' => $this->birth_date?->format('Y-m-d'),
            'age' => $age,
            'gender' => $this->gender ?? null,
            'gender_libelle' => $this->gender_libelle ?? null,
            'marital_status' => $this->marital_status ?? null,
            'marital_status_libelle' => $this->marital_status_libelle ?? null,
            'nationality' => $this->nationality ?? null,
            'id_number' => $this->id_number ?? null,
            'social_security_number' => $this->social_security_number ?? null,
            'position' => $this->position ?? null,
            'department' => $this->department ?? null,
            'manager' => $this->manager ?? null,
            'hire_date' => $this->hire_date?->format('Y-m-d'),
            'contract_start_date' => $this->contract_start_date?->format('Y-m-d'),
            'contract_end_date' => $this->contract_end_date?->format('Y-m-d'),
            'contract_type' => $this->contract_type ?? null,
            'contract_type_libelle' => $this->contract_type_libelle ?? null,
            'salary' => $this->salary ? (float)$this->salary : null,
            'currency' => $this->currency ?? 'fcfa',
            'formatted_salary' => $this->formatted_salary ?? 'Non défini',
            'work_schedule' => $this->work_schedule ?? null,
            'status' => $this->status ?? null,
            'status_libelle' => $this->status_libelle ?? null,
            'profile_picture' => $this->profile_picture ?? null,
            'notes' => $this->notes ?? null,
            'created_by' => $this->created_by ?? null,
            'updated_by' => $this->updated_by ?? null,
            'is_contract_expiring' => $this->is_contract_expiring ?? false,
            'is_contract_expired' => $this->is_contract_expired ?? false,
            'is_active' => $this->is_active ?? false,
            'is_inactive' => $this->is_inactive ?? false,
            'is_terminated' => $this->is_terminated ?? false,
            'is_on_leave' => $this->is_on_leave ?? false,
            'created_at' => $this->created_at?->format('Y-m-d H:i:s'),
            'updated_at' => $this->updated_at?->format('Y-m-d H:i:s'),
            // Relations
            'creator' => $this->whenLoaded('creator', function () {
                if (!$this->creator) return null;
                return [
                    'id' => $this->creator->id,
                    'nom' => $this->creator->nom ?? null,
                    'prenom' => $this->creator->prenom ?? null,
                ];
            }),
            'updater' => $this->whenLoaded('updater', function () {
                if (!$this->updater) return null;
                return [
                    'id' => $this->updater->id,
                    'nom' => $this->updater->nom ?? null,
                    'prenom' => $this->updater->prenom ?? null,
                ];
            }),
            'documents' => $this->whenLoaded('documents', function () {
                return $this->documents->map(function ($document) {
                    return [
                        'id' => $document->id,
                        'name' => $document->name,
                        'type' => $document->type,
                        'file_path' => $document->file_path,
                        'expiry_date' => $document->expiry_date?->format('Y-m-d'),
                    ];
                });
            }),
            'leaves' => $this->whenLoaded('leaves', function () {
                return $this->leaves->map(function ($leave) {
                    return [
                        'id' => $leave->id,
                        'type' => $leave->type,
                        'start_date' => $leave->start_date?->format('Y-m-d'),
                        'end_date' => $leave->end_date?->format('Y-m-d'),
                        'status' => $leave->status,
                    ];
                });
            }),
            'performances' => $this->whenLoaded('performances', function () {
                return $this->performances->map(function ($performance) {
                    return [
                        'id' => $performance->id,
                        'period' => $performance->period,
                        'rating' => (float)$performance->rating,
                        'status' => $performance->status,
                    ];
                });
            }),
        ];
    }
}

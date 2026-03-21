<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AttendanceResource extends JsonResource
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
            'user_id' => $this->user_id,
            'check_in_time' => $this->check_in_time?->format('Y-m-d H:i:s'),
            'check_out_time' => $this->check_out_time?->format('Y-m-d H:i:s'),
            'status' => $this->status,
            'location' => $this->location,
            'photo_path' => $this->photo_path,
            'photo_url' => $this->photo_url,
            'notes' => $this->notes,
            'validated_by' => $this->validated_by,
            'validated_at' => $this->validated_at?->format('Y-m-d H:i:s'),
            'validation_comment' => $this->validation_comment,
            'rejected_by' => $this->rejected_by,
            'rejected_at' => $this->rejected_at?->format('Y-m-d H:i:s'),
            'rejection_reason' => $this->rejection_reason,
            'rejection_comment' => $this->rejection_comment,
            'created_at' => $this->created_at?->format('Y-m-d H:i:s'),
            'updated_at' => $this->updated_at?->format('Y-m-d H:i:s'),
            // Relations
            'user' => $this->whenLoaded('user', function () {
                return [
                    'id' => $this->user->id,
                    'nom' => $this->user->nom,
                    'prenom' => $this->user->prenom,
                    'email' => $this->user->email,
                ];
            }),
            'approver' => $this->whenLoaded('approver', function () {
                return [
                    'id' => $this->approver->id,
                    'nom' => $this->approver->nom,
                    'prenom' => $this->approver->prenom,
                ];
            }),
            'validator' => $this->whenLoaded('validator', function () {
                return [
                    'id' => $this->validator->id,
                    'nom' => $this->validator->nom,
                    'prenom' => $this->validator->prenom,
                ];
            }),
            'rejector' => $this->whenLoaded('rejector', function () {
                return [
                    'id' => $this->rejector->id,
                    'nom' => $this->rejector->nom,
                    'prenom' => $this->rejector->prenom,
                ];
            }),
        ];
    }
}

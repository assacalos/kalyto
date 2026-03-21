<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SupplierResource extends JsonResource
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
            'nom' => $this->nom,
            'email' => $this->email,
            'telephone' => $this->telephone,
            'adresse' => $this->adresse,
            'ville' => $this->ville,
            'pays' => $this->pays,
            'contact_principal' => $this->contact_principal,
            'description' => $this->description,
            'ninea' => $this->ninea,
            'statut' => $this->statut,
            'status_text' => $this->status_text,
            'status_color' => $this->status_color,
            'note_evaluation' => $this->note_evaluation,
            'commentaires' => $this->commentaires,
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
            'created_by' => $this->whenLoaded('createdBy', function () {
                return [
                    'id' => $this->createdBy->id,
                    'name' => $this->createdBy->nom . ' ' . $this->createdBy->prenom,
                    'email' => $this->createdBy->email,
                ];
            }),
            'updated_by' => $this->whenLoaded('updatedBy', function () {
                return [
                    'id' => $this->updatedBy->id,
                    'name' => $this->updatedBy->nom . ' ' . $this->updatedBy->prenom,
                    'email' => $this->updatedBy->email,
                ];
            }),
            'validated_by' => $this->whenLoaded('validatedBy', function () {
                return [
                    'id' => $this->validatedBy->id,
                    'name' => $this->validatedBy->nom . ' ' . $this->validatedBy->prenom,
                    'email' => $this->validatedBy->email,
                ];
            }),
            'rejected_by' => $this->whenLoaded('rejectedBy', function () {
                return [
                    'id' => $this->rejectedBy->id,
                    'name' => $this->rejectedBy->nom . ' ' . $this->rejectedBy->prenom,
                    'email' => $this->rejectedBy->email,
                ];
            }),
        ];
    }
}

<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CongeResource extends JsonResource
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
            'type_conge' => $this->type_conge,
            'date_debut' => $this->date_debut?->format('Y-m-d'),
            'date_fin' => $this->date_fin?->format('Y-m-d'),
            'nombre_jours' => $this->nombre_jours,
            'motif' => $this->motif,
            'statut' => $this->statut,
            'commentaire_rh' => $this->commentaire_rh,
            'raison_rejet' => $this->raison_rejet,
            'urgent' => (bool) $this->urgent,
            'piece_jointe' => $this->piece_jointe,
            'approuve_par' => $this->approuve_par,
            'date_approbation' => $this->date_approbation?->format('Y-m-d H:i:s'),
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
            'approbateur' => $this->whenLoaded('approbateur', function () {
                return [
                    'id' => $this->approbateur->id,
                    'nom' => $this->approbateur->nom,
                    'prenom' => $this->approbateur->prenom,
                ];
            }),
        ];
    }
}

<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ClientResource extends JsonResource
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
            'prenom' => $this->prenom,
            'email' => $this->email,
            'contact' => $this->contact,
            'adresse' => $this->adresse,
            'nom_entreprise' => $this->nom_entreprise,
            'numero_contribuable' => $this->numero_contribuable,
            'ninea' => $this->ninea,
            'situation_geographique' => $this->situation_geographique,
            'status' => $this->status ?? 0,
            'status_label' => $this->getStatusLabel($this->status ?? 0),
            'commentaire' => $this->commentaire,
            'created_at' => $this->created_at?->format('Y-m-d H:i:s'),
            'updated_at' => $this->updated_at?->format('Y-m-d H:i:s'),
            // Champs calculés
            'full_name' => trim($this->nom . ' ' . ($this->prenom ?? '')),
            'display_name' => $this->nom_entreprise ?: trim($this->nom . ' ' . ($this->prenom ?? '')),
            // Relations (uniquement si eager loaded)
            'user' => $this->whenLoaded('user', function () {
                return [
                    'id' => $this->user->id,
                    'nom' => $this->user->nom,
                    'prenom' => $this->user->prenom,
                    'email' => $this->user->email,
                ];
            }),
        ];
    }

    /**
     * Obtenir le libellé du statut
     */
    private function getStatusLabel($status)
    {
        $statuses = [
            0 => 'En attente',
            1 => 'Validé',
            2 => 'Rejeté'
        ];

        return $statuses[$status] ?? 'Inconnu';
    }
}

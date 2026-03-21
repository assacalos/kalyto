<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class JournalEntryResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'date' => $this->date?->format('Y-m-d'),
            'reference' => $this->reference,
            'libelle' => $this->libelle,
            'categorie' => $this->categorie,
            'mode_paiement' => $this->mode_paiement,
            'mode_paiement_libelle' => $this->mode_paiement_libelle,
            'entree' => (float) $this->entree,
            'sortie' => (float) $this->sortie,
            'notes' => $this->notes,
            'created_at' => $this->created_at?->format('Y-m-d H:i:s'),
            'updated_at' => $this->updated_at?->format('Y-m-d H:i:s'),
            'user' => $this->whenLoaded('user', function () {
                return $this->user ? [
                    'id' => $this->user->id,
                    'nom' => $this->user->nom,
                    'prenom' => $this->user->prenom,
                ] : null;
            }),
        ];
    }
}

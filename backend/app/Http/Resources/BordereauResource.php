<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use App\Http\Resources\ClientResource;

class BordereauResource extends JsonResource
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
            'reference' => $this->reference,
            'titre' => $this->titre,
            'client_id' => $this->client_id,
            'devis_id' => $this->devis_id,
            'user_id' => $this->user_id,
            'date_creation' => $this->date_creation?->format('Y-m-d'),
            'date_validation' => $this->date_validation?->format('Y-m-d'),
            'status' => $this->status,
            'notes' => $this->notes,
            'commentaire' => $this->commentaire,
            'etat_livraison' => $this->etat_livraison,
            'garantie' => $this->garantie,
            'date_livraison' => $this->date_livraison?->format('Y-m-d'),
            'created_at' => $this->created_at?->format('Y-m-d H:i:s'),
            'updated_at' => $this->updated_at?->format('Y-m-d H:i:s'),
            // Relations
            'client' => $this->whenLoaded('client', function () {
                if (!$this->client) {
                    return null;
                }
                return new ClientResource($this->client);
            }),
            'devis' => $this->whenLoaded('devis', function () {
                if (!$this->devis) {
                    return null;
                }
                return [
                    'id' => $this->devis->id,
                    'reference' => $this->devis->reference,
                ];
            }),
            'user' => $this->whenLoaded('user', function () {
                if (!$this->user) {
                    return null;
                }
                return [
                    'id' => $this->user->id,
                    'nom' => $this->user->nom,
                    'prenom' => $this->user->prenom,
                    'email' => $this->user->email,
                ];
            }),
            'items' => $this->whenLoaded('items', function () {
                return $this->items->map(function ($item) {
                    return [
                        'id' => $item->id,
                        'reference' => $item->reference,
                        'designation' => $item->designation,
                        'quantite' => $item->quantite,
                        'description' => $item->description,
                    ];
                });
            }),
        ];
    }
}

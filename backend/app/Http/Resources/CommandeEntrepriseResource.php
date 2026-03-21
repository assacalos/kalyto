<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CommandeEntrepriseResource extends JsonResource
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
            'client_id' => $this->client_id,
            'user_id' => $this->user_id,
            'status' => $this->status,
            'status_text' => $this->status_text,
            'fichiers_scannes' => $this->fichiers_scannes,
            'created_at' => $this->created_at?->format('Y-m-d H:i:s'),
            'updated_at' => $this->updated_at?->format('Y-m-d H:i:s'),
            // Relations
            'client' => $this->whenLoaded('client', function () {
                return new ClientResource($this->client);
            }),
            'commercial' => $this->whenLoaded('commercial', function () {
                return [
                    'id' => $this->commercial->id,
                    'nom' => $this->commercial->nom,
                    'prenom' => $this->commercial->prenom,
                    'email' => $this->commercial->email,
                ];
            }),
            'items' => $this->whenLoaded('items', function () {
                return $this->items->map(function ($item) {
                    return [
                        'id' => $item->id,
                        'designation' => $item->designation,
                        'quantite' => $item->quantite,
                        'prix_unitaire' => (float)$item->prix_unitaire,
                        'total' => (float)$item->total,
                    ];
                });
            }),
        ];
    }
}

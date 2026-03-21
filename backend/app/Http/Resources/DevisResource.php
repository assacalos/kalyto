<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use App\Http\Resources\ClientResource;

class DevisResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        // Calculer les totaux seulement si les items sont chargés
        $sous_total = 0;
        $total_ht = 0;
        $tva_amount = 0;
        $total_ttc = 0;
        
        if ($this->relationLoaded('items') && $this->items && $this->items->count() > 0) {
            $sous_total = $this->items->sum(function ($item) {
                return ($item->quantite ?? 0) * ($item->prix_unitaire ?? 0);
            });
            
            $remise_globale_amount = $sous_total * (($this->remise_globale ?? 0) / 100);
            $total_ht = $sous_total - $remise_globale_amount;
            $tva_amount = $total_ht * (($this->tva ?? 0) / 100);
            $total_ttc = $total_ht + $tva_amount;
        }

        return [
            'id' => $this->id,
            'reference' => $this->reference,
            'client_id' => $this->client_id,
            'commercial_id' => $this->user_id,
            'date_creation' => $this->date_creation ? (is_string($this->date_creation) ? $this->date_creation : $this->date_creation->format('Y-m-d')) : null,
            'date_validite' => $this->date_validite ? (is_string($this->date_validite) ? $this->date_validite : $this->date_validite->format('Y-m-d')) : null,
            'status' => $this->status,
            'remise_globale' => (float)($this->remise_globale ?? 0),
            'tva' => round($tva_amount, 2), // Montant de la TVA calculé
            'tva_percentage' => (float)($this->tva ?? 0), // Pourcentage de TVA
            'total_ht' => round($total_ht, 2),
            'total_ttc' => round($total_ttc, 2),
            'notes' => $this->notes,
            'conditions' => $this->conditions,
            'commentaire' => $this->commentaire,
            'titre' => $this->titre,
            'delai_livraison' => $this->delai_livraison,
            'garantie' => $this->garantie,
            'created_at' => $this->created_at?->format('Y-m-d H:i:s'),
            'updated_at' => $this->updated_at?->format('Y-m-d H:i:s'),
            // Relations
            'client' => $this->whenLoaded('client', function () {
                if (!$this->client) {
                    return null;
                }
                return new ClientResource($this->client);
            }),
            'commercial' => $this->whenLoaded('commercial', function () {
                if (!$this->commercial) {
                    return null;
                }
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
                        'reference' => $item->reference,
                        'designation' => $item->designation,
                        'quantite' => $item->quantite,
                        'prix_unitaire' => (float) $item->prix_unitaire,
                        'total' => (float) ($item->quantite * $item->prix_unitaire),
                    ];
                });
            }),
        ];
    }
}

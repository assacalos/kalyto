<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class BonDeCommandeResource extends JsonResource
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
            'fournisseur_id' => $this->fournisseur_id,
            'numero_commande' => $this->numero_commande,
            'date_commande' => $this->date_commande?->format('Y-m-d'),
            'montant_total' => $this->montant_total ? (float)$this->montant_total : null,
            'description' => $this->description,
            'statut' => $this->statut,
            'commentaire' => $this->commentaire,
            'conditions_paiement' => $this->conditions_paiement,
            'delai_livraison' => $this->delai_livraison,
            'date_validation' => $this->date_validation?->format('Y-m-d'),
            'date_debut_traitement' => $this->date_debut_traitement?->format('Y-m-d'),
            'date_annulation' => $this->date_annulation?->format('Y-m-d'),
            'user_id' => $this->user_id,
            'created_at' => $this->created_at?->format('Y-m-d H:i:s'),
            'updated_at' => $this->updated_at?->format('Y-m-d H:i:s'),
            // Relations
            'fournisseur' => $this->whenLoaded('fournisseur', function () {
                return [
                    'id' => $this->fournisseur->id,
                    'nom' => $this->fournisseur->nom,
                    'email' => $this->fournisseur->email,
                ];
            }),
            'createur' => $this->whenLoaded('createur', function () {
                return [
                    'id' => $this->createur->id,
                    'nom' => $this->createur->nom,
                    'prenom' => $this->createur->prenom,
                    'email' => $this->createur->email,
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

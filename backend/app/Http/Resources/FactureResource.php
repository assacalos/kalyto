<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class FactureResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $client = $this->whenLoaded('client');
        $user = $this->whenLoaded('user');

        return [
            'id' => $this->id,
            'invoice_number' => $this->numero_facture,
            'client_id' => $this->client_id,
            'nom' => $client ? ($client->nom_entreprise ?? ($client->nom . ' ' . $client->prenom)) : null,
            'email' => $client ? $client->email : null,
            'adresse' => $client ? $client->adresse : null,
            'client_ninea' => $this->whenLoaded('client', fn () => $this->client->ninea),
            'user_id' => $this->user_id,
            'commercial_name' => $user ? ($user->nom . ' ' . $user->prenom) : null,
            'invoice_date' => $this->date_facture?->format('Y-m-d'),
            'due_date' => $this->date_echeance?->format('Y-m-d'),
            'status' => $this->status,
            'subtotal' => (float) $this->montant_ht,
            'tax_rate' => (float) $this->tva,
            'tax_amount' => (float) ($this->montant_ttc - $this->montant_ht),
            'total_amount' => (float) $this->montant_ttc,
            'currency' => 'fcfa',
            'notes' => $this->notes,
            'terms' => $this->terms,
            'items' => $this->whenLoaded('items', function () {
                return $this->items->map(function ($item) {
                    return [
                        'id' => $item->id,
                        'description' => $item->description,
                        'quantity' => $item->quantity,
                        'unit_price' => (float) $item->unit_price,
                        'total_price' => (float) $item->total_price,
                        'unit' => $item->unit
                    ];
                });
            }),
            'paiements' => $this->whenLoaded('paiements', function () {
                return $this->paiements->map(function ($paiement) {
                    return [
                        'id' => $paiement->id,
                        'montant' => (float) $paiement->montant,
                        'date_paiement' => $paiement->date_paiement?->format('Y-m-d'),
                        'status' => $paiement->status,
                    ];
                });
            }),
            'client' => $this->whenLoaded('client', function () {
                return new ClientResource($this->client);
            }),
            'user' => $this->whenLoaded('user', function () {
                return [
                    'id' => $this->user->id,
                    'nom' => $this->user->nom,
                    'prenom' => $this->user->prenom,
                    'email' => $this->user->email,
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
            'created_at' => $this->created_at?->toDateTimeString(),
            'updated_at' => $this->updated_at?->toDateTimeString()
        ];
    }
}

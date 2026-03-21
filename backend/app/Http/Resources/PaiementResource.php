<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PaiementResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        // Mapper type_paiement du backend vers payment_method du frontend
        $paymentMethodMapping = [
            'virement' => 'bank_transfer',
            'cheque' => 'check',
            'especes' => 'cash',
            'carte_bancaire' => 'card',
            'mobile_money' => 'direct_debit'
        ];
        $paymentMethod = $paymentMethodMapping[$this->type_paiement] ?? $this->type_paiement;

        return [
            'id' => $this->id,
            'payment_number' => $this->payment_number ?? 'N/A',
            'type' => $this->type ?? 'one_time',
            'client_id' => $this->client_id ?? 0,
            'client_name' => $this->client_name ?? ($this->whenLoaded('client') ? ($this->client->nom_entreprise ?? ($this->client->nom . ' ' . ($this->client->prenom ?? ''))) : 'Client inconnu'),
            'client_email' => $this->client_email ?? ($this->whenLoaded('client') ? $this->client->email : ''),
            'client_address' => $this->client_address ?? ($this->whenLoaded('client') ? $this->client->adresse : ''),
            'comptable_id' => $this->comptable_id ?? $this->user_id ?? 0,
            'comptable_name' => $this->comptable_name ?? ($this->whenLoaded('comptable') ? ($this->comptable->nom . ' ' . ($this->comptable->prenom ?? '')) : ($this->whenLoaded('user') ? ($this->user->nom . ' ' . ($this->user->prenom ?? '')) : 'Comptable inconnu')),
            'payment_date' => $this->date_paiement?->format('Y-m-d'),
            'due_date' => $this->due_date?->format('Y-m-d'),
            'status' => $this->status ?? 'draft',
            'amount' => (float)($this->montant ?? 0),
            'currency' => $this->currency ?? 'FCFA',
            'payment_method' => $paymentMethod,
            'description' => $this->description ?? '',
            'notes' => $this->notes ?? $this->commentaire ?? '',
            'reference' => $this->reference ?? '',
            'submitted_at' => $this->submitted_at?->format('Y-m-d H:i:s'),
            'approved_at' => $this->approved_at?->format('Y-m-d H:i:s'),
            'paid_at' => $this->paid_at?->format('Y-m-d H:i:s'),
            'created_at' => $this->created_at?->format('Y-m-d H:i:s'),
            'updated_at' => $this->updated_at?->format('Y-m-d H:i:s'),
            // Relations
            'client' => $this->whenLoaded('client', function () {
                return new ClientResource($this->client);
            }),
            'comptable' => $this->whenLoaded('comptable', function () {
                return [
                    'id' => $this->comptable->id,
                    'nom' => $this->comptable->nom,
                    'prenom' => $this->comptable->prenom,
                    'email' => $this->comptable->email,
                ];
            }),
            'facture' => $this->whenLoaded('facture', function () {
                return [
                    'id' => $this->facture->id,
                    'numero_facture' => $this->facture->numero_facture,
                    'montant_ttc' => (float) $this->facture->montant_ttc,
                ];
            }),
            'schedule' => $this->whenLoaded('schedule', function () {
                return [
                    'id' => $this->schedule->id,
                    'start_date' => $this->schedule->start_date?->format('Y-m-d'),
                    'end_date' => $this->schedule->end_date?->format('Y-m-d'),
                    'frequency' => $this->schedule->frequency ?? 30,
                    'total_installments' => $this->schedule->total_installments ?? 12,
                    'paid_installments' => $this->schedule->paid_installments ?? 0,
                    'installment_amount' => (float)($this->schedule->installment_amount ?? 0),
                    'status' => $this->schedule->status ?? 'active',
                    'next_payment_date' => $this->schedule->next_payment_date?->format('Y-m-d'),
                ];
            }),
        ];
    }
}

<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ReportingResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $user = $request->user();
        $isPatronOrAdmin = $user && in_array($user->role, [1, 6]);

        return [
            'id' => $this->id,
            'user_id' => $this->user_id,
            'user_name' => $this->user_name,
            'user_role' => $this->user_role,
            'report_date' => $this->report_date?->format('Y-m-d'),
            'status' => $this->status,
            'status_libelle' => $this->status_libelle,
            'submitted_at' => $this->submitted_at?->format('Y-m-d H:i:s'),
            'approved_at' => $this->approved_at?->format('Y-m-d H:i:s'),
            'rejected_at' => $this->rejected_at?->format('Y-m-d H:i:s'),
            
            // Nouveaux champs du formulaire
            'nature' => $this->nature,
            'nature_libelle' => $this->nature_libelle,
            'nom_societe' => $this->nom_societe,
            'contact_societe' => $this->contact_societe,
            'nom_personne' => $this->nom_personne,
            'contact_personne' => $this->contact_personne,
            'moyen_contact' => $this->moyen_contact,
            'moyen_contact_libelle' => $this->moyen_contact_libelle,
            'produit_demarche' => $this->produit_demarche,
            'commentaire' => $this->commentaire,
            'type_relance' => $this->type_relance,
            'type_relance_libelle' => $this->type_relance_libelle,
            'relance_date_heure' => $this->relance_date_heure?->format('Y-m-d H:i:s'),
            
            // Note du patron (visible uniquement pour Patron et Admin)
            'patron_note' => $this->when($isPatronOrAdmin, $this->patron_note),
            'rejection_reason' => $this->when($isPatronOrAdmin, $this->rejection_reason),
            
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
            'approver' => $this->whenLoaded('approver', function () {
                return [
                    'id' => $this->approver->id,
                    'nom' => $this->approver->nom,
                    'prenom' => $this->approver->prenom,
                ];
            }),
            'rejector' => $this->whenLoaded('rejector', function () {
                return [
                    'id' => $this->rejector->id,
                    'nom' => $this->rejector->nom,
                    'prenom' => $this->rejector->prenom,
                ];
            }),
        ];
    }
}

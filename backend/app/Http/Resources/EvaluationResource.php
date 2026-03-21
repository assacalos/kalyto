<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class EvaluationResource extends JsonResource
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
            'evaluateur_id' => $this->evaluateur_id,
            'type_evaluation' => $this->type_evaluation,
            'date_evaluation' => $this->date_evaluation?->format('Y-m-d'),
            'periode_debut' => $this->periode_debut?->format('Y-m-d'),
            'periode_fin' => $this->periode_fin?->format('Y-m-d'),
            'criteres_evaluation' => $this->criteres_evaluation,
            'note_globale' => $this->note_globale ? (float)$this->note_globale : null,
            'commentaires_evaluateur' => $this->commentaires_evaluateur,
            'commentaires_employe' => $this->commentaires_employe,
            'objectifs_futurs' => $this->objectifs_futurs,
            'statut' => $this->statut,
            'date_signature_employe' => $this->date_signature_employe?->format('Y-m-d'),
            'date_signature_evaluateur' => $this->date_signature_evaluateur?->format('Y-m-d'),
            'confidentiel' => (bool)$this->confidentiel,
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
            'evaluateur' => $this->whenLoaded('evaluateur', function () {
                return [
                    'id' => $this->evaluateur->id,
                    'nom' => $this->evaluateur->nom,
                    'prenom' => $this->evaluateur->prenom,
                    'email' => $this->evaluateur->email,
                ];
            }),
        ];
    }
}

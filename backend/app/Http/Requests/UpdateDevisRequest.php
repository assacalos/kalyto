<?php

namespace App\Http\Requests;

use App\Models\Devis;
use Illuminate\Foundation\Http\FormRequest;

class UpdateDevisRequest extends FormRequest
{
    public function authorize(): bool
    {
        $devis = Devis::findOrFail($this->route('id'));

        return $this->user()->can('update', $devis);
    }

    public function rules(): array
    {
        return [
            'client_id' => 'required|exists:clients,id',
            'date_validite' => 'nullable|date|after:today',
            'notes' => 'nullable|string',
            'remise_globale' => 'nullable|numeric|min:0',
            'tva' => 'nullable|numeric|min:0|max:100',
            'conditions' => 'nullable|string',
            'commentaire' => 'nullable|string',
            'titre' => 'nullable|string|max:255',
            'delai_livraison' => 'nullable|string|max:255',
            'garantie' => 'nullable|string|max:255',
            'items' => 'required|array|min:1',
            'items.*.reference' => 'nullable|string|max:100',
            'items.*.designation' => 'required|string',
            'items.*.quantite' => 'required|integer|min:1',
            'items.*.prix_unitaire' => 'required|numeric|min:0',
        ];
    }
}

<?php

namespace App\Http\Requests;

use App\Models\Facture;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateFactureRequest extends FormRequest
{
    public function authorize(): bool
    {
        $facture = Facture::findOrFail($this->route('id'));

        return $this->user()->can('update', $facture);
    }

    public function rules(): array
    {
        $id = $this->route('id');

        return [
            'numero_facture' => [
                'required',
                'string',
                Rule::unique('factures', 'numero_facture')->ignore($id),
            ],
            'montant' => 'required|numeric|min:0',
            'date_facture' => 'required|date',
            'description' => 'nullable|string',
            'status' => [
                'required',
                'string',
                Rule::in(['en_attente', 'valide', 'rejete', 'payee', 'impayee']),
            ],
        ];
    }
}

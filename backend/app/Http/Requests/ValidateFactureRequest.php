<?php

namespace App\Http\Requests;

use App\Models\Facture;
use Illuminate\Foundation\Http\FormRequest;

class ValidateFactureRequest extends FormRequest
{
    public function authorize(): bool
    {
        $facture = Facture::findOrFail($this->route('id'));

        return $this->user()->can('validate', $facture);
    }

    public function rules(): array
    {
        return [
            'commentaire' => 'nullable|string|max:500',
            'comments' => 'nullable|string|max:500',
        ];
    }
}

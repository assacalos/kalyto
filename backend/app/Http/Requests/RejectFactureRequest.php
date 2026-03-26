<?php

namespace App\Http\Requests;

use App\Models\Facture;
use Illuminate\Foundation\Http\FormRequest;

class RejectFactureRequest extends FormRequest
{
    public function authorize(): bool
    {
        $facture = Facture::findOrFail($this->route('id'));

        return $this->user()->can('reject', $facture);
    }

    public function rules(): array
    {
        return [
            'raison_rejet' => 'nullable|string|max:500',
            'reason' => 'nullable|string|max:500',
            'commentaire' => 'nullable|string|max:500',
        ];
    }
}

<?php

namespace App\Http\Requests;

use App\Models\Devis;
use Illuminate\Foundation\Http\FormRequest;

class RejectDevisRequest extends FormRequest
{
    public function authorize(): bool
    {
        $devis = Devis::findOrFail($this->route('id'));

        return $this->user()->can('reject', $devis);
    }

    public function rules(): array
    {
        return [
            'commentaire' => 'required|string',
        ];
    }
}

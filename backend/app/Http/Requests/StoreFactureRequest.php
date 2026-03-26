<?php

namespace App\Http\Requests;

use App\Models\Facture;
use Illuminate\Foundation\Http\FormRequest;

class StoreFactureRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('create', Facture::class);
    }

    public function rules(): array
    {
        return [
            'client_id' => 'required|exists:clients,id',
            'invoice_date' => 'required|date',
            'due_date' => 'required|date',
            'subtotal' => 'required|numeric|min:0',
            'tax_rate' => 'required|numeric|min:0|max:100',
            'tax_amount' => 'required|numeric|min:0',
            'total_amount' => 'required|numeric|min:0',
            'items' => 'required|array|min:1',
            'items.*.description' => 'required|string',
            'items.*.quantity' => 'required|integer|min:1',
            'items.*.unit_price' => 'required|numeric|min:0',
            'items.*.total_price' => 'required|numeric|min:0',
            'items.*.unit' => 'nullable|string',
            'notes' => 'nullable|string',
            'terms' => 'nullable|string',
            'numero_facture' => 'nullable|string|unique:factures,numero_facture',
        ];
    }
}

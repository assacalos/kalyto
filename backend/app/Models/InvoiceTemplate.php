<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class InvoiceTemplate extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'description',
        'template',
        'is_default'
    ];

    protected $casts = [
        'is_default' => 'boolean'
    ];

    // Scopes
    public function scopeDefault($query)
    {
        return $query->where('is_default', true);
    }

    // Méthodes utilitaires
    public function setAsDefault()
    {
        // Désactiver tous les autres templates par défaut
        self::where('is_default', true)->update(['is_default' => false]);
        
        // Activer ce template
        $this->update(['is_default' => true]);
    }

    public static function getDefaultTemplate()
    {
        return self::where('is_default', true)->first() ?? self::first();
    }

    // Méthode pour rendre le template avec des données
    public function render($invoice, $client, $commercial)
    {
        $template = $this->template;
        
        // Variables disponibles dans le template
        $variables = [
            '{{invoice_number}}' => $invoice->invoice_number,
            '{{invoice_date}}' => $invoice->invoice_date->format('d/m/Y'),
            '{{due_date}}' => $invoice->due_date->format('d/m/Y'),
            '{{client_name}}' => $client->nom,
            '{{client_email}}' => $client->email,
            '{{client_address}}' => $client->adresse,
            '{{commercial_name}}' => $commercial->nom . ' ' . $commercial->prenom,
            '{{subtotal}}' => number_format($invoice->subtotal, 2, ',', ' '),
            '{{tax_rate}}' => $invoice->tax_rate,
            '{{tax_amount}}' => number_format($invoice->tax_amount, 2, ',', ' '),
            '{{total_amount}}' => number_format($invoice->total_amount, 2, ',', ' '),
            '{{currency}}' => $invoice->currency,
            '{{notes}}' => $invoice->notes ?? '',
            '{{terms}}' => $invoice->terms ?? '',
        ];

        return str_replace(array_keys($variables), array_values($variables), $template);
    }
}
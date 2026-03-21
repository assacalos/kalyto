<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PaymentTemplate extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'description',
        'type',
        'default_amount',
        'default_payment_method',
        'default_frequency',
        'template',
        'is_default',
        'is_active',
        'created_by',
        'updated_by'
    ];

    protected $casts = [
        'default_amount' => 'decimal:2',
        'is_default' => 'boolean',
        'is_active' => 'boolean',
        'template' => 'array'
    ];

    // Relations
    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function updater()
    {
        return $this->belongsTo(User::class, 'updated_by');
    }

    // Scopes
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    public function scopeOneTime($query)
    {
        return $query->where('type', 'one_time');
    }

    public function scopeMonthly($query)
    {
        return $query->where('type', 'monthly');
    }

    public function scopeDefault($query)
    {
        return $query->where('is_default', true);
    }

    // Accesseurs
    public function getTypeLibelleAttribute()
    {
        $types = [
            'one_time' => 'Paiement unique',
            'monthly' => 'Paiement mensuel'
        ];

        return $types[$this->type] ?? $this->type;
    }

    public function getFormattedAmountAttribute()
    {
        return number_format($this->default_amount, 2, ',', ' ') . ' FCFA';
    }

    public function getPaymentMethodLibelleAttribute()
    {
        $methods = [
            'especes' => 'Espèces',
            'virement' => 'Virement',
            'cheque' => 'Chèque',
            'carte_bancaire' => 'Carte bancaire',
            'mobile_money' => 'Mobile Money'
        ];

        return $methods[$this->default_payment_method] ?? $this->default_payment_method;
    }

    // Méthodes utilitaires
    public function canBeSetAsDefault()
    {
        return $this->is_active;
    }

    public function setAsDefault()
    {
        if ($this->canBeSetAsDefault()) {
            // Retirer le statut par défaut des autres templates du même type
            self::where('type', $this->type)
                ->where('id', '!=', $this->id)
                ->update(['is_default' => false]);
            
            $this->update(['is_default' => true]);
            return true;
        }
        return false;
    }

    public function createPaymentFromTemplate($data = [])
    {
        $paymentData = array_merge([
            'type' => $this->type,
            'montant' => $this->default_amount,
            'type_paiement' => $this->default_payment_method,
            'currency' => 'FCFA',
            'status' => 'draft'
        ], $data);

        return Paiement::create($paymentData);
    }

    public function getTemplateData()
    {
        return $this->template ?? [];
    }

    public function setTemplateData($data)
    {
        $this->update(['template' => $data]);
    }
}
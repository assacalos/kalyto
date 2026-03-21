<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class TaxCategory extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'code',
        'description',
        'default_rate',
        'type',
        'frequency',
        'is_active',
        'applicable_to'
    ];

    protected $casts = [
        'default_rate' => 'decimal:2',
        'is_active' => 'boolean',
        'applicable_to' => 'array'
    ];

    // Relations
    public function taxes()
    {
        return $this->hasMany(Tax::class);
    }

    public function declarations()
    {
        return $this->hasMany(TaxDeclaration::class);
    }

    // Scopes
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    public function scopeByType($query, $type)
    {
        return $query->where('type', $type);
    }

    public function scopeByFrequency($query, $frequency)
    {
        return $query->where('frequency', $frequency);
    }

    // Accesseurs
    public function getTypeLibelleAttribute()
    {
        $types = [
            'percentage' => 'Pourcentage',
            'fixed' => 'Montant fixe'
        ];

        return $types[$this->type] ?? $this->type;
    }

    public function getFrequencyLibelleAttribute()
    {
        $frequencies = [
            'monthly' => 'Mensuelle',
            'quarterly' => 'Trimestrielle',
            'yearly' => 'Annuelle'
        ];

        return $frequencies[$this->frequency] ?? $this->frequency;
    }

    public function getFormattedRateAttribute()
    {
        if ($this->type === 'percentage') {
            return $this->default_rate . '%';
        }
        return number_format($this->default_rate, 2, ',', ' ') . ' €';
    }

    // Méthodes utilitaires
    public function calculateTax($baseAmount)
    {
        if ($this->type === 'percentage') {
            return ($baseAmount * $this->default_rate) / 100;
        }
        return $this->default_rate;
    }

    public function isApplicableTo($entityType)
    {
        if (empty($this->applicable_to)) {
            return true;
        }
        return in_array($entityType, $this->applicable_to);
    }

    public function activate()
    {
        $this->update(['is_active' => true]);
    }

    public function deactivate()
    {
        $this->update(['is_active' => false]);
    }

    // Méthodes statiques
    public static function getActiveByCode($code)
    {
        return self::where('code', $code)->where('is_active', true)->first();
    }

    public static function getByFrequency($frequency)
    {
        return self::where('frequency', $frequency)->where('is_active', true)->get();
    }
}
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class SalaryComponent extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'code',
        'description',
        'type',
        'calculation_type',
        'default_value',
        'is_taxable',
        'is_social_security',
        'is_mandatory',
        'is_active',
        'calculation_rules'
    ];

    protected $casts = [
        'default_value' => 'decimal:2',
        'is_taxable' => 'boolean',
        'is_social_security' => 'boolean',
        'is_mandatory' => 'boolean',
        'is_active' => 'boolean',
        'calculation_rules' => 'array'
    ];

    // Relations
    public function salaryItems()
    {
        return $this->hasMany(SalaryItem::class);
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

    public function scopeByCalculationType($query, $calculationType)
    {
        return $query->where('calculation_type', $calculationType);
    }

    public function scopeMandatory($query)
    {
        return $query->where('is_mandatory', true);
    }

    public function scopeTaxable($query)
    {
        return $query->where('is_taxable', true);
    }

    public function scopeSocialSecurity($query)
    {
        return $query->where('is_social_security', true);
    }

    // Accesseurs
    public function getTypeLibelleAttribute()
    {
        $types = [
            'base' => 'Salaire de base',
            'allowance' => 'Indemnité',
            'deduction' => 'Déduction',
            'bonus' => 'Prime',
            'overtime' => 'Heures supplémentaires'
        ];

        return $types[$this->type] ?? $this->type;
    }

    public function getCalculationTypeLibelleAttribute()
    {
        $types = [
            'fixed' => 'Montant fixe',
            'percentage' => 'Pourcentage',
            'hourly' => 'Horaire',
            'performance' => 'Performance'
        ];

        return $types[$this->calculation_type] ?? $this->calculation_type;
    }

    public function getFormattedDefaultValueAttribute()
    {
        if ($this->calculation_type === 'percentage') {
            return $this->default_value . '%';
        }
        return number_format($this->default_value, 2, ',', ' ') . ' €';
    }

    // Méthodes utilitaires
    public function calculateAmount($baseAmount = 0, $hours = 0, $performance = 0)
    {
        switch ($this->calculation_type) {
            case 'fixed':
                return $this->default_value;
            
            case 'percentage':
                return ($baseAmount * $this->default_value) / 100;
            
            case 'hourly':
                return $this->default_value * $hours;
            
            case 'performance':
                return $this->default_value * $performance;
            
            default:
                return $this->default_value;
        }
    }

    public function isAllowance()
    {
        return $this->type === 'allowance';
    }

    public function isDeduction()
    {
        return $this->type === 'deduction';
    }

    public function isBase()
    {
        return $this->type === 'base';
    }

    public function isBonus()
    {
        return $this->type === 'bonus';
    }

    public function isOvertime()
    {
        return $this->type === 'overtime';
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
    public static function getActiveComponents()
    {
        return self::active()->orderBy('type')->orderBy('name')->get();
    }

    public static function getComponentsByType($type)
    {
        return self::active()->byType($type)->orderBy('name')->get();
    }

    public static function getMandatoryComponents()
    {
        return self::active()->mandatory()->orderBy('name')->get();
    }

    public static function getTaxableComponents()
    {
        return self::active()->taxable()->orderBy('name')->get();
    }

    public static function getSocialSecurityComponents()
    {
        return self::active()->socialSecurity()->orderBy('name')->get();
    }
}
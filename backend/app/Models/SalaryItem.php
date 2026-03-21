<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class SalaryItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'salary_id',
        'salary_component_id',
        'name',
        'type',
        'amount',
        'rate',
        'unit',
        'quantity',
        'description',
        'is_taxable',
        'is_social_security',
        'calculation_details'
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'rate' => 'decimal:2',
        'is_taxable' => 'boolean',
        'is_social_security' => 'boolean',
        'calculation_details' => 'array'
    ];

    // Relations
    public function salary()
    {
        return $this->belongsTo(Salary::class);
    }

    public function salaryComponent()
    {
        return $this->belongsTo(SalaryComponent::class);
    }

    // Scopes
    public function scopeByType($query, $type)
    {
        return $query->where('type', $type);
    }

    public function scopeAllowances($query)
    {
        return $query->where('type', 'allowance');
    }

    public function scopeDeductions($query)
    {
        return $query->where('type', 'deduction');
    }

    public function scopeBonuses($query)
    {
        return $query->where('type', 'bonus');
    }

    public function scopeOvertime($query)
    {
        return $query->where('type', 'overtime');
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

    public function getFormattedAmountAttribute()
    {
        return number_format($this->amount, 2, ',', ' ') . ' €';
    }

    public function getFormattedRateAttribute()
    {
        if ($this->rate) {
            return $this->rate . ($this->unit === '%' ? '%' : ' ' . $this->unit);
        }
        return 'N/A';
    }

    public function getComponentNameAttribute()
    {
        return $this->salaryComponent ? $this->salaryComponent->name : $this->name;
    }

    public function getComponentCodeAttribute()
    {
        return $this->salaryComponent ? $this->salaryComponent->code : 'N/A';
    }

    // Méthodes utilitaires
    public function isAllowance()
    {
        return $this->type === 'allowance';
    }

    public function isDeduction()
    {
        return $this->type === 'deduction';
    }

    public function isBonus()
    {
        return $this->type === 'bonus';
    }

    public function isOvertime()
    {
        return $this->type === 'overtime';
    }

    public function isBase()
    {
        return $this->type === 'base';
    }

    public function calculateTax()
    {
        if (!$this->is_taxable) {
            return 0;
        }

        $taxRate = PayrollSetting::getValue('tax_rate', 20);
        return ($this->amount * $taxRate) / 100;
    }

    public function calculateSocialSecurity()
    {
        if (!$this->is_social_security) {
            return 0;
        }

        $socialSecurityRate = PayrollSetting::getValue('social_security_rate', 15);
        return ($this->amount * $socialSecurityRate) / 100;
    }

    public function getTaxAmount()
    {
        return $this->calculateTax();
    }

    public function getSocialSecurityAmount()
    {
        return $this->calculateSocialSecurity();
    }

    public function getNetAmount()
    {
        $tax = $this->getTaxAmount();
        $socialSecurity = $this->getSocialSecurityAmount();
        
        if ($this->isDeduction()) {
            return $this->amount; // Les déductions sont déjà nettes
        }
        
        return $this->amount - $tax - $socialSecurity;
    }

    // Méthodes statiques
    public static function getItemsBySalary($salaryId)
    {
        return self::where('salary_id', $salaryId)
            ->with('salaryComponent')
            ->orderBy('type')
            ->orderBy('name')
            ->get();
    }

    public static function getItemsByType($salaryId, $type)
    {
        return self::where('salary_id', $salaryId)
            ->where('type', $type)
            ->with('salaryComponent')
            ->orderBy('name')
            ->get();
    }

    public static function getTotalByType($salaryId, $type)
    {
        return self::where('salary_id', $salaryId)
            ->where('type', $type)
            ->sum('amount');
    }

    public static function getTotalTaxable($salaryId)
    {
        return self::where('salary_id', $salaryId)
            ->where('is_taxable', true)
            ->sum('amount');
    }

    public static function getTotalSocialSecurity($salaryId)
    {
        return self::where('salary_id', $salaryId)
            ->where('is_social_security', true)
            ->sum('amount');
    }
}

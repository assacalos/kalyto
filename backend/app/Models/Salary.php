<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class Salary extends Model
{
    use HasFactory;

    protected $fillable = [
        'company_id',
        'employee_id',
        'salary_number',
        'period',
        'period_start',
        'period_end',
        'salary_date',
        'base_salary',
        'gross_salary',
        'net_salary',
        'total_allowances',
        'total_deductions',
        'total_taxes',
        'total_social_security',
        'status',
        'notes',
        'justificatif',
        'salary_breakdown',
        'components',
        'calculated_at',
        'approved_at',
        'approved_by',
        'paid_at',
        'paid_by'
    ];

    protected $casts = [
        'period_start' => 'date',
        'period_end' => 'date',
        'salary_date' => 'date',
        'base_salary' => 'decimal:2',
        'gross_salary' => 'decimal:2',
        'net_salary' => 'decimal:2',
        'total_allowances' => 'decimal:2',
        'total_deductions' => 'decimal:2',
        'total_taxes' => 'decimal:2',
        'total_social_security' => 'decimal:2',
        'justificatif' => 'array',
        'salary_breakdown' => 'array',
        'components' => 'array',
        'calculated_at' => 'datetime',
        'approved_at' => 'datetime',
        'paid_at' => 'datetime'
    ];

    // Relations
    public function employee()
    {
        return $this->belongsTo(Employee::class, 'employee_id');
    }

    public function hr()
    {
        return $this->belongsTo(Employee::class, 'employee_id'); // Alias pour cohérence
    }

    public function approver()
    {
        return $this->belongsTo(User::class, 'approved_by');
    }

    public function payer()
    {
        return $this->belongsTo(User::class, 'paid_by');
    }

    public function salaryItems()
    {
        return $this->hasMany(SalaryItem::class);
    }

    // Scopes
    public function scopeDraft($query)
    {
        return $query->where('status', 'draft');
    }

    public function scopeCalculated($query)
    {
        return $query->where('status', 'calculated');
    }

    public function scopeApproved($query)
    {
        return $query->where('status', 'approved');
    }

    public function scopePaid($query)
    {
        return $query->where('status', 'paid');
    }

    public function scopeCancelled($query)
    {
        return $query->where('status', 'cancelled');
    }

    public function scopeByEmployee($query, $employeeId)
    {
        return $query->where('employee_id', $employeeId);
    }

    public function scopeByPeriod($query, $period)
    {
        return $query->where('period', $period);
    }

    public function scopeByDateRange($query, $startDate, $endDate)
    {
        return $query->whereBetween('salary_date', [$startDate, $endDate]);
    }

    // Accesseurs
    public function getStatusLibelleAttribute()
    {
        $statuses = [
            'draft' => 'Brouillon',
            'calculated' => 'Calculé',
            'approved' => 'Approuvé',
            'paid' => 'Payé',
            'cancelled' => 'Annulé'
        ];

        return $statuses[$this->status] ?? $this->status;
    }

    public function getEmployeeNameAttribute()
    {
        if (!$this->relationLoaded('employee') || !$this->employee) {
            return 'N/A';
        }
        return trim(($this->employee->first_name ?? '') . ' ' . ($this->employee->last_name ?? '')) ?: 'N/A';
    }

    public function getHrNameAttribute()
    {
        if (!$this->relationLoaded('hr') || !$this->hr) {
            return 'N/A';
        }
        return trim(($this->hr->first_name ?? '') . ' ' . ($this->hr->last_name ?? '')) ?: 'N/A';
    }

    public function getApproverNameAttribute()
    {
        if (!$this->relationLoaded('approver') || !$this->approver) {
            return 'N/A';
        }
        return trim(($this->approver->prenom ?? '') . ' ' . ($this->approver->nom ?? '')) ?: 'N/A';
    }

    public function getPayerNameAttribute()
    {
        if (!$this->relationLoaded('payer') || !$this->payer) {
            return 'N/A';
        }
        return trim(($this->payer->prenom ?? '') . ' ' . ($this->payer->nom ?? '')) ?: 'N/A';
    }

    public function getFormattedBaseSalaryAttribute()
    {
        return number_format($this->base_salary, 2, ',', ' ') . ' €';
    }

    public function getFormattedGrossSalaryAttribute()
    {
        return number_format($this->gross_salary, 2, ',', ' ') . ' €';
    }

    public function getFormattedNetSalaryAttribute()
    {
        return number_format($this->net_salary, 2, ',', ' ') . ' €';
    }

    public function getFormattedTotalAllowancesAttribute()
    {
        return number_format($this->total_allowances, 2, ',', ' ') . ' €';
    }

    public function getFormattedTotalDeductionsAttribute()
    {
        return number_format($this->total_deductions, 2, ',', ' ') . ' €';
    }

    public function getFormattedTotalTaxesAttribute()
    {
        return number_format($this->total_taxes, 2, ',', ' ') . ' €';
    }

    public function getFormattedTotalSocialSecurityAttribute()
    {
        return number_format($this->total_social_security, 2, ',', ' ') . ' €';
    }

    public function getDaysSincePaymentAttribute()
    {
        if (!$this->salary_date) {
            return null;
        }

        return now()->diffInDays($this->salary_date);
    }

    public function getIsOverdueAttribute()
    {
        return $this->status === 'approved' && $this->salary_date && $this->salary_date < now()->toDateString();
    }

    // Méthodes utilitaires
    public function canBeEdited()
    {
        return $this->status === 'draft';
    }

    public function canBeCalculated()
    {
        return $this->status === 'draft';
    }

    public function canBeApproved()
    {
        return in_array($this->status, ['pending', 'draft', 'calculated']);
    }

    public function canBePaid()
    {
        return $this->status === 'approved';
    }

    public function canBeCancelled()
    {
        return in_array($this->status, ['draft', 'calculated']);
    }

    public function calculateSalary()
    {
        if (!$this->canBeCalculated()) {
            return false;
        }

        // Récupérer les composants de salaire
        $components = SalaryComponent::getActiveComponents();
        $salaryItems = [];
        $totalAllowances = 0;
        $totalDeductions = 0;
        $totalTaxes = 0;
        $totalSocialSecurity = 0;

        foreach ($components as $component) {
            $amount = $component->calculateAmount($this->base_salary);
            
            if ($amount > 0) {
                $salaryItem = SalaryItem::create([
                    'salary_id' => $this->id,
                    'salary_component_id' => $component->id,
                    'name' => $component->name,
                    'type' => $component->type,
                    'amount' => $amount,
                    'rate' => $component->calculation_type === 'percentage' ? $component->default_value : null,
                    'unit' => $component->calculation_type === 'hourly' ? 'heures' : ($component->calculation_type === 'percentage' ? '%' : '€'),
                    'quantity' => 1,
                    'description' => $component->description,
                    'is_taxable' => $component->is_taxable,
                    'is_social_security' => $component->is_social_security,
                    'calculation_details' => [
                        'component_code' => $component->code,
                        'calculation_type' => $component->calculation_type,
                        'base_amount' => $this->base_salary
                    ]
                ]);

                $salaryItems[] = $salaryItem;

                // Calculer les totaux
                if ($component->isAllowance() || $component->isBonus() || $component->isOvertime()) {
                    $totalAllowances += $amount;
                } elseif ($component->isDeduction()) {
                    $totalDeductions += $amount;
                }

                if ($component->is_taxable) {
                    $totalTaxes += $this->calculateTax($amount);
                }

                if ($component->is_social_security) {
                    $totalSocialSecurity += $this->calculateSocialSecurity($amount);
                }
            }
        }

        // Calculer le salaire brut et net
        $grossSalary = $this->base_salary + $totalAllowances - $totalDeductions;
        $netSalary = $grossSalary - $totalTaxes - $totalSocialSecurity;

        // Mettre à jour le salaire
        $this->update([
            'gross_salary' => $grossSalary,
            'net_salary' => $netSalary,
            'total_allowances' => $totalAllowances,
            'total_deductions' => $totalDeductions,
            'total_taxes' => $totalTaxes,
            'total_social_security' => $totalSocialSecurity,
            'status' => 'calculated',
            'calculated_at' => now(),
            'salary_breakdown' => [
                'base_salary' => $this->base_salary,
                'allowances' => $totalAllowances,
                'deductions' => $totalDeductions,
                'taxes' => $totalTaxes,
                'social_security' => $totalSocialSecurity,
                'gross_salary' => $grossSalary,
                'net_salary' => $netSalary,
                'calculation_date' => now()->toIso8601String()
            ],
            'components' => $salaryItems
        ]);

        return true;
    }

    public function calculateTax($amount)
    {
        // Récupérer le taux d'imposition depuis les paramètres
        $taxRate = PayrollSetting::getValue('tax_rate', 20); // 20% par défaut
        return ($amount * $taxRate) / 100;
    }

    public function calculateSocialSecurity($amount)
    {
        // Récupérer le taux de charges sociales depuis les paramètres
        $socialSecurityRate = PayrollSetting::getValue('social_security_rate', 15); // 15% par défaut
        return ($amount * $socialSecurityRate) / 100;
    }

    public function approve($approverId, $notes = null)
    {
        if ($this->canBeApproved()) {
            $this->update([
                'status' => 'approved',
                'approved_at' => now(),
                'approved_by' => $approverId,
                'notes' => $notes ?? $this->notes
            ]);
            return true;
        }
        return false;
    }

    public function markAsPaid($payerId)
    {
        if ($this->canBePaid()) {
            $this->update([
                'status' => 'paid',
                'paid_at' => now(),
                'paid_by' => $payerId
            ]);
            return true;
        }
        return false;
    }

    public function cancel($reason = null)
    {
        if ($this->canBeCancelled()) {
            $this->update([
                'status' => 'cancelled',
                'notes' => $reason ?? $this->notes
            ]);
            return true;
        }
        return false;
    }

    // Méthodes statiques
    public static function generateSalaryNumber()
    {
        $count = self::count() + 1;
        return 'SAL-' . date('Y') . '-' . str_pad($count, 4, '0', STR_PAD_LEFT);
    }

    public static function getSalaryStats($startDate = null, $endDate = null)
    {
        $query = self::query();
        
        if ($startDate && $endDate) {
            $query->whereBetween('salary_date', [$startDate, $endDate]);
        }

        $salaries = $query->get();
        
        return [
            'total_salaries' => $salaries->count(),
            'draft_salaries' => $salaries->where('status', 'draft')->count(),
            'calculated_salaries' => $salaries->where('status', 'calculated')->count(),
            'approved_salaries' => $salaries->where('status', 'approved')->count(),
            'paid_salaries' => $salaries->where('status', 'paid')->count(),
            'cancelled_salaries' => $salaries->where('status', 'cancelled')->count(),
            'total_base_salary' => $salaries->sum('base_salary'),
            'total_gross_salary' => $salaries->sum('gross_salary'),
            'total_net_salary' => $salaries->sum('net_salary'),
            'total_allowances' => $salaries->sum('total_allowances'),
            'total_deductions' => $salaries->sum('total_deductions'),
            'total_taxes' => $salaries->sum('total_taxes'),
            'total_social_security' => $salaries->sum('total_social_security')
        ];
    }

    public static function getSalariesByPeriod($period)
    {
        return self::with(['employee', 'hr', 'salaryItems.salaryComponent'])
            ->where('period', $period)
            ->orderBy('employee_id')
            ->get();
    }

    public static function getOverdueSalaries()
    {
        return self::where('status', 'approved')
            ->where('salary_date', '<', now()->toDateString())
            ->with(['employee', 'hr'])
            ->get();
    }
}

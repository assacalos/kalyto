<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class Payroll extends Model
{
    use HasFactory;

    protected $fillable = [
        'hr_id',
        'payroll_number',
        'period',
        'period_start',
        'period_end',
        'payment_date',
        'total_employees',
        'total_gross_salary',
        'total_net_salary',
        'total_taxes',
        'total_social_security',
        'total_allowances',
        'total_deductions',
        'status',
        'notes',
        'payroll_summary',
        'calculated_at',
        'approved_at',
        'approved_by',
        'paid_at',
        'paid_by'
    ];

    protected $casts = [
        'period_start' => 'date',
        'period_end' => 'date',
        'payment_date' => 'date',
        'total_gross_salary' => 'decimal:2',
        'total_net_salary' => 'decimal:2',
        'total_taxes' => 'decimal:2',
        'total_social_security' => 'decimal:2',
        'total_allowances' => 'decimal:2',
        'total_deductions' => 'decimal:2',
        'payroll_summary' => 'array',
        'calculated_at' => 'datetime',
        'approved_at' => 'datetime',
        'paid_at' => 'datetime'
    ];

    // Relations
    public function hr()
    {
        return $this->belongsTo(User::class, 'hr_id');
    }

    public function approver()
    {
        return $this->belongsTo(User::class, 'approved_by');
    }

    public function payer()
    {
        return $this->belongsTo(User::class, 'paid_by');
    }

    public function salaries()
    {
        return $this->hasMany(Salary::class, 'period', 'period');
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

    public function scopeByPeriod($query, $period)
    {
        return $query->where('period', $period);
    }

    public function scopeByDateRange($query, $startDate, $endDate)
    {
        return $query->whereBetween('payment_date', [$startDate, $endDate]);
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

    public function getHrNameAttribute()
    {
        if (!$this->relationLoaded('hr') || !$this->hr) {
            return 'N/A';
        }
        return trim(($this->hr->prenom ?? '') . ' ' . ($this->hr->nom ?? '')) ?: 'N/A';
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

    public function getFormattedTotalGrossSalaryAttribute()
    {
        return number_format($this->total_gross_salary, 2, ',', ' ') . ' €';
    }

    public function getFormattedTotalNetSalaryAttribute()
    {
        return number_format($this->total_net_salary, 2, ',', ' ') . ' €';
    }

    public function getFormattedTotalTaxesAttribute()
    {
        return number_format($this->total_taxes, 2, ',', ' ') . ' €';
    }

    public function getFormattedTotalSocialSecurityAttribute()
    {
        return number_format($this->total_social_security, 2, ',', ' ') . ' €';
    }

    public function getFormattedTotalAllowancesAttribute()
    {
        return number_format($this->total_allowances, 2, ',', ' ') . ' €';
    }

    public function getFormattedTotalDeductionsAttribute()
    {
        return number_format($this->total_deductions, 2, ',', ' ') . ' €';
    }

    public function getDaysSincePaymentAttribute()
    {
        if (!$this->payment_date) {
            return null;
        }

        return now()->diffInDays($this->payment_date);
    }

    public function getIsOverdueAttribute()
    {
        return $this->status === 'approved' && $this->payment_date && $this->payment_date < now()->toDateString();
    }

    public function getAverageGrossSalaryAttribute()
    {
        return $this->total_employees > 0 ? $this->total_gross_salary / $this->total_employees : 0;
    }

    public function getAverageNetSalaryAttribute()
    {
        return $this->total_employees > 0 ? $this->total_net_salary / $this->total_employees : 0;
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
        return $this->status === 'calculated';
    }

    public function canBePaid()
    {
        return $this->status === 'approved';
    }

    public function canBeCancelled()
    {
        return in_array($this->status, ['draft', 'calculated']);
    }

    public function calculatePayroll()
    {
        if (!$this->canBeCalculated()) {
            return false;
        }

        // Récupérer tous les salaires de la période
        $salaries = Salary::where('period', $this->period)->get();
        
        if ($salaries->isEmpty()) {
            return false;
        }

        // Calculer les totaux
        $totalEmployees = $salaries->count();
        $totalGrossSalary = $salaries->sum('gross_salary');
        $totalNetSalary = $salaries->sum('net_salary');
        $totalTaxes = $salaries->sum('total_taxes');
        $totalSocialSecurity = $salaries->sum('total_social_security');
        $totalAllowances = $salaries->sum('total_allowances');
        $totalDeductions = $salaries->sum('total_deductions');

        // Mettre à jour la paie
        $this->update([
            'total_employees' => $totalEmployees,
            'total_gross_salary' => $totalGrossSalary,
            'total_net_salary' => $totalNetSalary,
            'total_taxes' => $totalTaxes,
            'total_social_security' => $totalSocialSecurity,
            'total_allowances' => $totalAllowances,
            'total_deductions' => $totalDeductions,
            'status' => 'calculated',
            'calculated_at' => now(),
            'payroll_summary' => [
                'period' => $this->period,
                'total_employees' => $totalEmployees,
                'average_gross_salary' => $totalEmployees > 0 ? $totalGrossSalary / $totalEmployees : 0,
                'average_net_salary' => $totalEmployees > 0 ? $totalNetSalary / $totalEmployees : 0,
                'total_gross_salary' => $totalGrossSalary,
                'total_net_salary' => $totalNetSalary,
                'total_taxes' => $totalTaxes,
                'total_social_security' => $totalSocialSecurity,
                'total_allowances' => $totalAllowances,
                'total_deductions' => $totalDeductions,
                'calculation_date' => now()->toIso8601String()
            ]
        ]);

        return true;
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
    public static function generatePayrollNumber()
    {
        $count = self::count() + 1;
        return 'PAY-' . date('Y') . '-' . str_pad($count, 4, '0', STR_PAD_LEFT);
    }

    public static function getPayrollStats($startDate = null, $endDate = null)
    {
        $query = self::query();
        
        if ($startDate && $endDate) {
            $query->whereBetween('payment_date', [$startDate, $endDate]);
        }

        $payrolls = $query->get();
        
        return [
            'total_payrolls' => $payrolls->count(),
            'draft_payrolls' => $payrolls->where('status', 'draft')->count(),
            'calculated_payrolls' => $payrolls->where('status', 'calculated')->count(),
            'approved_payrolls' => $payrolls->where('status', 'approved')->count(),
            'paid_payrolls' => $payrolls->where('status', 'paid')->count(),
            'cancelled_payrolls' => $payrolls->where('status', 'cancelled')->count(),
            'total_employees' => $payrolls->sum('total_employees'),
            'total_gross_salary' => $payrolls->sum('total_gross_salary'),
            'total_net_salary' => $payrolls->sum('total_net_salary'),
            'total_taxes' => $payrolls->sum('total_taxes'),
            'total_social_security' => $payrolls->sum('total_social_security'),
            'total_allowances' => $payrolls->sum('total_allowances'),
            'total_deductions' => $payrolls->sum('total_deductions')
        ];
    }

    public static function getPayrollsByPeriod($period)
    {
        return self::with(['hr', 'approver', 'payer'])
            ->where('period', $period)
            ->orderBy('payment_date')
            ->get();
    }

    public static function getOverduePayrolls()
    {
        return self::where('status', 'approved')
            ->where('payment_date', '<', now()->toDateString())
            ->with(['hr', 'approver'])
            ->get();
    }
}

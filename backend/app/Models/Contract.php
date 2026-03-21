<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class Contract extends Model
{
    use HasFactory;

    protected $fillable = [
        'contract_number',
        'employee_id',
        'employee_name',
        'employee_email',
        'contract_type',
        'position',
        'department',
        'job_title',
        'job_description',
        'gross_salary',
        'net_salary',
        'salary_currency',
        'payment_frequency',
        'start_date',
        'end_date',
        'duration_months',
        'work_location',
        'work_schedule',
        'weekly_hours',
        'probation_period',
        'status',
        'termination_reason',
        'termination_date',
        'notes',
        'contract_template',
        'approved_at',
        'approved_by',
        'rejection_reason',
        'created_by',
        'updated_by'
    ];

    protected $casts = [
        'start_date' => 'date',
        'end_date' => 'date',
        'termination_date' => 'date',
        'approved_at' => 'datetime',
        'gross_salary' => 'decimal:2',
        'net_salary' => 'decimal:2'
    ];

    // Relations
    public function employee()
    {
        return $this->belongsTo(Employee::class);
    }

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function updater()
    {
        return $this->belongsTo(User::class, 'updated_by');
    }

    public function approver()
    {
        return $this->belongsTo(User::class, 'approved_by');
    }

    public function clauses()
    {
        return $this->hasMany(ContractClause::class);
    }

    public function attachments()
    {
        return $this->hasMany(ContractAttachment::class);
    }

    public function amendments()
    {
        return $this->hasMany(ContractAmendment::class);
    }

    // Scopes
    public function scopeDraft($query)
    {
        return $query->where('status', 'draft');
    }

    public function scopePending($query)
    {
        return $query->where('status', 'pending');
    }

    public function scopeActive($query)
    {
        return $query->where('status', 'active');
    }

    public function scopeExpired($query)
    {
        return $query->where('status', 'expired');
    }

    public function scopeTerminated($query)
    {
        return $query->where('status', 'terminated');
    }

    public function scopeCancelled($query)
    {
        return $query->where('status', 'cancelled');
    }

    public function scopeByType($query, $contractType)
    {
        return $query->where('contract_type', $contractType);
    }

    public function scopeByDepartment($query, $department)
    {
        return $query->where('department', $department);
    }

    public function scopeByEmployee($query, $employeeId)
    {
        return $query->where('employee_id', $employeeId);
    }

    public function scopeExpiringSoon($query, $days = 30)
    {
        $endDate = now()->addDays($days);
        return $query->where('end_date', '<=', $endDate)
                    ->where('end_date', '>', now())
                    ->where('status', 'active');
    }

    public function scopeExpiredContracts($query)
    {
        return $query->where('end_date', '<', now())
                    ->where('status', 'active');
    }

    public function scopeByDateRange($query, $startDate, $endDate)
    {
        return $query->whereBetween('start_date', [$startDate, $endDate]);
    }

    // Accesseurs
    public function getStatusLibelleAttribute()
    {
        $statuses = [
            'draft' => 'Brouillon',
            'pending' => 'En attente',
            'active' => 'Actif',
            'expired' => 'Expiré',
            'terminated' => 'Résilié',
            'cancelled' => 'Annulé'
        ];

        return $statuses[$this->status] ?? $this->status;
    }

    public function getContractTypeLibelleAttribute()
    {
        $types = [
            'permanent' => 'CDI',
            'fixed_term' => 'CDD',
            'temporary' => 'Intérim',
            'internship' => 'Stage',
            'consultant' => 'Consultant'
        ];

        return $types[$this->contract_type] ?? $this->contract_type;
    }

    public function getPaymentFrequencyLibelleAttribute()
    {
        $frequencies = [
            'monthly' => 'Mensuel',
            'weekly' => 'Hebdomadaire',
            'daily' => 'Journalier',
            'hourly' => 'Horaire'
        ];

        return $frequencies[$this->payment_frequency] ?? $this->payment_frequency;
    }

    public function getWorkScheduleLibelleAttribute()
    {
        $schedules = [
            'full_time' => 'Temps plein',
            'part_time' => 'Temps partiel',
            'flexible' => 'Flexible'
        ];

        return $schedules[$this->work_schedule] ?? $this->work_schedule;
    }

    public function getProbationPeriodLibelleAttribute()
    {
        $periods = [
            'none' => 'Aucune',
            '1_month' => '1 mois',
            '3_months' => '3 mois',
            '6_months' => '6 mois'
        ];

        return $periods[$this->probation_period] ?? $this->probation_period;
    }

    public function getCreatorNameAttribute()
    {
        return $this->creator ? $this->creator->prenom . ' ' . $this->creator->nom : 'N/A';
    }

    public function getUpdaterNameAttribute()
    {
        return $this->updater ? $this->updater->prenom . ' ' . $this->updater->nom : 'N/A';
    }

    public function getApproverNameAttribute()
    {
        return $this->approver ? $this->approver->prenom . ' ' . $this->approver->nom : 'N/A';
    }

    public function getFormattedGrossSalaryAttribute()
    {
        return number_format($this->gross_salary, 0, ',', ' ') . ' ' . $this->salary_currency;
    }

    public function getFormattedNetSalaryAttribute()
    {
        return number_format($this->net_salary, 0, ',', ' ') . ' ' . $this->salary_currency;
    }

    public function getIsDraftAttribute()
    {
        return $this->status === 'draft';
    }

    public function getIsPendingAttribute()
    {
        return $this->status === 'pending';
    }

    public function getIsActiveAttribute()
    {
        return $this->status === 'active';
    }

    public function getIsExpiredAttribute()
    {
        return $this->status === 'expired';
    }

    public function getIsTerminatedAttribute()
    {
        return $this->status === 'terminated';
    }

    public function getIsCancelledAttribute()
    {
        return $this->status === 'cancelled';
    }

    public function getCanEditAttribute()
    {
        return $this->is_draft;
    }

    public function getCanSubmitAttribute()
    {
        return $this->is_draft;
    }

    public function getCanApproveAttribute()
    {
        return $this->is_pending;
    }

    public function getCanRejectAttribute()
    {
        return $this->is_pending;
    }

    public function getCanTerminateAttribute()
    {
        return $this->is_active;
    }

    public function getCanCancelAttribute()
    {
        return $this->is_draft || $this->is_pending;
    }

    public function getIsExpiringSoonAttribute()
    {
        if (!$this->end_date) return false;
        $daysUntilExpiry = $this->end_date->diffInDays(now());
        return $daysUntilExpiry <= 30 && $daysUntilExpiry > 0;
    }

    public function getHasExpiredAttribute()
    {
        if (!$this->end_date) return false;
        return $this->end_date < now();
    }

    public function getDurationInMonthsAttribute()
    {
        if (!$this->end_date) return null;
        return $this->start_date->diffInMonths($this->end_date);
    }

    public function getRemainingDaysAttribute()
    {
        if (!$this->end_date) return null;
        return $this->end_date->diffInDays(now());
    }

    // Méthodes utilitaires
    public function submit()
    {
        $this->update(['status' => 'pending']);
    }

    public function approve($approvedBy)
    {
        $this->update([
            'status' => 'active',
            'approved_at' => now(),
            'approved_by' => $approvedBy
        ]);
    }

    public function reject($rejectedBy, $reason)
    {
        $this->update([
            'status' => 'cancelled',
            'rejection_reason' => $reason,
            'approved_by' => $rejectedBy
        ]);
    }

    public function terminate($terminatedBy, $reason, $terminationDate = null)
    {
        $this->update([
            'status' => 'terminated',
            'termination_reason' => $reason,
            'termination_date' => $terminationDate ?? now(),
            'updated_by' => $terminatedBy
        ]);
    }

    public function cancel($cancelledBy, $reason = null)
    {
        $this->update([
            'status' => 'cancelled',
            'rejection_reason' => $reason,
            'updated_by' => $cancelledBy
        ]);
    }

    public function expire()
    {
        $this->update(['status' => 'expired']);
    }

    public function updateSalary($newGrossSalary, $newNetSalary, $updatedBy = null)
    {
        $this->update([
            'gross_salary' => $newGrossSalary,
            'net_salary' => $newNetSalary,
            'updated_by' => $updatedBy
        ]);
    }

    public function extendContract($newEndDate, $updatedBy = null)
    {
        $this->update([
            'end_date' => $newEndDate,
            'updated_by' => $updatedBy
        ]);
    }

    // Méthodes statiques
    public static function getContractStats()
    {
        $contracts = self::all();
        
        return [
            'total_contracts' => $contracts->count(),
            'draft_contracts' => $contracts->where('status', 'draft')->count(),
            'pending_contracts' => $contracts->where('status', 'pending')->count(),
            'active_contracts' => $contracts->where('status', 'active')->count(),
            'expired_contracts' => $contracts->where('status', 'expired')->count(),
            'terminated_contracts' => $contracts->where('status', 'terminated')->count(),
            'contracts_expiring_soon' => $contracts->filter(function ($contract) {
                return $contract->is_expiring_soon;
            })->count(),
            'average_salary' => $contracts->where('status', 'active')->avg('gross_salary') ?? 0,
            'contracts_by_type' => $contracts->groupBy('contract_type')->map->count(),
            'contracts_by_department' => $contracts->groupBy('department')->map->count(),
            'recent_contracts' => $contracts->sortByDesc('created_at')->take(10)->values()
        ];
    }

    public static function getContractsByEmployee($employeeId)
    {
        return self::byEmployee($employeeId)
            ->with(['creator', 'approver', 'clauses', 'attachments', 'amendments'])
            ->orderBy('start_date', 'desc')
            ->get();
    }

    public static function getContractsByDepartment($department)
    {
        return self::byDepartment($department)
            ->with(['employee', 'creator', 'approver'])
            ->orderBy('start_date', 'desc')
            ->get();
    }

    public static function getContractsByType($contractType)
    {
        return self::byType($contractType)
            ->with(['employee', 'creator', 'approver'])
            ->orderBy('start_date', 'desc')
            ->get();
    }

    public static function getExpiringContracts()
    {
        return self::expiringSoon()->with(['employee', 'creator', 'approver'])->get();
    }

    public static function getExpiredContracts()
    {
        return self::expired()->with(['employee', 'creator', 'approver'])->get();
    }

    public static function getActiveContracts()
    {
        return self::active()->with(['employee', 'creator', 'approver'])->get();
    }

    public static function getPendingContracts()
    {
        return self::pending()->with(['employee', 'creator'])->get();
    }

    public static function getDraftContracts()
    {
        return self::draft()->with(['employee', 'creator'])->get();
    }
}

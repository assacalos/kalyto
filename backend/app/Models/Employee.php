<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class Employee extends Model
{
    use HasFactory;

    protected $fillable = [
        'first_name',
        'last_name',
        'email',
        'phone',
        'address',
        'birth_date',
        'gender',
        'marital_status',
        'nationality',
        'id_number',
        'social_security_number',
        'position',
        'department',
        'manager',
        'hire_date',
        'contract_start_date',
        'contract_end_date',
        'contract_type',
        'salary',
        'currency',
        'work_schedule',
        'status',
        'profile_picture',
        'notes',
        'created_by',
        'updated_by'
    ];

    protected $casts = [
        'birth_date' => 'date',
        'hire_date' => 'date',
        'contract_start_date' => 'date',
        'contract_end_date' => 'date',
        'salary' => 'decimal:2'
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

    public function documents()
    {
        return $this->hasMany(EmployeeDocument::class);
    }

    public function leaves()
    {
        return $this->hasMany(EmployeeLeave::class);
    }

    public function performances()
    {
        return $this->hasMany(EmployeePerformance::class);
    }

    public function salaries()
    {
        return $this->hasMany(Salary::class);
    }

    // Scopes
    public function scopeActive($query)
    {
        return $query->where('status', 'active');
    }

    public function scopeInactive($query)
    {
        return $query->where('status', 'inactive');
    }

    public function scopeTerminated($query)
    {
        return $query->where('status', 'terminated');
    }

    public function scopeOnLeave($query)
    {
        return $query->where('status', 'on_leave');
    }

    public function scopeByDepartment($query, $department)
    {
        return $query->where('department', $department);
    }

    public function scopeByPosition($query, $position)
    {
        return $query->where('position', $position);
    }

    public function scopeByGender($query, $gender)
    {
        return $query->where('gender', $gender);
    }

    public function scopeByContractType($query, $contractType)
    {
        return $query->where('contract_type', $contractType);
    }

    public function scopeHiredAfter($query, $date)
    {
        return $query->where('hire_date', '>=', $date);
    }

    public function scopeHiredBefore($query, $date)
    {
        return $query->where('hire_date', '<=', $date);
    }

    public function scopeContractExpiring($query, $days = 30)
    {
        $expiryDate = now()->addDays($days);
        return $query->where('contract_end_date', '<=', $expiryDate)
                    ->where('contract_end_date', '>', now());
    }

    public function scopeContractExpired($query)
    {
        return $query->where('contract_end_date', '<', now());
    }

    // Accesseurs
    public function getFullNameAttribute()
    {
        return $this->first_name . ' ' . $this->last_name;
    }

    public function getInitialsAttribute()
    {
        return strtoupper(substr($this->first_name, 0, 1) . substr($this->last_name, 0, 1));
    }

    public function getAgeAttribute()
    {
        if (!$this->birth_date) return null;
        return $this->birth_date->age;
    }

    public function getStatusLibelleAttribute()
    {
        $statuses = [
            'active' => 'Actif',
            'inactive' => 'Inactif',
            'terminated' => 'Terminé',
            'on_leave' => 'En congé'
        ];

        return $statuses[$this->status] ?? $this->status;
    }

    public function getGenderLibelleAttribute()
    {
        $genders = [
            'male' => 'Masculin',
            'female' => 'Féminin',
            'other' => 'Autre'
        ];

        return $genders[$this->gender] ?? $this->gender;
    }

    public function getMaritalStatusLibelleAttribute()
    {
        $statuses = [
            'single' => 'Célibataire',
            'married' => 'Marié(e)',
            'divorced' => 'Divorcé(e)',
            'widowed' => 'Veuf/Veuve'
        ];

        return $statuses[$this->marital_status] ?? $this->marital_status;
    }

    public function getContractTypeLibelleAttribute()
    {
        $types = [
            'permanent' => 'Permanent',
            'temporary' => 'Temporaire',
            'internship' => 'Stagiaire',
            'intern' => 'Stagiaire', // Support pour compatibilité
            'consultant' => 'Consultant'
        ];

        return $types[$this->contract_type] ?? $this->contract_type;
    }

    public function getCreatorNameAttribute()
    {
        return $this->creator ? $this->creator->prenom . ' ' . $this->creator->nom : 'N/A';
    }

    public function getUpdaterNameAttribute()
    {
        return $this->updater ? $this->updater->prenom . ' ' . $this->updater->nom : 'N/A';
    }

    public function getFormattedSalaryAttribute()
    {
        if (!$this->salary) return 'Non défini';
        return number_format($this->salary, 0, ',', ' ') . ' ' . $this->currency;
    }

    public function getIsContractExpiringAttribute()
    {
        if (!$this->contract_end_date) return false;
        $daysUntilExpiry = $this->contract_end_date->diffInDays(now());
        return $daysUntilExpiry <= 30 && $daysUntilExpiry >= 0;
    }

    public function getIsContractExpiredAttribute()
    {
        if (!$this->contract_end_date) return false;
        return now()->isAfter($this->contract_end_date);
    }

    public function getIsActiveAttribute()
    {
        return $this->status === 'active';
    }

    public function getIsInactiveAttribute()
    {
        return $this->status === 'inactive';
    }

    public function getIsTerminatedAttribute()
    {
        return $this->status === 'terminated';
    }

    public function getIsOnLeaveAttribute()
    {
        return $this->status === 'on_leave';
    }

    // Méthodes utilitaires
    public function activate()
    {
        $this->update(['status' => 'active']);
    }

    public function deactivate()
    {
        $this->update(['status' => 'inactive']);
    }

    public function terminate($reason = null)
    {
        $this->update([
            'status' => 'terminated',
            'notes' => $reason ? $this->notes . "\n\nRaison de départ: " . $reason : $this->notes
        ]);
    }

    public function putOnLeave()
    {
        $this->update(['status' => 'on_leave']);
    }

    public function updateSalary($newSalary, $updatedBy = null)
    {
        $this->update([
            'salary' => $newSalary,
            'updated_by' => $updatedBy
        ]);
    }

    public function updateContract($startDate, $endDate, $contractType, $updatedBy = null)
    {
        $this->update([
            'contract_start_date' => $startDate,
            'contract_end_date' => $endDate,
            'contract_type' => $contractType,
            'updated_by' => $updatedBy
        ]);
    }

    // Méthodes statiques
    public static function getEmployeeStats()
    {
        $employees = self::all();
        
        return [
            'total_employees' => $employees->count(),
            'active_employees' => $employees->where('status', 'active')->count(),
            'inactive_employees' => $employees->where('status', 'inactive')->count(),
            'on_leave_employees' => $employees->where('status', 'on_leave')->count(),
            'terminated_employees' => $employees->where('status', 'terminated')->count(),
            'new_hires_this_month' => $employees->filter(function ($emp) {
                return $emp->hire_date && $emp->hire_date->isCurrentMonth();
            })->count(),
            'departures_this_month' => $employees->filter(function ($emp) {
                return $emp->status === 'terminated' && $emp->updated_at->isCurrentMonth();
            })->count(),
            'average_salary' => $employees->where('salary', '>', 0)->avg('salary') ?? 0,
            'departments' => $employees->pluck('department')->filter()->unique()->values()->toArray(),
            'positions' => $employees->pluck('position')->filter()->unique()->values()->toArray(),
            'expiring_contracts' => $employees->filter(function ($emp) {
                return $emp->is_contract_expiring;
            })->count(),
            'expired_contracts' => $employees->filter(function ($emp) {
                return $emp->is_contract_expired;
            })->count(),
            'employees_by_status' => $employees->groupBy('status')->map->count(),
            'employees_by_department' => $employees->groupBy('department')->map->count(),
            'employees_by_position' => $employees->groupBy('position')->map->count(),
            'employees_by_gender' => $employees->groupBy('gender')->map->count(),
            'employees_by_contract_type' => $employees->groupBy('contract_type')->map->count()
        ];
    }

    public static function getEmployeesByDepartment($department)
    {
        return self::byDepartment($department)->with(['creator', 'updater'])->get();
    }

    public static function getEmployeesByPosition($position)
    {
        return self::byPosition($position)->with(['creator', 'updater'])->get();
    }

    public static function getContractExpiringEmployees()
    {
        return self::contractExpiring()->with(['creator', 'updater'])->get();
    }

    public static function getContractExpiredEmployees()
    {
        return self::contractExpired()->with(['creator', 'updater'])->get();
    }

    public static function getNewHires($startDate, $endDate)
    {
        return self::hiredAfter($startDate)->hiredBefore($endDate)->with(['creator', 'updater'])->get();
    }

    public static function getDepartures($startDate, $endDate)
    {
        return self::terminated()
            ->whereBetween('updated_at', [$startDate, $endDate])
            ->with(['creator', 'updater'])
            ->get();
    }
}

<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ExpenseBudget extends Model
{
    use HasFactory;

    protected $fillable = [
        'expense_category_id',
        'employee_id',
        'period',
        'period_start',
        'period_end',
        'budget_amount',
        'spent_amount',
        'remaining_amount',
        'is_active',
        'notes'
    ];

    protected $casts = [
        'period_start' => 'date',
        'period_end' => 'date',
        'budget_amount' => 'decimal:2',
        'spent_amount' => 'decimal:2',
        'remaining_amount' => 'decimal:2',
        'is_active' => 'boolean'
    ];

    // Relations
    public function expenseCategory()
    {
        return $this->belongsTo(ExpenseCategory::class);
    }

    public function employee()
    {
        return $this->belongsTo(User::class, 'employee_id');
    }

    // Scopes
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    public function scopeByPeriod($query, $period)
    {
        return $query->where('period', $period);
    }

    public function scopeByCategory($query, $categoryId)
    {
        return $query->where('expense_category_id', $categoryId);
    }

    public function scopeByEmployee($query, $employeeId)
    {
        return $query->where('employee_id', $employeeId);
    }

    public function scopeGlobal($query)
    {
        return $query->whereNull('employee_id');
    }

    public function scopeOverBudget($query)
    {
        return $query->whereRaw('spent_amount > budget_amount');
    }

    public function scopeNearBudget($query, $threshold = 0.8)
    {
        return $query->whereRaw('spent_amount >= (budget_amount * ?)', [$threshold]);
    }

    // Accesseurs
    public function getCategoryNameAttribute()
    {
        return $this->expenseCategory ? $this->expenseCategory->name : 'N/A';
    }

    public function getEmployeeNameAttribute()
    {
        return $this->employee ? $this->employee->prenom . ' ' . $this->employee->nom : 'Budget Global';
    }

    public function getFormattedBudgetAmountAttribute()
    {
        return number_format($this->budget_amount, 2, ',', ' ') . ' €';
    }

    public function getFormattedSpentAmountAttribute()
    {
        return number_format($this->spent_amount, 2, ',', ' ') . ' €';
    }

    public function getFormattedRemainingAmountAttribute()
    {
        return number_format($this->remaining_amount, 2, ',', ' ') . ' €';
    }

    public function getBudgetUtilizationAttribute()
    {
        if ($this->budget_amount == 0) {
            return 0;
        }
        return ($this->spent_amount / $this->budget_amount) * 100;
    }

    public function getFormattedUtilizationAttribute()
    {
        return number_format($this->budget_utilization, 1) . '%';
    }

    public function getIsOverBudgetAttribute()
    {
        return $this->spent_amount > $this->budget_amount;
    }

    public function getIsNearBudgetAttribute()
    {
        return $this->budget_utilization >= 80;
    }

    public function getStatusAttribute()
    {
        if ($this->is_over_budget) {
            return 'over_budget';
        } elseif ($this->is_near_budget) {
            return 'near_budget';
        } else {
            return 'normal';
        }
    }

    public function getStatusLibelleAttribute()
    {
        $statuses = [
            'over_budget' => 'Dépassé',
            'near_budget' => 'Proche de la limite',
            'normal' => 'Normal'
        ];

        return $statuses[$this->status] ?? $this->status;
    }

    // Méthodes utilitaires
    public function updateSpentAmount()
    {
        $expenses = Expense::where('expense_category_id', $this->expense_category_id)
            ->whereBetween('expense_date', [$this->period_start, $this->period_end])
            ->whereIn('status', ['approved', 'paid']);

        if ($this->employee_id) {
            $expenses->where('employee_id', $this->employee_id);
        }

        $spentAmount = $expenses->sum('amount');
        $remainingAmount = $this->budget_amount - $spentAmount;

        $this->update([
            'spent_amount' => $spentAmount,
            'remaining_amount' => $remainingAmount
        ]);

        return $spentAmount;
    }

    public function canSpend($amount)
    {
        return $this->remaining_amount >= $amount;
    }

    public function getAvailableAmount()
    {
        return max(0, $this->remaining_amount);
    }

    public function activate()
    {
        $this->update(['is_active' => true]);
    }

    public function deactivate()
    {
        $this->update(['is_active' => false]);
    }

    public function isCurrentPeriod()
    {
        $now = now();
        return $now->between($this->period_start, $this->period_end);
    }

    public function isPastPeriod()
    {
        return $this->period_end < now();
    }

    public function isFuturePeriod()
    {
        return $this->period_start > now();
    }

    // Méthodes statiques
    public static function getBudgetForCategory($categoryId, $period, $employeeId = null)
    {
        return self::where('expense_category_id', $categoryId)
            ->where('period', $period)
            ->where('employee_id', $employeeId)
            ->active()
            ->first();
    }

    public static function getBudgetStats($startDate = null, $endDate = null)
    {
        $query = self::active();
        
        if ($startDate && $endDate) {
            $query->whereBetween('period_start', [$startDate, $endDate]);
        }

        $budgets = $query->get();
        
        return [
            'total_budgets' => $budgets->count(),
            'total_budget_amount' => $budgets->sum('budget_amount'),
            'total_spent_amount' => $budgets->sum('spent_amount'),
            'total_remaining_amount' => $budgets->sum('remaining_amount'),
            'over_budget_count' => $budgets->where('is_over_budget', true)->count(),
            'near_budget_count' => $budgets->where('is_near_budget', true)->count(),
            'average_utilization' => $budgets->avg('budget_utilization')
        ];
    }

    public static function getOverBudgetBudgets()
    {
        return self::active()
            ->overBudget()
            ->with(['expenseCategory', 'employee'])
            ->get();
    }

    public static function getNearBudgetBudgets()
    {
        return self::active()
            ->nearBudget()
            ->with(['expenseCategory', 'employee'])
            ->get();
    }

    public static function updateAllSpentAmounts()
    {
        $budgets = self::active()->get();
        $updated = 0;

        foreach ($budgets as $budget) {
            $budget->updateSpentAmount();
            $updated++;
        }

        return $updated;
    }
}
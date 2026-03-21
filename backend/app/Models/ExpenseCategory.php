<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ExpenseCategory extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'code',
        'description',
        'approval_limit',
        'requires_approval',
        'is_active',
        'approval_workflow'
    ];

    protected $casts = [
        'approval_limit' => 'decimal:2',
        'requires_approval' => 'boolean',
        'is_active' => 'boolean',
        'approval_workflow' => 'array'
    ];

    // Relations
    public function expenses()
    {
        return $this->hasMany(Expense::class);
    }

    public function budgets()
    {
        return $this->hasMany(ExpenseBudget::class);
    }

    // Scopes
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    public function scopeRequiresApproval($query)
    {
        return $query->where('requires_approval', true);
    }

    public function scopeAutoApproval($query)
    {
        return $query->where('requires_approval', false);
    }

    // Accesseurs
    public function getFormattedApprovalLimitAttribute()
    {
        return $this->approval_limit ? number_format($this->approval_limit, 2, ',', ' ') . ' €' : 'Aucune limite';
    }

    public function getApprovalWorkflowStepsAttribute()
    {
        return $this->approval_workflow ?? ['manager', 'director', 'ceo'];
    }

    // Méthodes utilitaires
    public function needsApproval($amount)
    {
        if (!$this->requires_approval) {
            return false;
        }

        if ($this->approval_limit && $amount <= $this->approval_limit) {
            return false;
        }

        return true;
    }

    public function getRequiredApprovers($amount)
    {
        if (!$this->needsApproval($amount)) {
            return [];
        }

        $workflow = $this->approval_workflow_steps;
        $approvers = [];

        // Logique pour déterminer les approbateurs selon le montant
        if ($amount <= 50000) {
            $approvers = ['manager'];
        } elseif ($amount <= 200000) {
            $approvers = ['manager', 'director'];
        } else {
            $approvers = ['manager', 'director', 'ceo'];
        }

        return $approvers;
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
    public static function getActiveCategories()
    {
        return self::active()->orderBy('name')->get();
    }

    public static function getCategoriesRequiringApproval()
    {
        return self::active()->requiresApproval()->orderBy('name')->get();
    }

    public static function getAutoApprovalCategories()
    {
        return self::active()->autoApproval()->orderBy('name')->get();
    }
}
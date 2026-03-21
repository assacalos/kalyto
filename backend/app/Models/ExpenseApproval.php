<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ExpenseApproval extends Model
{
    use HasFactory;

    protected $fillable = [
        'expense_id',
        'approver_id',
        'approval_level',
        'status',
        'comments',
        'reviewed_at',
        'approval_order',
        'is_required'
    ];

    protected $casts = [
        'reviewed_at' => 'datetime',
        'is_required' => 'boolean'
    ];

    // Relations
    public function expense()
    {
        return $this->belongsTo(Expense::class);
    }

    public function approver()
    {
        return $this->belongsTo(User::class, 'approver_id');
    }

    // Scopes
    public function scopePending($query)
    {
        return $query->where('status', 'pending');
    }

    public function scopeApproved($query)
    {
        return $query->where('status', 'approved');
    }

    public function scopeRejected($query)
    {
        return $query->where('status', 'rejected');
    }

    public function scopeByLevel($query, $level)
    {
        return $query->where('approval_level', $level);
    }

    public function scopeByApprover($query, $approverId)
    {
        return $query->where('approver_id', $approverId);
    }

    public function scopeRequired($query)
    {
        return $query->where('is_required', true);
    }

    public function scopeByOrder($query)
    {
        return $query->orderBy('approval_order');
    }

    // Accesseurs
    public function getStatusLibelleAttribute()
    {
        $statuses = [
            'pending' => 'En attente',
            'approved' => 'Approuvé',
            'rejected' => 'Rejeté'
        ];

        return $statuses[$this->status] ?? $this->status;
    }

    public function getApprovalLevelLibelleAttribute()
    {
        $levels = [
            'manager' => 'Manager',
            'director' => 'Directeur',
            'ceo' => 'PDG',
            'owner' => 'Propriétaire'
        ];

        return $levels[$this->approval_level] ?? $this->approval_level;
    }

    public function getApproverNameAttribute()
    {
        return $this->approver ? $this->approver->prenom . ' ' . $this->approver->nom : 'N/A';
    }

    public function getDaysSincePendingAttribute()
    {
        if ($this->status !== 'pending') {
            return null;
        }

        return now()->diffInDays($this->created_at);
    }

    public function getIsOverdueAttribute()
    {
        return $this->status === 'pending' && $this->days_since_pending > 3;
    }

    // Méthodes utilitaires
    public function canBeApproved()
    {
        return $this->status === 'pending';
    }

    public function canBeRejected()
    {
        return $this->status === 'pending';
    }

    public function approve($comments = null)
    {
        if ($this->canBeApproved()) {
            $this->update([
                'status' => 'approved',
                'comments' => $comments,
                'reviewed_at' => now()
            ]);

            // Vérifier si toutes les approbations sont terminées
            $this->checkExpenseApprovalStatus();

            return true;
        }
        return false;
    }

    public function reject($comments = null)
    {
        if ($this->canBeRejected()) {
            $this->update([
                'status' => 'rejected',
                'comments' => $comments,
                'reviewed_at' => now()
            ]);

            // Rejeter automatiquement la dépense
            $this->expense->reject($this->approver_id, $comments);

            return true;
        }
        return false;
    }

    public function checkExpenseApprovalStatus()
    {
        $expense = $this->expense;
        
        // Vérifier si toutes les approbations requises sont approuvées
        $requiredApprovals = $expense->approvals()->required()->get();
        $approvedCount = $requiredApprovals->where('status', 'approved')->count();
        
        if ($approvedCount === $requiredApprovals->count()) {
            // Toutes les approbations sont terminées, approuver la dépense
            $expense->approve($this->approver_id, 'Toutes les approbations requises ont été obtenues');
        } else {
            // Mettre en cours d'examen
            $expense->update(['status' => 'under_review']);
        }
    }

    public function isFirstApproval()
    {
        return $this->approval_order === 1;
    }

    public function isLastApproval()
    {
        $maxOrder = $this->expense->approvals()->max('approval_order');
        return $this->approval_order === $maxOrder;
    }

    public function getNextApproval()
    {
        return $this->expense->approvals()
            ->where('approval_order', '>', $this->approval_order)
            ->orderBy('approval_order')
            ->first();
    }

    public function getPreviousApproval()
    {
        return $this->expense->approvals()
            ->where('approval_order', '<', $this->approval_order)
            ->orderBy('approval_order', 'desc')
            ->first();
    }

    // Méthodes statiques
    public static function getPendingApprovalsForUser($userId)
    {
        return self::where('approver_id', $userId)
            ->where('status', 'pending')
            ->with(['expense.employee', 'expense.expenseCategory'])
            ->orderBy('created_at')
            ->get();
    }

    public static function getApprovalStats($startDate = null, $endDate = null)
    {
        $query = self::query();
        
        if ($startDate && $endDate) {
            $query->whereBetween('created_at', [$startDate, $endDate]);
        }

        $approvals = $query->get();
        
        return [
            'total_approvals' => $approvals->count(),
            'pending_approvals' => $approvals->where('status', 'pending')->count(),
            'approved_approvals' => $approvals->where('status', 'approved')->count(),
            'rejected_approvals' => $approvals->where('status', 'rejected')->count(),
            'overdue_approvals' => $approvals->where('is_overdue', true)->count()
        ];
    }

    public static function getOverdueApprovals()
    {
        return self::where('status', 'pending')
            ->where('created_at', '<', now()->subDays(3))
            ->with(['expense.employee', 'approver'])
            ->get();
    }
}
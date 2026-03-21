<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class Expense extends Model
{
    use HasFactory;

    protected $fillable = [
        'company_id',
        'expense_category_id',
        'employee_id',
        'user_id', // Pour compatibilité avec l'ancienne structure
        'comptable_id',
        'expense_number',
        'title',
        'expense_date',
        'submission_date',
        'amount',
        'currency',
        'description',
        'justification',
        'receipt_path',
        'status',
        'rejection_reason',
        'approval_history',
        'approved_at',
        'approved_by',
        'rejected_at',
        'rejected_by',
        'paid_at',
        'paid_by'
    ];

    protected $casts = [
        'expense_date' => 'date',
        'submission_date' => 'date',
        'amount' => 'decimal:2',
        'approval_history' => 'array',
        'approved_at' => 'datetime',
        'rejected_at' => 'datetime',
        'paid_at' => 'datetime'
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

    public function comptable()
    {
        return $this->belongsTo(User::class, 'comptable_id');
    }

    public function approver()
    {
        return $this->belongsTo(User::class, 'approved_by');
    }

    public function rejector()
    {
        return $this->belongsTo(User::class, 'rejected_by');
    }

    public function payer()
    {
        return $this->belongsTo(User::class, 'paid_by');
    }

    public function approvals()
    {
        return $this->hasMany(ExpenseApproval::class);
    }

    // Scopes
    public function scopeDraft($query)
    {
        return $query->where('status', 'draft');
    }

    public function scopeSubmitted($query)
    {
        return $query->where('status', 'submitted');
    }

    public function scopeUnderReview($query)
    {
        return $query->where('status', 'under_review');
    }

    public function scopeApproved($query)
    {
        return $query->where('status', 'approved');
    }

    public function scopeRejected($query)
    {
        return $query->where('status', 'rejected');
    }

    public function scopePaid($query)
    {
        return $query->where('status', 'paid');
    }

    public function scopeByEmployee($query, $employeeId)
    {
        return $query->where('employee_id', $employeeId);
    }

    public function scopeByCategory($query, $categoryId)
    {
        return $query->where('expense_category_id', $categoryId);
    }

    public function scopeByDateRange($query, $startDate, $endDate)
    {
        return $query->whereBetween('expense_date', [$startDate, $endDate]);
    }

    public function scopePendingApproval($query)
    {
        return $query->whereIn('status', ['submitted', 'under_review']);
    }

    // Accesseurs
    public function getStatusLibelleAttribute()
    {
        $statuses = [
            'draft' => 'Brouillon',
            'submitted' => 'Soumise',
            'under_review' => 'En cours d\'examen',
            'approved' => 'Approuvée',
            'rejected' => 'Rejetée',
            'paid' => 'Payée'
        ];

        return $statuses[$this->status] ?? $this->status;
    }

    public function getEmployeeNameAttribute()
    {
        if (!$this->relationLoaded('employee') || !$this->employee) {
            return 'N/A';
        }
        $prenom = trim(str_replace(["\r", "\n"], '', (string) ($this->employee->prenom ?? '')));
        $nom = trim(str_replace(["\r", "\n"], '', (string) ($this->employee->nom ?? '')));
        return trim($prenom . ' ' . $nom) ?: 'N/A';
    }

    public function getCategoryNameAttribute()
    {
        if (!$this->relationLoaded('expenseCategory') || !$this->expenseCategory) {
            return 'N/A';
        }
        return $this->expenseCategory->name ?? 'N/A';
    }

    public function getApproverNameAttribute()
    {
        if (!$this->relationLoaded('approver') || !$this->approver) {
            return 'N/A';
        }
        $prenom = trim(str_replace(["\r", "\n"], '', (string) ($this->approver->prenom ?? '')));
        $nom = trim(str_replace(["\r", "\n"], '', (string) ($this->approver->nom ?? '')));
        return trim($prenom . ' ' . $nom) ?: 'N/A';
    }

    public function getFormattedAmountAttribute()
    {
        return number_format($this->amount, 2, ',', ' ') . ' ' . $this->currency;
    }

    public function getDaysSinceSubmissionAttribute()
    {
        if (!$this->submission_date) {
            return null;
        }

        return now()->diffInDays($this->submission_date);
    }

    public function getIsOverdueAttribute()
    {
        return $this->status === 'submitted' && $this->days_since_submission > 7;
    }

    public function getHasReceiptAttribute()
    {
        if (empty($this->receipt_path)) {
            return false;
        }
        return \Storage::disk('private')->exists($this->receipt_path);
    }

    public function getReceiptUrlAttribute()
    {
        if ($this->has_receipt) {
            return route('api.expenses.receipt.show', ['id' => $this->id]);
        }
        return null;
    }

    // Méthodes utilitaires
    public function canBeEdited()
    {
        return $this->status === 'draft';
    }

    public function canBeSubmitted()
    {
        return $this->status === 'draft';
    }

    public function canBeApproved()
    {
        return in_array($this->status, ['submitted', 'under_review']);
    }

    public function canBeRejected()
    {
        return in_array($this->status, ['submitted', 'under_review']);
    }

    public function canBePaid()
    {
        return $this->status === 'approved';
    }

    public function submit()
    {
        if ($this->canBeSubmitted()) {
            $this->update([
                'status' => 'submitted',
                'submission_date' => now()->toDateString()
            ]);

            // Créer les approbations nécessaires
            $this->createRequiredApprovals();

            return true;
        }
        return false;
    }

    public function approve($approverId, $comments = null)
    {
        if ($this->canBeApproved()) {
            $this->update([
                'status' => 'approved',
                'approved_at' => now(),
                'approved_by' => $approverId
            ]);

            // Mettre à jour l'historique d'approbation
            $this->updateApprovalHistory($approverId, 'approved', $comments);

            return true;
        }
        return false;
    }

    public function reject($rejectorId, $reason)
    {
        if ($this->canBeRejected()) {
            $this->update([
                'status' => 'rejected',
                'rejected_at' => now(),
                'rejected_by' => $rejectorId,
                'rejection_reason' => $reason
            ]);

            // Mettre à jour l'historique d'approbation
            $this->updateApprovalHistory($rejectorId, 'rejected', $reason);

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

    public function createRequiredApprovals()
    {
        if (!$this->expenseCategory) {
            return;
        }

        $requiredApprovers = $this->expenseCategory->getRequiredApprovers($this->amount);
        
        foreach ($requiredApprovers as $index => $level) {
            // Trouver l'utilisateur avec le bon rôle pour ce niveau
            $approver = $this->findApproverForLevel($level);
            
            if ($approver) {
                ExpenseApproval::create([
                    'expense_id' => $this->id,
                    'approver_id' => $approver->id,
                    'approval_level' => $level,
                    'approval_order' => $index + 1,
                    'status' => 'pending'
                ]);
            }
        }
    }

    public function findApproverForLevel($level)
    {
        // Logique pour trouver l'approbateur selon le niveau
        $roleMap = [
            'manager' => 2, // Commercial/Manager
            'director' => 1, // Admin/Directeur
            'ceo' => 1, // Admin/CEO
            'owner' => 1 // Admin/Propriétaire
        ];

        $role = $roleMap[$level] ?? 1;
        
        return User::where('role', $role)->first();
    }

    public function updateApprovalHistory($userId, $action, $comments = null)
    {
        $history = $this->approval_history ?? [];
        $history[] = [
            'user_id' => $userId,
            'action' => $action,
            'comments' => $comments,
            'timestamp' => now()->toIso8601String()
        ];

        $this->update(['approval_history' => $history]);
    }

    public function uploadReceipt($file)
    {
        if ($file && $file->isValid()) {
            // Utiliser storeAs pour éviter de charger tout le fichier en mémoire
            // Générer un nom de fichier unique
            $filename = time() . '_' . uniqid() . '.' . $file->getClientOriginalExtension();
            $path = $file->storeAs('expense_receipts', $filename, 'private');
            $this->update(['receipt_path' => $path]);
            return $path;
        }
        return null;
    }

    public function deleteReceipt()
    {
        if ($this->has_receipt) {
            \Storage::disk('private')->delete($this->receipt_path);
            $this->update(['receipt_path' => null]);
            return true;
        }
        return false;
    }

    /**
     * Supprimer le fichier receipt lors de la suppression du modèle
     */
    protected static function boot()
    {
        parent::boot();

        static::deleting(function ($expense) {
            if ($expense->has_receipt) {
                \Storage::disk('private')->delete($expense->receipt_path);
            }
        });
    }

    // Méthodes statiques
    public static function generateExpenseNumber()
    {
        $count = self::count() + 1;
        return 'EXP-' . date('Y') . '-' . str_pad($count, 4, '0', STR_PAD_LEFT);
    }

    public static function getExpenseStats($startDate = null, $endDate = null)
    {
        $query = self::query();
        
        if ($startDate && $endDate) {
            $query->whereBetween('expense_date', [$startDate, $endDate]);
        }

        $expenses = $query->get();
        
        return [
            'total_expenses' => $expenses->count(),
            'draft_expenses' => $expenses->where('status', 'draft')->count(),
            'submitted_expenses' => $expenses->where('status', 'submitted')->count(),
            'under_review_expenses' => $expenses->where('status', 'under_review')->count(),
            'approved_expenses' => $expenses->where('status', 'approved')->count(),
            'rejected_expenses' => $expenses->where('status', 'rejected')->count(),
            'paid_expenses' => $expenses->where('status', 'paid')->count(),
            'total_amount' => $expenses->sum('amount'),
            'approved_amount' => $expenses->where('status', 'approved')->sum('amount'),
            'paid_amount' => $expenses->where('status', 'paid')->sum('amount'),
            'pending_amount' => $expenses->whereIn('status', ['submitted', 'under_review'])->sum('amount')
        ];
    }

    public static function getOverdueExpenses()
    {
        return self::where('status', 'submitted')
            ->where('submission_date', '<', now()->subDays(7))
            ->with(['employee', 'expenseCategory'])
            ->get();
    }
}
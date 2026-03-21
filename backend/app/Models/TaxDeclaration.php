<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class TaxDeclaration extends Model
{
    use HasFactory;

    protected $fillable = [
        'tax_category_id',
        'comptable_id',
        'declaration_number',
        'period',
        'period_start',
        'period_end',
        'submission_deadline',
        'payment_deadline',
        'total_revenue',
        'taxable_base',
        'tax_due',
        'tax_paid',
        'balance',
        'status',
        'declaration_data',
        'notes',
        'submission_reference',
        'submitted_at',
        'accepted_at'
    ];

    protected $casts = [
        'period_start' => 'date',
        'period_end' => 'date',
        'submission_deadline' => 'date',
        'payment_deadline' => 'date',
        'total_revenue' => 'decimal:2',
        'taxable_base' => 'decimal:2',
        'tax_due' => 'decimal:2',
        'tax_paid' => 'decimal:2',
        'balance' => 'decimal:2',
        'declaration_data' => 'array',
        'submitted_at' => 'datetime',
        'accepted_at' => 'datetime'
    ];

    // Relations
    public function taxCategory()
    {
        return $this->belongsTo(TaxCategory::class);
    }

    public function comptable()
    {
        return $this->belongsTo(User::class, 'comptable_id');
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

    public function scopeAccepted($query)
    {
        return $query->where('status', 'accepted');
    }

    public function scopeRejected($query)
    {
        return $query->where('status', 'rejected');
    }

    public function scopePaid($query)
    {
        return $query->where('status', 'paid');
    }

    public function scopeByPeriod($query, $period)
    {
        return $query->where('period', $period);
    }

    public function scopeByCategory($query, $categoryId)
    {
        return $query->where('tax_category_id', $categoryId);
    }

    public function scopeByComptable($query, $comptableId)
    {
        return $query->where('comptable_id', $comptableId);
    }

    public function scopeDueBefore($query, $date)
    {
        return $query->where('submission_deadline', '<=', $date);
    }

    // Accesseurs
    public function getStatusLibelleAttribute()
    {
        $statuses = [
            'draft' => 'Brouillon',
            'submitted' => 'Soumise',
            'accepted' => 'Acceptée',
            'rejected' => 'Rejetée',
            'paid' => 'Payée'
        ];

        return $statuses[$this->status] ?? $this->status;
    }

    public function getComptableNameAttribute()
    {
        if (!$this->relationLoaded('comptable') || !$this->comptable) {
            return 'N/A';
        }
        return trim(($this->comptable->prenom ?? '') . ' ' . ($this->comptable->nom ?? '')) ?: 'N/A';
    }

    public function getCategoryNameAttribute()
    {
        if (!$this->relationLoaded('taxCategory') || !$this->taxCategory) {
            return 'N/A';
        }
        return $this->taxCategory->name ?? 'N/A';
    }

    public function getDaysUntilSubmissionAttribute()
    {
        if (!$this->submission_deadline || $this->status === 'submitted') {
            return null;
        }

        $deadline = Carbon::parse($this->submission_deadline);
        $now = Carbon::now();
        
        if ($deadline->isPast()) {
            return -$deadline->diffInDays($now);
        }
        
        return $deadline->diffInDays($now);
    }

    public function getDaysUntilPaymentAttribute()
    {
        if (!$this->payment_deadline || $this->status === 'paid') {
            return null;
        }

        $deadline = Carbon::parse($this->payment_deadline);
        $now = Carbon::now();
        
        if ($deadline->isPast()) {
            return -$deadline->diffInDays($now);
        }
        
        return $deadline->diffInDays($now);
    }

    public function getIsSubmissionOverdueAttribute()
    {
        return $this->status === 'draft' && $this->submission_deadline && $this->submission_deadline < now()->toDateString();
    }

    public function getIsPaymentOverdueAttribute()
    {
        return in_array($this->status, ['submitted', 'accepted']) && $this->payment_deadline && $this->payment_deadline < now()->toDateString();
    }

    public function getFormattedBalanceAttribute()
    {
        $amount = number_format(abs($this->balance), 2, ',', ' ') . ' €';
        if ($this->balance > 0) {
            return 'À payer: ' . $amount;
        } elseif ($this->balance < 0) {
            return 'Crédit: ' . $amount;
        }
        return 'Équilibré';
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

    public function canBeAccepted()
    {
        return $this->status === 'submitted';
    }

    public function canBeRejected()
    {
        return $this->status === 'submitted';
    }

    public function canBePaid()
    {
        return $this->status === 'accepted' && $this->balance > 0;
    }

    public function submit($submissionReference = null)
    {
        if ($this->canBeSubmitted()) {
            $this->update([
                'status' => 'submitted',
                'submitted_at' => now(),
                'submission_reference' => $submissionReference ?? $this->generateSubmissionReference()
            ]);
            return true;
        }
        return false;
    }

    public function accept()
    {
        if ($this->canBeAccepted()) {
            $this->update([
                'status' => 'accepted',
                'accepted_at' => now()
            ]);
            return true;
        }
        return false;
    }

    public function reject($reason = null)
    {
        if ($this->canBeRejected()) {
            $this->update([
                'status' => 'rejected',
                'notes' => $reason ?? $this->notes
            ]);
            return true;
        }
        return false;
    }

    public function markAsPaid()
    {
        if ($this->canBePaid()) {
            $this->update([
                'status' => 'paid',
                'tax_paid' => $this->tax_due,
                'balance' => 0
            ]);
            return true;
        }
        return false;
    }

    public function calculateTax()
    {
        if ($this->taxCategory) {
            $taxDue = $this->taxCategory->calculateTax($this->taxable_base);
            $balance = $taxDue - $this->tax_paid;
            
            $this->update([
                'tax_due' => $taxDue,
                'balance' => $balance,
                'declaration_data' => array_merge($this->declaration_data ?? [], [
                    'calculation_date' => now()->toIso8601String(),
                    'tax_rate' => $this->taxCategory->default_rate,
                    'calculation_method' => $this->taxCategory->type
                ])
            ]);
            
            return $taxDue;
        }
        
        return 0;
    }

    public function generateSubmissionReference()
    {
        return 'DECL-' . $this->period . '-' . str_pad($this->id, 6, '0', STR_PAD_LEFT);
    }

    // Méthodes statiques
    public static function generateDeclarationNumber($categoryCode, $period)
    {
        $count = self::whereHas('taxCategory', function ($query) use ($categoryCode) {
            $query->where('code', $categoryCode);
        })->where('period', $period)->count() + 1;
        
        return strtoupper($categoryCode) . '-DECL-' . $period . '-' . str_pad($count, 3, '0', STR_PAD_LEFT);
    }

    public static function getDeclarationsByPeriod($period)
    {
        return self::with(['taxCategory', 'comptable'])
            ->where('period', $period)
            ->orderBy('submission_deadline')
            ->get();
    }

    public static function getDeclarationStats($startDate = null, $endDate = null)
    {
        $query = self::query();
        
        if ($startDate && $endDate) {
            $query->whereBetween('period_start', [$startDate, $endDate]);
        }

        $declarations = $query->get();
        
        return [
            'total_declarations' => $declarations->count(),
            'draft_declarations' => $declarations->where('status', 'draft')->count(),
            'submitted_declarations' => $declarations->where('status', 'submitted')->count(),
            'accepted_declarations' => $declarations->where('status', 'accepted')->count(),
            'rejected_declarations' => $declarations->where('status', 'rejected')->count(),
            'paid_declarations' => $declarations->where('status', 'paid')->count(),
            'total_revenue' => $declarations->sum('total_revenue'),
            'total_tax_due' => $declarations->sum('tax_due'),
            'total_tax_paid' => $declarations->sum('tax_paid'),
            'total_balance' => $declarations->sum('balance')
        ];
    }

    public static function getUpcomingDeadlines($days = 30)
    {
        return self::where('status', 'draft')
            ->whereBetween('submission_deadline', [now()->toDateString(), now()->addDays($days)->toDateString()])
            ->with(['taxCategory', 'comptable'])
            ->orderBy('submission_deadline')
            ->get();
    }
}
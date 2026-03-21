<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class Tax extends Model
{
    use HasFactory;

    protected $fillable = [
        'category',
        'comptable_id',
        'reference',
        'period',
        'period_start',
        'period_end',
        'due_date',
        'base_amount',
        'tax_rate',
        'tax_amount',
        'total_amount',
        'status',
        'description',
        'notes',
        'calculation_details',
        'declared_at',
        'paid_at',
        'validated_by',
        'validated_at',
        'validation_comment',
        'rejected_by',
        'rejected_at',
        'rejection_reason',
        'rejection_comment'
    ];

    protected $casts = [
        'period_start' => 'date',
        'period_end' => 'date',
        'due_date' => 'date',
        'base_amount' => 'decimal:2',
        'tax_rate' => 'decimal:2',
        'tax_amount' => 'decimal:2',
        'total_amount' => 'decimal:2',
        'calculation_details' => 'array',
        'declared_at' => 'datetime',
        'paid_at' => 'datetime',
        'validated_at' => 'datetime',
        'rejected_at' => 'datetime'
    ];

    // Relations
    // Note: category est maintenant un champ string, pas une relation

    public function comptable()
    {
        return $this->belongsTo(User::class, 'comptable_id');
    }

    public function payments()
    {
        return $this->hasMany(TaxPayment::class);
    }

    public function validatedBy()
    {
        return $this->belongsTo(User::class, 'validated_by');
    }

    public function rejectedBy()
    {
        return $this->belongsTo(User::class, 'rejected_by');
    }

    // Scopes
    public function scopeEnAttente($query)
    {
        return $query->where('status', 'en_attente');
    }

    public function scopeValide($query)
    {
        return $query->where('status', 'valide');
    }

    public function scopeRejete($query)
    {
        return $query->where('status', 'rejete');
    }

    public function scopePaye($query)
    {
        return $query->where('status', 'paye');
    }

    public function scopeByPeriod($query, $period)
    {
        return $query->where('period', $period);
    }

    public function scopeByCategory($query, $categoryName)
    {
        return $query->where('category', $categoryName);
    }

    public function scopeByComptable($query, $comptableId)
    {
        return $query->where('comptable_id', $comptableId);
    }

    public function scopeDueBefore($query, $date)
    {
        return $query->where('due_date', '<=', $date);
    }

    // Accesseurs
    public function getStatusLibelleAttribute()
    {
        $statuses = [
            'en_attente' => 'En attente',
            'valide' => 'Validé',
            'rejete' => 'Rejeté',
            'paye' => 'Payé'
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
        return $this->category ?? 'N/A';
    }

    public function getDaysUntilDueAttribute()
    {
        if (!$this->due_date || $this->status === 'paye') {
            return null;
        }

        $dueDate = Carbon::parse($this->due_date);
        $now = Carbon::now();
        
        if ($dueDate->isPast()) {
            return -$dueDate->diffInDays($now);
        }
        
        return $dueDate->diffInDays($now);
    }

    public function getIsOverdueAttribute()
    {
        return $this->status !== 'paye' && $this->due_date && $this->due_date < now()->toDateString();
    }

    public function getTotalPaidAttribute()
    {
        return $this->payments()->where('status', 'validated')->sum('amount_paid');
    }

    public function getRemainingAmountAttribute()
    {
        return $this->total_amount - $this->total_paid;
    }

    // Méthodes utilitaires
    public function canBeEdited()
    {
        // Peut être édité seulement si en attente
        return $this->status === 'en_attente';
    }

    public function canBeValidated()
    {
        return $this->status === 'en_attente';
    }

    public function canBeRejected()
    {
        return $this->status === 'en_attente';
    }

    public function canBePaid()
    {
        // Peut être payée si validée
        return $this->status === 'valide';
    }

    public function markAsPaid()
    {
        if ($this->canBePaid() || $this->remaining_amount <= 0) {
            $this->update([
                'status' => 'paye',
                'paid_at' => now()
            ]);
            return true;
        }
        return false;
    }

    public function validate($comment = null, $userId = null)
    {
        if ($this->canBeValidated()) {
            $this->update([
                'status' => 'valide',
                'validated_by' => $userId ?? auth()->id(),
                'validated_at' => now(),
                'validation_comment' => $comment
            ]);
            return true;
        }
        return false;
    }

    public function reject($reason, $comment, $userId = null)
    {
        if ($this->canBeRejected()) {
            $this->update([
                'status' => 'rejete',
                'rejected_by' => $userId ?? auth()->id(),
                'rejected_at' => now(),
                'rejection_reason' => $reason,
                'rejection_comment' => $comment
            ]);
            return true;
        }
        return false;
    }

    public function calculateTax($baseAmount = null, $taxRate = null)
    {
        $baseAmount = $baseAmount ?? $this->base_amount;
        
        // Si taxRate n'est pas fourni, chercher dans tax_categories par nom
        if (!$taxRate && $this->category) {
            $taxCategory = TaxCategory::where('name', $this->category)->first();
            if ($taxCategory) {
                $taxRate = $taxCategory->default_rate;
                // Utiliser la méthode de calcul de la catégorie si disponible
                if (method_exists($taxCategory, 'calculateTax')) {
                    $taxAmount = $taxCategory->calculateTax($baseAmount);
                } else {
                    $taxAmount = ($baseAmount * $taxRate) / 100;
                }
            } else {
                // Si la catégorie n'existe pas, utiliser tax_rate existant ou 0
                $taxRate = $this->tax_rate ?? 0;
                $taxAmount = ($baseAmount * $taxRate) / 100;
            }
        } else {
            // Utiliser le taxRate fourni ou celui existant
            $taxRate = $taxRate ?? $this->tax_rate ?? 0;
            $taxAmount = ($baseAmount * $taxRate) / 100;
        }
        
        $this->update([
            'base_amount' => $baseAmount,
            'tax_rate' => $taxRate,
            'tax_amount' => $taxAmount,
            'total_amount' => $baseAmount + $taxAmount,
            'calculation_details' => [
                'base_amount' => $baseAmount,
                'tax_rate' => $taxRate,
                'tax_amount' => $taxAmount,
                'calculation_date' => now()->toIso8601String()
            ]
        ]);
        
        return $taxAmount;
    }

    // Méthodes statiques
    public static function generateReference($categoryName, $period)
    {
        // Compter les taxes avec cette catégorie et cette période
        $count = self::where('category', $categoryName)
            ->where('period', $period)
            ->count() + 1;
        
        // Générer un code court depuis le nom (premiers caractères en majuscules)
        $code = strtoupper(substr(str_replace(' ', '', $categoryName), 0, 4));
        
        return $code . '-' . $period . '-' . str_pad($count, 3, '0', STR_PAD_LEFT);
    }

    // Note: Les taxes en retard ne changent plus de statut automatiquement
    // On utilise l'accesseur is_overdue pour identifier les taxes en retard

    public static function getTaxesByPeriod($period)
    {
        return self::with(['comptable', 'payments'])
            ->where('period', $period)
            ->orderBy('due_date')
            ->get();
    }

    public static function getTaxStats($startDate = null, $endDate = null)
    {
        $query = self::query();
        
        if ($startDate && $endDate) {
            $query->whereBetween('period_start', [$startDate, $endDate]);
        }

        $taxes = $query->get();
        
        return [
            'total_taxes' => $taxes->count(),
            'en_attente' => $taxes->where('status', 'en_attente')->count(),
            'valide' => $taxes->where('status', 'valide')->count(),
            'rejete' => $taxes->where('status', 'rejete')->count(),
            'paye' => $taxes->where('status', 'paye')->count(),
            'total_amount' => $taxes->sum('total_amount'),
            'total_paid' => $taxes->sum('total_paid'),
            'remaining_amount' => $taxes->sum('remaining_amount')
        ];
    }
}
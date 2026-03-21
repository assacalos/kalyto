<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class PaymentSchedule extends Model
{
    use HasFactory;

    protected $fillable = [
        'payment_id',
        'start_date',
        'end_date',
        'frequency',
        'total_installments',
        'paid_installments',
        'installment_amount',
        'status',
        'next_payment_date',
        'notes',
        'created_by',
        'updated_by'
    ];

    protected $casts = [
        'start_date' => 'date',
        'end_date' => 'date',
        'next_payment_date' => 'date',
        'installment_amount' => 'decimal:2'
    ];

    // Relations
    public function payment()
    {
        return $this->belongsTo(Paiement::class);
    }

    public function installments()
    {
        return $this->hasMany(PaymentInstallment::class, 'schedule_id');
    }

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function updater()
    {
        return $this->belongsTo(User::class, 'updated_by');
    }

    // Scopes
    public function scopeActive($query)
    {
        return $query->where('status', 'active');
    }

    public function scopePaused($query)
    {
        return $query->where('status', 'paused');
    }

    public function scopeCompleted($query)
    {
        return $query->where('status', 'completed');
    }

    public function scopeCancelled($query)
    {
        return $query->where('status', 'cancelled');
    }

    public function scopeDueSoon($query, $days = 7)
    {
        return $query->where('next_payment_date', '<=', Carbon::now()->addDays($days))
                    ->where('status', 'active');
    }

    // Accesseurs
    public function getStatusLibelleAttribute()
    {
        $statuses = [
            'active' => 'Actif',
            'paused' => 'En pause',
            'completed' => 'Terminé',
            'cancelled' => 'Annulé'
        ];

        return $statuses[$this->status] ?? $this->status;
    }

    public function getProgressPercentageAttribute()
    {
        if ($this->total_installments == 0) return 0;
        return round(($this->paid_installments / $this->total_installments) * 100, 2);
    }

    public function getRemainingInstallmentsAttribute()
    {
        return $this->total_installments - $this->paid_installments;
    }

    public function getTotalAmountAttribute()
    {
        return $this->total_installments * $this->installment_amount;
    }

    public function getPaidAmountAttribute()
    {
        return $this->paid_installments * $this->installment_amount;
    }

    public function getRemainingAmountAttribute()
    {
        return $this->total_amount - $this->paid_amount;
    }

    // Méthodes utilitaires
    public function canBePaused()
    {
        return $this->status === 'active';
    }

    public function canBeResumed()
    {
        return $this->status === 'paused';
    }

    public function canBeCancelled()
    {
        return in_array($this->status, ['active', 'paused']);
    }

    public function pause()
    {
        if ($this->canBePaused()) {
            $this->update(['status' => 'paused']);
            return true;
        }
        return false;
    }

    public function resume()
    {
        if ($this->canBeResumed()) {
            $this->update(['status' => 'active']);
            return true;
        }
        return false;
    }

    public function cancel()
    {
        if ($this->canBeCancelled()) {
            $this->update(['status' => 'cancelled']);
            return true;
        }
        return false;
    }

    public function complete()
    {
        if ($this->status === 'active' && $this->paid_installments >= $this->total_installments) {
            $this->update(['status' => 'completed']);
            return true;
        }
        return false;
    }

    public function generateInstallments()
    {
        $installments = [];
        $currentDate = Carbon::parse($this->start_date);
        
        for ($i = 1; $i <= $this->total_installments; $i++) {
            $installments[] = [
                'schedule_id' => $this->id,
                'installment_number' => $i,
                'due_date' => $currentDate->copy(),
                'amount' => $this->installment_amount,
                'status' => 'pending',
                'created_at' => now(),
                'updated_at' => now()
            ];
            
            $currentDate->addDays($this->frequency);
        }
        
        PaymentInstallment::insert($installments);
        
        // Mettre à jour la prochaine date de paiement
        $this->update(['next_payment_date' => $this->start_date]);
    }
}
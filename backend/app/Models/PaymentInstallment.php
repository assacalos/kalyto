<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class PaymentInstallment extends Model
{
    use HasFactory;

    protected $fillable = [
        'schedule_id',
        'installment_number',
        'due_date',
        'amount',
        'status',
        'paid_date',
        'notes',
        'paid_by'
    ];

    protected $casts = [
        'due_date' => 'date',
        'paid_date' => 'date',
        'amount' => 'decimal:2'
    ];

    // Relations
    public function schedule()
    {
        return $this->belongsTo(PaymentSchedule::class, 'schedule_id');
    }

    public function payer()
    {
        return $this->belongsTo(User::class, 'paid_by');
    }

    // Scopes
    public function scopePending($query)
    {
        return $query->where('status', 'pending');
    }

    public function scopePaid($query)
    {
        return $query->where('status', 'paid');
    }

    public function scopeOverdue($query)
    {
        return $query->where('status', 'overdue');
    }

    public function scopeDueToday($query)
    {
        return $query->where('due_date', Carbon::today())
                    ->where('status', 'pending');
    }

    public function scopeDueSoon($query, $days = 7)
    {
        return $query->where('due_date', '<=', Carbon::now()->addDays($days))
                    ->where('status', 'pending');
    }

    public function scopeOverdue($query)
    {
        return $query->where('due_date', '<', Carbon::today())
                    ->where('status', 'pending');
    }

    // Accesseurs
    public function getStatusLibelleAttribute()
    {
        $statuses = [
            'pending' => 'En attente',
            'paid' => 'Payé',
            'overdue' => 'En retard'
        ];

        return $statuses[$this->status] ?? $this->status;
    }

    public function getIsOverdueAttribute()
    {
        return $this->due_date < Carbon::today() && $this->status === 'pending';
    }

    public function getDaysOverdueAttribute()
    {
        if (!$this->is_overdue) return 0;
        return Carbon::today()->diffInDays($this->due_date);
    }

    public function getFormattedAmountAttribute()
    {
        return number_format($this->amount, 2, ',', ' ') . ' FCFA';
    }

    // Méthodes utilitaires
    public function canBePaid()
    {
        return $this->status === 'pending';
    }

    public function markAsPaid($payerId = null, $notes = null)
    {
        if ($this->canBePaid()) {
            $this->update([
                'status' => 'paid',
                'paid_date' => Carbon::today(),
                'paid_by' => $payerId,
                'notes' => $notes
            ]);

            // Mettre à jour le schedule
            $this->schedule->increment('paid_installments');
            
            // Mettre à jour la prochaine date de paiement
            $nextInstallment = $this->schedule->installments()
                ->where('status', 'pending')
                ->orderBy('due_date')
                ->first();
                
            if ($nextInstallment) {
                $this->schedule->update(['next_payment_date' => $nextInstallment->due_date]);
            } else {
                // Toutes les échéances sont payées
                $this->schedule->complete();
            }

            return true;
        }
        return false;
    }

    public function markAsOverdue()
    {
        if ($this->status === 'pending' && $this->due_date < Carbon::today()) {
            $this->update(['status' => 'overdue']);
            return true;
        }
        return false;
    }

    // Méthode statique pour marquer les échéances en retard
    public static function markOverdueInstallments()
    {
        return self::where('due_date', '<', Carbon::today())
                  ->where('status', 'pending')
                  ->update(['status' => 'overdue']);
    }
}
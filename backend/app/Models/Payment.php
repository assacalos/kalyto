<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class Payment extends Model
{
    use HasFactory;

    protected $fillable = [
        'payment_number',
        'type',
        'client_id',
        'comptable_id',
        'payment_date',
        'due_date',
        'status',
        'amount',
        'currency',
        'payment_method',
        'description',
        'notes',
        'reference',
        'payment_schedule_id',
        'submitted_at',
        'approved_at',
        'paid_at'
    ];

    protected $casts = [
        'payment_date' => 'date',
        'due_date' => 'date',
        'amount' => 'decimal:2',
        'submitted_at' => 'datetime',
        'approved_at' => 'datetime',
        'paid_at' => 'datetime'
    ];

    // Relations
    public function client()
    {
        return $this->belongsTo(Client::class);
    }

    public function comptable()
    {
        return $this->belongsTo(User::class, 'comptable_id');
    }

    public function paymentSchedule()
    {
        return $this->belongsTo(PaymentSchedule::class);
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

    public function scopeApproved($query)
    {
        return $query->where('status', 'approved');
    }

    public function scopePaid($query)
    {
        return $query->where('status', 'paid');
    }

    public function scopeOverdue($query)
    {
        return $query->where('status', 'overdue');
    }

    public function scopeRejected($query)
    {
        return $query->where('status', 'rejected');
    }

    public function scopeOneTime($query)
    {
        return $query->where('type', 'one_time');
    }

    public function scopeMonthly($query)
    {
        return $query->where('type', 'monthly');
    }

    public function scopeByClient($query, $clientId)
    {
        return $query->where('client_id', $clientId);
    }

    public function scopeByComptable($query, $comptableId)
    {
        return $query->where('comptable_id', $comptableId);
    }

    public function scopeByDateRange($query, $startDate, $endDate)
    {
        return $query->whereBetween('payment_date', [$startDate, $endDate]);
    }

    // Méthodes utilitaires
    public function isOverdue()
    {
        return $this->status !== 'paid' && $this->status !== 'rejected' && 
               $this->due_date && $this->due_date < now()->toDateString();
    }

    public function canBeEdited()
    {
        return in_array($this->status, ['draft']);
    }

    public function canBeSubmitted()
    {
        return in_array($this->status, ['draft']);
    }

    public function canBeApproved()
    {
        return in_array($this->status, ['submitted']);
    }

    public function canBeRejected()
    {
        return in_array($this->status, ['submitted']);
    }

    public function canBePaid()
    {
        return in_array($this->status, ['approved']);
    }

    public function markAsSubmitted()
    {
        if ($this->canBeSubmitted()) {
            $this->update([
                'status' => 'submitted',
                'submitted_at' => now()
            ]);
            return true;
        }
        return false;
    }

    public function markAsApproved()
    {
        if ($this->canBeApproved()) {
            $this->update([
                'status' => 'approved',
                'approved_at' => now()
            ]);
            return true;
        }
        return false;
    }

    public function markAsRejected()
    {
        if ($this->canBeRejected()) {
            $this->update(['status' => 'rejected']);
            return true;
        }
        return false;
    }

    public function markAsPaid()
    {
        if ($this->canBePaid()) {
            $this->update([
                'status' => 'paid',
                'paid_at' => now()
            ]);
            return true;
        }
        return false;
    }

    // Accesseurs
    public function getClientNameAttribute()
    {
        return $this->client ? $this->client->nom : 'Client inconnu';
    }

    public function getClientEmailAttribute()
    {
        return $this->client ? $this->client->email : null;
    }

    public function getClientAddressAttribute()
    {
        return $this->client ? $this->client->adresse : null;
    }

    public function getComptableNameAttribute()
    {
        return $this->comptable ? $this->comptable->nom . ' ' . $this->comptable->prenom : 'Comptable inconnu';
    }

    public function getStatusLibelleAttribute()
    {
        $statuses = [
            'draft' => 'Brouillon',
            'submitted' => 'Soumis',
            'approved' => 'Approuvé',
            'rejected' => 'Rejeté',
            'paid' => 'Payé',
            'overdue' => 'En retard'
        ];

        return $statuses[$this->status] ?? $this->status;
    }

    public function getPaymentMethodLibelleAttribute()
    {
        $methods = [
            'bank_transfer' => 'Virement bancaire',
            'check' => 'Chèque',
            'cash' => 'Espèces',
            'card' => 'Carte bancaire',
            'direct_debit' => 'Prélèvement automatique'
        ];

        return $methods[$this->payment_method] ?? $this->payment_method;
    }

    public function getDaysUntilDueAttribute()
    {
        if (!$this->due_date || $this->status === 'paid' || $this->status === 'rejected') {
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
        return $this->isOverdue();
    }

    // Méthodes statiques pour les statistiques
    public static function getPaymentStats($startDate = null, $endDate = null)
    {
        $query = self::query();
        
        if ($startDate && $endDate) {
            $query->whereBetween('payment_date', [$startDate, $endDate]);
        }

        $payments = $query->get();
        
        $totalPayments = $payments->count();
        $oneTimePayments = $payments->where('type', 'one_time')->count();
        $monthlyPayments = $payments->where('type', 'monthly')->count();
        $pendingPayments = $payments->whereIn('status', ['draft', 'submitted'])->count();
        $approvedPayments = $payments->where('status', 'approved')->count();
        $paidPayments = $payments->where('status', 'paid')->count();
        $overduePayments = $payments->where('status', 'overdue')->count();
        
        $totalAmount = $payments->sum('amount');
        $pendingAmount = $payments->whereIn('status', ['draft', 'submitted', 'approved'])->sum('amount');
        $paidAmount = $payments->where('status', 'paid')->sum('amount');
        $overdueAmount = $payments->where('status', 'overdue')->sum('amount');

        return [
            'total_payments' => $totalPayments,
            'one_time_payments' => $oneTimePayments,
            'monthly_payments' => $monthlyPayments,
            'pending_payments' => $pendingPayments,
            'approved_payments' => $approvedPayments,
            'paid_payments' => $paidPayments,
            'overdue_payments' => $overduePayments,
            'total_amount' => $totalAmount,
            'pending_amount' => $pendingAmount,
            'paid_amount' => $paidAmount,
            'overdue_amount' => $overdueAmount
        ];
    }

    public static function getMonthlyStats($year = null)
    {
        $year = $year ?? now()->year;
        
        $stats = [];
        for ($month = 1; $month <= 12; $month++) {
            $startDate = Carbon::create($year, $month, 1)->startOfMonth();
            $endDate = Carbon::create($year, $month, 1)->endOfMonth();
            
            $monthStats = self::getPaymentStats($startDate, $endDate);
            $stats[$month] = $monthStats['total_amount'];
        }
        
        return $stats;
    }

    public static function getPaymentMethodStats($startDate = null, $endDate = null)
    {
        $query = self::query();
        
        if ($startDate && $endDate) {
            $query->whereBetween('payment_date', [$startDate, $endDate]);
        }

        return $query->selectRaw('payment_method, COUNT(*) as count')
            ->groupBy('payment_method')
            ->pluck('count', 'payment_method')
            ->toArray();
    }

    // Méthode pour générer le numéro de paiement
    public static function generatePaymentNumber()
    {
        $year = date('Y');
        $count = self::whereYear('created_at', $year)->count() + 1;
        return 'PAY-' . $year . '-' . str_pad($count, 4, '0', STR_PAD_LEFT);
    }

    // Méthode pour mettre à jour les paiements en retard
    public static function updateOverduePayments()
    {
        return self::whereIn('status', ['submitted', 'approved'])
            ->where('due_date', '<', now()->toDateString())
            ->update(['status' => 'overdue']);
    }
}
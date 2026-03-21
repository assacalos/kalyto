<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class Invoice extends Model
{
    use HasFactory;

    protected $fillable = [
        'invoice_number',
        'client_id',
        'commercial_id',
        'invoice_date',
        'due_date',
        'status',
        'subtotal',
        'tax_rate',
        'tax_amount',
        'total_amount',
        'currency',
        'notes',
        'terms',
        'payment_info',
        'sent_at',
        'paid_at'
    ];

    protected $casts = [
        'invoice_date' => 'date',
        'due_date' => 'date',
        'subtotal' => 'decimal:2',
        'tax_rate' => 'decimal:2',
        'tax_amount' => 'decimal:2',
        'total_amount' => 'decimal:2',
        'payment_info' => 'array',
        'sent_at' => 'datetime',
        'paid_at' => 'datetime'
    ];

    // Relations
    public function client()
    {
        return $this->belongsTo(Client::class);
    }

    public function commercial()
    {
        return $this->belongsTo(User::class, 'commercial_id');
    }

    public function items()
    {
        return $this->hasMany(InvoiceItem::class);
    }

    // Scopes
    public function scopeDraft($query)
    {
        return $query->where('status', 'draft');
    }

    public function scopeSent($query)
    {
        return $query->where('status', 'sent');
    }

    public function scopePaid($query)
    {
        return $query->where('status', 'paid');
    }

    public function scopeOverdue($query)
    {
        return $query->where('status', 'overdue');
    }

    public function scopeCancelled($query)
    {
        return $query->where('status', 'cancelled');
    }

    public function scopeByClient($query, $clientId)
    {
        return $query->where('client_id', $clientId);
    }

    public function scopeByCommercial($query, $commercialId)
    {
        return $query->where('commercial_id', $commercialId);
    }

    public function scopeByDateRange($query, $startDate, $endDate)
    {
        return $query->whereBetween('invoice_date', [$startDate, $endDate]);
    }

    // Méthodes utilitaires
    public function isOverdue()
    {
        return $this->status !== 'paid' && $this->status !== 'cancelled' && 
               $this->due_date < now()->toDateString();
    }

    public function canBeEdited()
    {
        return in_array($this->status, ['draft']);
    }

    public function canBeSent()
    {
        return in_array($this->status, ['draft']);
    }

    public function canBePaid()
    {
        return in_array($this->status, ['sent', 'overdue']);
    }

    public function canBeCancelled()
    {
        return in_array($this->status, ['draft', 'sent']);
    }

    public function markAsSent()
    {
        if ($this->canBeSent()) {
            $this->update([
                'status' => 'sent',
                'sent_at' => now()
            ]);
            return true;
        }
        return false;
    }

    public function markAsPaid($paymentInfo = null)
    {
        if ($this->canBePaid()) {
            $this->update([
                'status' => 'paid',
                'paid_at' => now(),
                'payment_info' => $paymentInfo
            ]);
            return true;
        }
        return false;
    }

    public function markAsCancelled()
    {
        if ($this->canBeCancelled()) {
            $this->update(['status' => 'cancelled']);
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

    public function getCommercialNameAttribute()
    {
        return $this->commercial ? $this->commercial->nom . ' ' . $this->commercial->prenom : 'Commercial inconnu';
    }

    public function getStatusLibelleAttribute()
    {
        $statuses = [
            'draft' => 'Brouillon',
            'sent' => 'Envoyée',
            'paid' => 'Payée',
            'overdue' => 'En retard',
            'cancelled' => 'Annulée'
        ];

        return $statuses[$this->status] ?? $this->status;
    }

    public function getDaysUntilDueAttribute()
    {
        if ($this->status === 'paid' || $this->status === 'cancelled') {
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
    public static function getInvoiceStats($startDate = null, $endDate = null)
    {
        $query = self::query();
        
        if ($startDate && $endDate) {
            $query->whereBetween('invoice_date', [$startDate, $endDate]);
        }

        $invoices = $query->get();
        
        $totalInvoices = $invoices->count();
        $draftInvoices = $invoices->where('status', 'draft')->count();
        $sentInvoices = $invoices->where('status', 'sent')->count();
        $paidInvoices = $invoices->where('status', 'paid')->count();
        $overdueInvoices = $invoices->where('status', 'overdue')->count();
        
        $totalAmount = $invoices->sum('total_amount');
        $paidAmount = $invoices->where('status', 'paid')->sum('total_amount');
        $pendingAmount = $invoices->whereIn('status', ['sent', 'overdue'])->sum('total_amount');
        $overdueAmount = $invoices->where('status', 'overdue')->sum('total_amount');

        return [
            'total_invoices' => $totalInvoices,
            'draft_invoices' => $draftInvoices,
            'sent_invoices' => $sentInvoices,
            'paid_invoices' => $paidInvoices,
            'overdue_invoices' => $overdueInvoices,
            'total_amount' => $totalAmount,
            'paid_amount' => $paidAmount,
            'pending_amount' => $pendingAmount,
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
            
            $monthStats = self::getInvoiceStats($startDate, $endDate);
            $stats[$month] = $monthStats['total_amount'];
        }
        
        return $stats;
    }

    // Méthode pour générer le numéro de facture
    public static function generateInvoiceNumber()
    {
        $year = date('Y');
        $count = self::whereYear('created_at', $year)->count() + 1;
        return 'INV-' . $year . '-' . str_pad($count, 4, '0', STR_PAD_LEFT);
    }

    // Méthode pour mettre à jour les factures en retard
    public static function updateOverdueInvoices()
    {
        return self::where('status', 'sent')
            ->where('due_date', '<', now()->toDateString())
            ->update(['status' => 'overdue']);
    }
}
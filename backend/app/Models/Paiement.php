<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Paiement extends Model
{
    use HasFactory;

    protected $fillable = [
        'company_id',
        'payment_number',
        'type',
        'facture_id',
        'client_id',
        'client_name',
        'client_email',
        'client_address',
        'montant',
        'date_paiement',
        'due_date',
        'currency',
        'type_paiement',
        'status',
        'reference',
        'commentaire',
        'notes',
        'description',
        'user_id',
        'comptable_id',
        'comptable_name',
        'validated_by',
        'validated_at',
        'validation_comment',
        'rejected_by',
        'rejected_at',
        'rejection_reason',
        'rejection_comment',
        'submitted_at',
        'approved_at',
        'paid_at'
    ];

    protected $casts = [
        'date_paiement' => 'date',
        'due_date' => 'date',
        'montant' => 'decimal:2',
        'validated_at' => 'datetime',
        'rejected_at' => 'datetime',
        'submitted_at' => 'datetime',
        'approved_at' => 'datetime',
        'paid_at' => 'datetime'
    ];

    // Relations
    public function facture()
    {
        return $this->belongsTo(Facture::class);
    }

    public function client()
    {
        return $this->belongsTo(Client::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function comptable()
    {
        return $this->belongsTo(User::class, 'comptable_id');
    }

    public function validator()
    {
        return $this->belongsTo(User::class, 'validated_by');
    }

    public function rejector()
    {
        return $this->belongsTo(User::class, 'rejected_by');
    }

    public function schedule()
    {
        return $this->hasOne(PaymentSchedule::class, 'payment_id');
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

    public function scopeRejected($query)
    {
        return $query->where('status', 'rejected');
    }

    public function scopePaid($query)
    {
        return $query->where('status', 'paid');
    }

    public function scopeOverdue($query)
    {
        return $query->where('status', 'overdue');
    }

    public function scopeOneTime($query)
    {
        return $query->where('type', 'one_time');
    }

    public function scopeMonthly($query)
    {
        return $query->where('type', 'monthly');
    }

    // Anciens scopes pour compatibilité
    public function scopeEnAttente($query)
    {
        return $query->where('status', 'submitted');
    }

    public function scopeValide($query)
    {
        return $query->where('status', 'approved');
    }

    public function scopeRejete($query)
    {
        return $query->where('status', 'rejected');
    }

    public function scopeByType($query, $type)
    {
        return $query->where('type_paiement', $type);
    }

    public function scopeByDateRange($query, $startDate, $endDate)
    {
        return $query->whereBetween('date_paiement', [$startDate, $endDate]);
    }

    // Accesseurs
    public function getFormattedMontantAttribute()
    {
        return number_format($this->montant, 2, ',', ' ') . ' €';
    }

    public function getTypePaiementLibelleAttribute()
    {
        $types = [
            'especes' => 'Espèces',
            'virement' => 'Virement',
            'cheque' => 'Chèque',
            'carte_bancaire' => 'Carte bancaire',
            'mobile_money' => 'Mobile Money'
        ];

        return $types[$this->type_paiement] ?? $this->type_paiement;
    }

    public function getStatusLibelleAttribute()
    {
        $statuses = [
            'draft' => 'Brouillon',
            'submitted' => 'Soumis',
            'approved' => 'Approuvé',
            'rejected' => 'Rejeté',
            'paid' => 'Payé',
            'overdue' => 'En retard',
            // Anciens statuts pour compatibilité
            'en_attente' => 'En attente',
            'valide' => 'Validé',
            'rejete' => 'Rejeté'
        ];

        return $statuses[$this->status] ?? $this->status;
    }

    // Méthodes utilitaires
    public function canBeSubmitted()
    {
        return $this->status === 'draft';
    }

    public function canBeApproved()
    {
        return $this->status === 'submitted';
    }

    public function canBeRejected()
    {
        return in_array($this->status, ['submitted', 'approved']);
    }

    public function canBePaid()
    {
        return $this->status === 'approved';
    }

    public function canBeValidated()
    {
        return $this->status === 'submitted';
    }

    public function isOverdue()
    {
        return $this->status === 'overdue' || 
               ($this->due_date && $this->due_date < now()->toDateString() && $this->status !== 'paid');
    }

    public function submit()
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

    public function approve($approverId, $comment = null)
    {
        if ($this->canBeApproved()) {
            $this->update([
                'status' => 'approved',
                'approved_at' => now(),
                'validated_by' => $approverId,
                'validation_comment' => $comment
            ]);
            return true;
        }
        return false;
    }

    public function pay($payerId = null)
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

    public function markAsOverdue()
    {
        if ($this->isOverdue()) {
            $this->update(['status' => 'overdue']);
            return true;
        }
        return false;
    }

    public function validate($validatorId, $comment = null)
    {
        return $this->approve($validatorId, $comment);
    }

    public function reject($rejectorId, $reason, $comment = null)
    {
        if ($this->canBeRejected()) {
            $this->update([
                'status' => 'rejected',
                'rejected_by' => $rejectorId,
                'rejected_at' => now(),
                'rejection_reason' => $reason,
                'rejection_comment' => $comment
            ]);
            return true;
        }
        return false;
    }

    // Méthode pour générer un numéro de paiement unique
    public static function generatePaymentNumber()
    {
        $prefix = 'PAY';
        $date = now()->format('Ymd');
        $lastPayment = self::whereDate('created_at', now()->toDateString())
                          ->orderBy('id', 'desc')
                          ->first();
        
        $sequence = $lastPayment ? 
            (int)substr($lastPayment->payment_number, -4) + 1 : 1;
        
        return $prefix . $date . str_pad($sequence, 4, '0', STR_PAD_LEFT);
    }
}

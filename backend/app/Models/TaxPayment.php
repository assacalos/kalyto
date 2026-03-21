<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class TaxPayment extends Model
{
    use HasFactory;

    protected $fillable = [
        'tax_id',
        'comptable_id',
        'payment_reference',
        'payment_date',
        'amount_paid',
        'payment_method',
        'bank_reference',
        'notes',
        'receipt_path',
        'status',
        'validated_at',
        'validated_by'
    ];

    protected $casts = [
        'payment_date' => 'date',
        'amount_paid' => 'decimal:2',
        'validated_at' => 'datetime'
    ];

    // Relations
    public function tax()
    {
        return $this->belongsTo(Tax::class);
    }

    public function comptable()
    {
        return $this->belongsTo(User::class, 'comptable_id');
    }

    public function validator()
    {
        return $this->belongsTo(User::class, 'validated_by');
    }

    // Scopes
    public function scopePending($query)
    {
        return $query->where('status', 'pending');
    }

    public function scopeValidated($query)
    {
        return $query->where('status', 'validated');
    }

    public function scopeRejected($query)
    {
        return $query->where('status', 'rejected');
    }

    public function scopeByTax($query, $taxId)
    {
        return $query->where('tax_id', $taxId);
    }

    public function scopeByComptable($query, $comptableId)
    {
        return $query->where('comptable_id', $comptableId);
    }

    public function scopeByPaymentMethod($query, $method)
    {
        return $query->where('payment_method', $method);
    }

    public function scopeByDateRange($query, $startDate, $endDate)
    {
        return $query->whereBetween('payment_date', [$startDate, $endDate]);
    }

    // Accesseurs
    public function getStatusLibelleAttribute()
    {
        $statuses = [
            'pending' => 'En attente',
            'validated' => 'Validé',
            'rejected' => 'Rejeté'
        ];

        return $statuses[$this->status] ?? $this->status;
    }

    public function getPaymentMethodLibelleAttribute()
    {
        $methods = [
            'bank_transfer' => 'Virement bancaire',
            'check' => 'Chèque',
            'cash' => 'Espèces',
            'online' => 'Paiement en ligne',
            'direct_debit' => 'Prélèvement automatique'
        ];

        return $methods[$this->payment_method] ?? $this->payment_method;
    }

    public function getComptableNameAttribute()
    {
        if (!$this->relationLoaded('comptable') || !$this->comptable) {
            return 'N/A';
        }
        return trim(($this->comptable->prenom ?? '') . ' ' . ($this->comptable->nom ?? '')) ?: 'N/A';
    }

    public function getValidatorNameAttribute()
    {
        if (!$this->relationLoaded('validator') || !$this->validator) {
            return 'N/A';
        }
        return trim(($this->validator->prenom ?? '') . ' ' . ($this->validator->nom ?? '')) ?: 'N/A';
    }

    public function getTaxReferenceAttribute()
    {
        return $this->tax ? $this->tax->reference : 'N/A';
    }

    public function getFormattedAmountAttribute()
    {
        return number_format($this->amount_paid, 2, ',', ' ') . ' €';
    }

    // Méthodes utilitaires
    public function canBeValidated()
    {
        return $this->status === 'pending';
    }

    public function canBeRejected()
    {
        return $this->status === 'pending';
    }

    public function validate($validatorId, $notes = null)
    {
        if ($this->canBeValidated()) {
            $this->update([
                'status' => 'validated',
                'validated_at' => now(),
                'validated_by' => $validatorId,
                'notes' => $notes ?? $this->notes
            ]);

            // Mettre à jour le statut de la taxe si entièrement payée
            $tax = $this->tax;
            if ($tax && $tax->remaining_amount <= 0) {
                $tax->markAsPaid();
            }

            return true;
        }
        return false;
    }

    public function reject($validatorId, $reason)
    {
        if ($this->canBeRejected()) {
            $this->update([
                'status' => 'rejected',
                'validated_by' => $validatorId,
                'notes' => $reason
            ]);
            return true;
        }
        return false;
    }

    public function hasReceipt()
    {
        if (empty($this->receipt_path)) {
            return false;
        }
        return \Storage::disk('private')->exists($this->receipt_path);
    }

    public function uploadReceipt($file)
    {
        if ($file && $file->isValid()) {
            $path = $file->store('tax_receipts', 'private');
            $this->update(['receipt_path' => $path]);
            return $path;
        }
        return null;
    }

    public function deleteReceipt()
    {
        if ($this->hasReceipt()) {
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

        static::deleting(function ($taxPayment) {
            if ($taxPayment->hasReceipt()) {
                \Storage::disk('private')->delete($taxPayment->receipt_path);
            }
        });
    }

    // Méthodes statiques
    public static function generateReference($taxReference)
    {
        $count = self::whereHas('tax', function ($query) use ($taxReference) {
            $query->where('reference', $taxReference);
        })->count() + 1;
        
        return $taxReference . '-PAY-' . str_pad($count, 3, '0', STR_PAD_LEFT);
    }

    public static function getPaymentStats($startDate = null, $endDate = null)
    {
        $query = self::query();
        
        if ($startDate && $endDate) {
            $query->whereBetween('payment_date', [$startDate, $endDate]);
        }

        $payments = $query->get();
        
        return [
            'total_payments' => $payments->count(),
            'pending_payments' => $payments->where('status', 'pending')->count(),
            'validated_payments' => $payments->where('status', 'validated')->count(),
            'rejected_payments' => $payments->where('status', 'rejected')->count(),
            'total_amount' => $payments->sum('amount_paid'),
            'validated_amount' => $payments->where('status', 'validated')->sum('amount_paid'),
            'pending_amount' => $payments->where('status', 'pending')->sum('amount_paid')
        ];
    }

    public static function getPaymentMethodStats($startDate = null, $endDate = null)
    {
        $query = self::where('status', 'validated');
        
        if ($startDate && $endDate) {
            $query->whereBetween('payment_date', [$startDate, $endDate]);
        }

        return $query->selectRaw('payment_method, COUNT(*) as count, SUM(amount_paid) as total_amount')
            ->groupBy('payment_method')
            ->get()
            ->keyBy('payment_method')
            ->toArray();
    }
}
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class Facture extends Model
{
    use HasFactory;

    protected $fillable = [
        'company_id',
        'client_id',
        'numero_facture',
        'date_facture',
        'date_echeance',
        'montant_ht',
        'tva',
        'montant_ttc',
        'status',
        'type_paiement',
        'notes',
        'terms',
        'user_id',
        'validated_by',
        'validated_at',
        'validation_comment',
        'rejected_by',
        'rejected_at',
        'rejection_reason',
        'rejection_comment'
    ];

    protected $casts = [
        'date_facture' => 'date',
        'date_echeance' => 'date',
        'montant_ht' => 'decimal:2',
        'tva' => 'decimal:2',
        'montant_ttc' => 'decimal:2',
        'validated_at' => 'datetime',
        'rejected_at' => 'datetime'
    ];

    /**
     * Relation avec le client
     */
    public function client()
    {
        return $this->belongsTo(Client::class);
    }

    /**
     * Relation avec l'utilisateur créateur
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Relation avec l'utilisateur qui a validé
     */
    public function validator()
    {
        return $this->belongsTo(User::class, 'validated_by');
    }

    /**
     * Relation avec l'utilisateur qui a rejeté
     */
    public function rejector()
    {
        return $this->belongsTo(User::class, 'rejected_by');
    }

    /**
     * Relation avec les paiements
     */
    public function paiements()
    {
        return $this->hasMany(Paiement::class);
    }

    /**
     * Relation avec les items de la facture
     */
    public function items()
    {
        return $this->hasMany(FactureItem::class, 'facture_id');
    }

    /**
     * Vérifier si la facture est en attente
     */
    public function isPending()
    {
        return $this->status === 'en_attente';
    }

    /**
     * Vérifier si la facture est validée
     */
    public function isValidated()
    {
        return $this->status === 'valide';
    }

    /**
     * Vérifier si la facture est rejetée
     */
    public function isRejected()
    {
        return $this->status === 'rejete';
    }

    /**
     * Vérifier si la facture peut être validée
     */
    public function canBeValidated()
    {
        return $this->status === 'en_attente';
    }

    /**
     * Vérifier si la facture peut être rejetée
     */
    public function canBeRejected()
    {
        return $this->status === 'en_attente';
    }

    /**
     * Obtenir le statut formaté
     */
    public function getFormattedStatusAttribute()
    {
        $statuses = [
            'en_attente' => 'En attente',
            'valide' => 'Validé',
            'rejete' => 'Rejeté'
        ];

        return $statuses[$this->status] ?? $this->status;
    }

    /**
     * Obtenir le montant formaté
     */
    public function getFormattedAmountAttribute()
    {
        return number_format($this->montant_ttc, 2, ',', ' ') . ' €';
    }

    /**
     * Scope pour les factures en attente
     */
    public function scopePending($query)
    {
        return $query->where('status', 'en_attente');
    }

    /**
     * Scope pour les factures validées
     */
    public function scopeValidated($query)
    {
        return $query->where('status', 'valide');
    }

    /**
     * Scope pour les factures rejetées
     */
    public function scopeRejected($query)
    {
        return $query->where('status', 'rejete');
    }
}

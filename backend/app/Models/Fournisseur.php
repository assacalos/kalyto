<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Fournisseur extends Model
{
    use HasFactory;

    protected $fillable = [
        'nom',
        'email',
        'telephone',
        'adresse',
        'ville',
        'pays',
        'description',
        'ninea',
        'status',
        'note_evaluation',
        'commentaires',
        'created_by',
        'updated_by',
        'validated_by',
        'validated_at',
        'validation_comment',
        'rejected_by',
        'rejected_at',
        'rejection_reason',
        'rejection_comment'
    ];

    protected $casts = [
        'note_evaluation' => 'decimal:1',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'deleted_at' => 'datetime',
    ];

    // Constantes pour les statuts
    const STATUS_EN_ATTENTE = 'en_attente';
    const STATUS_VALIDE = 'valide';
    const STATUS_REJETE = 'rejete';

    // Scopes
    public function scopeEnAttente($query)
    {
        return $query->where('status', self::STATUS_EN_ATTENTE);
    }

    public function scopeValide($query)
    {
        return $query->where('status', self::STATUS_VALIDE);
    }

    public function scopeRejete($query)
    {
        return $query->where('status', self::STATUS_REJETE);
    }

    public function scopeByStatus($query, $status)
    {
        if ($status && $status !== 'all') {
            return $query->where('status', $status);
        }
        return $query;
    }

    public function scopeSearch($query, $search)
    {
        if ($search) {
            return $query->where(function ($q) use ($search) {
                $q->where('nom', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%")
                  ->orWhere('ville', 'like', "%{$search}%");
            });
        }
        return $query;
    }

    // Accessors
    public function getStatusTextAttribute()
    {
        return match ($this->status) {
            self::STATUS_EN_ATTENTE => 'En attente',
            self::STATUS_VALIDE => 'Validé',
            self::STATUS_REJETE => 'Rejeté',
            default => 'Inconnu',
        };
    }

    /** Pour compatibilité API (SupplierResource attend "statut"). */
    public function getStatutAttribute()
    {
        return $this->status;
    }

    public function getStatusColorAttribute()
    {
        return match ($this->status) {
            self::STATUS_EN_ATTENTE => 'orange',
            self::STATUS_VALIDE => 'green',
            self::STATUS_REJETE => 'red',
            default => 'grey',
        };
    }

    // Relations
    public function createdBy()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function updatedBy()
    {
        return $this->belongsTo(User::class, 'updated_by');
    }

    public function validatedBy()
    {
        return $this->belongsTo(User::class, 'validated_by');
    }

    public function rejectedBy()
    {
        return $this->belongsTo(User::class, 'rejected_by');
    }

    // Méthodes utilitaires
    public function isEnAttente()
    {
        return $this->status === self::STATUS_EN_ATTENTE;
    }

    public function isValide()
    {
        return $this->status === self::STATUS_VALIDE;
    }

    public function isRejete()
    {
        return $this->status === self::STATUS_REJETE;
    }

    public function validate($comment = null)
    {
        $this->update([
            'status' => self::STATUS_VALIDE,
            'validated_by' => auth()->id(),
            'validated_at' => now(),
            'validation_comment' => $comment,
            'updated_by' => auth()->id(),
        ]);
    }

    public function reject($reason, $comment = null)
    {
        $this->update([
            'status' => self::STATUS_REJETE,
            'rejected_by' => auth()->id(),
            'rejected_at' => now(),
            'rejection_reason' => $reason,
            'rejection_comment' => $comment,
            'updated_by' => auth()->id(),
        ]);
    }

    public function activate()
    {
        $this->update([
            'statut' => self::STATUS_ACTIVE,
            'updated_by' => auth()->id(),
        ]);
    }

    public function deactivate()
    {
        $this->update([
            'statut' => self::STATUS_INACTIVE,
            'updated_by' => auth()->id(),
        ]);
    }

    public function rate($rating, $comments = null)
    {
        $this->update([
            'note_evaluation' => $rating,
            'commentaires' => $comments,
            'updated_by' => auth()->id(),
        ]);
    }
}

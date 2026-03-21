<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Reporting extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'report_date',
        'nature',
        'nom_societe',
        'contact_societe',
        'nom_personne',
        'contact_personne',
        'moyen_contact',
        'produit_demarche',
        'commentaire',
        'type_relance',
        'relance_date_heure',
        'status',
        'submitted_at',
        'approved_at',
        'approved_by',
        'rejected_at',
        'rejected_by',
        'rejection_reason',
        'patron_note',
    ];

    protected $casts = [
        'report_date' => 'date',
        'submitted_at' => 'datetime',
        'approved_at' => 'datetime',
        'rejected_at' => 'datetime',
        'relance_date_heure' => 'datetime'
    ];

    // Relations
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function approver()
    {
        return $this->belongsTo(User::class, 'approved_by');
    }

    public function rejector()
    {
        return $this->belongsTo(User::class, 'rejected_by');
    }

    // Scopes
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

    public function scopeByUser($query, $userId)
    {
        return $query->where('user_id', $userId);
    }

    public function scopeByDateRange($query, $startDate, $endDate)
    {
        return $query->whereBetween('report_date', [$startDate, $endDate]);
    }

    // Méthodes utilitaires
    public function canBeEdited()
    {
        return $this->status === 'submitted';
    }

    public function canBeApproved()
    {
        return $this->status === 'submitted';
    }

    public function canBeRejected()
    {
        return $this->status === 'submitted';
    }

    public function approve($approvedBy, $patronNote = null)
    {
        if ($this->canBeApproved()) {
            $this->update([
                'status' => 'approved',
                'approved_at' => now(),
                'approved_by' => $approvedBy,
                'patron_note' => $patronNote
            ]);
            return true;
        }
        return false;
    }

    public function reject($rejectedBy, $reason = null)
    {
        if ($this->canBeRejected()) {
            $this->update([
                'status' => 'rejected',
                'rejected_at' => now(),
                'rejected_by' => $rejectedBy,
                'rejection_reason' => $reason
            ]);
            return true;
        }
        return false;
    }

    // Accesseurs
    public function getUserNameAttribute()
    {
        if (!$this->relationLoaded('user') || !$this->user) {
            return 'Utilisateur inconnu';
        }
        return trim(($this->user->nom ?? '') . ' ' . ($this->user->prenom ?? '')) ?: 'Utilisateur inconnu';
    }

    public function getUserRoleAttribute()
    {
        if (!$this->relationLoaded('user') || !$this->user) {
            return 'Inconnu';
        }
        
        $roles = [
            1 => 'Admin',
            2 => 'Commercial',
            3 => 'Comptable',
            4 => 'RH',
            5 => 'Technicien',
            6 => 'Patron'
        ];

        return $roles[$this->user->role] ?? 'Inconnu';
    }

    public function getStatusLibelleAttribute()
    {
        $statuses = [
            'submitted' => 'Soumis',
            'approved' => 'Approuvé',
            'rejected' => 'Rejeté'
        ];

        return $statuses[$this->status] ?? $this->status;
    }

    public function getNatureLibelleAttribute()
    {
        $natures = [
            'echange_telephonique' => 'Échange téléphonique',
            'visite' => 'Visite',
            'depannage_visite' => 'Dépannage visite',
            'depannage_bureau' => 'Dépannage bureau',
            'depannage_telephonique' => 'Dépannage téléphonique',
            'programmation' => 'Programmation',
        ];

        return $natures[$this->nature] ?? $this->nature;
    }

    public function getMoyenContactLibelleAttribute()
    {
        $moyens = [
            'mail' => 'Email',
            'whatsapp' => 'WhatsApp',
            'linkedin' => 'LinkedIn'
        ];

        return $moyens[$this->moyen_contact] ?? $this->moyen_contact;
    }

    public function getTypeRelanceLibelleAttribute()
    {
        $types = [
            'telephonique' => 'Relance téléphonique',
            'mail' => 'Relance par mail',
            'rdv' => 'Relance par RDV'
        ];

        return $types[$this->type_relance] ?? $this->type_relance;
    }
}

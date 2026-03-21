<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ContractAmendment extends Model
{
    use HasFactory;

    protected $fillable = [
        'contract_id',
        'amendment_type',
        'reason',
        'description',
        'changes',
        'effective_date',
        'status',
        'approval_notes',
        'approved_at',
        'approved_by',
        'created_by'
    ];

    protected $casts = [
        'changes' => 'array',
        'effective_date' => 'date',
        'approved_at' => 'datetime'
    ];

    // Relations
    public function contract()
    {
        return $this->belongsTo(Contract::class);
    }

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function approver()
    {
        return $this->belongsTo(User::class, 'approved_by');
    }

    // Scopes
    public function scopePending($query)
    {
        return $query->where('status', 'pending');
    }

    public function scopeApproved($query)
    {
        return $query->where('status', 'approved');
    }

    public function scopeRejected($query)
    {
        return $query->where('status', 'rejected');
    }

    public function scopeByContract($query, $contractId)
    {
        return $query->where('contract_id', $contractId);
    }

    public function scopeByType($query, $amendmentType)
    {
        return $query->where('amendment_type', $amendmentType);
    }

    public function scopeByEffectiveDate($query, $startDate, $endDate)
    {
        return $query->whereBetween('effective_date', [$startDate, $endDate]);
    }

    public function scopeRecent($query, $days = 30)
    {
        return $query->where('created_at', '>=', now()->subDays($days));
    }

    // Accesseurs
    public function getAmendmentTypeLibelleAttribute()
    {
        $types = [
            'salary' => 'Salaire',
            'position' => 'Poste',
            'schedule' => 'Horaires',
            'location' => 'Lieu de travail',
            'other' => 'Autre'
        ];

        return $types[$this->amendment_type] ?? $this->amendment_type;
    }

    public function getStatusLibelleAttribute()
    {
        $statuses = [
            'pending' => 'En attente',
            'approved' => 'Approuvé',
            'rejected' => 'Rejeté'
        ];

        return $statuses[$this->status] ?? $this->status;
    }

    public function getCreatorNameAttribute()
    {
        return $this->creator ? $this->creator->prenom . ' ' . $this->creator->nom : 'N/A';
    }

    public function getApproverNameAttribute()
    {
        return $this->approver ? $this->approver->prenom . ' ' . $this->approver->nom : 'N/A';
    }

    public function getIsPendingAttribute()
    {
        return $this->status === 'pending';
    }

    public function getIsApprovedAttribute()
    {
        return $this->status === 'approved';
    }

    public function getIsRejectedAttribute()
    {
        return $this->status === 'rejected';
    }

    public function getCanApproveAttribute()
    {
        return $this->is_pending;
    }

    public function getCanRejectAttribute()
    {
        return $this->is_pending;
    }

    // Méthodes utilitaires
    public function approve($approvedBy, $approvalNotes = null)
    {
        $this->update([
            'status' => 'approved',
            'approved_at' => now(),
            'approved_by' => $approvedBy,
            'approval_notes' => $approvalNotes ?? $this->approval_notes
        ]);
    }

    public function reject($rejectedBy, $rejectionReason = null)
    {
        $this->update([
            'status' => 'rejected',
            'approved_by' => $rejectedBy,
            'approval_notes' => $rejectionReason ?? $this->approval_notes
        ]);
    }

    public function updateChanges($newChanges, $updatedBy = null)
    {
        $this->update([
            'changes' => $newChanges,
            'updated_by' => $updatedBy
        ]);
    }

    // Méthodes statiques
    public static function getAmendmentsByContract($contractId)
    {
        return self::byContract($contractId)
            ->with(['creator', 'approver'])
            ->orderBy('created_at', 'desc')
            ->get();
    }

    public static function getAmendmentsByType($amendmentType)
    {
        return self::byType($amendmentType)
            ->with(['contract', 'creator', 'approver'])
            ->orderBy('created_at', 'desc')
            ->get();
    }

    public static function getPendingAmendments()
    {
        return self::pending()
            ->with(['contract', 'creator'])
            ->orderBy('created_at', 'desc')
            ->get();
    }

    public static function getApprovedAmendments()
    {
        return self::approved()
            ->with(['contract', 'creator', 'approver'])
            ->orderBy('approved_at', 'desc')
            ->get();
    }

    public static function getRejectedAmendments()
    {
        return self::rejected()
            ->with(['contract', 'creator', 'approver'])
            ->orderBy('created_at', 'desc')
            ->get();
    }

    public static function getAmendmentStats($contractId = null)
    {
        $query = self::query();
        if ($contractId) {
            $query->where('contract_id', $contractId);
        }

        $amendments = $query->get();
        
        return [
            'total_amendments' => $amendments->count(),
            'pending_amendments' => $amendments->where('status', 'pending')->count(),
            'approved_amendments' => $amendments->where('status', 'approved')->count(),
            'rejected_amendments' => $amendments->where('status', 'rejected')->count(),
            'amendments_by_type' => $amendments->groupBy('amendment_type')->map->count(),
            'amendments_by_status' => $amendments->groupBy('status')->map->count()
        ];
    }
}

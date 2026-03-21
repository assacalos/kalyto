<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class EmployeeLeave extends Model
{
    use HasFactory;

    protected $fillable = [
        'employee_id',
        'type',
        'start_date',
        'end_date',
        'total_days',
        'reason',
        'status',
        'comments',
        'approved_by',
        'approved_at',
        'approved_by_name',
        'rejection_reason',
        'created_by'
    ];

    protected $casts = [
        'start_date' => 'date',
        'end_date' => 'date',
        'approved_at' => 'datetime'
    ];

    // Relations
    public function employee()
    {
        return $this->belongsTo(Employee::class);
    }

    public function approver()
    {
        return $this->belongsTo(User::class, 'approved_by');
    }

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
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

    public function scopeCancelled($query)
    {
        return $query->where('status', 'cancelled');
    }

    public function scopeByType($query, $type)
    {
        return $query->where('type', $type);
    }

    public function scopeByEmployee($query, $employeeId)
    {
        return $query->where('employee_id', $employeeId);
    }

    public function scopeByDateRange($query, $startDate, $endDate)
    {
        return $query->where(function ($q) use ($startDate, $endDate) {
            $q->whereBetween('start_date', [$startDate, $endDate])
              ->orWhereBetween('end_date', [$startDate, $endDate])
              ->orWhere(function ($q2) use ($startDate, $endDate) {
                  $q2->where('start_date', '<=', $startDate)
                    ->where('end_date', '>=', $endDate);
              });
        });
    }

    public function scopeCurrent($query)
    {
        $today = now()->toDateString();
        return $query->where('start_date', '<=', $today)
                    ->where('end_date', '>=', $today)
                    ->where('status', 'approved');
    }

    public function scopeUpcoming($query)
    {
        return $query->where('start_date', '>', now()->toDateString())
                    ->where('status', 'approved');
    }

    // Accesseurs
    public function getTypeLibelleAttribute()
    {
        $types = [
            'annual' => 'Congé annuel',
            'sick' => 'Congé maladie',
            'maternity' => 'Congé maternité',
            'paternity' => 'Congé paternité',
            'personal' => 'Congé personnel',
            'emergency' => 'Congé d\'urgence',
            'unpaid' => 'Congé sans solde'
        ];

        return $types[$this->type] ?? $this->type;
    }

    public function getStatusLibelleAttribute()
    {
        $statuses = [
            'pending' => 'En attente',
            'approved' => 'Approuvé',
            'rejected' => 'Rejeté',
            'cancelled' => 'Annulé'
        ];

        return $statuses[$this->status] ?? $this->status;
    }

    public function getApproverNameAttribute()
    {
        return $this->approver ? $this->approver->prenom . ' ' . $this->approver->nom : 'N/A';
    }

    public function getCreatorNameAttribute()
    {
        return $this->creator ? $this->creator->prenom . ' ' . $this->creator->nom : 'N/A';
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

    public function getIsCancelledAttribute()
    {
        return $this->status === 'cancelled';
    }

    public function getIsCurrentAttribute()
    {
        $today = now()->toDateString();
        return $this->status === 'approved' && 
               $this->start_date <= $today && 
               $this->end_date >= $today;
    }

    public function getIsUpcomingAttribute()
    {
        return $this->status === 'approved' && 
               $this->start_date > now()->toDateString();
    }

    public function getIsPastAttribute()
    {
        return $this->end_date < now()->toDateString();
    }

    public function getDurationAttribute()
    {
        return $this->start_date->diffInDays($this->end_date) + 1;
    }

    // Méthodes utilitaires
    public function approve($approvedBy, $notes = null)
    {
        $approver = \App\Models\User::find($approvedBy);
        $approverName = $approver ? ($approver->prenom . ' ' . $approver->nom) : null;

        $this->update([
            'status' => 'approved',
            'approved_by' => $approvedBy,
            'approved_at' => now(),
            'approved_by_name' => $approverName,
            'rejection_reason' => null
        ]);

        if ($notes) {
            $this->update(['comments' => ($this->comments ?? '') . "\n\nNotes d'approbation: " . $notes]);
        }
    }

    public function reject($rejectedBy, $reason)
    {
        $rejecter = \App\Models\User::find($rejectedBy);
        $rejecterName = $rejecter ? ($rejecter->prenom . ' ' . $rejecter->nom) : null;

        $this->update([
            'status' => 'rejected',
            'approved_by' => $rejectedBy,
            'approved_at' => now(),
            'approved_by_name' => $rejecterName,
            'rejection_reason' => $reason
        ]);
    }

    public function cancel($cancelledBy, $reason = null)
    {
        $this->update([
            'status' => 'cancelled',
            'rejection_reason' => $reason ?? 'Annulé par l\'utilisateur'
        ]);
    }

    // Méthodes statiques
    public static function getLeaveStats($startDate = null, $endDate = null)
    {
        $query = self::query();
        
        if ($startDate && $endDate) {
            $query->byDateRange($startDate, $endDate);
        }

        $leaves = $query->get();
        
        return [
            'total_leaves' => $leaves->count(),
            'pending_leaves' => $leaves->where('status', 'pending')->count(),
            'approved_leaves' => $leaves->where('status', 'approved')->count(),
            'rejected_leaves' => $leaves->where('status', 'rejected')->count(),
            'annual_leaves' => $leaves->where('type', 'annual')->count(),
            'sick_leaves' => $leaves->where('type', 'sick')->count(),
            'maternity_leaves' => $leaves->where('type', 'maternity')->count(),
            'paternity_leaves' => $leaves->where('type', 'paternity')->count(),
            'personal_leaves' => $leaves->where('type', 'personal')->count(),
            'unpaid_leaves' => $leaves->where('type', 'unpaid')->count(),
            'current_leaves' => $leaves->filter(function ($leave) {
                return $leave->is_current;
            })->count(),
            'upcoming_leaves' => $leaves->filter(function ($leave) {
                return $leave->is_upcoming;
            })->count(),
            'total_days' => $leaves->sum('total_days'),
            'average_days' => $leaves->avg('total_days') ?? 0,
            'leaves_by_type' => $leaves->groupBy('type')->map->count(),
            'leaves_by_status' => $leaves->groupBy('status')->map->count()
        ];
    }

    public static function getLeavesByEmployee($employeeId)
    {
        return self::byEmployee($employeeId)
            ->with(['approver', 'creator'])
            ->orderBy('start_date', 'desc')
            ->get();
    }

    public static function getCurrentLeaves()
    {
        return self::current()->with(['employee', 'approver', 'creator'])->get();
    }

    public static function getUpcomingLeaves()
    {
        return self::upcoming()->with(['employee', 'approver', 'creator'])->get();
    }

    public static function getPendingLeaves()
    {
        return self::pending()->with(['employee', 'creator'])->get();
    }

    public static function getLeavesByType($type)
    {
        return self::byType($type)->with(['employee', 'approver', 'creator'])->get();
    }

    public static function getLeavesByDateRange($startDate, $endDate)
    {
        return self::byDateRange($startDate, $endDate)
            ->with(['employee', 'approver', 'creator'])
            ->get();
    }
}

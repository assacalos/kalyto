<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class Intervention extends Model
{
    use HasFactory;

    protected $fillable = [
        'type',
        'title',
        'description',
        'scheduled_date',
        'start_date',
        'end_date',
        'status',
        'priority',
        'location',
        'client_id', // ID du client sélectionné
        'client_name', // Gardé pour compatibilité et affichage
        'client_phone', // Gardé pour compatibilité et affichage
        'client_email', // Gardé pour compatibilité et affichage
        'equipment',
        'problem_description',
        'solution',
        'notes',
        'attachments',
        'estimated_duration',
        'actual_duration',
        'cost',
        'created_by',
        'approved_by',
        'approved_at',
        'rejection_reason',
        'completion_notes',
    ];

    protected $casts = [
        'scheduled_date' => 'datetime',
        'start_date' => 'datetime',
        'end_date' => 'datetime',
        'approved_at' => 'datetime',
        'attachments' => 'array',
        'estimated_duration' => 'decimal:2',
        'actual_duration' => 'decimal:2',
        'cost' => 'decimal:2'
    ];

    // Relations
    public function client()
    {
        return $this->belongsTo(Client::class, 'client_id');
    }

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function approver()
    {
        return $this->belongsTo(User::class, 'approved_by');
    }

    public function reports()
    {
        return $this->hasMany(InterventionReport::class);
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

    public function scopeInProgress($query)
    {
        return $query->where('status', 'in_progress');
    }

    public function scopeCompleted($query)
    {
        return $query->where('status', 'completed');
    }

    public function scopeRejected($query)
    {
        return $query->where('status', 'rejected');
    }

    public function scopeByType($query, $type)
    {
        return $query->where('type', $type);
    }

    public function scopeByPriority($query, $priority)
    {
        return $query->where('priority', $priority);
    }

    public function scopeByCreator($query, $userId)
    {
        return $query->where('created_by', $userId);
    }

    // Accesseurs
    public function getStatusLibelleAttribute()
    {
        $statuses = [
            'pending' => 'En attente',
            'approved' => 'Approuvée',
            'in_progress' => 'En cours',
            'completed' => 'Terminée',
            'rejected' => 'Rejetée'
        ];

        return $statuses[$this->status] ?? $this->status;
    }

    public function getTypeLibelleAttribute()
    {
        $types = [
            'external' => 'Externe',
            'on_site' => 'Sur place'
        ];

        return $types[$this->type] ?? $this->type;
    }

    public function getPriorityLibelleAttribute()
    {
        $priorities = [
            'low' => 'Faible',
            'medium' => 'Moyenne',
            'high' => 'Élevée',
            'urgent' => 'Urgente'
        ];

        return $priorities[$this->priority] ?? $this->priority;
    }

    public function getFormattedCostAttribute()
    {
        return $this->cost ? number_format($this->cost, 2, ',', ' ') . ' €' : 'N/A';
    }

    public function getFormattedEstimatedDurationAttribute()
    {
        return $this->estimated_duration ? $this->estimated_duration . 'h' : 'N/A';
    }

    public function getFormattedActualDurationAttribute()
    {
        return $this->actual_duration ? $this->actual_duration . 'h' : 'N/A';
    }

    public function getCreatorNameAttribute()
    {
        return $this->creator ? $this->creator->prenom . ' ' . $this->creator->nom : 'N/A';
    }

    public function getApproverNameAttribute()
    {
        return $this->approver ? $this->approver->prenom . ' ' . $this->approver->nom : 'N/A';
    }

    public function getCalculatedDurationAttribute()
    {
        if ($this->start_date && $this->end_date) {
            return $this->start_date->diffInHours($this->end_date);
        }
        return $this->actual_duration;
    }

    public function getIsOverdueAttribute()
    {
        if ($this->status === 'completed') return false;
        return now()->isAfter($this->scheduled_date);
    }

    public function getIsDueSoonAttribute()
    {
        if ($this->status === 'completed') return false;
        $dueDate = $this->scheduled_date->subHours(2);
        return now()->isAfter($dueDate) && !$this->is_overdue;
    }

    // Méthodes utilitaires
    public function canBeEdited()
    {
        return in_array($this->status, ['pending', 'rejected']);
    }

    public function canBeApproved()
    {
        return $this->status === 'pending';
    }

    public function canBeRejected()
    {
        return $this->status === 'pending';
    }

    public function canBeStarted()
    {
        return $this->status === 'approved';
    }

    public function canBeCompleted()
    {
        return $this->status === 'in_progress';
    }

    public function approve($userId, $notes = null)
    {
        if ($this->canBeApproved()) {
            $this->update([
                'status' => 'approved',
                'approved_by' => $userId,
                'approved_at' => now()
            ]);
            return true;
        }
        return false;
    }

    public function reject($reason)
    {
        if ($this->canBeRejected()) {
            $this->update([
                'status' => 'rejected',
                'rejection_reason' => $reason
            ]);
            return true;
        }
        return false;
    }

    public function start()
    {
        if ($this->canBeStarted()) {
            $this->update([
                'status' => 'in_progress',
                'start_date' => now()
            ]);
            return true;
        }
        return false;
    }

    public function complete($completionNotes = null, $actualDuration = null, $cost = null)
    {
        if ($this->canBeCompleted()) {
            $this->update([
                'status' => 'completed',
                'end_date' => now(),
                'completion_notes' => $completionNotes,
                'actual_duration' => $actualDuration,
                'cost' => $cost
            ]);
            return true;
        }
        return false;
    }

    // Méthodes statiques
    public static function getInterventionStats($startDate = null, $endDate = null)
    {
        $query = self::query();
        
        if ($startDate && $endDate) {
            $query->whereBetween('created_at', [$startDate, $endDate]);
        }

        $interventions = $query->get();
        
        return [
            'total_interventions' => $interventions->count(),
            'pending_interventions' => $interventions->where('status', 'pending')->count(),
            'approved_interventions' => $interventions->where('status', 'approved')->count(),
            'in_progress_interventions' => $interventions->where('status', 'in_progress')->count(),
            'completed_interventions' => $interventions->where('status', 'completed')->count(),
            'rejected_interventions' => $interventions->where('status', 'rejected')->count(),
            'external_interventions' => $interventions->where('type', 'external')->count(),
            'on_site_interventions' => $interventions->where('type', 'on_site')->count(),
            'average_duration' => $interventions->where('actual_duration', '!=', null)->avg('actual_duration') ?? 0,
            'total_cost' => $interventions->sum('cost'),
            'interventions_by_month' => $interventions->groupBy(function ($intervention) {
                return $intervention->created_at->format('Y-m');
            })->map->count(),
            'interventions_by_priority' => $interventions->groupBy('priority')->map->count()
        ];
    }

    public static function getInterventionsByStatus($status)
    {
        return self::where('status', $status)->with(['creator', 'approver'])->get();
    }

    public static function getInterventionsByType($type)
    {
        return self::where('type', $type)->with(['creator', 'approver'])->get();
    }

    public static function getOverdueInterventions()
    {
        return self::where('status', '!=', 'completed')
            ->where('scheduled_date', '<', now())
            ->with(['creator', 'approver'])
            ->get();
    }

    public static function getDueSoonInterventions()
    {
        $dueDate = now()->addHours(2);
        return self::where('status', '!=', 'completed')
            ->where('scheduled_date', '<=', $dueDate)
            ->where('scheduled_date', '>', now())
            ->with(['creator', 'approver'])
            ->get();
    }
}

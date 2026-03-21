<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class EquipmentAssignment extends Model
{
    use HasFactory;

    protected $fillable = [
        'equipment_id',
        'user_id',
        'assigned_date',
        'return_date',
        'status',
        'notes',
        'assigned_by',
        'returned_by'
    ];

    protected $casts = [
        'assigned_date' => 'date',
        'return_date' => 'date'
    ];

    // Relations
    public function equipment()
    {
        return $this->belongsTo(EquipmentNew::class, 'equipment_id');
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function assignedBy()
    {
        return $this->belongsTo(User::class, 'assigned_by');
    }

    public function returnedBy()
    {
        return $this->belongsTo(User::class, 'returned_by');
    }

    // Scopes
    public function scopeActive($query)
    {
        return $query->where('status', 'active');
    }

    public function scopeReturned($query)
    {
        return $query->where('status', 'returned');
    }

    public function scopeLost($query)
    {
        return $query->where('status', 'lost');
    }

    public function scopeDamaged($query)
    {
        return $query->where('status', 'damaged');
    }

    public function scopeByEquipment($query, $equipmentId)
    {
        return $query->where('equipment_id', $equipmentId);
    }

    public function scopeByUser($query, $userId)
    {
        return $query->where('user_id', $userId);
    }

    public function scopeByAssignedBy($query, $assignedBy)
    {
        return $query->where('assigned_by', $assignedBy);
    }

    public function scopeCurrent($query)
    {
        return $query->where('status', 'active');
    }

    public function scopeHistorical($query)
    {
        return $query->whereIn('status', ['returned', 'lost', 'damaged']);
    }

    // Accesseurs
    public function getStatusLibelleAttribute()
    {
        $statuses = [
            'active' => 'Actif',
            'returned' => 'Retourné',
            'lost' => 'Perdu',
            'damaged' => 'Endommagé'
        ];

        return $statuses[$this->status] ?? $this->status;
    }

    public function getUserNameAttribute()
    {
        return $this->user ? $this->user->prenom . ' ' . $this->user->nom : 'N/A';
    }

    public function getAssignedByNameAttribute()
    {
        return $this->assignedBy ? $this->assignedBy->prenom . ' ' . $this->assignedBy->nom : 'N/A';
    }

    public function getReturnedByNameAttribute()
    {
        return $this->returnedBy ? $this->returnedBy->prenom . ' ' . $this->returnedBy->nom : 'N/A';
    }

    public function getDurationAttribute()
    {
        if ($this->return_date) {
            return $this->assigned_date->diffInDays($this->return_date);
        }
        return $this->assigned_date->diffInDays(now());
    }

    public function getIsActiveAttribute()
    {
        return $this->status === 'active';
    }

    public function getIsReturnedAttribute()
    {
        return $this->status === 'returned';
    }

    public function getIsLostAttribute()
    {
        return $this->status === 'lost';
    }

    public function getIsDamagedAttribute()
    {
        return $this->status === 'damaged';
    }

    // Méthodes utilitaires
    public function return($returnedBy, $notes = null)
    {
        if ($this->status === 'active') {
            $this->update([
                'status' => 'returned',
                'return_date' => now(),
                'returned_by' => $returnedBy,
                'notes' => $notes ?? $this->notes
            ]);

            // Mettre à jour l'équipement
            if ($this->equipment) {
                $this->equipment->update([
                    'assigned_to' => null,
                    'updated_by' => $returnedBy
                ]);
            }

            return true;
        }
        return false;
    }

    public function markAsLost($notes = null)
    {
        if ($this->status === 'active') {
            $this->update([
                'status' => 'lost',
                'notes' => $notes ?? $this->notes
            ]);

            // Mettre à jour l'équipement
            if ($this->equipment) {
                $this->equipment->update([
                    'status' => 'broken',
                    'assigned_to' => null,
                    'updated_by' => $this->assigned_by
                ]);
            }

            return true;
        }
        return false;
    }

    public function markAsDamaged($notes = null)
    {
        if ($this->status === 'active') {
            $this->update([
                'status' => 'damaged',
                'notes' => $notes ?? $this->notes
            ]);

            // Mettre à jour l'équipement
            if ($this->equipment) {
                $this->equipment->update([
                    'status' => 'broken',
                    'assigned_to' => null,
                    'updated_by' => $this->assigned_by
                ]);
            }

            return true;
        }
        return false;
    }

    // Méthodes statiques
    public static function getAssignmentStats()
    {
        $assignments = self::all();
        
        return [
            'total_assignments' => $assignments->count(),
            'active_assignments' => $assignments->where('status', 'active')->count(),
            'returned_assignments' => $assignments->where('status', 'returned')->count(),
            'lost_assignments' => $assignments->where('status', 'lost')->count(),
            'damaged_assignments' => $assignments->where('status', 'damaged')->count(),
            'average_duration' => $assignments->avg('duration') ?? 0,
            'assignments_by_status' => $assignments->groupBy('status')->map->count()
        ];
    }

    public static function getCurrentAssignments()
    {
        return self::active()->with(['equipment', 'user', 'assignedBy'])->get();
    }

    public static function getAssignmentsByUser($userId)
    {
        return self::byUser($userId)
            ->with(['equipment', 'assignedBy', 'returnedBy'])
            ->orderBy('assigned_date', 'desc')
            ->get();
    }

    public static function getAssignmentsByEquipment($equipmentId)
    {
        return self::byEquipment($equipmentId)
            ->with(['user', 'assignedBy', 'returnedBy'])
            ->orderBy('assigned_date', 'desc')
            ->get();
    }

    public static function getHistoricalAssignments()
    {
        return self::historical()->with(['equipment', 'user', 'assignedBy', 'returnedBy'])->get();
    }
}

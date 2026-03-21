<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class EquipmentMaintenance extends Model
{
    use HasFactory;

    protected $table = 'equipment_maintenance';

    protected $fillable = [
        'equipment_id',
        'type',
        'status',
        'description',
        'notes',
        'scheduled_date',
        'start_date',
        'end_date',
        'technician',
        'cost',
        'attachments',
        'created_by'
    ];

    protected $casts = [
        'scheduled_date' => 'datetime',
        'start_date' => 'datetime',
        'end_date' => 'datetime',
        'cost' => 'decimal:2',
        'attachments' => 'array'
    ];

    // Relations
    public function equipment()
    {
        return $this->belongsTo(EquipmentNew::class, 'equipment_id');
    }

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    // Scopes
    public function scopeScheduled($query)
    {
        return $query->where('status', 'scheduled');
    }

    public function scopeInProgress($query)
    {
        return $query->where('status', 'in_progress');
    }

    public function scopeCompleted($query)
    {
        return $query->where('status', 'completed');
    }

    public function scopeCancelled($query)
    {
        return $query->where('status', 'cancelled');
    }

    public function scopePreventive($query)
    {
        return $query->where('type', 'preventive');
    }

    public function scopeCorrective($query)
    {
        return $query->where('type', 'corrective');
    }

    public function scopeEmergency($query)
    {
        return $query->where('type', 'emergency');
    }

    public function scopeByEquipment($query, $equipmentId)
    {
        return $query->where('equipment_id', $equipmentId);
    }

    public function scopeByTechnician($query, $technician)
    {
        return $query->where('technician', $technician);
    }

    public function scopeOverdue($query)
    {
        return $query->where('status', 'scheduled')
                    ->where('scheduled_date', '<', now());
    }

    // Accesseurs
    public function getTypeLibelleAttribute()
    {
        $types = [
            'preventive' => 'Préventive',
            'corrective' => 'Corrective',
            'emergency' => 'Urgente'
        ];

        return $types[$this->type] ?? $this->type;
    }

    public function getStatusLibelleAttribute()
    {
        $statuses = [
            'scheduled' => 'Programmée',
            'in_progress' => 'En cours',
            'completed' => 'Terminée',
            'cancelled' => 'Annulée'
        ];

        return $statuses[$this->status] ?? $this->status;
    }

    public function getCreatorNameAttribute()
    {
        return $this->creator ? $this->creator->prenom . ' ' . $this->creator->nom : 'N/A';
    }

    public function getFormattedCostAttribute()
    {
        return $this->cost ? number_format($this->cost, 2, ',', ' ') . ' €' : 'N/A';
    }

    public function getDurationAttribute()
    {
        if ($this->start_date && $this->end_date) {
            return $this->start_date->diffInHours($this->end_date);
        }
        return null;
    }

    public function getIsOverdueAttribute()
    {
        return $this->status === 'scheduled' && $this->scheduled_date->isPast();
    }

    // Méthodes utilitaires
    public function start()
    {
        if ($this->status === 'scheduled') {
            $this->update([
                'status' => 'in_progress',
                'start_date' => now()
            ]);
            return true;
        }
        return false;
    }

    public function complete($notes = null, $cost = null)
    {
        if ($this->status === 'in_progress') {
            $this->update([
                'status' => 'completed',
                'end_date' => now(),
                'notes' => $notes ?? $this->notes,
                'cost' => $cost ?? $this->cost
            ]);

            // Mettre à jour l'équipement
            if ($this->equipment) {
                $this->equipment->updateMaintenance(
                    $this->end_date,
                    $this->end_date->addMonths(6) // Prochaine maintenance dans 6 mois
                );
            }

            return true;
        }
        return false;
    }

    public function cancel($reason = null)
    {
        if (in_array($this->status, ['scheduled', 'in_progress'])) {
            $this->update([
                'status' => 'cancelled',
                'notes' => $reason ?? $this->notes
            ]);
            return true;
        }
        return false;
    }

    public function addAttachment($attachmentPath)
    {
        $attachments = $this->attachments ?? [];
        $attachments[] = $attachmentPath;
        $this->update(['attachments' => $attachments]);
    }

    public function removeAttachment($attachmentPath)
    {
        $attachments = $this->attachments ?? [];
        $attachments = array_filter($attachments, function($attachment) use ($attachmentPath) {
            return $attachment !== $attachmentPath;
        });
        $this->update(['attachments' => array_values($attachments)]);
    }

    // Méthodes statiques
    public static function getMaintenanceStats($startDate = null, $endDate = null)
    {
        $query = self::query();
        
        if ($startDate && $endDate) {
            $query->whereBetween('scheduled_date', [$startDate, $endDate]);
        }

        $maintenance = $query->get();
        
        return [
            'total_maintenance' => $maintenance->count(),
            'scheduled_maintenance' => $maintenance->where('status', 'scheduled')->count(),
            'in_progress_maintenance' => $maintenance->where('status', 'in_progress')->count(),
            'completed_maintenance' => $maintenance->where('status', 'completed')->count(),
            'cancelled_maintenance' => $maintenance->where('status', 'cancelled')->count(),
            'preventive_maintenance' => $maintenance->where('type', 'preventive')->count(),
            'corrective_maintenance' => $maintenance->where('type', 'corrective')->count(),
            'emergency_maintenance' => $maintenance->where('type', 'emergency')->count(),
            'overdue_maintenance' => $maintenance->filter(function ($m) {
                return $m->is_overdue;
            })->count(),
            'total_cost' => $maintenance->sum('cost'),
            'average_cost' => $maintenance->avg('cost') ?? 0,
            'maintenance_by_type' => $maintenance->groupBy('type')->map->count(),
            'maintenance_by_status' => $maintenance->groupBy('status')->map->count()
        ];
    }

    public static function getOverdueMaintenance()
    {
        return self::overdue()->with(['equipment', 'creator'])->get();
    }

    public static function getMaintenanceByEquipment($equipmentId)
    {
        return self::byEquipment($equipmentId)
            ->with(['creator'])
            ->orderBy('scheduled_date', 'desc')
            ->get();
    }

    public static function getMaintenanceByTechnician($technician)
    {
        return self::byTechnician($technician)
            ->with(['equipment', 'creator'])
            ->orderBy('scheduled_date', 'desc')
            ->get();
    }
}

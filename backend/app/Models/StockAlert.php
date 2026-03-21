<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class StockAlert extends Model
{
    use HasFactory;

    protected $fillable = [
        'stock_id',
        'type',
        'status',
        'message',
    ];

    protected $casts = [
        // Pas de casts nécessaires selon la migration
    ];

    // Relations
    public function stock()
    {
        return $this->belongsTo(Stock::class);
    }

    public function acknowledgedBy()
    {
        return $this->belongsTo(User::class, 'acknowledged_by');
    }

    public function resolvedBy()
    {
        return $this->belongsTo(User::class, 'resolved_by');
    }

    // Scopes
    public function scopeActive($query)
    {
        return $query->where('status', 'active');
    }

    public function scopeAcknowledged($query)
    {
        return $query->where('status', 'acknowledged');
    }

    public function scopeResolved($query)
    {
        return $query->where('status', 'resolved');
    }

    public function scopeDismissed($query)
    {
        return $query->where('status', 'dismissed');
    }

    public function scopeByType($query, $type)
    {
        return $query->where('type', $type);
    }

    public function scopeByPriority($query, $priority)
    {
        return $query->where('priority', $priority);
    }

    public function scopeByStock($query, $stockId)
    {
        return $query->where('stock_id', $stockId);
    }

    public function scopeLowStock($query)
    {
        return $query->where('type', 'low_stock');
    }

    public function scopeOutOfStock($query)
    {
        return $query->where('type', 'out_of_stock');
    }

    public function scopeOverstock($query)
    {
        return $query->where('type', 'overstock');
    }

    public function scopeExpiry($query)
    {
        return $query->where('type', 'expiry');
    }

    public function scopeReorder($query)
    {
        return $query->where('type', 'reorder');
    }

    public function scopeUrgent($query)
    {
        return $query->where('priority', 'urgent');
    }

    public function scopeHigh($query)
    {
        return $query->where('priority', 'high');
    }

    public function scopeMedium($query)
    {
        return $query->where('priority', 'medium');
    }

    public function scopeLow($query)
    {
        return $query->where('priority', 'low');
    }

    // Accesseurs
    public function getTypeLibelleAttribute()
    {
        $types = [
            'low_stock' => 'Stock faible',
            'out_of_stock' => 'Stock épuisé',
            'overstock' => 'Stock excédentaire',
            'expiry' => 'Expiration',
            'reorder' => 'Réapprovisionnement'
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

    public function getStatusLibelleAttribute()
    {
        $statuses = [
            'active' => 'Active',
            'acknowledged' => 'Acquittée',
            'resolved' => 'Résolue',
            'dismissed' => 'Rejetée'
        ];

        return $statuses[$this->status] ?? $this->status;
    }

    public function getAcknowledgedByNameAttribute()
    {
        if (!$this->relationLoaded('acknowledgedBy') || !$this->acknowledgedBy) {
            return 'N/A';
        }
        return trim(($this->acknowledgedBy->prenom ?? '') . ' ' . ($this->acknowledgedBy->nom ?? '')) ?: 'N/A';
    }

    public function getResolvedByNameAttribute()
    {
        if (!$this->relationLoaded('resolvedBy') || !$this->resolvedBy) {
            return 'N/A';
        }
        return trim(($this->resolvedBy->prenom ?? '') . ' ' . ($this->resolvedBy->nom ?? '')) ?: 'N/A';
    }

    public function getIsActiveAttribute()
    {
        return $this->status === 'active';
    }

    public function getIsAcknowledgedAttribute()
    {
        return $this->status === 'acknowledged';
    }

    public function getIsResolvedAttribute()
    {
        return $this->status === 'resolved';
    }

    public function getIsDismissedAttribute()
    {
        return $this->status === 'dismissed';
    }

    public function getDurationAttribute()
    {
        if ($this->resolved_at) {
            return $this->triggered_at->diffInHours($this->resolved_at);
        }
        return $this->triggered_at->diffInHours(now());
    }

    // Méthodes utilitaires
    public function acknowledge($userId, $notes = null)
    {
        $this->update([
            'status' => 'acknowledged',
            'acknowledged_at' => now(),
            'acknowledged_by' => $userId,
            'notes' => $notes ?? $this->notes
        ]);
    }

    public function resolve($userId, $notes = null)
    {
        $this->update([
            'status' => 'resolved',
            'resolved_at' => now(),
            'resolved_by' => $userId,
            'notes' => $notes ?? $this->notes
        ]);
    }

    public function dismiss($userId, $notes = null)
    {
        $this->update([
            'status' => 'dismissed',
            'notes' => $notes ?? $this->notes
        ]);
    }

    // Méthodes statiques
    public static function getAlertStats()
    {
        $alerts = self::all();
        
        return [
            'total_alerts' => $alerts->count(),
            'active_alerts' => $alerts->where('status', 'active')->count(),
            'acknowledged_alerts' => $alerts->where('status', 'acknowledged')->count(),
            'resolved_alerts' => $alerts->where('status', 'resolved')->count(),
            'dismissed_alerts' => $alerts->where('status', 'dismissed')->count(),
            'low_stock_alerts' => $alerts->where('type', 'low_stock')->count(),
            'out_of_stock_alerts' => $alerts->where('type', 'out_of_stock')->count(),
            'overstock_alerts' => $alerts->where('type', 'overstock')->count(),
            'expiry_alerts' => $alerts->where('type', 'expiry')->count(),
            'reorder_alerts' => $alerts->where('type', 'reorder')->count(),
            'urgent_alerts' => $alerts->where('priority', 'urgent')->count(),
            'high_alerts' => $alerts->where('priority', 'high')->count(),
            'medium_alerts' => $alerts->where('priority', 'medium')->count(),
            'low_alerts' => $alerts->where('priority', 'low')->count(),
            'alerts_by_type' => $alerts->groupBy('type')->map->count(),
            'alerts_by_priority' => $alerts->groupBy('priority')->map->count(),
            'alerts_by_status' => $alerts->groupBy('status')->map->count()
        ];
    }

    public static function getActiveAlerts()
    {
        return self::active()->with(['stock', 'acknowledgedBy', 'resolvedBy'])->get();
    }

    public static function getAlertsByType($type)
    {
        return self::byType($type)->with(['stock', 'acknowledgedBy', 'resolvedBy'])->get();
    }

    public static function getAlertsByPriority($priority)
    {
        return self::byPriority($priority)->with(['stock', 'acknowledgedBy', 'resolvedBy'])->get();
    }

    public static function getAlertsByStock($stockId)
    {
        return self::byStock($stockId)
            ->with(['acknowledgedBy', 'resolvedBy'])
            ->orderBy('triggered_at', 'desc')
            ->get();
    }

    public static function getUrgentAlerts()
    {
        return self::urgent()->with(['stock', 'acknowledgedBy', 'resolvedBy'])->get();
    }

    public static function getHighPriorityAlerts()
    {
        return self::high()->with(['stock', 'acknowledgedBy', 'resolvedBy'])->get();
    }
}

<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class StockMovement extends Model
{
    use HasFactory;

    protected $fillable = [
        'stock_id',
        'type',
        'reason',
        'quantity',
        'unit_cost',
        'total_cost',
        'reference',
        'location_from',
        'location_to',
        'notes',
        'attachments',
        'created_by'
    ];

    protected $casts = [
        'quantity' => 'decimal:3',
        'unit_cost' => 'decimal:2',
        'total_cost' => 'decimal:2',
        'attachments' => 'array'
    ];

    // Relations
    public function stock()
    {
        return $this->belongsTo(Stock::class);
    }

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    // Scopes
    public function scopeIn($query)
    {
        return $query->where('type', 'in');
    }

    public function scopeOut($query)
    {
        return $query->where('type', 'out');
    }

    public function scopeTransfer($query)
    {
        return $query->where('type', 'transfer');
    }

    public function scopeAdjustment($query)
    {
        return $query->where('type', 'adjustment');
    }

    public function scopeReturn($query)
    {
        return $query->where('type', 'return');
    }

    public function scopeByStock($query, $stockId)
    {
        return $query->where('stock_id', $stockId);
    }

    public function scopeByReason($query, $reason)
    {
        return $query->where('reason', $reason);
    }

    public function scopeByDateRange($query, $startDate, $endDate)
    {
        return $query->whereBetween('created_at', [$startDate, $endDate]);
    }

    // Accesseurs
    public function getTypeLibelleAttribute()
    {
        $types = [
            'in' => 'Entrée',
            'out' => 'Sortie',
            'transfer' => 'Transfert',
            'adjustment' => 'Ajustement',
            'return' => 'Retour'
        ];

        return $types[$this->type] ?? $this->type;
    }

    public function getReasonLibelleAttribute()
    {
        $reasons = [
            'purchase' => 'Achat',
            'sale' => 'Vente',
            'transfer' => 'Transfert',
            'adjustment' => 'Ajustement',
            'return' => 'Retour',
            'loss' => 'Perte',
            'damage' => 'Dommage',
            'expired' => 'Expiré',
            'other' => 'Autre'
        ];

        return $reasons[$this->reason] ?? $this->reason;
    }

    public function getCreatorNameAttribute()
    {
        if (!$this->relationLoaded('creator') || !$this->creator) {
            return 'N/A';
        }
        return trim(($this->creator->prenom ?? '') . ' ' . ($this->creator->nom ?? '')) ?: 'N/A';
    }

    public function getFormattedQuantityAttribute()
    {
        return number_format($this->quantity, 3, ',', ' ');
    }

    public function getFormattedUnitCostAttribute()
    {
        return $this->unit_cost ? number_format($this->unit_cost, 2, ',', ' ') . ' €' : 'N/A';
    }

    public function getFormattedTotalCostAttribute()
    {
        return $this->total_cost ? number_format($this->total_cost, 2, ',', ' ') . ' €' : 'N/A';
    }

    public function getIsInAttribute()
    {
        return $this->type === 'in';
    }

    public function getIsOutAttribute()
    {
        return $this->type === 'out';
    }

    public function getIsTransferAttribute()
    {
        return $this->type === 'transfer';
    }

    public function getIsAdjustmentAttribute()
    {
        return $this->type === 'adjustment';
    }

    public function getIsReturnAttribute()
    {
        return $this->type === 'return';
    }

    // Méthodes utilitaires
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
    public static function getMovementStats($startDate = null, $endDate = null)
    {
        $query = self::query();
        
        if ($startDate && $endDate) {
            $query->whereBetween('created_at', [$startDate, $endDate]);
        }

        $movements = $query->get();
        
        return [
            'total_movements' => $movements->count(),
            'in_movements' => $movements->where('type', 'in')->count(),
            'out_movements' => $movements->where('type', 'out')->count(),
            'transfer_movements' => $movements->where('type', 'transfer')->count(),
            'adjustment_movements' => $movements->where('type', 'adjustment')->count(),
            'return_movements' => $movements->where('type', 'return')->count(),
            'purchase_movements' => $movements->where('reason', 'purchase')->count(),
            'sale_movements' => $movements->where('reason', 'sale')->count(),
            'total_quantity_in' => $movements->where('type', 'in')->sum('quantity'),
            'total_quantity_out' => $movements->where('type', 'out')->sum('quantity'),
            'total_cost_in' => $movements->where('type', 'in')->sum('total_cost'),
            'total_cost_out' => $movements->where('type', 'out')->sum('total_cost'),
            'movements_by_type' => $movements->groupBy('type')->map->count(),
            'movements_by_reason' => $movements->groupBy('reason')->map->count()
        ];
    }

    public static function getMovementsByStock($stockId)
    {
        return self::byStock($stockId)
            ->with(['creator'])
            ->orderBy('created_at', 'desc')
            ->get();
    }

    public static function getMovementsByDateRange($startDate, $endDate)
    {
        return self::byDateRange($startDate, $endDate)
            ->with(['stock', 'creator'])
            ->orderBy('created_at', 'desc')
            ->get();
    }

    public static function getRecentMovements($limit = 50)
    {
        return self::with(['stock', 'creator'])
            ->orderBy('created_at', 'desc')
            ->limit($limit)
            ->get();
    }
}

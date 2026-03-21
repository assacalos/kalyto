<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class StockOrderItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'stock_order_id',
        'stock_id',
        'quantity',
        'unit_cost',
        'total_cost',
        'received_quantity',
        'notes'
    ];

    protected $casts = [
        'quantity' => 'decimal:3',
        'unit_cost' => 'decimal:2',
        'total_cost' => 'decimal:2',
        'received_quantity' => 'decimal:3'
    ];

    // Relations
    public function stockOrder()
    {
        return $this->belongsTo(StockOrder::class);
    }

    public function stock()
    {
        return $this->belongsTo(Stock::class);
    }

    // Accesseurs
    public function getFormattedQuantityAttribute()
    {
        return number_format($this->quantity, 3, ',', ' ');
    }

    public function getFormattedReceivedQuantityAttribute()
    {
        return number_format($this->received_quantity, 3, ',', ' ');
    }

    public function getFormattedUnitCostAttribute()
    {
        return number_format($this->unit_cost, 2, ',', ' ') . ' €';
    }

    public function getFormattedTotalCostAttribute()
    {
        return number_format($this->total_cost, 2, ',', ' ') . ' €';
    }

    public function getRemainingQuantityAttribute()
    {
        return $this->quantity - $this->received_quantity;
    }

    public function getCompletionRateAttribute()
    {
        if ($this->quantity == 0) return 0;
        return ($this->received_quantity / $this->quantity) * 100;
    }

    public function getIsFullyReceivedAttribute()
    {
        return $this->received_quantity >= $this->quantity;
    }

    public function getIsPartiallyReceivedAttribute()
    {
        return $this->received_quantity > 0 && $this->received_quantity < $this->quantity;
    }

    public function getIsNotReceivedAttribute()
    {
        return $this->received_quantity == 0;
    }

    // Méthodes utilitaires
    public function receive($quantity, $notes = null)
    {
        if ($quantity > $this->remaining_quantity) {
            throw new \Exception('Quantité reçue supérieure à la quantité restante');
        }

        $this->update([
            'received_quantity' => $this->received_quantity + $quantity,
            'notes' => $notes ?? $this->notes
        ]);

        // Mettre à jour le stock
        $this->stock->addStock($quantity, $this->unit_cost, 'purchase', $this->stockOrder->order_number, $notes);

        return $this;
    }

    public function adjustReceivedQuantity($newQuantity, $notes = null)
    {
        if ($newQuantity < 0 || $newQuantity > $this->quantity) {
            throw new \Exception('Quantité reçue invalide');
        }

        $difference = $newQuantity - $this->received_quantity;
        
        if ($difference > 0) {
            // Ajouter la différence au stock
            $this->stock->addStock($difference, $this->unit_cost, 'purchase', $this->stockOrder->order_number, $notes);
        } elseif ($difference < 0) {
            // Retirer la différence du stock
            $this->stock->removeStock(abs($difference), 'adjustment', $this->stockOrder->order_number, $notes);
        }

        $this->update([
            'received_quantity' => $newQuantity,
            'notes' => $notes ?? $this->notes
        ]);

        return $this;
    }

    // Méthodes statiques
    public static function getItemStats($startDate = null, $endDate = null)
    {
        $query = self::query();
        
        if ($startDate && $endDate) {
            $query->whereHas('stockOrder', function ($q) use ($startDate, $endDate) {
                $q->whereBetween('order_date', [$startDate, $endDate]);
            });
        }

        $items = $query->get();
        
        return [
            'total_items' => $items->count(),
            'fully_received' => $items->filter(function ($item) {
                return $item->is_fully_received;
            })->count(),
            'partially_received' => $items->filter(function ($item) {
                return $item->is_partially_received;
            })->count(),
            'not_received' => $items->filter(function ($item) {
                return $item->is_not_received;
            })->count(),
            'total_quantity' => $items->sum('quantity'),
            'total_received_quantity' => $items->sum('received_quantity'),
            'total_cost' => $items->sum('total_cost'),
            'average_completion_rate' => $items->avg('completion_rate') ?? 0
        ];
    }

    public static function getItemsByOrder($orderId)
    {
        return self::where('stock_order_id', $orderId)
            ->with(['stock'])
            ->orderBy('id')
            ->get();
    }

    public static function getItemsByStock($stockId)
    {
        return self::where('stock_id', $stockId)
            ->with(['stockOrder'])
            ->orderBy('created_at', 'desc')
            ->get();
    }

    public static function getPendingItems()
    {
        return self::whereRaw('received_quantity < quantity')
            ->with(['stock', 'stockOrder'])
            ->get();
    }

    public static function getOverdueItems()
    {
        return self::whereHas('stockOrder', function ($query) {
            $query->where('status', 'sent')
                  ->where('expected_date', '<', now());
        })->with(['stock', 'stockOrder'])->get();
    }
}

<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class StockOrder extends Model
{
    use HasFactory;

    protected $fillable = [
        'order_number',
        'supplier',
        'status',
        'order_date',
        'expected_date',
        'received_date',
        'total_amount',
        'notes',
        'attachments',
        'created_by',
        'approved_by',
        'approved_at'
    ];

    protected $casts = [
        'order_date' => 'date',
        'expected_date' => 'date',
        'received_date' => 'date',
        'total_amount' => 'decimal:2',
        'attachments' => 'array',
        'approved_at' => 'datetime'
    ];

    // Relations
    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function approver()
    {
        return $this->belongsTo(User::class, 'approved_by');
    }

    public function items()
    {
        return $this->hasMany(StockOrderItem::class);
    }

    // Scopes
    public function scopeDraft($query)
    {
        return $query->where('status', 'draft');
    }

    public function scopeSent($query)
    {
        return $query->where('status', 'sent');
    }

    public function scopeConfirmed($query)
    {
        return $query->where('status', 'confirmed');
    }

    public function scopeReceived($query)
    {
        return $query->where('status', 'received');
    }

    public function scopeCancelled($query)
    {
        return $query->where('status', 'cancelled');
    }

    public function scopeBySupplier($query, $supplier)
    {
        return $query->where('supplier', $supplier);
    }

    public function scopeByDateRange($query, $startDate, $endDate)
    {
        return $query->whereBetween('order_date', [$startDate, $endDate]);
    }

    public function scopeOverdue($query)
    {
        return $query->where('status', 'sent')
                    ->where('expected_date', '<', now());
    }

    // Accesseurs
    public function getStatusLibelleAttribute()
    {
        $statuses = [
            'draft' => 'Brouillon',
            'sent' => 'Envoyée',
            'confirmed' => 'Confirmée',
            'received' => 'Reçue',
            'cancelled' => 'Annulée'
        ];

        return $statuses[$this->status] ?? $this->status;
    }

    public function getCreatorNameAttribute()
    {
        if (!$this->relationLoaded('creator') || !$this->creator) {
            return 'N/A';
        }
        return trim(($this->creator->prenom ?? '') . ' ' . ($this->creator->nom ?? '')) ?: 'N/A';
    }

    public function getApproverNameAttribute()
    {
        if (!$this->relationLoaded('approver') || !$this->approver) {
            return 'N/A';
        }
        return trim(($this->approver->prenom ?? '') . ' ' . ($this->approver->nom ?? '')) ?: 'N/A';
    }

    public function getFormattedTotalAmountAttribute()
    {
        return number_format($this->total_amount, 2, ',', ' ') . ' €';
    }

    public function getIsDraftAttribute()
    {
        return $this->status === 'draft';
    }

    public function getIsSentAttribute()
    {
        return $this->status === 'sent';
    }

    public function getIsConfirmedAttribute()
    {
        return $this->status === 'confirmed';
    }

    public function getIsReceivedAttribute()
    {
        return $this->status === 'received';
    }

    public function getIsCancelledAttribute()
    {
        return $this->status === 'cancelled';
    }

    public function getIsOverdueAttribute()
    {
        return $this->status === 'sent' && $this->expected_date && $this->expected_date->isPast();
    }

    public function getItemsCountAttribute()
    {
        return $this->items->count();
    }

    public function getTotalQuantityAttribute()
    {
        return $this->items->sum('quantity');
    }

    public function getReceivedQuantityAttribute()
    {
        return $this->items->sum('received_quantity');
    }

    public function getCompletionRateAttribute()
    {
        if ($this->total_quantity == 0) return 0;
        return ($this->received_quantity / $this->total_quantity) * 100;
    }

    // Méthodes utilitaires
    public function approve($userId)
    {
        $this->update([
            'status' => 'sent',
            'approved_by' => $userId,
            'approved_at' => now()
        ]);
    }

    public function confirm()
    {
        $this->update(['status' => 'confirmed']);
    }

    public function receive($receivedDate = null)
    {
        $this->update([
            'status' => 'received',
            'received_date' => $receivedDate ?? now()
        ]);
    }

    public function cancel($reason = null)
    {
        $this->update([
            'status' => 'cancelled',
            'notes' => $reason ?? $this->notes
        ]);
    }

    public function addItem($stockId, $quantity, $unitCost, $notes = null)
    {
        return StockOrderItem::create([
            'stock_order_id' => $this->id,
            'stock_id' => $stockId,
            'quantity' => $quantity,
            'unit_cost' => $unitCost,
            'total_cost' => $quantity * $unitCost,
            'notes' => $notes
        ]);
    }

    public function updateTotalAmount()
    {
        $total = $this->items->sum('total_cost');
        $this->update(['total_amount' => $total]);
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
    public static function generateOrderNumber()
    {
        $count = self::count() + 1;
        return 'CMD-' . date('Y') . '-' . str_pad($count, 4, '0', STR_PAD_LEFT);
    }

    public static function getOrderStats($startDate = null, $endDate = null)
    {
        $query = self::query();
        
        if ($startDate && $endDate) {
            $query->whereBetween('order_date', [$startDate, $endDate]);
        }

        $orders = $query->get();
        
        return [
            'total_orders' => $orders->count(),
            'draft_orders' => $orders->where('status', 'draft')->count(),
            'sent_orders' => $orders->where('status', 'sent')->count(),
            'confirmed_orders' => $orders->where('status', 'confirmed')->count(),
            'received_orders' => $orders->where('status', 'received')->count(),
            'cancelled_orders' => $orders->where('status', 'cancelled')->count(),
            'overdue_orders' => $orders->filter(function ($order) {
                return $order->is_overdue;
            })->count(),
            'total_amount' => $orders->sum('total_amount'),
            'average_amount' => $orders->avg('total_amount') ?? 0,
            'orders_by_status' => $orders->groupBy('status')->map->count(),
            'orders_by_supplier' => $orders->groupBy('supplier')->map->count()
        ];
    }

    public static function getOrdersBySupplier($supplier)
    {
        return self::bySupplier($supplier)
            ->with(['creator', 'approver', 'items.stock'])
            ->orderBy('order_date', 'desc')
            ->get();
    }

    public static function getOverdueOrders()
    {
        return self::overdue()->with(['creator', 'approver', 'items.stock'])->get();
    }

    public static function getRecentOrders($limit = 50)
    {
        return self::with(['creator', 'approver', 'items.stock'])
            ->orderBy('order_date', 'desc')
            ->limit($limit)
            ->get();
    }
}

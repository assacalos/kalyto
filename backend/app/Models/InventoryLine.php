<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class InventoryLine extends Model
{
    use HasFactory;

    protected $fillable = ['inventory_session_id', 'stock_id', 'theoretical_qty', 'counted_qty'];

    protected $casts = [
        'theoretical_qty' => 'decimal:2',
        'counted_qty' => 'decimal:2',
    ];

    public function session()
    {
        return $this->belongsTo(InventorySession::class, 'inventory_session_id');
    }

    public function stock()
    {
        return $this->belongsTo(Stock::class);
    }

    public function getSkuAttribute(): ?string
    {
        return $this->stock?->sku;
    }

    public function getProductNameAttribute(): ?string
    {
        return $this->stock?->name;
    }

    public function getUnitAttribute(): string
    {
        return $this->stock?->unit ?? 'pièce';
    }
}

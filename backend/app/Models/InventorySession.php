<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class InventorySession extends Model
{
    use HasFactory;

    protected $fillable = ['company_id', 'date', 'depot', 'status', 'closed_at'];

    protected $casts = [
        'date' => 'date',
        'closed_at' => 'datetime',
    ];

    public const STATUS_IN_PROGRESS = 'in_progress';
    public const STATUS_CLOSED = 'closed';

    public function lines()
    {
        return $this->hasMany(InventoryLine::class, 'inventory_session_id');
    }

    public function scopeInProgress($query)
    {
        return $query->where('status', self::STATUS_IN_PROGRESS);
    }

    public function scopeClosed($query)
    {
        return $query->where('status', self::STATUS_CLOSED);
    }

    public function getLinesCountAttribute()
    {
        return $this->lines()->count();
    }

    public function isClosed(): bool
    {
        return $this->status === self::STATUS_CLOSED;
    }
}

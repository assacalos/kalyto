<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Equipment extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'model',
        'serial_number',
        'brand',
        'description',
        'status',
        'purchase_date',
        'warranty_end_date',
        'location',
        'purchase_price',
        'specifications',
        'maintenance_history'
    ];

    protected $casts = [
        'purchase_date' => 'date',
        'warranty_end_date' => 'date',
        'purchase_price' => 'decimal:2',
        'specifications' => 'array',
        'maintenance_history' => 'array'
    ];

    // Scopes
    public function scopeActive($query)
    {
        return $query->where('status', 'active');
    }

    public function scopeMaintenance($query)
    {
        return $query->where('status', 'maintenance');
    }

    public function scopeOutOfOrder($query)
    {
        return $query->where('status', 'out_of_order');
    }

    public function scopeRetired($query)
    {
        return $query->where('status', 'retired');
    }

    public function scopeByLocation($query, $location)
    {
        return $query->where('location', $location);
    }

    public function scopeByBrand($query, $brand)
    {
        return $query->where('brand', $brand);
    }

    // Accesseurs
    public function getStatusLibelleAttribute()
    {
        $statuses = [
            'active' => 'Actif',
            'maintenance' => 'En maintenance',
            'out_of_order' => 'Hors service',
            'retired' => 'Retiré'
        ];

        return $statuses[$this->status] ?? $this->status;
    }

    public function getFormattedPurchasePriceAttribute()
    {
        return $this->purchase_price ? number_format($this->purchase_price, 2, ',', ' ') . ' €' : 'N/A';
    }

    public function getIsUnderWarrantyAttribute()
    {
        if (!$this->warranty_end_date) return false;
        return now()->isBefore($this->warranty_end_date);
    }

    public function getWarrantyDaysRemainingAttribute()
    {
        if (!$this->warranty_end_date || !$this->is_under_warranty) return 0;
        return now()->diffInDays($this->warranty_end_date, false);
    }

    // Méthodes utilitaires
    public function addMaintenanceRecord($record)
    {
        $history = $this->maintenance_history ?? [];
        $history[] = array_merge($record, ['date' => now()->toISOString()]);
        $this->update(['maintenance_history' => $history]);
    }

    public function setStatus($status)
    {
        $this->update(['status' => $status]);
    }

    // Méthodes statiques
    public static function getActiveEquipment()
    {
        return self::active()->orderBy('name')->get();
    }

    public static function getEquipmentByLocation($location)
    {
        return self::byLocation($location)->orderBy('name')->get();
    }

    public static function getEquipmentByBrand($brand)
    {
        return self::byBrand($brand)->orderBy('name')->get();
    }

    public static function getEquipmentStats()
    {
        return [
            'total_equipment' => self::count(),
            'active_equipment' => self::active()->count(),
            'maintenance_equipment' => self::maintenance()->count(),
            'out_of_order_equipment' => self::outOfOrder()->count(),
            'retired_equipment' => self::retired()->count(),
            'under_warranty' => self::where('warranty_end_date', '>', now())->count(),
            'total_value' => self::sum('purchase_price')
        ];
    }
}

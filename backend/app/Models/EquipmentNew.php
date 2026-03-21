<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class EquipmentNew extends Model
{
    use HasFactory;

    protected $table = 'equipment_new';

    protected $fillable = [
        'name',
        'description',
        'category',
        'status',
        'condition',
        'serial_number',
        'model',
        'brand',
        'location',
        'department',
        'assigned_to',
        'purchase_date',
        'warranty_expiry',
        'last_maintenance',
        'next_maintenance',
        'purchase_price',
        'current_value',
        'supplier',
        'notes',
        'attachments',
        'created_by',
        'updated_by'
    ];

    protected $casts = [
        'purchase_date' => 'date',
        'warranty_expiry' => 'date',
        'last_maintenance' => 'date',
        'next_maintenance' => 'date',
        'purchase_price' => 'decimal:2',
        'current_value' => 'decimal:2',
        'attachments' => 'array'
    ];

    // Relations
    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function updater()
    {
        return $this->belongsTo(User::class, 'updated_by');
    }

    public function maintenance()
    {
        return $this->hasMany(EquipmentMaintenance::class, 'equipment_id');
    }

    public function assignments()
    {
        return $this->hasMany(EquipmentAssignment::class, 'equipment_id');
    }

    public function categoryInfo()
    {
        return $this->belongsTo(EquipmentCategory::class, 'category', 'name');
    }

    // Scopes
    public function scopeActive($query)
    {
        return $query->where('status', 'active');
    }

    public function scopeInactive($query)
    {
        return $query->where('status', 'inactive');
    }

    public function scopeInMaintenance($query)
    {
        return $query->where('status', 'maintenance');
    }

    public function scopeBroken($query)
    {
        return $query->where('status', 'broken');
    }

    public function scopeRetired($query)
    {
        return $query->where('status', 'retired');
    }

    public function scopeByCategory($query, $category)
    {
        return $query->where('category', $category);
    }

    public function scopeByLocation($query, $location)
    {
        return $query->where('location', $location);
    }

    public function scopeByDepartment($query, $department)
    {
        return $query->where('department', $department);
    }

    public function scopeByBrand($query, $brand)
    {
        return $query->where('brand', $brand);
    }

    public function scopeByCondition($query, $condition)
    {
        return $query->where('condition', $condition);
    }

    public function scopeNeedsMaintenance($query)
    {
        return $query->where('next_maintenance', '<=', now());
    }

    public function scopeWarrantyExpired($query)
    {
        return $query->where('warranty_expiry', '<', now());
    }

    public function scopeWarrantyExpiringSoon($query)
    {
        $soon = now()->addDays(30);
        return $query->where('warranty_expiry', '<=', $soon)
                    ->where('warranty_expiry', '>', now());
    }

    // Accesseurs
    public function getStatusLibelleAttribute()
    {
        $statuses = [
            'active' => 'Actif',
            'inactive' => 'Inactif',
            'maintenance' => 'En maintenance',
            'broken' => 'Hors service',
            'retired' => 'Retiré'
        ];

        return $statuses[$this->status] ?? $this->status;
    }

    public function getConditionLibelleAttribute()
    {
        $conditions = [
            'excellent' => 'Excellent',
            'good' => 'Bon',
            'fair' => 'Correct',
            'poor' => 'Mauvais',
            'critical' => 'Critique'
        ];

        return $conditions[$this->condition] ?? $this->condition;
    }

    public function getCreatorNameAttribute()
    {
        return $this->creator ? $this->creator->prenom . ' ' . $this->creator->nom : 'N/A';
    }

    public function getUpdaterNameAttribute()
    {
        return $this->updater ? $this->updater->prenom . ' ' . $this->updater->nom : 'N/A';
    }

    public function getFormattedPurchasePriceAttribute()
    {
        return $this->purchase_price ? number_format($this->purchase_price, 2, ',', ' ') . ' €' : 'N/A';
    }

    public function getFormattedCurrentValueAttribute()
    {
        return $this->current_value ? number_format($this->current_value, 2, ',', ' ') . ' €' : 'N/A';
    }

    public function getIsWarrantyExpiredAttribute()
    {
        if (!$this->warranty_expiry) return false;
        return now()->isAfter($this->warranty_expiry);
    }

    public function getIsWarrantyExpiringSoonAttribute()
    {
        if (!$this->warranty_expiry) return false;
        $soon = now()->addDays(30);
        return $this->warranty_expiry->isBefore($soon) && $this->warranty_expiry->isAfter(now());
    }

    public function getNeedsMaintenanceAttribute()
    {
        if (!$this->next_maintenance) return false;
        return now()->isAfter($this->next_maintenance);
    }

    public function getAgeInYearsAttribute()
    {
        if (!$this->purchase_date) return null;
        return $this->purchase_date->diffInYears(now());
    }

    public function getDepreciationRateAttribute()
    {
        if (!$this->purchase_price || !$this->current_value || $this->purchase_price == 0) return null;
        return (($this->purchase_price - $this->current_value) / $this->purchase_price) * 100;
    }

    // Méthodes utilitaires
    public function assignTo($userId, $assignedBy, $notes = null)
    {
        EquipmentAssignment::create([
            'equipment_id' => $this->id,
            'user_id' => $userId,
            'assigned_date' => now(),
            'status' => 'active',
            'notes' => $notes,
            'assigned_by' => $assignedBy
        ]);

        $this->update([
            'assigned_to' => User::find($userId)->prenom . ' ' . User::find($userId)->nom,
            'updated_by' => $assignedBy
        ]);
    }

    public function returnFrom($returnedBy, $notes = null)
    {
        $assignment = $this->assignments()->where('status', 'active')->first();
        if ($assignment) {
            $assignment->update([
                'status' => 'returned',
                'return_date' => now(),
                'returned_by' => $returnedBy,
                'notes' => $notes
            ]);
        }

        $this->update([
            'assigned_to' => null,
            'updated_by' => $returnedBy
        ]);
    }

    public function scheduleMaintenance($type, $description, $scheduledDate, $technician = null, $createdBy)
    {
        return EquipmentMaintenance::create([
            'equipment_id' => $this->id,
            'type' => $type,
            'description' => $description,
            'scheduled_date' => $scheduledDate,
            'technician' => $technician,
            'created_by' => $createdBy
        ]);
    }

    public function updateMaintenance($lastMaintenance, $nextMaintenance = null)
    {
        $this->update([
            'last_maintenance' => $lastMaintenance,
            'next_maintenance' => $nextMaintenance
        ]);
    }

    // Méthodes statiques
    public static function getEquipmentStats()
    {
        $equipment = self::all();
        
        return [
            'total_equipment' => $equipment->count(),
            'active_equipment' => $equipment->where('status', 'active')->count(),
            'inactive_equipment' => $equipment->where('status', 'inactive')->count(),
            'maintenance_equipment' => $equipment->where('status', 'maintenance')->count(),
            'broken_equipment' => $equipment->where('status', 'broken')->count(),
            'retired_equipment' => $equipment->where('status', 'retired')->count(),
            'excellent_condition' => $equipment->where('condition', 'excellent')->count(),
            'good_condition' => $equipment->where('condition', 'good')->count(),
            'fair_condition' => $equipment->where('condition', 'fair')->count(),
            'poor_condition' => $equipment->where('condition', 'poor')->count(),
            'critical_condition' => $equipment->where('condition', 'critical')->count(),
            'needs_maintenance' => $equipment->filter(function ($eq) {
                return $eq->needs_maintenance;
            })->count(),
            'warranty_expired' => $equipment->filter(function ($eq) {
                return $eq->is_warranty_expired;
            })->count(),
            'warranty_expiring_soon' => $equipment->filter(function ($eq) {
                return $eq->is_warranty_expiring_soon;
            })->count(),
            'total_value' => $equipment->sum('current_value'),
            'average_age' => $equipment->filter(function ($eq) {
                return $eq->age_in_years !== null;
            })->avg('age_in_years') ?? 0,
            'equipment_by_category' => $equipment->groupBy('category')->map->count(),
            'equipment_by_status' => $equipment->groupBy('status')->map->count(),
            'equipment_by_condition' => $equipment->groupBy('condition')->map->count()
        ];
    }

    public static function getEquipmentByCategory($category)
    {
        return self::byCategory($category)->with(['creator', 'updater'])->get();
    }

    public static function getEquipmentByLocation($location)
    {
        return self::byLocation($location)->with(['creator', 'updater'])->get();
    }

    public static function getEquipmentByDepartment($department)
    {
        return self::byDepartment($department)->with(['creator', 'updater'])->get();
    }

    public static function getEquipmentByBrand($brand)
    {
        return self::byBrand($brand)->with(['creator', 'updater'])->get();
    }

    public static function getEquipmentNeedingMaintenance()
    {
        return self::needsMaintenance()->with(['creator', 'updater'])->get();
    }

    public static function getEquipmentWithExpiredWarranty()
    {
        return self::warrantyExpired()->with(['creator', 'updater'])->get();
    }

    public static function getEquipmentWithExpiringWarranty()
    {
        return self::warrantyExpiringSoon()->with(['creator', 'updater'])->get();
    }
}

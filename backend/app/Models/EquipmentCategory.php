<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class EquipmentCategory extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'description',
        'icon',
        'color',
        'is_active',
        'default_settings'
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'default_settings' => 'array'
    ];

    // Relations
    public function equipment()
    {
        return $this->hasMany(Equipment::class, 'category', 'name');
    }

    // Scopes
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    // Accesseurs
    public function getFormattedColorAttribute()
    {
        return $this->color ? '#' . ltrim($this->color, '#') : '#3B82F6';
    }

    // Méthodes utilitaires
    public function activate()
    {
        $this->update(['is_active' => true]);
    }

    public function deactivate()
    {
        $this->update(['is_active' => false]);
    }

    // Méthodes statiques
    public static function getActiveCategories()
    {
        return self::active()->orderBy('name')->get();
    }

    public static function getCategoryByName($name)
    {
        return self::where('name', $name)->active()->first();
    }

    public static function getCategoryStats()
    {
        $categories = self::active()->get();
        $stats = [];

        foreach ($categories as $category) {
            $equipmentCount = Equipment::where('category', $category->name)->count();
            $activeCount = Equipment::where('category', $category->name)->where('status', 'active')->count();
            $maintenanceCount = Equipment::where('category', $category->name)->where('status', 'maintenance')->count();
            $brokenCount = Equipment::where('category', $category->name)->where('status', 'broken')->count();

            $stats[] = [
                'category' => $category->name,
                'total_equipment' => $equipmentCount,
                'active_equipment' => $activeCount,
                'maintenance_equipment' => $maintenanceCount,
                'broken_equipment' => $brokenCount,
                'color' => $category->formatted_color
            ];
        }

        return $stats;
    }
}

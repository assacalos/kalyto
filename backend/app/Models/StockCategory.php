<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class StockCategory extends Model
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
    public function stocks()
    {
        return $this->hasMany(Stock::class, 'category', 'name');
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
            $stockCount = Stock::where('category', $category->name)->count();
            $activeCount = Stock::where('category', $category->name)->where('status', 'active')->count();
            $lowStockCount = Stock::where('category', $category->name)
                                ->whereRaw('current_quantity <= minimum_quantity')
                                ->count();
            $outOfStockCount = Stock::where('category', $category->name)
                                  ->where('current_quantity', 0)
                                  ->count();

            $stats[] = [
                'category' => $category->name,
                'total_stocks' => $stockCount,
                'active_stocks' => $activeCount,
                'low_stock' => $lowStockCount,
                'out_of_stock' => $outOfStockCount,
                'color' => $category->formatted_color
            ];
        }

        return $stats;
    }
}

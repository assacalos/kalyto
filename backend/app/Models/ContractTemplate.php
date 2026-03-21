<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ContractTemplate extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'description',
        'contract_type',
        'department',
        'content',
        'is_active',
        'created_by',
        'updated_by'
    ];

    protected $casts = [
        'is_active' => 'boolean'
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

    // Scopes
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    public function scopeInactive($query)
    {
        return $query->where('is_active', false);
    }

    public function scopeByType($query, $contractType)
    {
        return $query->where('contract_type', $contractType);
    }

    public function scopeByDepartment($query, $department)
    {
        return $query->where('department', $department);
    }

    public function scopeByTypeAndDepartment($query, $contractType, $department)
    {
        return $query->where('contract_type', $contractType)
                    ->where('department', $department);
    }

    // Accesseurs
    public function getContractTypeLibelleAttribute()
    {
        $types = [
            'permanent' => 'CDI',
            'fixed_term' => 'CDD',
            'temporary' => 'Intérim',
            'internship' => 'Stage',
            'consultant' => 'Consultant'
        ];

        return $types[$this->contract_type] ?? $this->contract_type;
    }

    public function getCreatorNameAttribute()
    {
        return $this->creator ? $this->creator->prenom . ' ' . $this->creator->nom : 'N/A';
    }

    public function getUpdaterNameAttribute()
    {
        return $this->updater ? $this->updater->prenom . ' ' . $this->updater->nom : 'N/A';
    }

    public function getIsActiveAttribute()
    {
        return $this->attributes['is_active'];
    }

    public function getIsInactiveAttribute()
    {
        return !$this->is_active;
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

    public function updateContent($newContent, $updatedBy = null)
    {
        $this->update([
            'content' => $newContent,
            'updated_by' => $updatedBy
        ]);
    }

    // Méthodes statiques
    public static function getTemplatesByType($contractType)
    {
        return self::byType($contractType)
            ->active()
            ->with(['creator', 'updater'])
            ->orderBy('name')
            ->get();
    }

    public static function getTemplatesByDepartment($department)
    {
        return self::byDepartment($department)
            ->active()
            ->with(['creator', 'updater'])
            ->orderBy('name')
            ->get();
    }

    public static function getTemplatesByTypeAndDepartment($contractType, $department)
    {
        return self::byTypeAndDepartment($contractType, $department)
            ->active()
            ->with(['creator', 'updater'])
            ->orderBy('name')
            ->get();
    }

    public static function getActiveTemplates()
    {
        return self::active()
            ->with(['creator', 'updater'])
            ->orderBy('name')
            ->get();
    }

    public static function getTemplateStats()
    {
        $templates = self::all();
        
        return [
            'total_templates' => $templates->count(),
            'active_templates' => $templates->where('is_active', true)->count(),
            'inactive_templates' => $templates->where('is_active', false)->count(),
            'templates_by_type' => $templates->groupBy('contract_type')->map->count(),
            'templates_by_department' => $templates->groupBy('department')->map->count()
        ];
    }
}

<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ContractClause extends Model
{
    use HasFactory;

    protected $fillable = [
        'contract_id',
        'title',
        'content',
        'type',
        'is_mandatory',
        'order'
    ];

    protected $casts = [
        'is_mandatory' => 'boolean'
    ];

    // Relations
    public function contract()
    {
        return $this->belongsTo(Contract::class);
    }

    // Scopes
    public function scopeByContract($query, $contractId)
    {
        return $query->where('contract_id', $contractId);
    }

    public function scopeByType($query, $type)
    {
        return $query->where('type', $type);
    }

    public function scopeMandatory($query)
    {
        return $query->where('is_mandatory', true);
    }

    public function scopeOptional($query)
    {
        return $query->where('is_mandatory', false);
    }

    public function scopeOrdered($query)
    {
        return $query->orderBy('order');
    }

    // Accesseurs
    public function getTypeLibelleAttribute()
    {
        $types = [
            'standard' => 'Standard',
            'custom' => 'Personnalisé',
            'legal' => 'Légal',
            'benefit' => 'Avantage'
        ];

        return $types[$this->type] ?? $this->type;
    }

    public function getIsMandatoryAttribute()
    {
        return $this->attributes['is_mandatory'];
    }

    public function getIsOptionalAttribute()
    {
        return !$this->is_mandatory;
    }

    // Méthodes utilitaires
    public function markAsMandatory()
    {
        $this->update(['is_mandatory' => true]);
    }

    public function markAsOptional()
    {
        $this->update(['is_mandatory' => false]);
    }

    public function reorder($newOrder)
    {
        $this->update(['order' => $newOrder]);
    }

    // Méthodes statiques
    public static function getClausesByContract($contractId)
    {
        return self::byContract($contractId)
            ->ordered()
            ->get();
    }

    public static function getClausesByType($type)
    {
        return self::byType($type)->with(['contract'])->get();
    }

    public static function getMandatoryClauses()
    {
        return self::mandatory()->with(['contract'])->get();
    }

    public static function getOptionalClauses()
    {
        return self::optional()->with(['contract'])->get();
    }
}

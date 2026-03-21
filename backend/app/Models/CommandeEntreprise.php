<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CommandeEntreprise extends Model
{
    use HasFactory;

    protected $table = 'commandes_entreprise';

    protected $fillable = [
        'client_id',
        'user_id',
        'status',
        'fichiers_scannes',
    ];

    protected $casts = [
        'status' => 'integer',
        'fichiers_scannes' => 'array',
    ];

    // Relations
    public function client()
    {
        return $this->belongsTo(Client::class);
    }

    public function commercial()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function items()
    {
        return $this->hasMany(CommandeItem::class, 'commande_entreprise_id');
    }

    // Accesseurs
    public function getStatusTextAttribute()
    {
        return match($this->status) {
            1 => 'En attente',
            2 => 'Validé',
            3 => 'Rejeté',
            4 => 'Livré',
            default => 'Inconnu',
        };
    }

    // Scopes
    public function scopeSoumis($query)
    {
        return $query->where('status', 1);
    }

    public function scopeValides($query)
    {
        return $query->where('status', 2);
    }

    public function scopeRejetes($query)
    {
        return $query->where('status', 3);
    }

    public function scopeLives($query)
    {
        return $query->where('status', 4);
    }
}

<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CommandeItem extends Model
{
    use HasFactory;

    protected $table = 'commande_items';

    protected $fillable = [
        'commande_entreprise_id',
        'designation',
        'unite',
        'quantite',
        'prix_unitaire',
        'description',
        'date_livraison',
    ];

    protected $casts = [
        'quantite' => 'integer',
        'prix_unitaire' => 'decimal:2',
        'date_livraison' => 'datetime',
    ];

    // Relations
    public function commandeEntreprise()
    {
        return $this->belongsTo(CommandeEntreprise::class, 'commande_entreprise_id');
    }

    // Accesseurs
    public function getMontantTotalAttribute()
    {
        return round($this->quantite * $this->prix_unitaire, 2);
    }
}

<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class BonDeCommandeItem extends Model
{
    use HasFactory;

    protected $table = 'bon_de_commande_items';

    protected $fillable = [
        'bon_de_commande_id',
        'ref',
        'designation',
        'quantite',
        'prix_unitaire',
        'description',
    ];

    protected $casts = [
        'quantite' => 'integer',
        'prix_unitaire' => 'decimal:2',
    ];

    // Relations
    public function bonDeCommande()
    {
        return $this->belongsTo(BonDeCommande::class, 'bon_de_commande_id');
    }

    // Accesseurs
    public function getMontantTotalAttribute()
    {
        return round($this->quantite * $this->prix_unitaire, 2);
    }
}

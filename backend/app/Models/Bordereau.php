<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Bordereau extends Model
{
    use HasFactory;

    protected $table = 'bordereaus';

    protected $fillable = [
        'company_id',
        'reference',
        'titre',
        'client_id',
        'devis_id',
        'user_id',
        'date_creation',
        'date_validation',
        'notes',
        'status',
        'commentaire',
        'etat_livraison',
        'garantie',
        'date_livraison',
    ];

    protected $casts = [
        'date_creation' => 'date',
        'date_validation' => 'date',
        'date_livraison' => 'date',
    ];

    public function client() {
        return $this->belongsTo(Client::class);
    }

    public function devis() {
        return $this->belongsTo(Devis::class);
    }

    public function user() {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function items() {
        return $this->hasMany(BordereauItem::class);
    }
}


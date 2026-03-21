<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class BordereauItem extends Model
{
    use HasFactory;

    protected $table = 'bordereau_items';

    protected $fillable = [
        'bordereau_id',
        'reference',
        'designation',
        'quantite',
        'description',
    ];

    public function bordereau() {
        return $this->belongsTo(Bordereau::class);
    }
}


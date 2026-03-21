<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Compte extends Model
{
    use HasFactory;

    protected $fillable = ['code', 'libelle', 'type', 'actif'];

    protected $casts = [
        'actif' => 'boolean',
    ];

    public function journalEntries()
    {
        return $this->hasMany(JournalEntry::class, 'compte_id');
    }

    public function scopeActifs($query)
    {
        return $query->where('actif', true);
    }
}

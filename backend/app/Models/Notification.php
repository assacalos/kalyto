<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class Notification extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'type',
        'titre',          // Colonne réelle en base
        'message',        // Colonne réelle en base
        'data',           // Colonne réelle en base (stocke le JSON)
        'statut',         // Colonne réelle en base (non_lue, lue)
        'priorite',       // Colonne réelle en base
        'canal',          // Colonne réelle en base
        'date_lecture',   // Colonne réelle en base
        'date_expiration',// Colonne réelle en base
        'envoyee',        // Colonne réelle en base
    ];

    protected $casts = [
        'data'            => 'array',
        'date_lecture'    => 'datetime',
        'date_expiration' => 'datetime',
        'envoyee'         => 'boolean',
        'created_at'      => 'datetime',
        'updated_at'      => 'datetime'
    ];

    /**
     * RELATION : Utilisateur
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * LOGIQUE : Marquer comme lue
     * Synchronise le statut et la date de lecture
     */
    public function marquerCommeLue()
    {
        $this->update([
            'statut' => 'lue',
            'date_lecture' => Carbon::now()
        ]);
    }

    /**
     * COMPATIBILITÉ FRONTEND : 
     * Pour éviter de modifier le code partout, on crée des "Accessors"
     * qui récupèrent les infos là où elles sont (dans la colonne titre ou dans le JSON data)
     */

    // Accesseur pour $notification->title
    public function getTitleAttribute()
    {
        return $this->titre;
    }

    // Accesseur pour $notification->is_read
    public function getIsReadAttribute()
    {
        return $this->statut === 'lue';
    }

    // Accesseur pour récupérer entity_type depuis le JSON data
    public function getEntityTypeAttribute()
    {
        return $this->data['entity_type'] ?? null;
    }

    // Accesseur pour récupérer entity_id depuis le JSON data
    public function getEntityIdAttribute()
    {
        return $this->data['entity_id'] ?? null;
    }

    /**
     * LIBELLÉS & TRADUCTIONS
     */
    public function getStatutLibelle()
    {
        return [
            'non_lue' => 'Non lue',
            'lue' => 'Lue',
            'archivee' => 'Archivée'
        ][$this->statut] ?? 'Inconnu';
    }

    public function getPrioriteLibelle()
    {
        return [
            'basse' => 'Basse',
            'normale' => 'Normale',
            'haute' => 'Haute',
            'urgente' => 'Urgente'
        ][$this->priorite] ?? 'Normale';
    }

    /**
     * SCOPES
     */
    public function scopeNonLues($query) { return $query->where('statut', 'non_lue'); }
    public function scopeLues($query) { return $query->where('statut', 'lue'); }
    public function scopePourUtilisateur($query, $userId) { return $query->where('user_id', $userId); }

    public function scopeNonExpirees($query)
    {
        return $query->where(function($q) {
            $q->whereNull('date_expiration')
              ->orWhere('date_expiration', '>', Carbon::now());
        });
    }
}
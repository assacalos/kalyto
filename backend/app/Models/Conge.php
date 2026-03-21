<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class Conge extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'type_conge',
        'date_debut',
        'date_fin',
        'nombre_jours',
        'motif',
        'statut',
        'commentaire_rh',
        'approuve_par',
        'date_approbation',
        'raison_rejet',
        'urgent',
        'piece_jointe'
    ];

    protected $casts = [
        'date_debut' => 'date',
        'date_fin' => 'date',
        'date_approbation' => 'datetime',
        'urgent' => 'boolean'
    ];

    /**
     * Relation avec l'utilisateur (employé)
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Relation avec l'utilisateur qui a approuvé
     */
    public function approbateur()
    {
        return $this->belongsTo(User::class, 'approuve_par');
    }

    /**
     * Vérifier si le congé est en cours
     */
    public function isEnCours()
    {
        $aujourdhui = Carbon::today();
        return $this->date_debut <= $aujourdhui && $this->date_fin >= $aujourdhui;
    }

    /**
     * Vérifier si le congé est passé
     */
    public function isPasse()
    {
        return $this->date_fin < Carbon::today();
    }

    /**
     * Vérifier si le congé est futur
     */
    public function isFutur()
    {
        return $this->date_debut > Carbon::today();
    }

    /**
     * Obtenir le statut en français
     */
    public function getStatutLibelle()
    {
        $statuts = [
            'en_attente' => 'En attente',
            'approuve' => 'Approuvé',
            'rejete' => 'Rejeté'
        ];

        return $statuts[$this->statut] ?? 'Inconnu';
    }

    /**
     * Obtenir le type de congé en français
     */
    public function getTypeLibelle()
    {
        $types = [
            'annuel' => 'Congé annuel',
            'maladie' => 'Arrêt maladie',
            'maternite' => 'Congé maternité',
            'paternite' => 'Congé paternité',
            'formation' => 'Congé formation',
            'personnel' => 'Congé personnel',
            'exceptionnel' => 'Congé exceptionnel'
        ];

        return $types[$this->type_conge] ?? 'Autre';
    }

    /**
     * Scope pour les congés en attente
     */
    public function scopeEnAttente($query)
    {
        return $query->where('statut', 'en_attente');
    }

    /**
     * Scope pour les congés approuvés
     */
    public function scopeApprouves($query)
    {
        return $query->where('statut', 'approuve');
    }

    /**
     * Scope pour les congés rejetés
     */
    public function scopeRejetes($query)
    {
        return $query->where('statut', 'rejete');
    }

    /**
     * Scope pour les congés urgents
     */
    public function scopeUrgents($query)
    {
        return $query->where('urgent', true);
    }

    /**
     * Scope pour les congés d'un utilisateur
     */
    public function scopePourUtilisateur($query, $userId)
    {
        return $query->where('user_id', $userId);
    }

    /**
     * Scope pour les congés d'une période
     */
    public function scopePourPeriode($query, $dateDebut, $dateFin)
    {
        return $query->where(function($q) use ($dateDebut, $dateFin) {
            $q->whereBetween('date_debut', [$dateDebut, $dateFin])
              ->orWhereBetween('date_fin', [$dateDebut, $dateFin])
              ->orWhere(function($q2) use ($dateDebut, $dateFin) {
                  $q2->where('date_debut', '<=', $dateDebut)
                     ->where('date_fin', '>=', $dateFin);
              });
        });
    }
}

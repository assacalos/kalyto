<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class Evaluation extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'evaluateur_id',
        'type_evaluation',
        'date_evaluation',
        'periode_debut',
        'periode_fin',
        'criteres_evaluation',
        'note_globale',
        'commentaires_evaluateur',
        'commentaires_employe',
        'objectifs_futurs',
        'statut',
        'date_signature_employe',
        'date_signature_evaluateur',
        'confidentiel'
    ];

    protected $casts = [
        'date_evaluation' => 'date',
        'periode_debut' => 'date',
        'periode_fin' => 'date',
        'criteres_evaluation' => 'array',
        'note_globale' => 'decimal:2',
        'date_signature_employe' => 'date',
        'date_signature_evaluateur' => 'date',
        'confidentiel' => 'boolean'
    ];

    /**
     * Relation avec l'employé évalué
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Relation avec l'évaluateur
     */
    public function evaluateur()
    {
        return $this->belongsTo(User::class, 'evaluateur_id');
    }

    /**
     * Obtenir le statut en français
     */
    public function getStatutLibelle()
    {
        $statuts = [
            'en_cours' => 'En cours',
            'finalisee' => 'Finalisée',
            'archivee' => 'Archivée'
        ];

        return $statuts[$this->statut] ?? 'Inconnu';
    }

    /**
     * Obtenir le type d'évaluation en français
     */
    public function getTypeLibelle()
    {
        $types = [
            'annuelle' => 'Évaluation annuelle',
            'trimestrielle' => 'Évaluation trimestrielle',
            'probation' => 'Évaluation de période d\'essai',
            'performance' => 'Évaluation de performance',
            'objectifs' => 'Évaluation d\'objectifs'
        ];

        return $types[$this->type_evaluation] ?? 'Autre';
    }

    /**
     * Obtenir la note en lettres
     */
    public function getNoteLettres()
    {
        if ($this->note_globale >= 18) return 'Excellent';
        if ($this->note_globale >= 16) return 'Très bien';
        if ($this->note_globale >= 14) return 'Bien';
        if ($this->note_globale >= 12) return 'Assez bien';
        if ($this->note_globale >= 10) return 'Passable';
        return 'Insuffisant';
    }

    /**
     * Vérifier si l'évaluation est signée
     */
    public function isSignee()
    {
        return $this->date_signature_employe && $this->date_signature_evaluateur;
    }

    /**
     * Vérifier si l'évaluation est en retard
     */
    public function isEnRetard()
    {
        return $this->date_evaluation < Carbon::today() && $this->statut === 'en_cours';
    }

    /**
     * Scope pour les évaluations en cours
     */
    public function scopeEnCours($query)
    {
        return $query->where('statut', 'en_cours');
    }

    /**
     * Scope pour les évaluations finalisées
     */
    public function scopeFinalisees($query)
    {
        return $query->where('statut', 'finalisee');
    }

    /**
     * Scope pour les évaluations d'un utilisateur
     */
    public function scopePourUtilisateur($query, $userId)
    {
        return $query->where('user_id', $userId);
    }

    /**
     * Scope pour les évaluations d'un évaluateur
     */
    public function scopeParEvaluateur($query, $evaluateurId)
    {
        return $query->where('evaluateur_id', $evaluateurId);
    }

    /**
     * Scope pour les évaluations d'une période
     */
    public function scopePourPeriode($query, $dateDebut, $dateFin)
    {
        return $query->whereBetween('date_evaluation', [$dateDebut, $dateFin]);
    }

    /**
     * Scope pour les évaluations confidentielles
     */
    public function scopeConfidentielles($query)
    {
        return $query->where('confidentiel', true);
    }

    /**
     * Scope pour les évaluations publiques
     */
    public function scopePubliques($query)
    {
        return $query->where('confidentiel', false);
    }
}

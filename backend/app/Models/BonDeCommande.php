<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class BonDeCommande extends Model
{
    use HasFactory;

    protected $fillable = [
        'fournisseur_id',
        'numero_commande',
        'date_commande',
        'montant_total',
        'description',
        'statut',
        'commentaire',
        'conditions_paiement',
        'delai_livraison',
        'date_validation',
        'date_debut_traitement',
        'date_annulation',
        'user_id'
    ];

    protected $casts = [
        'date_commande' => 'date',
        'date_validation' => 'date',
        'date_debut_traitement' => 'date',
        'date_annulation' => 'date',
        'montant_total' => 'decimal:2'
    ];

    // Relations
    public function fournisseur()
    {
        return $this->belongsTo(Fournisseur::class);
    }

    public function createur()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function items()
    {
        return $this->hasMany(BonDeCommandeItem::class, 'bon_de_commande_id');
    }

    // Scopes
    public function scopeEnAttente($query)
    {
        return $query->where('statut', 'en_attente');
    }

    public function scopeValides($query)
    {
        return $query->where('statut', 'valide');
    }

    public function scopeEnCours($query)
    {
        return $query->where('statut', 'en_cours');
    }

    public function scopeLives($query)
    {
        return $query->where('statut', 'livre');
    }

    public function scopeAnnules($query)
    {
        return $query->where('statut', 'annule');
    }

    // Méthodes utilitaires
    public function peutEtreModifie()
    {
        return in_array($this->statut, ['en_attente']);
    }

    public function peutEtreValide()
    {
        return $this->statut === 'en_attente';
    }

    public function peutEtreMarqueEnCours()
    {
        return $this->statut === 'valide';
    }

    public function peutEtreMarqueLivre()
    {
        return $this->statut === 'en_cours';
    }

    public function peutEtreAnnule()
    {
        return in_array($this->statut, ['en_attente', 'valide', 'en_cours']);
    }

    // Accesseurs
    public function getStatutLibelleAttribute()
    {
        $statuts = [
            'en_attente' => 'En attente',
            'valide' => 'Validé',
            'en_cours' => 'En cours',
            'livre' => 'Livré',
            'annule' => 'Annulé'
        ];

        return $statuts[$this->statut] ?? $this->statut;
    }

    public function getDureeTraitementAttribute()
    {
        // Cette méthode n'est plus utilisable sans date_livraison
        return null;
    }

    public function getRetardAttribute()
    {
        // Cette méthode n'est plus utilisable sans date_livraison_prevue et date_livraison
        return false;
    }
}

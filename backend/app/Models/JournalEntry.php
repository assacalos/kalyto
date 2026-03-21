<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class JournalEntry extends Model
{
    use HasFactory;

    protected $fillable = [
        'company_id',
        'compte_id',
        'date',
        'reference',
        'libelle',
        'categorie',
        'mode_paiement',
        'entree',
        'sortie',
        'user_id',
        'notes',
    ];

    protected $casts = [
        'date' => 'date',
        'entree' => 'decimal:2',
        'sortie' => 'decimal:2',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function compte()
    {
        return $this->belongsTo(Compte::class);
    }

    public function scopeByMonth($query, $year, $month)
    {
        return $query->whereYear('date', $year)->whereMonth('date', $month);
    }

    public function scopeByDateRange($query, $startDate, $endDate)
    {
        return $query->whereBetween('date', [$startDate, $endDate]);
    }

    public function scopeOrdered($query)
    {
        return $query->orderBy('date')->orderBy('id');
    }

    public function getModePaiementLibelleAttribute()
    {
        $modes = [
            'especes' => 'Espèces',
            'virement' => 'Virement',
            'cheque' => 'Chèque',
            'carte_bancaire' => 'Carte bancaire',
            'mobile_money' => 'Mobile Money',
            'autre' => 'Autre',
        ];

        return $modes[$this->mode_paiement] ?? $this->mode_paiement;
    }

    /**
     * Solde cumulé jusqu'à cette entrée (inclus) à partir d'un solde initial.
     */
    public static function soldeCumuleDepuis(float $soldeInitial, $query)
    {
        $solde = (float) $soldeInitial;
        $entries = $query->orderBy('date')->orderBy('id')->get();
        $entries->each(function ($entry) use (&$solde) {
            $solde = $solde + (float) $entry->entree - (float) $entry->sortie;
            $entry->solde = round($solde, 2);
        });
        return $entries;
    }

    /**
     * Calcule le solde total à une date donnée (toutes entrées avant ou à cette date).
     * @param string $date
     * @param int|null $companyId scope par société si fourni
     */
    public static function soldeAu($date, $companyId = null)
    {
        $q = static::where('date', '<=', $date);
        if ($companyId !== null) {
            $q->where('company_id', $companyId);
        }
        $entrees = (float) (clone $q)->sum('entree');
        $sorties = (float) (clone $q)->sum('sortie');
        return round($entrees - $sorties, 2);
    }
}

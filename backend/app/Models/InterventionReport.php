<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class InterventionReport extends Model
{
    use HasFactory;

    protected $fillable = [
        'intervention_id',
        'technician_id',
        'report_number',
        'work_performed',
        'findings',
        'recommendations',
        'parts_used',
        'labor_hours',
        'parts_cost',
        'labor_cost',
        'total_cost',
        'photos',
        'client_signature',
        'technician_signature',
        'report_date'
    ];

    protected $casts = [
        'parts_used' => 'array',
        'photos' => 'array',
        'labor_hours' => 'decimal:2',
        'parts_cost' => 'decimal:2',
        'labor_cost' => 'decimal:2',
        'total_cost' => 'decimal:2',
        'report_date' => 'datetime'
    ];

    // Relations
    public function intervention()
    {
        return $this->belongsTo(Intervention::class);
    }

    public function technician()
    {
        return $this->belongsTo(User::class, 'technician_id');
    }

    // Accesseurs
    public function getTechnicianNameAttribute()
    {
        return $this->technician ? $this->technician->prenom . ' ' . $this->technician->nom : 'N/A';
    }

    public function getFormattedLaborHoursAttribute()
    {
        return $this->labor_hours ? $this->labor_hours . 'h' : 'N/A';
    }

    public function getFormattedPartsCostAttribute()
    {
        return $this->parts_cost ? number_format($this->parts_cost, 2, ',', ' ') . ' €' : 'N/A';
    }

    public function getFormattedLaborCostAttribute()
    {
        return $this->labor_cost ? number_format($this->labor_cost, 2, ',', ' ') . ' €' : 'N/A';
    }

    public function getFormattedTotalCostAttribute()
    {
        return $this->total_cost ? number_format($this->total_cost, 2, ',', ' ') . ' €' : 'N/A';
    }

    // Méthodes utilitaires
    public function calculateTotalCost()
    {
        $total = ($this->parts_cost ?? 0) + ($this->labor_cost ?? 0);
        $this->update(['total_cost' => $total]);
        return $total;
    }

    public function addPhoto($photoPath)
    {
        $photos = $this->photos ?? [];
        $photos[] = $photoPath;
        $this->update(['photos' => $photos]);
    }

    public function removePhoto($photoPath)
    {
        $photos = $this->photos ?? [];
        $photos = array_filter($photos, function($photo) use ($photoPath) {
            return $photo !== $photoPath;
        });
        $this->update(['photos' => array_values($photos)]);
    }

    // Méthodes statiques
    public static function generateReportNumber()
    {
        $count = self::count() + 1;
        return 'RAPP-' . date('Y') . '-' . str_pad($count, 4, '0', STR_PAD_LEFT);
    }

    public static function getReportsByIntervention($interventionId)
    {
        return self::where('intervention_id', $interventionId)
            ->with(['technician'])
            ->orderBy('report_date', 'desc')
            ->get();
    }

    public static function getReportsByTechnician($technicianId)
    {
        return self::where('technician_id', $technicianId)
            ->with(['intervention'])
            ->orderBy('report_date', 'desc')
            ->get();
    }

    public static function getReportStats($startDate = null, $endDate = null)
    {
        $query = self::query();
        
        if ($startDate && $endDate) {
            $query->whereBetween('report_date', [$startDate, $endDate]);
        }

        $reports = $query->get();
        
        return [
            'total_reports' => $reports->count(),
            'total_labor_hours' => $reports->sum('labor_hours'),
            'total_parts_cost' => $reports->sum('parts_cost'),
            'total_labor_cost' => $reports->sum('labor_cost'),
            'total_cost' => $reports->sum('total_cost'),
            'average_labor_hours' => $reports->avg('labor_hours') ?? 0,
            'average_cost' => $reports->avg('total_cost') ?? 0
        ];
    }
}

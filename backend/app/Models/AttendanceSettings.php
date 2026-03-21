<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AttendanceSettings extends Model
{
    use HasFactory;

    protected $fillable = [
        'allowed_radius',
        'work_start_time',
        'work_end_time',
        'late_threshold_minutes',
        'require_photo',
        'require_location',
        'allowed_locations',
        'is_active'
    ];

    protected $casts = [
        'allowed_radius' => 'decimal:2',
        'work_start_time' => 'datetime:H:i',
        'work_end_time' => 'datetime:H:i',
        'require_photo' => 'boolean',
        'require_location' => 'boolean',
        'allowed_locations' => 'array',
        'is_active' => 'boolean'
    ];

    // Méthodes utilitaires
    public function isLocationAllowed($latitude, $longitude)
    {
        if (!$this->allowed_locations || empty($this->allowed_locations)) {
            return true; // Si aucun lieu spécifique, autoriser partout
        }

        foreach ($this->allowed_locations as $location) {
            $distance = $this->calculateDistance(
                $latitude,
                $longitude,
                $location['latitude'],
                $location['longitude']
            );
            
            if ($distance <= $this->allowed_radius) {
                return true;
            }
        }

        return false;
    }

    public function isLate($checkInTime)
    {
        $workStart = \Carbon\Carbon::parse($checkInTime->format('Y-m-d') . ' ' . $this->work_start_time->format('H:i:s'));
        $threshold = $workStart->addMinutes($this->late_threshold_minutes);
        
        return $checkInTime->gt($threshold);
    }

    public function getLateMinutes($checkInTime)
    {
        $workStart = \Carbon\Carbon::parse($checkInTime->format('Y-m-d') . ' ' . $this->work_start_time->format('H:i:s'));
        return $checkInTime->diffInMinutes($workStart);
    }

    public function isEarlyLeave($checkOutTime)
    {
        $workEnd = \Carbon\Carbon::parse($checkOutTime->format('Y-m-d') . ' ' . $this->work_end_time->format('H:i:s'));
        return $checkOutTime->lt($workEnd);
    }

    public function getEarlyLeaveMinutes($checkOutTime)
    {
        $workEnd = \Carbon\Carbon::parse($checkOutTime->format('Y-m-d') . ' ' . $this->work_end_time->format('H:i:s'));
        return $workEnd->diffInMinutes($checkOutTime);
    }

    // Calcul de distance entre deux points (formule de Haversine)
    private function calculateDistance($lat1, $lon1, $lat2, $lon2)
    {
        $earthRadius = 6371000; // Rayon de la Terre en mètres

        $lat1Rad = deg2rad($lat1);
        $lon1Rad = deg2rad($lon1);
        $lat2Rad = deg2rad($lat2);
        $lon2Rad = deg2rad($lon2);

        $deltaLat = $lat2Rad - $lat1Rad;
        $deltaLon = $lon2Rad - $lon1Rad;

        $a = sin($deltaLat / 2) * sin($deltaLat / 2) +
             cos($lat1Rad) * cos($lat2Rad) *
             sin($deltaLon / 2) * sin($deltaLon / 2);
        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        return $earthRadius * $c;
    }

    // Méthode statique pour obtenir les paramètres actifs
    public static function getActiveSettings()
    {
        return self::where('is_active', true)->first() ?? self::getDefaultSettings();
    }

    public static function getDefaultSettings()
    {
        return new self([
            'allowed_radius' => 100,
            'work_start_time' => '08:00:00',
            'work_end_time' => '17:00:00',
            'late_threshold_minutes' => 15,
            'require_photo' => true,
            'require_location' => true,
            'allowed_locations' => [],
            'is_active' => true
        ]);
    }
}
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PayrollSetting extends Model
{
    use HasFactory;

    protected $fillable = [
        'setting_key',
        'setting_name',
        'description',
        'value_type',
        'decimal_value',
        'integer_value',
        'string_value',
        'boolean_value',
        'unit',
        'is_active',
        'notes'
    ];

    protected $casts = [
        'decimal_value' => 'decimal:4',
        'boolean_value' => 'boolean',
        'is_active' => 'boolean'
    ];

    // Scopes
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    public function scopeByType($query, $type)
    {
        return $query->where('value_type', $type);
    }

    // Accesseurs
    public function getValueAttribute()
    {
        switch ($this->value_type) {
            case 'decimal':
                return $this->decimal_value;
            case 'integer':
                return $this->integer_value;
            case 'string':
                return $this->string_value;
            case 'boolean':
                return $this->boolean_value;
            default:
                return null;
        }
    }

    public function getFormattedValueAttribute()
    {
        $value = $this->value;
        
        if ($this->unit) {
            if ($this->value_type === 'decimal' || $this->value_type === 'integer') {
                return number_format($value, 2, ',', ' ') . ' ' . $this->unit;
            }
            return $value . ' ' . $this->unit;
        }
        
        return $value;
    }

    // Méthodes utilitaires
    public function setSettingValue($value)
    {
        switch ($this->value_type) {
            case 'decimal':
                $this->update(['decimal_value' => $value]);
                break;
            case 'integer':
                $this->update(['integer_value' => $value]);
                break;
            case 'string':
                $this->update(['string_value' => $value]);
                break;
            case 'boolean':
                $this->update(['boolean_value' => $value]);
                break;
        }
    }

    public function activate()
    {
        $this->update(['is_active' => true]);
    }

    public function deactivate()
    {
        $this->update(['is_active' => false]);
    }

    // Méthodes statiques
    public static function getValue($key, $default = null)
    {
        $setting = self::where('setting_key', $key)->active()->first();
        
        if ($setting) {
            return $setting->value;
        }
        
        return $default;
    }

    public static function setValue($key, $value, $settingName = null, $description = null)
    {
        $setting = self::where('setting_key', $key)->first();
        
        if ($setting) {
            $setting->setSettingValue($value);
        } else {
            // Déterminer le type de valeur
            $valueType = 'string';
            if (is_numeric($value)) {
                $valueType = is_int($value) ? 'integer' : 'decimal';
            } elseif (is_bool($value)) {
                $valueType = 'boolean';
            }
            
            self::create([
                'setting_key' => $key,
                'setting_name' => $settingName ?? $key,
                'description' => $description,
                'value_type' => $valueType,
                'is_active' => true
            ])->setValue($value);
        }
    }

    public static function getTaxRate()
    {
        return self::getValue('tax_rate', 20);
    }

    public static function getSocialSecurityRate()
    {
        return self::getValue('social_security_rate', 15);
    }

    public static function getMinimumWage()
    {
        return self::getValue('minimum_wage', 50000);
    }

    public static function getOvertimeRate()
    {
        return self::getValue('overtime_rate', 1.5);
    }

    public static function getWorkingHoursPerDay()
    {
        return self::getValue('working_hours_per_day', 8);
    }

    public static function getWorkingDaysPerWeek()
    {
        return self::getValue('working_days_per_week', 5);
    }

    public static function getWorkingDaysPerMonth()
    {
        return self::getValue('working_days_per_month', 22);
    }

    public static function initializeDefaultSettings()
    {
        $defaultSettings = [
            [
                'key' => 'tax_rate',
                'name' => 'Taux d\'imposition',
                'description' => 'Taux d\'imposition sur le revenu (%)',
                'value' => 20,
                'type' => 'decimal',
                'unit' => '%'
            ],
            [
                'key' => 'social_security_rate',
                'name' => 'Taux de charges sociales',
                'description' => 'Taux de charges sociales (%)',
                'value' => 15,
                'type' => 'decimal',
                'unit' => '%'
            ],
            [
                'key' => 'minimum_wage',
                'name' => 'Salaire minimum',
                'description' => 'Salaire minimum légal',
                'value' => 50000,
                'type' => 'decimal',
                'unit' => '€'
            ],
            [
                'key' => 'overtime_rate',
                'name' => 'Taux heures supplémentaires',
                'description' => 'Multiplicateur pour les heures supplémentaires',
                'value' => 1.5,
                'type' => 'decimal',
                'unit' => 'x'
            ],
            [
                'key' => 'working_hours_per_day',
                'name' => 'Heures de travail par jour',
                'description' => 'Nombre d\'heures de travail par jour',
                'value' => 8,
                'type' => 'integer',
                'unit' => 'heures'
            ],
            [
                'key' => 'working_days_per_week',
                'name' => 'Jours de travail par semaine',
                'description' => 'Nombre de jours de travail par semaine',
                'value' => 5,
                'type' => 'integer',
                'unit' => 'jours'
            ],
            [
                'key' => 'working_days_per_month',
                'name' => 'Jours de travail par mois',
                'description' => 'Nombre de jours de travail par mois',
                'value' => 22,
                'type' => 'integer',
                'unit' => 'jours'
            ]
        ];

        foreach ($defaultSettings as $setting) {
            self::firstOrCreate(
                ['setting_key' => $setting['key']],
                [
                    'setting_name' => $setting['name'],
                    'description' => $setting['description'],
                    'value_type' => $setting['type'],
                    'unit' => $setting['unit'],
                    'is_active' => true
                ]
            )->setSettingValue($setting['value']);
        }
    }

    public static function getAllSettings()
    {
        return self::active()->orderBy('setting_name')->get();
    }

    public static function getSettingsByType($type)
    {
        return self::active()->byType($type)->orderBy('setting_name')->get();
    }
}

<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class EmployeeDocument extends Model
{
    use HasFactory;

    protected $fillable = [
        'employee_id',
        'name',
        'type',
        'description',
        'file_path',
        'file_size',
        'expiry_date',
        'is_required',
        'created_by'
    ];

    protected $casts = [
        'expiry_date' => 'date',
        'is_required' => 'boolean'
    ];

    // Relations
    public function employee()
    {
        return $this->belongsTo(Employee::class);
    }

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    // Scopes
    public function scopeByType($query, $type)
    {
        return $query->where('type', $type);
    }

    public function scopeRequired($query)
    {
        return $query->where('is_required', true);
    }

    public function scopeOptional($query)
    {
        return $query->where('is_required', false);
    }

    public function scopeExpiring($query, $days = 30)
    {
        $expiryDate = now()->addDays($days);
        return $query->where('expiry_date', '<=', $expiryDate)
                    ->where('expiry_date', '>', now());
    }

    public function scopeExpired($query)
    {
        return $query->where('expiry_date', '<', now());
    }

    public function scopeByEmployee($query, $employeeId)
    {
        return $query->where('employee_id', $employeeId);
    }

    // Accesseurs
    public function getTypeLibelleAttribute()
    {
        $types = [
            'contract' => 'Contrat',
            'id_card' => 'Carte d\'identité',
            'passport' => 'Passeport',
            'diploma' => 'Diplôme',
            'certificate' => 'Certificat',
            'medical' => 'Certificat médical',
            'other' => 'Autre'
        ];

        return $types[$this->type] ?? $this->type;
    }

    public function getCreatorNameAttribute()
    {
        return $this->creator ? $this->creator->prenom . ' ' . $this->creator->nom : 'N/A';
    }

    public function getFormattedFileSizeAttribute()
    {
        if (!$this->file_size) return 'N/A';
        
        $bytes = (int) $this->file_size;
        $units = ['B', 'KB', 'MB', 'GB'];
        
        for ($i = 0; $bytes > 1024 && $i < count($units) - 1; $i++) {
            $bytes /= 1024;
        }
        
        return round($bytes, 2) . ' ' . $units[$i];
    }

    public function getIsExpiringAttribute()
    {
        if (!$this->expiry_date) return false;
        $daysUntilExpiry = $this->expiry_date->diffInDays(now());
        return $daysUntilExpiry <= 30 && $daysUntilExpiry >= 0;
    }

    public function getIsExpiredAttribute()
    {
        if (!$this->expiry_date) return false;
        return now()->isAfter($this->expiry_date);
    }

    public function getIsRequiredAttribute()
    {
        return $this->is_required;
    }

    public function getIsOptionalAttribute()
    {
        return !$this->is_required;
    }

    // Méthodes utilitaires
    public function markAsRequired()
    {
        $this->update(['is_required' => true]);
    }

    public function markAsOptional()
    {
        $this->update(['is_required' => false]);
    }

    public function updateExpiryDate($newDate)
    {
        $this->update(['expiry_date' => $newDate]);
    }

    public function updateFile($filePath, $fileSize)
    {
        $this->update([
            'file_path' => $filePath,
            'file_size' => $fileSize
        ]);
    }

    // Méthodes statiques
    public static function getDocumentStats()
    {
        $documents = self::all();
        
        return [
            'total_documents' => $documents->count(),
            'required_documents' => $documents->where('is_required', true)->count(),
            'optional_documents' => $documents->where('is_required', false)->count(),
            'expiring_documents' => $documents->filter(function ($doc) {
                return $doc->is_expiring;
            })->count(),
            'expired_documents' => $documents->filter(function ($doc) {
                return $doc->is_expired;
            })->count(),
            'documents_by_type' => $documents->groupBy('type')->map->count(),
            'documents_by_employee' => $documents->groupBy('employee_id')->map->count()
        ];
    }

    public static function getDocumentsByEmployee($employeeId)
    {
        return self::byEmployee($employeeId)
            ->with(['creator'])
            ->orderBy('created_at', 'desc')
            ->get();
    }

    public static function getExpiringDocuments()
    {
        return self::expiring()->with(['employee', 'creator'])->get();
    }

    public static function getExpiredDocuments()
    {
        return self::expired()->with(['employee', 'creator'])->get();
    }

    public static function getRequiredDocuments()
    {
        return self::required()->with(['employee', 'creator'])->get();
    }

    public static function getDocumentsByType($type)
    {
        return self::byType($type)->with(['employee', 'creator'])->get();
    }
}

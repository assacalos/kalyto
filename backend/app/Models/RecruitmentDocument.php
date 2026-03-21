<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class RecruitmentDocument extends Model
{
    use HasFactory;

    protected $fillable = [
        'application_id',
        'file_name',
        'file_path',
        'file_type',
        'file_size',
        'uploaded_at'
    ];

    protected $casts = [
        'uploaded_at' => 'datetime'
    ];

    // Relations
    public function application()
    {
        return $this->belongsTo(RecruitmentApplication::class);
    }

    // Scopes
    public function scopeByApplication($query, $applicationId)
    {
        return $query->where('application_id', $applicationId);
    }

    public function scopeByType($query, $fileType)
    {
        return $query->where('file_type', $fileType);
    }

    public function scopeRecent($query, $days = 30)
    {
        return $query->where('uploaded_at', '>=', now()->subDays($days));
    }

    // Accesseurs
    public function getFormattedFileSizeAttribute()
    {
        $bytes = $this->file_size;
        $units = ['B', 'KB', 'MB', 'GB'];
        
        for ($i = 0; $bytes > 1024 && $i < count($units) - 1; $i++) {
            $bytes /= 1024;
        }
        
        return round($bytes, 2) . ' ' . $units[$i];
    }

    public function getFileExtensionAttribute()
    {
        return pathinfo($this->file_name, PATHINFO_EXTENSION);
    }

    public function getIsImageAttribute()
    {
        $imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
        return in_array(strtolower($this->file_extension), $imageExtensions);
    }

    public function getIsPdfAttribute()
    {
        return strtolower($this->file_extension) === 'pdf';
    }

    public function getIsDocumentAttribute()
    {
        $documentExtensions = ['doc', 'docx', 'txt', 'rtf'];
        return in_array(strtolower($this->file_extension), $documentExtensions);
    }

    // Méthodes utilitaires
    public function updateFile($fileName, $filePath, $fileType, $fileSize)
    {
        $this->update([
            'file_name' => $fileName,
            'file_path' => $filePath,
            'file_type' => $fileType,
            'file_size' => $fileSize,
            'uploaded_at' => now()
        ]);
    }

    // Méthodes statiques
    public static function getDocumentStats($applicationId = null)
    {
        $query = self::query();
        if ($applicationId) {
            $query->where('application_id', $applicationId);
        }

        $documents = $query->get();
        
        return [
            'total_documents' => $documents->count(),
            'total_size' => $documents->sum('file_size'),
            'average_size' => $documents->avg('file_size') ?? 0,
            'documents_by_type' => $documents->groupBy('file_type')->map->count(),
            'recent_documents' => $documents->sortByDesc('uploaded_at')->take(10)->values()
        ];
    }

    public static function getDocumentsByApplication($applicationId)
    {
        return self::byApplication($applicationId)
            ->with(['application'])
            ->orderBy('uploaded_at', 'desc')
            ->get();
    }

    public static function getDocumentsByType($fileType)
    {
        return self::byType($fileType)->with(['application'])->get();
    }

    public static function getRecentDocuments($days = 30)
    {
        return self::recent($days)->with(['application'])->get();
    }
}

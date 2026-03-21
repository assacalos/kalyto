<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ContractAttachment extends Model
{
    use HasFactory;

    protected $fillable = [
        'contract_id',
        'file_name',
        'file_path',
        'file_type',
        'file_size',
        'attachment_type',
        'description',
        'uploaded_at',
        'uploaded_by'
    ];

    protected $casts = [
        'uploaded_at' => 'datetime'
    ];

    // Relations
    public function contract()
    {
        return $this->belongsTo(Contract::class);
    }

    public function uploader()
    {
        return $this->belongsTo(User::class, 'uploaded_by');
    }

    // Scopes
    public function scopeByContract($query, $contractId)
    {
        return $query->where('contract_id', $contractId);
    }

    public function scopeByType($query, $attachmentType)
    {
        return $query->where('attachment_type', $attachmentType);
    }

    public function scopeByFileType($query, $fileType)
    {
        return $query->where('file_type', $fileType);
    }

    public function scopeRecent($query, $days = 30)
    {
        return $query->where('uploaded_at', '>=', now()->subDays($days));
    }

    // Accesseurs
    public function getAttachmentTypeLibelleAttribute()
    {
        $types = [
            'contract' => 'Contrat',
            'addendum' => 'Avenant',
            'amendment' => 'Modification',
            'termination' => 'Résiliation',
            'other' => 'Autre'
        ];

        return $types[$this->attachment_type] ?? $this->attachment_type;
    }

    public function getUploaderNameAttribute()
    {
        return $this->uploader ? $this->uploader->prenom . ' ' . $this->uploader->nom : 'N/A';
    }

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

    public function getIsPdfAttribute()
    {
        return strtolower($this->file_extension) === 'pdf';
    }

    public function getIsImageAttribute()
    {
        $imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
        return in_array(strtolower($this->file_extension), $imageExtensions);
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
    public static function getAttachmentsByContract($contractId)
    {
        return self::byContract($contractId)
            ->with(['uploader'])
            ->orderBy('uploaded_at', 'desc')
            ->get();
    }

    public static function getAttachmentsByType($attachmentType)
    {
        return self::byType($attachmentType)->with(['contract', 'uploader'])->get();
    }

    public static function getRecentAttachments($days = 30)
    {
        return self::recent($days)->with(['contract', 'uploader'])->get();
    }

    public static function getAttachmentStats($contractId = null)
    {
        $query = self::query();
        if ($contractId) {
            $query->where('contract_id', $contractId);
        }

        $attachments = $query->get();
        
        return [
            'total_attachments' => $attachments->count(),
            'total_size' => $attachments->sum('file_size'),
            'average_size' => $attachments->avg('file_size') ?? 0,
            'attachments_by_type' => $attachments->groupBy('attachment_type')->map->count(),
            'attachments_by_file_type' => $attachments->groupBy('file_type')->map->count()
        ];
    }
}

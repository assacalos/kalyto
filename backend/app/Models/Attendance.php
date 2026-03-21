<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\DB;

class Attendance extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'check_in_time',
        'check_out_time',
        'status',
        'location',
        'photo_path',
        'notes',
        'validated_by',
        'validated_at',
        'validation_comment',
        'rejected_by',
        'rejected_at',
        'rejection_reason',
        'rejection_comment',
    ];

    protected $casts = [
        'check_in_time' => 'datetime',
        'check_out_time' => 'datetime',
        'validated_at' => 'datetime',
        'rejected_at' => 'datetime',
        'location' => 'array',
    ];

    // Relations
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function approver(): BelongsTo
    {
        return $this->belongsTo(User::class, 'validated_by');
    }

    public function validator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'validated_by');
    }

    public function rejector(): BelongsTo
    {
        return $this->belongsTo(User::class, 'rejected_by');
    }

    // Scopes
    public function scopePending($query)
    {
        return $query->where('status', 'en_attente');
    }

    public function scopeApproved($query)
    {
        return $query->where('status', 'valide');
    }

    public function scopeRejected($query)
    {
        return $query->where('status', 'rejete');
    }

    // Accessors
    public function getPhotoUrlAttribute()
    {
        if ($this->photo_path) {
            return asset('storage/' . $this->photo_path);
        }
        return null;
    }

    public function getStatusLabelAttribute()
    {
        return match($this->status) {
            'en_attente' => 'En attente',
            'valide' => 'Validé',
            'rejete' => 'Rejeté',
            default => 'Inconnu'
        };
    }

    // Méthodes
    public function canBeApproved(): bool
    {
        // Un pointage peut être approuvé s'il est en attente ou si le statut est null (ancien pointage)
        return $this->status === 'en_attente' || $this->status === null;
    }

    public function canBeRejected(): bool
    {
        // Un pointage peut être rejeté s'il est en attente ou si le statut est null (ancien pointage)
        return $this->status === 'en_attente' || $this->status === null;
    }

    public function approve(User $approver, string $comment = null): bool
    {
        if (!$this->canBeApproved()) {
            \Log::warning('Attendance cannot be approved', [
                'attendance_id' => $this->id,
                'current_status' => $this->status,
                'can_be_approved' => $this->canBeApproved(),
            ]);
            return false;
        }

        // Méthode 1 : Utiliser update() sur le modèle (méthode standard)
        $this->status = 'valide';
        $this->validated_by = $approver->id;
        $this->validated_at = now();
        $this->validation_comment = $comment;
        $this->updated_at = now();
        
        $saved = $this->save();
        
        \Log::info('Attendance approve save result', [
            'attendance_id' => $this->id,
            'save_result' => $saved,
            'status_after_save' => $this->status,
        ]);

        // Méthode 2 : Si save() échoue, utiliser DB::table() comme fallback
        if (!$saved || $this->status !== 'valide') {
            \Log::warning('Save failed, trying DB::table() update', [
                'attendance_id' => $this->id,
                'save_result' => $saved,
                'status' => $this->status,
            ]);
            
            $updated = DB::table('attendances')
                ->where('id', $this->id)
                ->update([
                    'status' => 'valide',
                    'validated_by' => $approver->id,
                    'validated_at' => now(),
                    'validation_comment' => $comment,
                    'updated_at' => now(),
                ]);
            
            \Log::info('DB::table() update result', [
                'attendance_id' => $this->id,
                'rows_affected' => $updated,
            ]);
        }

        // Méthode 3 : Forcer le rechargement depuis la base de données
        // Utiliser fresh() pour obtenir un nouveau modèle depuis la DB
        $freshAttendance = static::find($this->id);
        
        if (!$freshAttendance) {
            \Log::error('Cannot find attendance after update', [
                'attendance_id' => $this->id,
            ]);
            return false;
        }

        \Log::info('Fresh attendance status', [
            'attendance_id' => $freshAttendance->id,
            'status' => $freshAttendance->status,
            'validated_by' => $freshAttendance->validated_by,
        ]);

        // Vérifier que le statut est bien 'valide' dans la base de données
        if ($freshAttendance->status !== 'valide') {
            \Log::error('Attendance status not updated correctly in database', [
                'attendance_id' => $this->id,
                'expected_status' => 'valide',
                'actual_status' => $freshAttendance->status,
            ]);
            return false;
        }

        // Copier les attributs du modèle frais vers l'instance actuelle
        $this->status = $freshAttendance->status;
        $this->validated_by = $freshAttendance->validated_by;
        $this->validated_at = $freshAttendance->validated_at;
        $this->validation_comment = $freshAttendance->validation_comment;
        $this->updated_at = $freshAttendance->updated_at;
        
        // Marquer les attributs comme synchronisés
        $this->syncOriginal();

        \Log::info('Attendance approved successfully', [
            'attendance_id' => $this->id,
            'final_status' => $this->status,
            'validated_by' => $this->validated_by,
        ]);

        return true;
    }

    public function reject(User $approver, string $reason, string $comment = null): bool
    {
        if (!$this->canBeRejected()) {
            return false;
        }

        $this->update([
            'status' => 'rejete',
            'rejected_by' => $approver->id,
            'rejected_at' => now(),
            'rejection_reason' => $reason,
            'rejection_comment' => $comment,
        ]);

        return true;
    }
}
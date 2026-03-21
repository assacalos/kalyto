<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class RecruitmentInterview extends Model
{
    use HasFactory;

    protected $fillable = [
        'application_id',
        'scheduled_at',
        'location',
        'type',
        'meeting_link',
        'notes',
        'status',
        'feedback',
        'interviewer_id',
        'completed_at'
    ];

    protected $casts = [
        'scheduled_at' => 'datetime',
        'completed_at' => 'datetime'
    ];

    // Relations
    public function application()
    {
        return $this->belongsTo(RecruitmentApplication::class);
    }

    public function interviewer()
    {
        return $this->belongsTo(User::class, 'interviewer_id');
    }

    // Scopes
    public function scopeScheduled($query)
    {
        return $query->where('status', 'scheduled');
    }

    public function scopeCompleted($query)
    {
        return $query->where('status', 'completed');
    }

    public function scopeCancelled($query)
    {
        return $query->where('status', 'cancelled');
    }

    public function scopeByApplication($query, $applicationId)
    {
        return $query->where('application_id', $applicationId);
    }

    public function scopeByInterviewer($query, $interviewerId)
    {
        return $query->where('interviewer_id', $interviewerId);
    }

    public function scopeByType($query, $type)
    {
        return $query->where('type', $type);
    }

    public function scopeUpcoming($query)
    {
        return $query->where('scheduled_at', '>', now())
                    ->where('status', 'scheduled');
    }

    public function scopeToday($query)
    {
        return $query->whereDate('scheduled_at', today())
                    ->where('status', 'scheduled');
    }

    public function scopeThisWeek($query)
    {
        return $query->whereBetween('scheduled_at', [now()->startOfWeek(), now()->endOfWeek()])
                    ->where('status', 'scheduled');
    }

    // Accesseurs
    public function getStatusLibelleAttribute()
    {
        $statuses = [
            'scheduled' => 'Programmé',
            'completed' => 'Terminé',
            'cancelled' => 'Annulé'
        ];

        return $statuses[$this->status] ?? $this->status;
    }

    public function getTypeLibelleAttribute()
    {
        $types = [
            'phone' => 'Téléphonique',
            'video' => 'Vidéo',
            'in_person' => 'En personne'
        ];

        return $types[$this->type] ?? $this->type;
    }

    public function getInterviewerNameAttribute()
    {
        if (!$this->relationLoaded('interviewer') || !$this->interviewer) {
            return 'N/A';
        }
        return trim(($this->interviewer->prenom ?? '') . ' ' . ($this->interviewer->nom ?? '')) ?: 'N/A';
    }

    public function getIsScheduledAttribute()
    {
        return $this->status === 'scheduled';
    }

    public function getIsCompletedAttribute()
    {
        return $this->status === 'completed';
    }

    public function getIsCancelledAttribute()
    {
        return $this->status === 'cancelled';
    }

    public function getIsUpcomingAttribute()
    {
        return $this->is_scheduled && $this->scheduled_at > now();
    }

    public function getIsTodayAttribute()
    {
        return $this->is_scheduled && $this->scheduled_at->isToday();
    }

    public function getIsOverdueAttribute()
    {
        return $this->is_scheduled && $this->scheduled_at < now();
    }

    public function getDurationAttribute()
    {
        if (!$this->completed_at) return null;
        return $this->scheduled_at->diffInMinutes($this->completed_at);
    }

    public function getFormattedDurationAttribute()
    {
        if (!$this->duration) return 'N/A';
        
        $hours = floor($this->duration / 60);
        $minutes = $this->duration % 60;
        
        if ($hours > 0) {
            return $hours . 'h ' . $minutes . 'min';
        }
        
        return $minutes . 'min';
    }

    // Méthodes utilitaires
    public function complete($completedBy, $feedback = null)
    {
        $this->update([
            'status' => 'completed',
            'completed_at' => now(),
            'feedback' => $feedback ?? $this->feedback,
            'interviewer_id' => $completedBy
        ]);
    }

    public function cancel($reason = null)
    {
        $this->update([
            'status' => 'cancelled',
            'notes' => $reason ? $this->notes . "\n\nRaison d'annulation: " . $reason : $this->notes
        ]);
    }

    public function reschedule($newScheduledAt, $newLocation = null, $newType = null, $newMeetingLink = null)
    {
        $this->update([
            'scheduled_at' => $newScheduledAt,
            'location' => $newLocation ?? $this->location,
            'type' => $newType ?? $this->type,
            'meeting_link' => $newMeetingLink ?? $this->meeting_link
        ]);
    }

    // Méthodes statiques
    public static function getInterviewStats($applicationId = null)
    {
        $query = self::query();
        if ($applicationId) {
            $query->where('application_id', $applicationId);
        }

        $interviews = $query->get();
        
        return [
            'total_interviews' => $interviews->count(),
            'scheduled_interviews' => $interviews->where('status', 'scheduled')->count(),
            'completed_interviews' => $interviews->where('status', 'completed')->count(),
            'cancelled_interviews' => $interviews->where('status', 'cancelled')->count(),
            'upcoming_interviews' => $interviews->filter(function ($interview) {
                return $interview->is_upcoming;
            })->count(),
            'today_interviews' => $interviews->filter(function ($interview) {
                return $interview->is_today;
            })->count(),
            'overdue_interviews' => $interviews->filter(function ($interview) {
                return $interview->is_overdue;
            })->count(),
            'interviews_by_type' => $interviews->groupBy('type')->map->count(),
            'interviews_by_status' => $interviews->groupBy('status')->map->count(),
            'average_duration' => $interviews->where('status', 'completed')->avg('duration') ?? 0
        ];
    }

    public static function getInterviewsByApplication($applicationId)
    {
        return self::byApplication($applicationId)
            ->with(['application', 'interviewer'])
            ->orderBy('scheduled_at', 'desc')
            ->get();
    }

    public static function getInterviewsByInterviewer($interviewerId)
    {
        return self::byInterviewer($interviewerId)
            ->with(['application'])
            ->orderBy('scheduled_at', 'desc')
            ->get();
    }

    public static function getUpcomingInterviews()
    {
        return self::upcoming()->with(['application', 'interviewer'])->get();
    }

    public static function getTodayInterviews()
    {
        return self::today()->with(['application', 'interviewer'])->get();
    }

    public static function getThisWeekInterviews()
    {
        return self::thisWeek()->with(['application', 'interviewer'])->get();
    }

    public static function getOverdueInterviews()
    {
        return self::scheduled()
            ->where('scheduled_at', '<', now())
            ->with(['application', 'interviewer'])
            ->get();
    }

    public static function getInterviewsByType($type)
    {
        return self::byType($type)->with(['application', 'interviewer'])->get();
    }
}

<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class RecruitmentApplication extends Model
{
    use HasFactory;

    protected $fillable = [
        'recruitment_request_id',
        'candidate_name',
        'candidate_email',
        'candidate_phone',
        'candidate_address',
        'cover_letter',
        'resume_path',
        'portfolio_url',
        'linkedin_url',
        'status',
        'notes',
        'rejection_reason',
        'reviewed_at',
        'reviewed_by',
        'interview_scheduled_at',
        'interview_completed_at',
        'interview_notes'
    ];

    protected $casts = [
        'reviewed_at' => 'datetime',
        'interview_scheduled_at' => 'datetime',
        'interview_completed_at' => 'datetime'
    ];

    // Relations
    public function recruitmentRequest()
    {
        return $this->belongsTo(RecruitmentRequest::class);
    }

    public function reviewer()
    {
        return $this->belongsTo(User::class, 'reviewed_by');
    }

    public function documents()
    {
        return $this->hasMany(RecruitmentDocument::class);
    }

    public function interviews()
    {
        return $this->hasMany(RecruitmentInterview::class);
    }

    // Scopes
    public function scopePending($query)
    {
        return $query->where('status', 'pending');
    }

    public function scopeReviewed($query)
    {
        return $query->where('status', 'reviewed');
    }

    public function scopeShortlisted($query)
    {
        return $query->where('status', 'shortlisted');
    }

    public function scopeInterviewed($query)
    {
        return $query->where('status', 'interviewed');
    }

    public function scopeRejected($query)
    {
        return $query->where('status', 'rejected');
    }

    public function scopeHired($query)
    {
        return $query->where('status', 'hired');
    }

    public function scopeByRequest($query, $requestId)
    {
        return $query->where('recruitment_request_id', $requestId);
    }

    public function scopeByCandidate($query, $email)
    {
        return $query->where('candidate_email', $email);
    }

    public function scopeByStatus($query, $status)
    {
        return $query->where('status', $status);
    }

    public function scopeRecent($query, $days = 30)
    {
        return $query->where('created_at', '>=', now()->subDays($days));
    }

    // Accesseurs
    public function getStatusLibelleAttribute()
    {
        $statuses = [
            'pending' => 'En attente',
            'reviewed' => 'Examiné',
            'shortlisted' => 'Pré-sélectionné',
            'interviewed' => 'Interviewé',
            'rejected' => 'Rejeté',
            'hired' => 'Embauché'
        ];

        return $statuses[$this->status] ?? $this->status;
    }

    public function getReviewerNameAttribute()
    {
        if (!$this->relationLoaded('reviewer') || !$this->reviewer) {
            return 'N/A';
        }
        return trim(($this->reviewer->prenom ?? '') . ' ' . ($this->reviewer->nom ?? '')) ?: 'N/A';
    }

    public function getIsPendingAttribute()
    {
        return $this->status === 'pending';
    }

    public function getIsReviewedAttribute()
    {
        return $this->status === 'reviewed';
    }

    public function getIsShortlistedAttribute()
    {
        return $this->status === 'shortlisted';
    }

    public function getIsInterviewedAttribute()
    {
        return $this->status === 'interviewed';
    }

    public function getIsRejectedAttribute()
    {
        return $this->status === 'rejected';
    }

    public function getIsHiredAttribute()
    {
        return $this->status === 'hired';
    }

    public function getCanReviewAttribute()
    {
        return $this->is_pending;
    }

    public function getCanShortlistAttribute()
    {
        return $this->is_reviewed;
    }

    public function getCanInterviewAttribute()
    {
        return $this->is_shortlisted;
    }

    public function getCanRejectAttribute()
    {
        return in_array($this->status, ['pending', 'reviewed', 'shortlisted', 'interviewed']);
    }

    public function getCanHireAttribute()
    {
        return $this->is_interviewed;
    }

    public function getDocumentsCountAttribute()
    {
        return $this->documents()->count();
    }

    public function getInterviewsCountAttribute()
    {
        return $this->interviews()->count();
    }

    public function getScheduledInterviewsCountAttribute()
    {
        return $this->interviews()->where('status', 'scheduled')->count();
    }

    public function getCompletedInterviewsCountAttribute()
    {
        return $this->interviews()->where('status', 'completed')->count();
    }

    // Méthodes utilitaires
    public function review($reviewedBy, $notes = null)
    {
        $this->update([
            'status' => 'reviewed',
            'reviewed_at' => now(),
            'reviewed_by' => $reviewedBy,
            'notes' => $notes ?? $this->notes
        ]);
    }

    public function shortlist($shortlistedBy, $notes = null)
    {
        $this->update([
            'status' => 'shortlisted',
            'reviewed_at' => now(),
            'reviewed_by' => $shortlistedBy,
            'notes' => $notes ?? $this->notes
        ]);
    }

    public function scheduleInterview($scheduledAt, $location, $type = 'in_person', $meetingLink = null, $notes = null)
    {
        $this->update([
            'interview_scheduled_at' => $scheduledAt,
            'interview_notes' => $notes ?? $this->interview_notes
        ]);

        // Créer l'entretien
        RecruitmentInterview::create([
            'application_id' => $this->id,
            'scheduled_at' => $scheduledAt,
            'location' => $location,
            'type' => $type,
            'meeting_link' => $meetingLink,
            'notes' => $notes,
            'status' => 'scheduled'
        ]);
    }

    public function completeInterview($completedBy, $feedback = null)
    {
        $this->update([
            'status' => 'interviewed',
            'interview_completed_at' => now(),
            'interview_notes' => $feedback ?? $this->interview_notes
        ]);

        // Mettre à jour l'entretien
        $interview = $this->interviews()->latest()->first();
        if ($interview) {
            $interview->update([
                'status' => 'completed',
                'completed_at' => now(),
                'feedback' => $feedback,
                'interviewer_id' => $completedBy
            ]);
        }
    }

    public function reject($rejectedBy, $reason)
    {
        $this->update([
            'status' => 'rejected',
            'rejection_reason' => $reason,
            'reviewed_at' => now(),
            'reviewed_by' => $rejectedBy
        ]);
    }

    public function hire($hiredBy, $notes = null)
    {
        $this->update([
            'status' => 'hired',
            'reviewed_at' => now(),
            'reviewed_by' => $hiredBy,
            'notes' => $notes ?? $this->notes
        ]);
    }

    // Méthodes statiques
    public static function getApplicationStats($requestId = null)
    {
        $query = self::query();
        if ($requestId) {
            $query->where('recruitment_request_id', $requestId);
        }

        $applications = $query->get();
        
        return [
            'total_applications' => $applications->count(),
            'pending_applications' => $applications->where('status', 'pending')->count(),
            'reviewed_applications' => $applications->where('status', 'reviewed')->count(),
            'shortlisted_applications' => $applications->where('status', 'shortlisted')->count(),
            'interviewed_applications' => $applications->where('status', 'interviewed')->count(),
            'hired_applications' => $applications->where('status', 'hired')->count(),
            'rejected_applications' => $applications->where('status', 'rejected')->count(),
            'average_processing_time' => $applications->where('status', 'hired')->avg(function ($app) {
                return $app->created_at->diffInDays($app->updated_at);
            }) ?? 0,
            'applications_by_status' => $applications->groupBy('status')->map->count(),
            'applications_by_month' => $applications->groupBy(function ($app) {
                return $app->created_at->format('Y-m');
            })->map->count()
        ];
    }

    public static function getApplicationsByRequest($requestId)
    {
        return self::byRequest($requestId)
            ->with(['recruitmentRequest', 'reviewer', 'documents', 'interviews'])
            ->orderBy('created_at', 'desc')
            ->get();
    }

    public static function getApplicationsByCandidate($email)
    {
        return self::byCandidate($email)
            ->with(['recruitmentRequest', 'reviewer', 'documents', 'interviews'])
            ->orderBy('created_at', 'desc')
            ->get();
    }

    public static function getPendingApplications()
    {
        return self::pending()->with(['recruitmentRequest', 'documents'])->get();
    }

    public static function getShortlistedApplications()
    {
        return self::shortlisted()->with(['recruitmentRequest', 'reviewer', 'documents'])->get();
    }

    public static function getInterviewedApplications()
    {
        return self::interviewed()->with(['recruitmentRequest', 'reviewer', 'documents', 'interviews'])->get();
    }

    public static function getHiredApplications()
    {
        return self::hired()->with(['recruitmentRequest', 'reviewer', 'documents', 'interviews'])->get();
    }

    public static function getRejectedApplications()
    {
        return self::rejected()->with(['recruitmentRequest', 'reviewer'])->get();
    }
}

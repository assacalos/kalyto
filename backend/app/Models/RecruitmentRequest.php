<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class RecruitmentRequest extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'department',
        'position',
        'description',
        'requirements',
        'responsibilities',
        'number_of_positions',
        'employment_type',
        'experience_level',
        'salary_range',
        'location',
        'application_deadline',
        'status',
        'rejection_reason',
        'published_at',
        'published_by',
        'approved_at',
        'approved_by',
        'created_by',
        'updated_by'
    ];

    protected $casts = [
        'application_deadline' => 'datetime',
        'published_at' => 'datetime',
        'approved_at' => 'datetime'
    ];

    // Relations
    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function updater()
    {
        return $this->belongsTo(User::class, 'updated_by');
    }

    public function publisher()
    {
        return $this->belongsTo(User::class, 'published_by');
    }

    public function approver()
    {
        return $this->belongsTo(User::class, 'approved_by');
    }

    public function applications()
    {
        return $this->hasMany(RecruitmentApplication::class);
    }

    // Scopes
    public function scopeDraft($query)
    {
        return $query->where('status', 'draft');
    }

    public function scopePublished($query)
    {
        return $query->where('status', 'published');
    }

    public function scopeClosed($query)
    {
        return $query->where('status', 'closed');
    }

    public function scopeCancelled($query)
    {
        return $query->where('status', 'cancelled');
    }

    public function scopeByDepartment($query, $department)
    {
        return $query->where('department', $department);
    }

    public function scopeByPosition($query, $position)
    {
        return $query->where('position', $position);
    }

    public function scopeByEmploymentType($query, $employmentType)
    {
        return $query->where('employment_type', $employmentType);
    }

    public function scopeByExperienceLevel($query, $experienceLevel)
    {
        return $query->where('experience_level', $experienceLevel);
    }

    public function scopeByDeadline($query, $startDate, $endDate)
    {
        return $query->whereBetween('application_deadline', [$startDate, $endDate]);
    }

    public function scopeExpiring($query, $days = 7)
    {
        $deadline = now()->addDays($days);
        return $query->where('application_deadline', '<=', $deadline)
                    ->where('application_deadline', '>', now())
                    ->where('status', 'published');
    }

    public function scopeExpired($query)
    {
        return $query->where('application_deadline', '<', now());
    }

    // Accesseurs
    public function getStatusLibelleAttribute()
    {
        $statuses = [
            'draft' => 'Brouillon',
            'published' => 'Publié',
            'closed' => 'Fermé',
            'cancelled' => 'Annulé'
        ];

        return $statuses[$this->status] ?? $this->status;
    }

    public function getEmploymentTypeLibelleAttribute()
    {
        $types = [
            'full_time' => 'Temps plein',
            'part_time' => 'Temps partiel',
            'contract' => 'Contrat',
            'internship' => 'Stage'
        ];

        return $types[$this->employment_type] ?? $this->employment_type;
    }

    public function getExperienceLevelLibelleAttribute()
    {
        $levels = [
            'entry' => 'Débutant',
            'junior' => 'Junior (0-2 ans)',
            'mid' => 'Intermédiaire (2-5 ans)',
            'senior' => 'Senior (5-10 ans)',
            'expert' => 'Expert (10+ ans)'
        ];

        return $levels[$this->experience_level] ?? $this->experience_level;
    }

    public function getCreatorNameAttribute()
    {
        if (!$this->relationLoaded('creator') || !$this->creator) {
            return 'N/A';
        }
        return trim(($this->creator->prenom ?? '') . ' ' . ($this->creator->nom ?? '')) ?: 'N/A';
    }

    public function getUpdaterNameAttribute()
    {
        if (!$this->relationLoaded('updater') || !$this->updater) {
            return 'N/A';
        }
        return trim(($this->updater->prenom ?? '') . ' ' . ($this->updater->nom ?? '')) ?: 'N/A';
    }

    public function getPublisherNameAttribute()
    {
        if (!$this->relationLoaded('publisher') || !$this->publisher) {
            return 'N/A';
        }
        return trim(($this->publisher->prenom ?? '') . ' ' . ($this->publisher->nom ?? '')) ?: 'N/A';
    }

    public function getApproverNameAttribute()
    {
        if (!$this->relationLoaded('approver') || !$this->approver) {
            return 'N/A';
        }
        return trim(($this->approver->prenom ?? '') . ' ' . ($this->approver->nom ?? '')) ?: 'N/A';
    }

    public function getIsDraftAttribute()
    {
        return $this->status === 'draft';
    }

    public function getIsPublishedAttribute()
    {
        return $this->status === 'published';
    }

    public function getIsClosedAttribute()
    {
        return $this->status === 'closed';
    }

    public function getIsCancelledAttribute()
    {
        return $this->status === 'cancelled';
    }

    public function getCanPublishAttribute()
    {
        return $this->is_draft;
    }

    public function getCanCloseAttribute()
    {
        return $this->is_published;
    }

    public function getCanCancelAttribute()
    {
        return $this->is_draft || $this->is_published;
    }

    public function getCanEditAttribute()
    {
        return $this->is_draft;
    }

    public function getIsExpiringAttribute()
    {
        if ($this->status !== 'published') return false;
        $daysUntilDeadline = $this->application_deadline->diffInDays(now());
        return $daysUntilDeadline <= 7 && $daysUntilDeadline >= 0;
    }

    public function getIsExpiredAttribute()
    {
        return $this->application_deadline < now();
    }

    public function getApplicationsCountAttribute()
    {
        return $this->applications()->count();
    }

    public function getPendingApplicationsCountAttribute()
    {
        return $this->applications()->where('status', 'pending')->count();
    }

    public function getShortlistedApplicationsCountAttribute()
    {
        return $this->applications()->where('status', 'shortlisted')->count();
    }

    public function getHiredApplicationsCountAttribute()
    {
        return $this->applications()->where('status', 'hired')->count();
    }

    // Méthodes utilitaires
    public function publish($publishedBy)
    {
        $this->update([
            'status' => 'published',
            'published_at' => now(),
            'published_by' => $publishedBy
        ]);
    }

    public function close()
    {
        $this->update(['status' => 'closed']);
    }

    public function cancel($reason = null)
    {
        $this->update([
            'status' => 'cancelled',
            'rejection_reason' => $reason
        ]);
    }

    public function approve($approvedBy)
    {
        $this->update([
            'approved_at' => now(),
            'approved_by' => $approvedBy
        ]);
    }

    // Méthodes statiques
    public static function getRecruitmentStats()
    {
        $requests = self::all();
        $applications = RecruitmentApplication::all();
        
        return [
            'total_requests' => $requests->count(),
            'draft_requests' => $requests->where('status', 'draft')->count(),
            'published_requests' => $requests->where('status', 'published')->count(),
            'closed_requests' => $requests->where('status', 'closed')->count(),
            'cancelled_requests' => $requests->where('status', 'cancelled')->count(),
            'total_applications' => $applications->count(),
            'pending_applications' => $applications->where('status', 'pending')->count(),
            'shortlisted_applications' => $applications->where('status', 'shortlisted')->count(),
            'interviewed_applications' => $applications->where('status', 'interviewed')->count(),
            'hired_applications' => $applications->where('status', 'hired')->count(),
            'rejected_applications' => $applications->where('status', 'rejected')->count(),
            'average_application_time' => $applications->where('status', 'hired')->avg(function ($app) {
                return $app->created_at->diffInDays($app->updated_at);
            }) ?? 0,
            'applications_by_department' => $requests->groupBy('department')->map(function ($deptRequests) {
                return $deptRequests->sum(function ($request) {
                    return $request->applications_count;
                });
            }),
            'applications_by_position' => $requests->groupBy('position')->map(function ($posRequests) {
                return $posRequests->sum(function ($request) {
                    return $request->applications_count;
                });
            }),
            'recent_applications' => $applications->sortByDesc('created_at')->take(10)->values()
        ];
    }

    public static function getRequestsByDepartment($department)
    {
        return self::byDepartment($department)->with(['creator', 'publisher', 'approver'])->get();
    }

    public static function getRequestsByPosition($position)
    {
        return self::byPosition($position)->with(['creator', 'publisher', 'approver'])->get();
    }

    public static function getExpiringRequests()
    {
        return self::expiring()->with(['creator', 'publisher', 'approver'])->get();
    }

    public static function getExpiredRequests()
    {
        return self::expired()->with(['creator', 'publisher', 'approver'])->get();
    }

    public static function getPublishedRequests()
    {
        return self::published()->with(['creator', 'publisher', 'approver'])->get();
    }

    public static function getDraftRequests()
    {
        return self::draft()->with(['creator'])->get();
    }
}

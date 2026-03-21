<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class EmployeePerformance extends Model
{
    use HasFactory;

    protected $fillable = [
        'employee_id',
        'period',
        'rating',
        'comments',
        'goals',
        'achievements',
        'areas_for_improvement',
        'status',
        'reviewed_by',
        'reviewed_at',
        'created_by'
    ];

    protected $casts = [
        'rating' => 'decimal:1',
        'reviewed_at' => 'datetime'
    ];

    // Relations
    public function employee()
    {
        return $this->belongsTo(Employee::class);
    }

    public function reviewer()
    {
        return $this->belongsTo(User::class, 'reviewed_by');
    }

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    // Scopes
    public function scopeDraft($query)
    {
        return $query->where('status', 'draft');
    }

    public function scopeSubmitted($query)
    {
        return $query->where('status', 'submitted');
    }

    public function scopeReviewed($query)
    {
        return $query->where('status', 'reviewed');
    }

    public function scopeApproved($query)
    {
        return $query->where('status', 'approved');
    }

    public function scopeByEmployee($query, $employeeId)
    {
        return $query->where('employee_id', $employeeId);
    }

    public function scopeByPeriod($query, $period)
    {
        return $query->where('period', $period);
    }

    public function scopeByRating($query, $minRating, $maxRating = null)
    {
        if ($maxRating === null) {
            return $query->where('rating', '>=', $minRating);
        }
        return $query->whereBetween('rating', [$minRating, $maxRating]);
    }

    public function scopeByYear($query, $year)
    {
        return $query->where('period', 'like', $year . '%');
    }

    public function scopeExcellent($query)
    {
        return $query->where('rating', '>=', 4.5);
    }

    public function scopeGood($query)
    {
        return $query->whereBetween('rating', [3.5, 4.4]);
    }

    public function scopeAverage($query)
    {
        return $query->whereBetween('rating', [2.5, 3.4]);
    }

    public function scopePoor($query)
    {
        return $query->whereBetween('rating', [1.0, 2.4]);
    }

    public function scopeNeedsImprovement($query)
    {
        return $query->where('rating', '<', 2.5);
    }

    // Accesseurs
    public function getStatusLibelleAttribute()
    {
        $statuses = [
            'draft' => 'Brouillon',
            'submitted' => 'Soumis',
            'reviewed' => 'Évalué',
            'approved' => 'Approuvé'
        ];

        return $statuses[$this->status] ?? $this->status;
    }

    public function getReviewerNameAttribute()
    {
        return $this->reviewer ? $this->reviewer->prenom . ' ' . $this->reviewer->nom : 'N/A';
    }

    public function getCreatorNameAttribute()
    {
        return $this->creator ? $this->creator->prenom . ' ' . $this->creator->nom : 'N/A';
    }

    public function getFormattedRatingAttribute()
    {
        return number_format($this->rating, 1);
    }

    public function getRatingTextAttribute()
    {
        if ($this->rating >= 4.5) return 'Excellent';
        if ($this->rating >= 3.5) return 'Bon';
        if ($this->rating >= 2.5) return 'Moyen';
        if ($this->rating >= 1.0) return 'Faible';
        return 'Très faible';
    }

    public function getRatingColorAttribute()
    {
        if ($this->rating >= 4.5) return 'green';
        if ($this->rating >= 3.5) return 'blue';
        if ($this->rating >= 2.5) return 'orange';
        if ($this->rating >= 1.0) return 'red';
        return 'red';
    }

    public function getIsDraftAttribute()
    {
        return $this->status === 'draft';
    }

    public function getIsSubmittedAttribute()
    {
        return $this->status === 'submitted';
    }

    public function getIsReviewedAttribute()
    {
        return $this->status === 'reviewed';
    }

    public function getIsApprovedAttribute()
    {
        return $this->status === 'approved';
    }

    public function getIsExcellentAttribute()
    {
        return $this->rating >= 4.5;
    }

    public function getIsGoodAttribute()
    {
        return $this->rating >= 3.5 && $this->rating < 4.5;
    }

    public function getIsAverageAttribute()
    {
        return $this->rating >= 2.5 && $this->rating < 3.5;
    }

    public function getIsPoorAttribute()
    {
        return $this->rating >= 1.0 && $this->rating < 2.5;
    }

    public function getNeedsImprovementAttribute()
    {
        return $this->rating < 2.5;
    }

    // Méthodes utilitaires
    public function submit()
    {
        $this->update(['status' => 'submitted']);
    }

    public function review($reviewedBy, $comments = null)
    {
        $this->update([
            'status' => 'reviewed',
            'reviewed_by' => $reviewedBy,
            'reviewed_at' => now(),
            'comments' => $comments ?? $this->comments
        ]);
    }

    public function approve($approvedBy, $finalComments = null)
    {
        $this->update([
            'status' => 'approved',
            'reviewed_by' => $approvedBy,
            'reviewed_at' => now(),
            'comments' => $finalComments ?? $this->comments
        ]);
    }

    public function updateRating($newRating, $updatedBy = null)
    {
        $this->update([
            'rating' => $newRating,
            'updated_by' => $updatedBy
        ]);
    }

    public function addComment($comment, $addedBy = null)
    {
        $existingComments = $this->comments ?? '';
        $newComment = $existingComments ? $existingComments . "\n\n" . $comment : $comment;
        
        $this->update([
            'comments' => $newComment,
            'updated_by' => $addedBy
        ]);
    }

    // Méthodes statiques
    public static function getPerformanceStats($startDate = null, $endDate = null)
    {
        $query = self::query();
        
        if ($startDate && $endDate) {
            $query->whereBetween('created_at', [$startDate, $endDate]);
        }

        $performances = $query->get();
        
        return [
            'total_performances' => $performances->count(),
            'draft_performances' => $performances->where('status', 'draft')->count(),
            'submitted_performances' => $performances->where('status', 'submitted')->count(),
            'reviewed_performances' => $performances->where('status', 'reviewed')->count(),
            'approved_performances' => $performances->where('status', 'approved')->count(),
            'excellent_performances' => $performances->filter(function ($perf) {
                return $perf->is_excellent;
            })->count(),
            'good_performances' => $performances->filter(function ($perf) {
                return $perf->is_good;
            })->count(),
            'average_performances' => $performances->filter(function ($perf) {
                return $perf->is_average;
            })->count(),
            'poor_performances' => $performances->filter(function ($perf) {
                return $perf->is_poor;
            })->count(),
            'needs_improvement' => $performances->filter(function ($perf) {
                return $perf->needs_improvement;
            })->count(),
            'average_rating' => $performances->avg('rating') ?? 0,
            'highest_rating' => $performances->max('rating') ?? 0,
            'lowest_rating' => $performances->min('rating') ?? 0,
            'performances_by_status' => $performances->groupBy('status')->map->count(),
            'performances_by_period' => $performances->groupBy('period')->map->count()
        ];
    }

    public static function getPerformancesByEmployee($employeeId)
    {
        return self::byEmployee($employeeId)
            ->with(['reviewer', 'creator'])
            ->orderBy('period', 'desc')
            ->get();
    }

    public static function getPerformancesByPeriod($period)
    {
        return self::byPeriod($period)->with(['employee', 'reviewer', 'creator'])->get();
    }

    public static function getPerformancesByYear($year)
    {
        return self::byYear($year)->with(['employee', 'reviewer', 'creator'])->get();
    }

    public static function getExcellentPerformances()
    {
        return self::excellent()->with(['employee', 'reviewer', 'creator'])->get();
    }

    public static function getPoorPerformances()
    {
        return self::poor()->with(['employee', 'reviewer', 'creator'])->get();
    }

    public static function getPerformancesNeedingImprovement()
    {
        return self::needsImprovement()->with(['employee', 'reviewer', 'creator'])->get();
    }

    public static function getDraftPerformances()
    {
        return self::draft()->with(['employee', 'creator'])->get();
    }

    public static function getSubmittedPerformances()
    {
        return self::submitted()->with(['employee', 'creator'])->get();
    }
}

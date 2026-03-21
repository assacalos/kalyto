<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Besoin extends Model
{
    use HasFactory;

    protected $table = 'besoins';

    protected $fillable = [
        'title',
        'description',
        'created_by',
        'reminder_frequency',
        'next_reminder_at',
        'status',
        'treated_at',
        'treated_by',
        'treated_note',
    ];

    protected $casts = [
        'next_reminder_at' => 'datetime',
        'treated_at' => 'datetime',
    ];

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function treatedByUser()
    {
        return $this->belongsTo(User::class, 'treated_by');
    }

    public function scopePending($query)
    {
        return $query->where('status', 'pending');
    }

    public function scopeTreated($query)
    {
        return $query->where('status', 'treated');
    }

    public function isReminderDue(): bool
    {
        if ($this->status !== 'pending') {
            return false;
        }
        return $this->next_reminder_at && now()->gte($this->next_reminder_at);
    }

    /** Nombre de jours entre deux rappels. */
    public function getReminderIntervalDays(): int
    {
        return match ($this->reminder_frequency ?? 'weekly') {
            'daily' => 1,
            'every_2_days' => 2,
            'weekly' => 7,
            default => 7,
        };
    }

    /** Calcule la prochaine date de rappel à partir de maintenant. */
    public function computeNextReminderAt(): ?\DateTimeInterface
    {
        $days = $this->getReminderIntervalDays();
        return now()->addDays($days);
    }

    /** Reprogramme le prochain rappel après envoi. */
    public function scheduleNextReminder(): void
    {
        $this->update(['next_reminder_at' => $this->computeNextReminderAt()]);
    }
}

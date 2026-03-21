<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\Besoin;
use App\Services\NotificationService;

class SendBesoinRemindersCommand extends Command
{
    protected $signature = 'app:send-besoin-reminders';

    protected $description = 'Envoie les rappels automatiques au patron pour les besoins en attente (période définie par le technicien)';

    public function handle(NotificationService $notificationService): int
    {
        $besoins = Besoin::pending()
            ->whereNotNull('next_reminder_at')
            ->where('next_reminder_at', '<=', now())
            ->with('creator')
            ->get();

        $count = 0;
        foreach ($besoins as $besoin) {
            try {
                $notificationService->notifyBesoinReminder($besoin);
                $besoin->scheduleNextReminder();
                $count++;
            } catch (\Throwable $e) {
                $this->warn("Besoin #{$besoin->id}: " . $e->getMessage());
            }
        }

        if ($count > 0) {
            $this->info("{$count} rappel(s) besoin envoyé(s) au patron.");
        }
        return 0;
    }
}

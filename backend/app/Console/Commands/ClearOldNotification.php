<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\Notification;

class ClearOldNotification extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'app:clear-old-notification';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Supprime les notifications vieilles de plus de 30 jours';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        //
        // On demande à Eloquent de supprimer les vieilles lignes
        $count = Notification::where('created_at', '<', now()->subDays(30))->delete();

    // On affiche un message de succès dans la console
        $this->info("$count notifications anciennes ont été supprimées avec succès !");
    }
}

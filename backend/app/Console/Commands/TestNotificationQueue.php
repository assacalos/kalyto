<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Jobs\SendNotificationJob;
use App\Models\User;

class TestNotificationQueue extends Command
{
    /**
     * Le nom et la signature de la commande.
     *
     * @var string
     */
    protected $signature = 'test:notification-queue {--user-id=1}';

    /**
     * La description de la commande.
     *
     * @var string
     */
    protected $description = 'Tester le système de queue pour les notifications';

    /**
     * Exécuter la commande.
     *
     * @return int
     */
    public function handle()
    {
        $userId = $this->option('user-id');

        // Vérifier que l'utilisateur existe
        $user = User::find($userId);
        if (!$user) {
            $this->error("❌ Utilisateur avec l'ID {$userId} introuvable !");
            $this->info("💡 Utilisez --user-id=X pour spécifier un autre ID");
            return 1;
        }

        $this->info("🚀 Test du système de queue pour les notifications...");
        $this->newLine();

        // Afficher la configuration actuelle
        $queueConnection = config('queue.default');
        $this->info("📋 Configuration actuelle : QUEUE_CONNECTION={$queueConnection}");
        
        if ($queueConnection === 'sync') {
            $this->warn("⚠️  Mode 'sync' détecté : Les notifications seront traitées immédiatement (sans queue)");
        } else {
            $this->info("✅ Mode '{$queueConnection}' détecté : Les notifications seront mises en queue");
            $this->warn("⚠️  Assurez-vous que le worker tourne : php artisan queue:work");
        }
        
        $this->newLine();

        // Créer plusieurs notifications de test
        $notifications = [
            [
                'user_id' => $userId,
                'title' => 'Test Queue #1',
                'message' => 'Première notification de test via queue',
                'type' => 'info',
                'priorite' => 'normale'
            ],
            [
                'user_id' => $userId,
                'title' => 'Test Queue #2',
                'message' => 'Deuxième notification de test via queue',
                'type' => 'success',
                'priorite' => 'normale'
            ],
            [
                'user_id' => $userId,
                'title' => 'Test Queue #3',
                'message' => 'Troisième notification de test via queue',
                'type' => 'warning',
                'priorite' => 'haute'
            ],
        ];

        $this->info("📤 Envoi de " . count($notifications) . " notifications à la queue...");
        $this->newLine();

        foreach ($notifications as $index => $notificationData) {
            SendNotificationJob::dispatch($notificationData);
            $this->line("  ✅ Notification #" . ($index + 1) . " envoyée : {$notificationData['title']}");
        }

        $this->newLine();
        $this->info("✅ Toutes les notifications ont été envoyées à la queue !");
        $this->newLine();

        if ($queueConnection === 'sync') {
            $this->info("💡 Les notifications ont été créées immédiatement en base de données.");
        } else {
            $this->info("💡 Les notifications sont maintenant dans la table 'jobs'.");
            $this->info("💡 Le worker va les traiter automatiquement.");
            $this->newLine();
            $this->warn("⚠️  Si le worker ne tourne pas, lancez : php artisan queue:work");
        }

        $this->newLine();
        $this->info("📊 Pour vérifier les notifications créées :");
        $this->line("   SELECT * FROM notifications WHERE user_id = {$userId} ORDER BY created_at DESC;");
        $this->newLine();
        $this->info("📋 Pour voir les jobs en attente :");
        $this->line("   SELECT * FROM jobs;");
        $this->newLine();

        return 0;
    }
}


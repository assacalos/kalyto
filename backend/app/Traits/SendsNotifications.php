<?php

namespace App\Traits;

use Illuminate\Support\Facades\Log;

/**
 * Trait pour envoyer les notifications (Email, Push, Pusher) sans faire échouer la requête.
 * En cas d'erreur, on log et on continue pour que l'utilisateur reçoive quand même un succès
 * car l'entité a bien été créée/modifiée en base.
 *
 * Les emails sont envoyés via Mail::queue() dans ProcessNotificationActionsJob (EventNotificationMail
 * implémente ShouldQueue). Utiliser QUEUE_CONNECTION=database (ex. o2switch) et un worker.
 */
trait SendsNotifications
{
    /**
     * Exécute un bloc d'envoi de notifications dans un try-catch.
     * En cas d'exception, log l'erreur et ne propage pas.
     *
     * @param callable $fn Bloc qui gère l'envoi (Email, Push, Pusher)
     */
    protected function safeNotify(callable $fn): void
    {
        try {
            $fn();
        } catch (\Exception $e) {
            Log::error($e->getMessage());
        }
    }
}

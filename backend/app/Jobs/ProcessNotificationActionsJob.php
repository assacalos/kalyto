<?php

namespace App\Jobs;

use App\Mail\EventNotificationMail;
use App\Models\Notification;
use App\Services\FcmV1Service;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;

class ProcessNotificationActionsJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public $tries = 3;
    public $backoff = [10, 30, 60];
    protected $notification;

    public function __construct(Notification $notification)
    {
        $this->notification = $notification;
    }

    public function handle()
    {
        try {
            // Sauvegarder l'ID avant de recharger
            $notificationId = $this->notification->id ?? null;
            
            // Recharger la notification depuis la base de données
            // (nécessaire car avec SerializesModels, seul l'ID est sérialisé)
            $this->notification = $this->notification->fresh(['user']);
            
            if (!$this->notification) {
                Log::error("Notification introuvable dans ProcessNotificationActionsJob", [
                    'notification_id' => $notificationId ?? 'N/A'
                ]);
                return;
            }

            // 1. Envoi Push (Firebase)
            $this->sendPush();

            // 2. Envoi WebSocket (Pusher/Reverb) pour mise à jour UI en direct
            // On lance l'événement Laravel standard seulement si le broadcasting est activé
            $broadcastDriver = config('broadcasting.default');
            if ($broadcastDriver && $broadcastDriver !== 'null') {
                try {
                    event(new \App\Events\NotificationReceived($this->notification));
                } catch (\Exception $e) {
                    // Ne pas faire échouer le job si le broadcasting échoue
                    Log::warning("Erreur lors du broadcasting de la notification", [
                        'notification_id' => $this->notification->id,
                        'error' => $e->getMessage()
                    ]);
                }
            }

            // 3. Envoi email au destinataire (en plus des notifications in-app / push)
            $this->sendEmail();

        } catch (\Exception $e) {
            Log::error("Erreur Job Notifications", [
                'notification_id' => $this->notification->id ?? 'N/A',
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            // Relancer l'exception pour que Laravel marque le job comme échoué
            throw $e;
        }
    }

    protected function sendPush()
    {
        try {
            $pushService = app(FcmV1Service::class);
            
            // S'assurer que data est bien un array
            $data = $this->notification->data ?? [];
            if (is_string($data)) {
                $data = json_decode($data, true) ?? [];
            }
            
            $title = $this->notification->title ?? $this->notification->titre ?? 'Nouvelle notification';
            $message = $this->notification->message ?? '';
            
            Log::info("Tentative d'envoi de notification push", [
                'notification_id' => $this->notification->id,
                'user_id' => $this->notification->user_id,
                'title' => $title
            ]);
            
            // Options explicites pour que le son et la priorité soient appliqués (client, devis, etc.)
            $options = [
                'sound' => 'default',
                'priority' => in_array($this->notification->priorite ?? '', ['haute', 'urgente']) ? 'high' : 'high',
            ];

            $result = $pushService->sendToUser(
                $this->notification->user_id,
                $title,
                $message,
                [
                    'entity_type' => $data['entity_type'] ?? $this->notification->entity_type ?? null,
                    'entity_id' => (string)($data['entity_id'] ?? $this->notification->entity_id ?? ''),
                    'action_route' => $data['action_route'] ?? null,
                    'id' => (string)$this->notification->id,
                    'type' => $this->notification->type,
                ],
                $options
            );
            
            if (isset($result['success']) && !$result['success']) {
                Log::warning("Échec de l'envoi de notification push", [
                    'notification_id' => $this->notification->id,
                    'message' => $result['message'] ?? 'Raison inconnue'
                ]);
            }
            
        } catch (\Exception $e) {
            Log::error("Erreur lors de l'envoi push", [
                'notification_id' => $this->notification->id ?? 'N/A',
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            throw $e;
        }
    }

    /**
     * Envoie un email au destinataire de la notification (user_id) si l'utilisateur a un email valide.
     * Une erreur d'envoi ne fait pas échouer le job.
     */
    protected function sendEmail(): void
    {
        try {
            $user = $this->notification->user;
            if (!$user || empty(trim($user->email ?? ''))) {
                return;
            }

            $data = $this->notification->data ?? [];
            if (is_string($data)) {
                $data = json_decode($data, true) ?? [];
            }

            $titre = $this->notification->title ?? $this->notification->titre ?? 'Nouvelle notification';
            $message = $this->notification->message ?? '';

            $actionRoute = $data['action_route'] ?? null;
            $actionUrl = null;
            if (!empty($actionRoute)) {
                $baseUrl = rtrim(config('app.url', ''), '/');
                $actionUrl = str_starts_with($actionRoute, 'http') ? $actionRoute : $baseUrl . '/' . ltrim($actionRoute, '/');
            }

            $recipientName = trim(($user->prenom ?? '') . ' ' . ($user->nom ?? '')) ?: null;
            Mail::to($user->email)->send(new EventNotificationMail(
                $titre,
                $message,
                $actionUrl,
                'Voir dans l\'application',
                $recipientName
            ));
        } catch (\Exception $e) {
            Log::warning("Erreur lors de l'envoi de l'email de notification", [
                'notification_id' => $this->notification->id ?? 'N/A',
                'user_id' => $this->notification->user_id ?? 'N/A',
                'error' => $e->getMessage(),
            ]);
        }
    }
}
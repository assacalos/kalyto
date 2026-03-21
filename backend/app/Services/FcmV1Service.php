<?php

namespace App\Services;

use Kreait\Firebase\Factory;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification as FcmNotification;
use Kreait\Firebase\Messaging\AndroidConfig;
use Kreait\Firebase\Messaging\ApnsConfig;
use App\Models\DeviceToken;
use App\Models\User;
use Illuminate\Support\Facades\Log;

/**
 * Service FCM v1 (API moderne)
 * Remplace l'ancien PushNotificationService qui utilise l'API Legacy
 */
class FcmV1Service
{
    protected $messaging;

    public function __construct()
    {
        try {
            $serviceAccountPath = $this->resolveServiceAccountPath();

            if (!$serviceAccountPath || !file_exists($serviceAccountPath)) {
                Log::error("Fichier JSON de compte de service Firebase introuvable", [
                    'path' => $serviceAccountPath
                ]);
                $this->messaging = null;
                return;
            }

            $factory = (new Factory)->withServiceAccount($serviceAccountPath);
            $this->messaging = $factory->createMessaging();

            Log::info("FCM v1 initialisé avec succès (authentification par fichier JSON)");
        } catch (\Exception $e) {
            Log::error("Erreur initialisation FCM v1: " . $e->getMessage());
            $this->messaging = null;
        }
    }

    /**
     * Résout le chemin du fichier JSON (absolu ou relatif à base_path).
     */
    protected function resolveServiceAccountPath(): ?string
    {
        $path = config('services.fcm.service_account_json');
        if (empty($path)) {
            return null;
        }
        if (!str_starts_with($path, '/') && !preg_match('#^[A-Za-z]:\\\\#', $path)) {
            $path = base_path($path);
        }
        return $path;
    }

    /**
     * Indique si le service FCM est correctement configuré (fichier JSON valide et chargé).
     */
    public function isConfigured(): bool
    {
        return $this->messaging !== null;
    }

    /**
     * Envoyer une notification push à un utilisateur
     * 
     * @param int $userId ID de l'utilisateur
     * @param string $title Titre de la notification
     * @param string $body Corps de la notification
     * @param array $data Données supplémentaires (optionnel)
     * @param array $options Options supplémentaires (optionnel)
     * @return array Résultat de l'envoi
     */
    public function sendToUser($userId, $title, $body, $data = [], $options = [])
    {
        if (!$this->messaging) {
            return ['success' => false, 'message' => 'FCM non initialisé'];
        }

        $user = User::find($userId);
        if (!$user) {
            Log::warning("Utilisateur introuvable", ['user_id' => $userId]);
            return ['success' => false, 'message' => 'Utilisateur introuvable'];
        }

        // Récupérer tous les tokens actifs
        $tokens = $user->activeDeviceTokens()->pluck('token')->toArray();

        if (empty($tokens)) {
            Log::warning("Aucun token actif", [
                'user_id' => $userId,
                'user_email' => $user->email ?? 'N/A',
            ]);
            return [
                'success' => false,
                'message' => 'Aucun token d\'appareil actif',
            ];
        }

        return $this->sendToTokens($tokens, $title, $body, $data, $options);
    }

    /**
     * Envoyer une notification à plusieurs tokens
     * 
     * @param array $tokens Liste des tokens FCM
     * @param string $title Titre
     * @param string $body Corps
     * @param array $data Données
     * @param array $options Options
     * @return array
     */
    public function sendToTokens($tokens, $title, $body, $data = [], $options = [])
    {
        if (!$this->messaging) {
            return ['success' => false, 'message' => 'FCM non initialisé'];
        }

        if (empty($tokens)) {
            return ['success' => false, 'message' => 'Aucun token fourni'];
        }

        // Convertir en tableau si nécessaire
        if (is_string($tokens)) {
            $tokens = [$tokens];
        }

        $successCount = 0;
        $failureCount = 0;
        $errors = [];

        foreach ($tokens as $token) {
            try {
                // Créer la notification FCM
                $notification = FcmNotification::create($title, $body);

                // Configuration Android (son + vibration explicites pour tous les types : client, devis, etc.)
                $androidConfig = AndroidConfig::fromArray([
                    'priority' => $options['priority'] ?? 'high',
                    'notification' => [
                        'sound' => $options['sound'] ?? 'default',
                        'default_sound' => true,
                        'default_vibrate_timings' => true,
                        'channel_id' => 'high_importance_channel',
                        'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                        'notification_priority' => 'PRIORITY_HIGH',
                    ],
                ]);

                // Configuration iOS
                $apnsPayload = [
                    'aps' => [
                        'alert' => [
                            'title' => $title,
                            'body' => $body,
                        ],
                        'sound' => $options['sound'] ?? 'default',
                    ],
                ];
                
                // Ajouter le badge seulement s'il est défini et est un nombre
                if (isset($options['badge']) && is_numeric($options['badge'])) {
                    $apnsPayload['aps']['badge'] = (int)$options['badge'];
                }
                
                $apnsConfig = ApnsConfig::fromArray([
                    'payload' => $apnsPayload,
                ]);

                // Créer le message
                $message = CloudMessage::withTarget('token', $token)
                    ->withNotification($notification)
                    ->withData(array_merge([
                        'title' => $title,
                        'body' => $body,
                        'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                    ], $data))
                    ->withAndroidConfig($androidConfig)
                    ->withApnsConfig($apnsConfig);

                // Envoyer
                $result = $this->messaging->send($message);
                
                $successCount++;
                
                // Mettre à jour last_used_at
                $this->markTokenAsUsed($token);
                
                Log::info("Notification FCM v1 envoyée", [
                    'token' => substr($token, 0, 20) . '...',
                    'title' => $title,
                ]);

            } catch (\Kreait\Firebase\Exception\MessagingException $e) {
                $failureCount++;
                $errorCode = $e->getMessage();
                
                Log::error("Erreur FCM v1", [
                    'token' => substr($token, 0, 20) . '...',
                    'error' => $errorCode,
                ]);

                // Désactiver les tokens invalides
                if ($this->isInvalidTokenError($errorCode)) {
                    $this->deactivateToken($token);
                }

                $errors[] = [
                    'token' => substr($token, 0, 20) . '...',
                    'error' => $errorCode,
                ];
            } catch (\Exception $e) {
                $failureCount++;
                Log::error("Erreur envoi FCM v1", [
                    'token' => substr($token, 0, 20) . '...',
                    'error' => $e->getMessage(),
                ]);
                
                $errors[] = [
                    'token' => substr($token, 0, 20) . '...',
                    'error' => $e->getMessage(),
                ];
            }
        }

        return [
            'success' => $successCount > 0,
            'success_count' => $successCount,
            'failure_count' => $failureCount,
            'total' => count($tokens),
            'errors' => $errors,
        ];
    }

    /**
     * Vérifier si l'erreur indique un token invalide
     */
    protected function isInvalidTokenError($error)
    {
        $invalidErrors = [
            'InvalidRegistration',
            'NotRegistered',
            'MismatchSenderId',
            'INVALID_ARGUMENT',
            'UNREGISTERED',
        ];

        foreach ($invalidErrors as $invalidError) {
            if (stripos($error, $invalidError) !== false) {
                return true;
            }
        }

        return false;
    }

    /**
     * Marquer un token comme utilisé
     */
    protected function markTokenAsUsed($token)
    {
        DeviceToken::where('token', $token)->update(['last_used_at' => now()]);
    }

    /**
     * Désactiver un token invalide
     */
    protected function deactivateToken($token)
    {
        DeviceToken::where('token', $token)->update(['is_active' => false]);
        Log::info("Token désactivé (invalide)", ['token' => substr($token, 0, 20) . '...']);
    }

    /**
     * Enregistrer un device token
     */
    public function registerDeviceToken($userId, $token, $deviceInfo = [])
    {
        return DeviceToken::updateOrCreate(
            [
                'user_id' => $userId,
                'token' => $token,
            ],
            [
                'device_type' => $deviceInfo['device_type'] ?? null,
                'device_id' => $deviceInfo['device_id'] ?? null,
                'app_version' => $deviceInfo['app_version'] ?? null,
                'is_active' => true,
                'last_used_at' => now(),
            ]
        );
    }
}


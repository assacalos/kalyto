<?php

namespace App\Services;

/**
 * Alias pour compatibilité avec l'ancien code
 * PushNotificationService pointe vers FcmV1Service
 * 
 * @deprecated Utilisez FcmV1Service directement dans le nouveau code
 */
class PushNotificationService extends FcmV1Service
{
    // Classe vide, hérite de FcmV1Service
    // Toute la logique est dans FcmV1Service
}


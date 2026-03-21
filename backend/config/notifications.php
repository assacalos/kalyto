<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Configuration des Notifications
    |--------------------------------------------------------------------------
    |
    | Configuration pour les notifications en temps réel de l'application ERP
    |
    */

    'broadcasting' => [
        'enabled' => env('NOTIFICATIONS_BROADCASTING_ENABLED', true),
        'driver' => env('BROADCAST_DRIVER', 'pusher'),
    ],

    'pusher' => [
        'app_id' => env('PUSHER_APP_ID'),
        'key' => env('PUSHER_APP_KEY'),
        'secret' => env('PUSHER_APP_SECRET'),
        'cluster' => env('PUSHER_APP_CLUSTER', 'mt1'),
        'useTLS' => true,
    ],

    'channels' => [
        'user' => 'user.{user_id}',
        'role' => 'role.{role_id}',
        'admin' => 'admin',
        'rh' => 'rh',
        'commercial' => 'commercial',
        'comptable' => 'comptable',
        'technicien' => 'technicien',
        'patron' => 'patron',
    ],

    'events' => [
        'notification_received' => 'notification.received',
        'notification_read' => 'notification.read',
        'notification_archived' => 'notification.archived',
        'pointage_created' => 'pointage.created',
        'pointage_validated' => 'pointage.validated',
        'pointage_rejected' => 'pointage.rejected',
        'conge_created' => 'conge.created',
        'conge_approved' => 'conge.approved',
        'conge_rejected' => 'conge.rejected',
        'evaluation_created' => 'evaluation.created',
        'evaluation_signed' => 'evaluation.signed',
        'evaluation_finalized' => 'evaluation.finalized',
        'client_created' => 'client.created',
        'client_approved' => 'client.approved',
        'client_rejected' => 'client.rejected',
        'payment_created' => 'payment.created',
        'payment_validated' => 'payment.validated',
        'system_notification' => 'system.notification',
    ],

    'priorities' => [
        'basse' => 1,
        'normale' => 2,
        'haute' => 3,
        'urgente' => 4,
    ],

    'types' => [
        'pointage' => 'Pointage',
        'conge' => 'Congé',
        'evaluation' => 'Évaluation',
        'client' => 'Client',
        'facture' => 'Facture',
        'paiement' => 'Paiement',
        'systeme' => 'Système',
        'rapport' => 'Rapport',
        'maintenance' => 'Maintenance',
    ],

    'expiration' => [
        'default' => 30, // jours
        'urgent' => 7, // jours
        'system' => 90, // jours
    ],

    'cleanup' => [
        'enabled' => env('NOTIFICATIONS_CLEANUP_ENABLED', true),
        'schedule' => 'daily', // daily, weekly, monthly
        'retention_days' => 90,
    ],
];

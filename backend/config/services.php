<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'mailgun' => [
        'domain' => env('MAILGUN_DOMAIN'),
        'secret' => env('MAILGUN_SECRET'),
        'endpoint' => env('MAILGUN_ENDPOINT', 'api.mailgun.net'),
        'scheme' => 'https',
    ],

    'postmark' => [
        'token' => env('POSTMARK_TOKEN'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'fcm' => [
        // API Legacy (obsolète) - non utilisée par FcmV1Service ni par push:test
        'server_key' => env('FCM_SERVER_KEY'),

        // API v1 (recommandée) : authentification par fichier JSON compte de service Firebase
        // Chemin absolu ou relatif à base_path (ex: storage/app/firebase/service-account.json)
        'service_account_json' => env('FCM_SERVICE_ACCOUNT_JSON', storage_path('app/firebase/service-account.json')),
    ],

];

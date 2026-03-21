<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Cross-Origin Resource Sharing (CORS) Configuration
    |--------------------------------------------------------------------------
    |
    | Here you may configure your settings for cross-origin resource sharing
    | or "CORS". This determines what cross-origin operations may execute
    | in web browsers. You are free to adjust these settings as needed.
    |
    | To learn more: https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS
    |
    | IMPORTANT: Pour les applications mobiles Flutter, CORS est moins restrictif
    | car les applications natives ne sont pas soumises aux mêmes restrictions
    | que les navigateurs web. Cependant, cette configuration permet également
    | l'accès depuis des applications web.
    |
    */

    /*
    |--------------------------------------------------------------------------
    | Paths
    |--------------------------------------------------------------------------
    |
    | Les chemins pour lesquels CORS sera appliqué. Par défaut, toutes les
    | routes API et les cookies CSRF de Sanctum.
    |
    */

    'paths' => ['api/*', 'sanctum/csrf-cookie'],

    /*
    |--------------------------------------------------------------------------
    | Allowed Methods
    |--------------------------------------------------------------------------
    |
    | Les méthodes HTTP autorisées pour les requêtes CORS.
    | OPTIONS est nécessaire pour les requêtes preflight.
    |
    */

    'allowed_methods' => ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS', 'HEAD'],

    /*
    |--------------------------------------------------------------------------
    | Allowed Origins
    |--------------------------------------------------------------------------
    |
    | Les origines autorisées. Utilisez '*' pour autoriser toutes les origines
    | (recommandé pour les applications mobiles Flutter).
    |
    | Pour la production, vous pouvez spécifier des origines spécifiques :
    | CORS_ALLOWED_ORIGINS=https://app.example.com,https://admin.example.com
    |
    | Pour les applications mobiles, '*' est généralement acceptable car
    | les applications natives ne sont pas soumises aux restrictions CORS.
    |
    */

    'allowed_origins' => array_filter(explode(',', env('CORS_ALLOWED_ORIGINS', '*'))),

    /*
    |--------------------------------------------------------------------------
    | Allowed Origins Patterns
    |--------------------------------------------------------------------------
    |
    | Patterns d'origines autorisées (expressions régulières).
    | Utile pour autoriser des sous-domaines dynamiques.
    |
    */

    'allowed_origins_patterns' => [],

    /*
    |--------------------------------------------------------------------------
    | Allowed Headers
    |--------------------------------------------------------------------------
    |
    | Les en-têtes HTTP autorisés dans les requêtes CORS.
    | Ajout de headers couramment utilisés par Flutter et les applications mobiles.
    |
    */

    'allowed_headers' => [
        'Content-Type',
        'Authorization',
        'X-Requested-With',
        'Accept',
        'Origin',
        'X-CSRF-TOKEN',
        'X-XSRF-TOKEN',
        'Cache-Control',
        'Pragma',
        'X-Auth-Token',
        'X-API-Key',
    ],

    /*
    |--------------------------------------------------------------------------
    | Exposed Headers
    |--------------------------------------------------------------------------
    |
    | Les en-têtes que le client peut lire dans la réponse.
    | Utile pour la pagination et les métadonnées.
    |
    */

    'exposed_headers' => [
        'X-Total-Count',
        'X-Page',
        'X-Per-Page',
        'X-Pagination-Total',
        'X-Pagination-Count',
        'X-Pagination-Per-Page',
        'X-Pagination-Current-Page',
        'X-Pagination-Total-Pages',
    ],

    /*
    |--------------------------------------------------------------------------
    | Max Age
    |--------------------------------------------------------------------------
    |
    | Durée en secondes pendant laquelle le résultat d'une requête preflight
    | peut être mis en cache. 3600 = 1 heure.
    |
    */

    'max_age' => 3600,

    /*
    |--------------------------------------------------------------------------
    | Supports Credentials
    |--------------------------------------------------------------------------
    |
    | Indique si les cookies et les credentials peuvent être envoyés avec
    | les requêtes. Important pour l'authentification avec Sanctum.
    |
    | IMPORTANT: 
    | - Pour les applications mobiles Flutter utilisant des tokens Bearer,
    |   supports_credentials peut être false (recommandé).
    | - Pour les applications web utilisant des cookies Sanctum, 
    |   supports_credentials doit être true, mais allowed_origins ne peut
    |   pas contenir '*'. Dans ce cas, spécifiez des origines exactes dans
    |   votre fichier .env (CORS_ALLOWED_ORIGINS).
    |
    | Pour les applications mobiles, false est généralement suffisant car
    | elles utilisent des tokens d'authentification plutôt que des cookies.
    |
    */

    'supports_credentials' => env('CORS_SUPPORTS_CREDENTIALS', false),

];

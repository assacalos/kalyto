<?php

namespace App\Http\Middleware;

use Illuminate\Foundation\Http\Middleware\VerifyCsrfToken as Middleware;

class VerifyCsrfToken extends Middleware
{
    /**
     * The URIs that should be excluded from CSRF verification.
     *
     * @var array<int, string>
     */
    protected $except = [
        // API : l'app utilise un token Bearer (pas de session cookie).
        // Exclure les routes API évite "CSRF token mismatch" sur le navigateur (Flutter web).
        'api/*',
    ];
}

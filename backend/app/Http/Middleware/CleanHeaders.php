<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class CleanHeaders
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $response = $next($request);

        // Nettoyer les en-têtes de la réponse pour éviter les caractères de nouvelle ligne
        $headers = $response->headers->all();
        
        foreach ($headers as $name => $values) {
            // Nettoyer chaque valeur d'en-tête
            $cleanedValues = [];
            foreach ($values as $value) {
                // Supprimer les caractères de nouvelle ligne et les espaces en début/fin
                $cleanedValue = trim(str_replace(["\r", "\n", "\r\n"], '', $value));
                if (!empty($cleanedValue)) {
                    $cleanedValues[] = $cleanedValue;
                }
            }
            
            if (!empty($cleanedValues)) {
                $response->headers->set($name, $cleanedValues);
            }
        }

        return $response;
    }
}


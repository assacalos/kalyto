<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class RoleMiddleware
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next, ...$roles): Response
    {
        if (!auth()->check()) {
            return response()->json(['message' => 'Non authentifié'], 401);
        }

        $user = auth()->user();
        
        // Parser les rôles: si c'est une chaîne comme "1,2,6", la diviser en tableau
        $allowedRoles = [];
        foreach ($roles as $role) {
            // Si le rôle contient une virgule, c'est une chaîne de plusieurs rôles
            if (strpos($role, ',') !== false) {
                $allowedRoles = array_merge($allowedRoles, array_map('intval', explode(',', $role)));
            } else {
                $allowedRoles[] = (int)$role;
            }
        }
        
        // Convertir le rôle de l'utilisateur en entier (gère string "6" ou int 6)
        $userRole = is_numeric($user->role) ? (int) $user->role : 0;
        
        // Dédupliquer les rôles autorisés
        $allowedRoles = array_unique($allowedRoles);
        
        // Accepter aussi si l'utilisateur est Patron ou Admin (au cas où le rôle en base diffère)
        $isAllowed = in_array($userRole, $allowedRoles)
            || (method_exists($user, 'isPatron') && $user->isPatron())
            || (method_exists($user, 'isAdmin') && $user->isAdmin());
        
        if (!$isAllowed) {
            return response()->json([
                'message' => 'Accès refusé. Rôle insuffisant.',
                'required_roles' => array_values($allowedRoles), // array_values pour réindexer
                'user_role' => $userRole,
                'route' => $request->path() // Ajout du chemin pour debug
            ], 403);
        }

        return $next($request);
    }
}

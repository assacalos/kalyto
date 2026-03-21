<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use App\Services\NotificationService;

class NotificationMiddleware
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $response = $next($request);
        
        // Vérifier si l'utilisateur est authentifié
        if (auth()->check()) {
            $user = auth()->user();
            
            // Ajouter le nombre de notifications non lues à la réponse
            $unreadCount = \App\Models\Notification::where('user_id', $user->id)
                ->where('statut', 'non_lue')
                ->count();
            
            // Ajouter les notifications urgentes
            $urgentCount = \App\Models\Notification::where('user_id', $user->id)
                ->where('statut', 'non_lue')
                ->where('priorite', 'urgente')
                ->count();
            
            // Ajouter les informations de notification à la réponse
            if ($response instanceof \Illuminate\Http\JsonResponse) {
                $data = $response->getData(true);
                $data['notifications'] = [
                    'unread_count' => $unreadCount,
                    'urgent_count' => $urgentCount
                ];
                $response->setData($data);
            }
        }
        
        return $response;
    }
}

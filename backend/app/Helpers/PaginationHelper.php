<?php

namespace App\Helpers;

use Illuminate\Http\Request;

class PaginationHelper
{
    /**
     * Get pagination parameters from request with defaults.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  int  $defaultPerPage
     * @param  int  $maxPerPage
     * @return array
     */
    public static function getPaginationParams(Request $request, int $defaultPerPage = 15, int $maxPerPage = 100): array
    {
        $perPage = (int) ($request->get('per_page') ?? $request->get('limit') ?? $defaultPerPage);
        
        // Limiter le nombre maximum d'éléments par page pour éviter les surcharges
        $perPage = min($perPage, $maxPerPage);
        $perPage = max($perPage, 1); // Minimum 1
        
        return [
            'per_page' => $perPage,
            'page' => (int) ($request->get('page') ?? 1),
        ];
    }

    /**
     * Format paginated response with additional metadata.
     *
     * @param  \Illuminate\Contracts\Pagination\LengthAwarePaginator  $paginator
     * @param  string  $message
     * @return array
     */
    public static function formatPaginatedResponse($paginator, string $message = 'Données récupérées avec succès'): array
    {
        return [
            'success' => true,
            'message' => $message,
            'data' => $paginator->items(),
            'pagination' => [
                'current_page' => $paginator->currentPage(),
                'per_page' => $paginator->perPage(),
                'total' => $paginator->total(),
                'last_page' => $paginator->lastPage(),
                'from' => $paginator->firstItem(),
                'to' => $paginator->lastItem(),
            ],
        ];
    }
}


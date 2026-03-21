<?php

namespace App\Helpers;

use Illuminate\Http\JsonResponse;

class ApiResponseHelper
{
    /**
     * Normalize API response to ensure consistent format.
     * This helper can be used to convert old format responses to new format.
     *
     * @param  mixed  $data
     * @param  string  $message
     * @param  int  $code
     * @return array
     */
    public static function normalizeSuccess($data, string $message = 'Opération réussie', int $code = 200): array
    {
        return [
            'success' => true,
            'message' => $message,
            'data' => $data,
        ];
    }

    /**
     * Normalize error response.
     *
     * @param  string  $message
     * @param  int  $code
     * @param  array  $errors
     * @return array
     */
    public static function normalizeError(string $message, int $code = 400, array $errors = []): array
    {
        $response = [
            'success' => false,
            'message' => $message,
        ];

        if (!empty($errors)) {
            $response['errors'] = $errors;
        }

        return $response;
    }

    /**
     * Check if response is in new format (has 'success' and 'data').
     *
     * @param  array  $response
     * @return bool
     */
    public static function isNewFormat(array $response): bool
    {
        return isset($response['success']) && array_key_exists('data', $response);
    }

    /**
     * Extract data from response (handles both old and new format).
     *
     * @param  array  $response
     * @return mixed
     */
    public static function extractData(array $response)
    {
        if (self::isNewFormat($response)) {
            return $response['data'] ?? null;
        }

        // Old format - return response without 'success' and 'message'
        unset($response['success'], $response['message']);
        return count($response) === 1 ? reset($response) : $response;
    }
}


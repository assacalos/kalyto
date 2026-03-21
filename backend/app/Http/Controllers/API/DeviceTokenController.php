<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Services\PushNotificationService;
use App\Models\DeviceToken;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class DeviceTokenController extends Controller
{
    protected $pushService;

    public function __construct(PushNotificationService $pushService)
    {
        $this->pushService = $pushService;
    }

    /**
     * Enregistrer ou mettre à jour un token d'appareil
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function store(Request $request)
    {
        // Accepter "token" ou "fcm_token" (l'app Flutter envoie les deux ; en cas d'oubli, un seul suffit)
        $tokenValue = $request->input('token') ?? $request->input('fcm_token');

        $validator = Validator::make(array_merge($request->all(), ['token' => $tokenValue]), [
            'token' => 'required|string|max:500',
            'device_type' => 'nullable|string|in:ios,android,web',
            'device_id' => 'nullable|string|max:255',
            'app_version' => 'nullable|string|max:50',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur de validation',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $user = $request->user();
            
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Utilisateur non authentifié'
                ], 401);
            }

            $deviceToken = $this->pushService->registerDeviceToken(
                $user->id,
                $tokenValue,
                [
                    'device_type' => $request->device_type,
                    'device_id' => $request->device_id,
                    'app_version' => $request->app_version,
                ]
            );

            Log::info("Token d'appareil enregistré", [
                'user_id' => $user->id,
                'device_token_id' => $deviceToken->id,
                'device_type' => $request->device_type,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Token d\'appareil enregistré avec succès',
                'data' => [
                    'id' => $deviceToken->id,
                    'token' => substr($deviceToken->token, 0, 20) . '...', // Masquer le token complet
                    'device_type' => $deviceToken->device_type,
                    'device_id' => $deviceToken->device_id,
                    'app_version' => $deviceToken->app_version,
                    'is_active' => $deviceToken->is_active,
                    'created_at' => $deviceToken->created_at,
                ]
            ], 201);

        } catch (\Exception $e) {
            Log::error("Erreur lors de l'enregistrement du token d'appareil", [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'enregistrement du token',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Lister les tokens d'appareil de l'utilisateur authentifié
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function index(Request $request)
    {
        try {
            $user = $request->user();
            
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Utilisateur non authentifié'
                ], 401);
            }

            $perPage = min((int) $request->get('per_page', 20), 100);
            $tokensPaginated = DeviceToken::where('user_id', $user->id)
                ->orderBy('created_at', 'desc')
                ->paginate($perPage);

            $data = $tokensPaginated->getCollection()->map(function ($token) {
                return [
                    'id' => $token->id,
                    'token' => substr($token->token, 0, 20) . '...',
                    'device_type' => $token->device_type,
                    'device_id' => $token->device_id,
                    'app_version' => $token->app_version,
                    'is_active' => $token->is_active,
                    'last_used_at' => $token->last_used_at,
                    'created_at' => $token->created_at,
                ];
            });

            return response()->json([
                'success' => true,
                'data' => $data->values(),
                'pagination' => [
                    'current_page' => $tokensPaginated->currentPage(),
                    'last_page' => $tokensPaginated->lastPage(),
                    'per_page' => $tokensPaginated->perPage(),
                    'total' => $tokensPaginated->total(),
                    'from' => $tokensPaginated->firstItem(),
                    'to' => $tokensPaginated->lastItem(),
                ],
                'message' => 'Tokens d\'appareil récupérés avec succès',
            ], 200, [], JSON_UNESCAPED_UNICODE);

        } catch (\Exception $e) {
            Log::error("Erreur lors de la récupération des tokens d'appareil", [
                'error' => $e->getMessage(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des tokens',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Supprimer un token d'appareil
     * 
     * @param Request $request
     * @param int $id ID du token à supprimer
     * @return \Illuminate\Http\JsonResponse
     */
    public function destroy(Request $request, $id)
    {
        try {
            $user = $request->user();
            
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Utilisateur non authentifié'
                ], 401);
            }

            $deviceToken = DeviceToken::where('id', $id)
                ->where('user_id', $user->id)
                ->first();

            if (!$deviceToken) {
                return response()->json([
                    'success' => false,
                    'message' => 'Token d\'appareil introuvable'
                ], 404);
            }

            $deviceToken->delete();

            Log::info("Token d'appareil supprimé", [
                'user_id' => $user->id,
                'device_token_id' => $id,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Token d\'appareil supprimé avec succès'
            ]);

        } catch (\Exception $e) {
            Log::error("Erreur lors de la suppression du token d'appareil", [
                'error' => $e->getMessage(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la suppression du token',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Supprimer tous les tokens d'appareil de l'utilisateur
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function destroyAll(Request $request)
    {
        try {
            $user = $request->user();
            
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Utilisateur non authentifié'
                ], 401);
            }

            $count = DeviceToken::where('user_id', $user->id)->delete();

            Log::info("Tous les tokens d'appareil supprimés", [
                'user_id' => $user->id,
                'count' => $count,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Tous les tokens d\'appareil ont été supprimés',
                'count' => $count
            ]);

        } catch (\Exception $e) {
            Log::error("Erreur lors de la suppression de tous les tokens d'appareil", [
                'error' => $e->getMessage(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la suppression des tokens',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
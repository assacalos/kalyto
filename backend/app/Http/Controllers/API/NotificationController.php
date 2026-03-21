<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\Controller;
use Illuminate\Http\Request;
use App\Models\Notification;
use App\Models\User;
use App\Services\NotificationService;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Auth;

class NotificationController extends Controller
{
    protected $notificationService;

    public function __construct(NotificationService $notificationService)
    {
        $this->notificationService = $notificationService;
    }
    public function index(Request $request)
    {
        $user = $request->user();
        if (!$user) {
            return response()->json(['success' => false, 'message' => 'Non authentifié'], 401);
        }

        $query = Notification::where('user_id', $user->id)->orderBy('created_at', 'desc');

        if ($request->has('type')) {
            $query->where('type', $request->type);
        }

        if ($request->boolean('unread_only')) {
            $query->where(function($q) {
                $q->where('is_read', false)->orWhere('statut', 'non_lue');
            });
        }

        $perPage = min((int) $request->get('per_page', 20), 100);
        $notifications = $query->paginate($perPage);

        $formatted = $notifications->getCollection()->map(function ($n) {
            return [
                'id' => (string) $n->id,
                'title' => $n->title ?? $n->titre ?? '',
                'message' => $n->message,
                'type' => $n->type,
                'entity_type' => $n->entity_type,
                'entity_id' => $n->entity_id ? (string) $n->entity_id : null,
                'is_read' => $n->is_read !== null ? (bool) $n->is_read : ($n->statut === 'lue'),
                'created_at' => $n->created_at->toIso8601String(),
                'action_route' => $n->action_route,
            ];
        });

        return response()->json([
            'success' => true,
            'data' => $formatted->values(),
            'pagination' => [
                'current_page' => $notifications->currentPage(),
                'last_page' => $notifications->lastPage(),
                'per_page' => $notifications->perPage(),
                'total' => $notifications->total(),
                'from' => $notifications->firstItem(),
                'to' => $notifications->lastItem(),
            ],
            'unread_count' => Notification::where('user_id', $user->id)->where('is_read', false)->count(),
            'message' => 'Liste des notifications récupérée avec succès',
        ], 200, [], JSON_UNESCAPED_UNICODE);
    }

    public function show($id)
    {
        $notification = Notification::where('user_id', Auth::id())->findOrFail($id);
        if (!$notification->is_read) {
            $notification->update(['is_read' => true, 'statut' => 'lue', 'date_lecture' => now()]);
        }
        return response()->json(['success' => true, 'notification' => $notification]);
    }

    public function markAsRead($id)
    {
        $notification = Notification::where('user_id', Auth::id())->findOrFail($id);
        $notification->update(['is_read' => true, 'statut' => 'lue', 'date_lecture' => now()]);
        return response()->json(['success' => true, 'message' => 'Marquée comme lue']);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'message' => 'required|string|max:1000',
            'type' => 'required|string|in:info,success,warning,error,task',
            'entity_type' => 'required|string|max:100',
            'entity_id' => 'required|string|max:255',
            'recipient_role' => 'nullable|string',
            'recipient_ids' => 'nullable|array',
            'user_id' => 'nullable|integer',
            'priorite' => 'nullable|string|in:basse,normale,haute,urgente',
        ]);

        try {
            $users = collect();
            if ($request->filled('recipient_role')) {
                $roleId = $this->getRoleId($validated['recipient_role']);
                if ($roleId) {
                    $users = User::where('role', $roleId)->where('is_active', true)->get();
                }
            } elseif ($request->filled('recipient_ids')) {
                $users = User::whereIn('id', $validated['recipient_ids'])->where('is_active', true)->get();
            } elseif ($request->filled('user_id')) {
                $user = User::find($validated['user_id']);
                if ($user && $user->is_active) $users = collect([$user]);
            }

            if ($users->isEmpty()) {
                return response()->json(['success' => false, 'message' => 'Aucun destinataire'], 404);
            }

            $results = [];
            $data = [
                'entity_type' => $validated['entity_type'],
                'entity_id' => $validated['entity_id'],
                'action_route' => "/{$validated['entity_type']}s/{$validated['entity_id']}"
            ];

            foreach ($users as $user) {
                try {
                    $notification = $this->notificationService->createAndBroadcast(
                        $user->id,
                        $validated['type'],
                        $validated['title'],
                        $validated['message'],
                        $data,
                        $validated['priorite'] ?? 'normale',
                        'app'
                    );

                    if ($notification) {
                        $results[] = ['user_id' => $user->id, 'sent' => true, 'notification_id' => $notification->id];
                    } else {
                        $results[] = ['user_id' => $user->id, 'sent' => false];
                    }
                } catch (\Exception $e) {
                    Log::error($e->getMessage());
                    $results[] = ['user_id' => $user->id, 'sent' => false];
                }
            }

            return response()->json(['success' => true, 'results' => $results], 201);
        } catch (\Exception $e) {
            Log::error('Erreur lors de la création de notification: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }
    }

    private function getRoleId($roleName)
    {
        $map = ['admin' => 1, 'commercial' => 2, 'comptable' => 3, 'rh' => 4, 'technicien' => 5, 'patron' => 6];
        return $map[strtolower($roleName)] ?? null;
    }

    public function destroy($id)
    {
        Notification::where('user_id', Auth::id())->findOrFail($id)->delete();
        return response()->json(['success' => true, 'message' => 'Supprimée']);
    }

    public function statistics()
    {
        $userId = Auth::id();
        return response()->json([
            'success' => true,
            'statistiques' => [
                'total' => Notification::where('user_id', $userId)->count(),
                'non_lues' => Notification::where('user_id', $userId)->where('is_read', false)->count(),
            ]
        ]);
    }
}
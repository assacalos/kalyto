<?php

namespace App\Http\Controllers\API;

use App\Models\Task;
use App\Http\Resources\TaskResource;
use App\Services\NotificationService;
use App\Traits\SendsNotifications;
use Illuminate\Http\Request;

class TaskController extends Controller
{
    use SendsNotifications;

    protected NotificationService $notificationService;

    public function __construct(NotificationService $notificationService)
    {
        $this->notificationService = $notificationService;
    }
    /**
     * Liste des tâches.
     * Patron/Admin : toutes les tâches (filtres assigned_to, status).
     * Autres : uniquement les tâches qui leur sont assignées.
     */
    public function index(Request $request)
    {
        try {
            $user = $request->user();
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Utilisateur non authentifié',
                ], 401);
            }

            $query = Task::with(['assignedTo', 'assignedBy'])->ordered();

            if (in_array($user->role, [1, 6])) {
                // Patron ou Admin : voir toutes les tâches
                if ($request->filled('assigned_to')) {
                    $query->forUser((int) $request->assigned_to);
                }
                if ($request->filled('status')) {
                    $query->byStatus($request->status);
                }
            } else {
                // Autres : uniquement les tâches assignées à l'utilisateur
                $query->forUser($user->id);
                if ($request->filled('status')) {
                    $query->byStatus($request->status);
                }
            }

            $perPage = min((int) $request->get('per_page', 20), 100);
            $paginated = $query->paginate($perPage);

            return response()->json([
                'success' => true,
                'data' => TaskResource::collection($paginated),
                'pagination' => [
                    'current_page' => $paginated->currentPage(),
                    'last_page' => $paginated->lastPage(),
                    'per_page' => $paginated->perPage(),
                    'total' => $paginated->total(),
                    'from' => $paginated->firstItem(),
                    'to' => $paginated->lastItem(),
                ],
                'message' => 'Liste des tâches récupérée avec succès',
            ], 200, [], JSON_UNESCAPED_UNICODE);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des tâches: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Détail d'une tâche.
     */
    public function show(Request $request, $id)
    {
        try {
            $user = $request->user();
            $task = Task::with(['assignedTo', 'assignedBy'])->find($id);
            if (!$task) {
                return response()->json([
                    'success' => false,
                    'message' => 'Tâche non trouvée',
                ], 404);
            }
            if (!in_array($user->role, [1, 6]) && $task->assigned_to !== $user->id) {
                return response()->json([
                    'success' => false,
                    'message' => 'Accès non autorisé à cette tâche',
                ], 403);
            }
            return response()->json([
                'success' => true,
                'data' => new TaskResource($task),
                'message' => 'Tâche récupérée avec succès',
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Créer / assigner une tâche (Patron ou Admin uniquement).
     */
    public function store(Request $request)
    {
        try {
            $user = $request->user();
            if (!in_array($user->role, [1, 6])) {
                return response()->json([
                    'success' => false,
                    'message' => 'Seul le patron ou l\'administrateur peut assigner des tâches',
                ], 403);
            }

            $request->validate([
                'titre' => 'required|string|max:255',
                'description' => 'nullable|string',
                'assigned_to' => 'required|exists:users,id',
                'priority' => 'nullable|in:low,medium,high,urgent',
                'due_date' => 'nullable|date',
            ]);

            $task = new Task();
            $task->titre = $request->titre;
            $task->description = $request->description;
            $task->assigned_to = $request->assigned_to;
            $task->assigned_by = $user->id;
            $task->status = 'pending';
            $task->priority = $request->input('priority', 'medium');
            $task->due_date = $request->due_date;
            $task->save();

            $this->safeNotify(function () use ($task) {
                $this->notificationService->notifyTaskAssigned($task);
            });

            return response()->json([
                'success' => true,
                'data' => new TaskResource($task->load(['assignedTo', 'assignedBy'])),
                'message' => 'Tâche assignée avec succès',
            ], 201);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Données invalides',
                'errors' => $e->errors(),
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la création: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Mettre à jour une tâche.
     * Patron/Admin : tous les champs.
     * Assigné : uniquement le statut (in_progress, completed).
     */
    public function update(Request $request, $id)
    {
        try {
            $user = $request->user();
            $task = Task::find($id);
            if (!$task) {
                return response()->json([
                    'success' => false,
                    'message' => 'Tâche non trouvée',
                ], 404);
            }

            $previousStatus = $task->status;
            $isPatronOrAdmin = in_array($user->role, [1, 6]);
            $isAssignee = $task->assigned_to === $user->id;

            if ($isPatronOrAdmin) {
                $request->validate([
                    'titre' => 'sometimes|string|max:255',
                    'description' => 'nullable|string',
                    'assigned_to' => 'sometimes|exists:users,id',
                    'status' => 'sometimes|in:pending,in_progress,completed,cancelled',
                    'priority' => 'sometimes|in:low,medium,high,urgent',
                    'due_date' => 'nullable|date',
                ]);
                if ($request->has('titre')) {
                    $task->titre = $request->titre;
                }
                if (array_key_exists('description', $request->all())) {
                    $task->description = $request->description;
                }
                if ($request->has('assigned_to')) {
                    $task->assigned_to = $request->assigned_to;
                }
                if ($request->has('status')) {
                    $task->status = $request->status;
                    if ($request->status === 'completed') {
                        $task->completed_at = now();
                    } else {
                        $task->completed_at = null;
                    }
                }
                if ($request->has('priority')) {
                    $task->priority = $request->priority;
                }
                if (array_key_exists('due_date', $request->all())) {
                    $task->due_date = $request->due_date;
                }
            } elseif ($isAssignee) {
                $request->validate([
                    'status' => 'required|in:in_progress,completed',
                ]);
                $task->status = $request->status;
                if ($request->status === 'completed') {
                    $task->completed_at = now();
                }
            } else {
                return response()->json([
                    'success' => false,
                    'message' => 'Accès non autorisé',
                ], 403);
            }

            $task->save();

            if ($previousStatus !== 'completed' && $task->status === 'completed') {
                $this->safeNotify(function () use ($task) {
                    $this->notificationService->notifyTaskCompleted($task);
                });
            }

            return response()->json([
                'success' => true,
                'data' => new TaskResource($task->load(['assignedTo', 'assignedBy'])),
                'message' => 'Tâche mise à jour avec succès',
            ]);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Données invalides',
                'errors' => $e->errors(),
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Supprimer une tâche (Patron ou Admin uniquement).
     */
    public function destroy(Request $request, $id)
    {
        try {
            $user = $request->user();
            if (!in_array($user->role, [1, 6])) {
                return response()->json([
                    'success' => false,
                    'message' => 'Seul le patron ou l\'administrateur peut supprimer des tâches',
                ], 403);
            }
            $task = Task::find($id);
            if (!$task) {
                return response()->json([
                    'success' => false,
                    'message' => 'Tâche non trouvée',
                ], 404);
            }
            $task->delete();
            return response()->json([
                'success' => true,
                'message' => 'Tâche supprimée avec succès',
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 500);
        }
    }
}

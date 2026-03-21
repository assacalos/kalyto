<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\Controller;
use App\Services\NotificationService;
use App\Traits\SendsNotifications;
use App\Models\Besoin;
use Illuminate\Http\Request;

class BesoinController extends Controller
{
    use SendsNotifications;

    protected $notificationService;

    public function __construct(NotificationService $notificationService)
    {
        $this->notificationService = $notificationService;
    }

    /**
     * Liste des besoins : technicien = les siens, patron/admin = tous.
     */
    public function index(Request $request)
    {
        $user = $request->user();
        if (!$user) {
            return response()->json(['success' => false, 'message' => 'Non authentifié'], 401);
        }

        $query = Besoin::with(['creator', 'treatedByUser'])->orderByDesc('created_at');

        if ($user->role == 5) {
            $query->where('created_by', $user->id);
        }

        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        $perPage = min((int) $request->get('per_page', 20), 100);
        $besoins = $query->paginate($perPage);

        return response()->json([
            'success' => true,
            'data' => $besoins->items(),
            'pagination' => [
                'current_page' => $besoins->currentPage(),
                'last_page' => $besoins->lastPage(),
                'per_page' => $besoins->perPage(),
                'total' => $besoins->total(),
                'from' => $besoins->firstItem(),
                'to' => $besoins->lastItem(),
            ],
        ], 200, [], JSON_UNESCAPED_UNICODE);
    }

    /**
     * Créer un besoin (technicien). Définit la périodicité des rappels au patron.
     */
    public function store(Request $request)
    {
        $user = $request->user();
        if (!$user || $user->role != 5) {
            return response()->json(['success' => false, 'message' => 'Réservé au technicien'], 403);
        }

        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'reminder_frequency' => 'required|in:daily,every_2_days,weekly',
        ]);

        $freq = $validated['reminder_frequency'];
        $temp = new Besoin();
        $temp->reminder_frequency = $freq;
        $nextReminder = $temp->computeNextReminderAt();

        $besoin = Besoin::create([
            'title' => $validated['title'],
            'description' => $validated['description'] ?? null,
            'created_by' => $user->id,
            'reminder_frequency' => $freq,
            'next_reminder_at' => $nextReminder,
            'status' => 'pending',
        ]);

        $this->safeNotify(function () use ($besoin) {
            $this->notificationService->notifyNewBesoin($besoin);
        });

        return response()->json([
            'success' => true,
            'data' => $besoin->load('creator'),
            'message' => 'Besoin enregistré. Le patron sera rappelé automatiquement selon la période choisie.',
        ], 201, [], JSON_UNESCAPED_UNICODE);
    }

    /**
     * Détail d'un besoin.
     */
    public function show($id)
    {
        $besoin = Besoin::with(['creator', 'treatedByUser'])->find($id);
        if (!$besoin) {
            return response()->json(['success' => false, 'message' => 'Besoin introuvable'], 404);
        }
        return response()->json(['success' => true, 'data' => $besoin], 200, [], JSON_UNESCAPED_UNICODE);
    }

    /**
     * Marquer comme traité (patron/admin). Arrête les rappels.
     */
    public function markTreated(Request $request, $id)
    {
        $user = $request->user();
        if (!$user || !in_array($user->role, [1, 6])) {
            return response()->json(['success' => false, 'message' => 'Réservé au patron ou admin'], 403);
        }

        $besoin = Besoin::find($id);
        if (!$besoin) {
            return response()->json(['success' => false, 'message' => 'Besoin introuvable'], 404);
        }
        if ($besoin->status === 'treated') {
            return response()->json(['success' => true, 'data' => $besoin->fresh()]);
        }

        $note = $request->input('treated_note');
        $besoin->update([
            'status' => 'treated',
            'treated_at' => now(),
            'treated_by' => $user->id,
            'treated_note' => $note,
            'next_reminder_at' => null,
        ]);

        return response()->json([
            'success' => true,
            'data' => $besoin->fresh(['creator', 'treatedByUser']),
            'message' => 'Besoin marqué comme traité.',
        ], 200, [], JSON_UNESCAPED_UNICODE);
    }
}

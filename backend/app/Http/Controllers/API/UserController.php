<?php

namespace App\Http\Controllers\API;

use App\Http\Requests\LoginRequest;
use Illuminate\Http\Request;
use App\Http\Controllers\API\Controller;
use App\Http\Resources\UserResource;
use Illuminate\Support\Facades\Auth;

class UserController extends Controller
{
    /**
     * Inscription publique : crée un utilisateur en attente de validation (is_active = false).
     * Le patron attribuera le rôle et validera le compte.
     */
    public function register(Request $request)
    {
        try {
            $validated = $request->validate([
                'nom' => 'required|string|max:255',
                'prenom' => 'required|string|max:255',
                'email' => 'required|string|email|max:255|unique:users',
                'password' => 'required|string|min:6|confirmed',
                'photo' => 'nullable|image|max:2048', // 2 Mo max, multipart accepté
            ]);

            $avatarPath = null;
            if ($request->hasFile('photo')) {
                $file = $request->file('photo');
                $path = $file->store('avatars', 'public'); // storage/app/public/avatars
                $avatarPath = $path; // ex: avatars/xxx.jpg
            }

            $user = \App\Models\User::create([
                'nom' => $validated['nom'],
                'prenom' => $validated['prenom'],
                'email' => $validated['email'],
                'password' => bcrypt($validated['password']),
                'avatar' => $avatarPath,
                'role' => 2, // Commercial par défaut, le patron changera lors de la validation
                'is_active' => false,
            ]);

            return $this->successResponse([
                'id' => $user->id,
                'nom' => $user->nom,
                'prenom' => $user->prenom,
                'email' => $user->email,
                'avatar' => $user->avatar ? asset('storage/' . $user->avatar) : null,
            ], 'Inscription enregistrée. Votre compte sera activé après validation par l\'administrateur.');
        } catch (\Illuminate\Validation\ValidationException $e) {
            return $this->handleValidationException($e);
        } catch (\Exception $e) {
            \Log::error('Erreur API - Register', [
                'email' => $request->input('email'),
                'error' => $e->getMessage(),
            ]);
            return $this->errorResponse('Une erreur est survenue lors de l\'inscription.', 500);
        }
    }

    public function login(LoginRequest $request)
    {
        try {
            $credentials = $request->only('email', 'password');

            if (!Auth::attempt($credentials)) {
                return $this->errorResponse('Email ou mot de passe incorrect', 401);
            }

            $user = Auth::user();
            
            if (!$user) {
                return $this->errorResponse('Utilisateur non trouvé', 404);
            }

            // Vérifier si l'utilisateur est actif
            if (!$user->is_active) {
                return $this->errorResponse('Votre compte a été désactivé. Contactez l\'administrateur.', 403);
            }

            $token = $user->createToken('mobile-app')->plainTextToken;

            return $this->successResponse([
                'token' => $token,
                'user' => new UserResource($user),
            ], 'Connexion réussie');
        } catch (\Illuminate\Validation\ValidationException $e) {
            return $this->handleValidationException($e);
        } catch (\Exception $e) {
            \Log::error('Erreur API - Login', [
                'endpoint' => $request->path(),
                'method' => $request->method(),
                'email' => $request->input('email'),
                'error' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
                'trace' => $e->getTraceAsString(),
            ]);

            $message = config('app.debug')
                ? 'Erreur serveur (login): ' . $e->getMessage()
                : 'Une erreur est survenue. Veuillez réessayer plus tard.';
            return $this->errorResponse($message, 500);
        }
    }

    public function logout(Request $request)
    {
        try {
            $request->user()->currentAccessToken()->delete();
            
            return $this->successResponse(null, 'Déconnexion réussie');
        } catch (\Exception $e) {
            \Log::error('Erreur API - Logout', [
                'endpoint' => $request->path(),
                'method' => $request->method(),
                'user_id' => $request->user()?->id,
                'error' => $e->getMessage(),
            ]);

            return $this->errorResponse('Une erreur est survenue lors de la déconnexion', 500);
        }
    }

    public function me(Request $request)
    {
        try {
            $user = $request->user();
            
            if (!$user) {
                return $this->unauthorizedResponse('Utilisateur non authentifié');
            }

            // Vérifier si getRoleName existe, sinon utiliser une valeur par défaut
            $roleName = method_exists($user, 'getRoleName') ? $user->getRoleName() : 'Utilisateur';
            
            return $this->successResponse(new UserResource($user));
        } catch (\Exception $e) {
            \Log::error('Me endpoint error', [
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);

            if (config('app.debug')) {
                return $this->errorResponse('Erreur: ' . $e->getMessage(), 500);
            }

            return $this->errorResponse('Erreur lors de la récupération des informations utilisateur', 500);
        }
    }

    /**
     * Mise à jour du profil de l'utilisateur connecté (nom, prénom, email).
     * Permet à chaque utilisateur de renseigner ou modifier son email pour recevoir les notifications par mail.
     */
    public function updateProfile(Request $request)
    {
        try {
            $user = $request->user();
            if (!$user) {
                return $this->unauthorizedResponse('Utilisateur non authentifié');
            }

            $validated = $request->validate([
                'nom' => 'required|string|max:255',
                'prenom' => 'required|string|max:255',
                'email' => 'required|email|max:255|unique:users,email,' . $user->id,
            ]);

            $user->update([
                'nom' => $validated['nom'],
                'prenom' => $validated['prenom'],
                'email' => $validated['email'],
            ]);

            return $this->successResponse(new UserResource($user->fresh()), 'Profil mis à jour avec succès.');
        } catch (\Illuminate\Validation\ValidationException $e) {
            return $this->handleValidationException($e);
        } catch (\Exception $e) {
            \Log::error('Update profile error', [
                'user_id' => $request->user()?->id,
                'message' => $e->getMessage(),
            ]);
            return $this->errorResponse('Erreur lors de la mise à jour du profil.', 500);
        }
    }

    /**
     * Mise à jour de la photo de profil (avatar) de l'utilisateur connecté.
     */
    public function updateProfilePhoto(Request $request)
    {
        try {
            $user = $request->user();
            if (!$user) {
                return $this->unauthorizedResponse('Utilisateur non authentifié');
            }

            $request->validate([
                'photo' => 'required|image|mimes:jpeg,png,jpg|max:2048',
            ]);

            $file = $request->file('photo');
            $path = $file->store('avatars', 'public');

            // Supprimer l'ancien avatar s'il existe
            if ($user->avatar) {
                \Illuminate\Support\Facades\Storage::disk('public')->delete($user->avatar);
            }

            $user->update(['avatar' => $path]);

            return $this->successResponse(
                new UserResource($user->fresh()),
                'Photo de profil mise à jour avec succès.'
            );
        } catch (\Illuminate\Validation\ValidationException $e) {
            return $this->handleValidationException($e);
        } catch (\Exception $e) {
            \Log::error('Update profile photo error', [
                'user_id' => $request->user()?->id,
                'message' => $e->getMessage(),
            ]);
            return $this->errorResponse('Erreur lors de la mise à jour de la photo.', 500);
        }
    }

    public function refresh(Request $request)
    {
        try {
            $user = $request->user();
            
            if (!$user) {
                return $this->unauthorizedResponse('Utilisateur non authentifié');
            }

            // Vérifier si l'utilisateur est actif
            if (!$user->is_active) {
                return $this->errorResponse('Votre compte a été désactivé. Contactez l\'administrateur.', 403);
            }

            // Supprimer l'ancien token
            $request->user()->currentAccessToken()->delete();

            // Créer un nouveau token
            $token = $user->createToken('mobile-app')->plainTextToken;

            return $this->successResponse([
                'token' => $token,
                'user' => new UserResource($user),
            ], 'Token rafraîchi avec succès');
        } catch (\Exception $e) {
            \Log::error('Erreur API - Refresh', [
                'endpoint' => $request->path(),
                'method' => $request->method(),
                'user_id' => $request->user()?->id,
                'error' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
                'trace' => $e->getTraceAsString(),
            ]);

            return $this->errorResponse('Une erreur est survenue lors du rafraîchissement du token', 500);
        }
    }
    /**
     * Liste des utilisateurs (Admin uniquement)
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
            
            $role = $request->query('role');
            $status = $request->query('status');
            $search = $request->query('search');

            $query = \App\Models\User::query();

            // Filtre par rôle
            if ($role !== null) {
                $query->where('role', $role);
            }

            // Filtre par statut (actif/inactif)
            if ($status !== null) {
                $query->where('is_active', $status);
            }

            // Recherche par nom, prénom ou email
            if ($search) {
                $query->where(function($q) use ($search) {
                    $q->where('nom', 'like', "%{$search}%")
                      ->orWhere('prenom', 'like', "%{$search}%")
                      ->orWhere('email', 'like', "%{$search}%");
                });
            }

            $perPage = min((int) $request->get('per_page', 20), 100);
            $users = $query->orderBy('created_at', 'desc')->paginate($perPage);

            return response()->json([
                'success' => true,
                'data' => UserResource::collection($users),
                'pagination' => [
                    'current_page' => $users->currentPage(),
                    'last_page' => $users->lastPage(),
                    'per_page' => $users->perPage(),
                    'total' => $users->total(),
                    'from' => $users->firstItem(),
                    'to' => $users->lastItem(),
                ],
                'message' => 'Liste des utilisateurs récupérée avec succès',
            ], 200, [], JSON_UNESCAPED_UNICODE);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des utilisateurs: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Créer un nouvel utilisateur (Admin uniquement)
     */
    public function store(Request $request)
    {
        try {
            $validated = $request->validate([
                'nom' => 'required|string|max:255',
                'prenom' => 'required|string|max:255',
                'email' => 'required|string|email|max:255|unique:users',
                'password' => 'required|string|min:6',
                'role' => 'required|integer|in:1,2,3,4,5,6',
                'company_id' => 'nullable|integer|exists:companies,id',
                /* 'telephone' => 'nullable|string|max:20',
                'adresse' => 'nullable|string|max:255',
                'date_embauche' => 'nullable|date',
                'salaire' => 'nullable|numeric|min:0',
                'departement' => 'nullable|string|max:100',
                'poste' => 'nullable|string|max:100' */
            ]);

            $user = \App\Models\User::create([
                'nom' => $validated['nom'],
                'prenom' => $validated['prenom'],
                'email' => $validated['email'],
                'password' => bcrypt($validated['password']),
                'role' => $validated['role'],
                'company_id' => $validated['company_id'] ?? null,
                'is_active' => true,
               /*  'telephone' => $validated['telephone'],
                'adresse' => $validated['adresse'],
                'date_embauche' => $validated['date_embauche'],
                'salaire' => $validated['salaire'],
                'departement' => $validated['departement'],
                'poste' => $validated['poste'], */
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Utilisateur créé avec succès',
                'data' => $user
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la création de l\'utilisateur: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Afficher un utilisateur spécifique (Admin uniquement)
     */
    public function show($id)
    {
        try {
            $user = \App\Models\User::findOrFail($id);
            
            return response()->json([
                'success' => true,
                'data' => $user
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Utilisateur non trouvé: ' . $e->getMessage()
            ], 404);
        }
    }

    /**
     * Modifier un utilisateur (Admin uniquement)
     */
    public function update(Request $request, $id)
    {
        try {
            $user = \App\Models\User::findOrFail($id);

            $validated = $request->validate([
                'nom' => 'required|string|max:255',
                'prenom' => 'required|string|max:255',
                'email' => 'required|email|unique:users,email,' . $user->id,
                'password' => 'nullable|string|min:6',
                'role' => 'required|integer|in:1,2,3,4,5,6',
                'company_id' => 'nullable|integer|exists:companies,id',
               /*  'telephone' => 'nullable|string|max:20',
                'adresse' => 'nullable|string|max:255',
                'date_embauche' => 'nullable|date',
                'salaire' => 'nullable|numeric|min:0',
                'departement' => 'nullable|string|max:100',
                'poste' => 'nullable|string|max:100' */
            ]);

            $updateData = $validated;
            if (!empty($validated['password'])) {
                $updateData['password'] = bcrypt($validated['password']);
            } else {
                unset($updateData['password']);
            }

            $user->update($updateData);

            return response()->json([
                'success' => true,
                'message' => 'Utilisateur modifié avec succès',
                'data' => $user
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la modification: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Supprimer un utilisateur (Admin uniquement)
     */
    public function destroy($id)
    {
        try {
            $user = \App\Models\User::findOrFail($id);
            
            // Empêcher la suppression de l'utilisateur connecté
            if ($user->id === auth()->id()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Impossible de supprimer votre propre compte'
                ], 403);
            }

            $user->delete();

            return response()->json([
                'success' => true,
                'message' => 'Utilisateur supprimé avec succès'
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la suppression: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Activer un utilisateur (Admin uniquement)
     */
    public function activate($id)
    {
        try {
            $user = \App\Models\User::findOrFail($id);
            $user->update(['is_active' => true]);

            return response()->json([
                'success' => true,
                'message' => 'Utilisateur activé avec succès',
                'data' => $user
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'activation: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Désactiver un utilisateur (Admin uniquement)
     */
    public function deactivate($id)
    {
        try {
            $user = \App\Models\User::findOrFail($id);
            
            // Empêcher la désactivation de l'utilisateur connecté
            if ($user->id === auth()->id()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Impossible de désactiver votre propre compte'
                ], 403);
            }

            $user->update(['is_active' => false]);

            return response()->json([
                'success' => true,
                'message' => 'Utilisateur désactivé avec succès',
                'data' => $user
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la désactivation: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Liste des inscriptions en attente (Patron ou Admin)
     */
    public function pendingRegistrations(Request $request)
    {
        try {
            $user = $request->user();
            if (!$user || ! $user->isAdminOrPatron()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Non autorisé',
                ], 403);
            }

            $pending = \App\Models\User::where('is_active', false)
                ->orderBy('created_at', 'desc')
                ->get()
                ->map(function ($u) {
                    return [
                        'id' => $u->id,
                        'nom' => $u->nom,
                        'prenom' => $u->prenom,
                        'email' => $u->email,
                        'role' => $u->role,
                        'created_at' => $u->created_at?->toIso8601String(),
                    ];
                });

            return response()->json([
                'success' => true,
                'data' => $pending,
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Valider une inscription : attribuer le rôle, la société et activer le compte.
     * - Si le validant est le Patron : la société du validé = société du patron.
     * - Si le validant est l'Admin : la société du validé = company_id envoyé (optionnel).
     */
    public function approveRegistration(Request $request, $id)
    {
        try {
            $user = $request->user();
            if (!$user || ! $user->isAdminOrPatron()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Non autorisé',
                ], 403);
            }

            $validated = $request->validate([
                'role' => 'required|integer|in:1,2,3,4,5,6',
                'company_id' => 'nullable|integer|exists:companies,id',
            ]);

            $targetUser = \App\Models\User::findOrFail($id);
            if ($targetUser->is_active) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cet utilisateur est déjà actif.',
                ], 400);
            }

            $companyId = null;
            if ($user->isPatron()) {
                // Patron valide → le validé reçoit la société du patron
                $companyId = $user->company_id;
            } else {
                // Admin valide → utiliser le company_id envoyé (optionnel)
                $companyId = $validated['company_id'] ?? null;
            }

            $targetUser->update([
                'role' => $validated['role'],
                'company_id' => $companyId,
                'is_active' => true,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Inscription validée avec succès',
                'data' => new UserResource($targetUser),
            ], 200);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return $this->handleValidationException($e);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Rejeter une inscription (Patron ou Admin) : supprimer ou garder inactif
     */
    public function rejectRegistration(Request $request, $id)
    {
        try {
            $user = $request->user();
            if (!$user || ! $user->isAdminOrPatron()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Non autorisé',
                ], 403);
            }

            $targetUser = \App\Models\User::findOrFail($id);
            if ($targetUser->is_active) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cet utilisateur est déjà actif.',
                ], 400);
            }

            $targetUser->delete();

            return response()->json([
                'success' => true,
                'message' => 'Inscription rejetée',
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Statistiques des utilisateurs (Admin uniquement)
     */
    public function statistics()
    {
        try {
            $totalUsers = \App\Models\User::count();
            $activeUsers = \App\Models\User::where('is_active', true)->count();
            $inactiveUsers = \App\Models\User::where('is_active', false)->count();

            // Répartition par rôle
            $usersByRole = \App\Models\User::selectRaw('role, COUNT(*) as total')
                ->groupBy('role')
                ->get();

            // Utilisateurs créés par mois (derniers 12 mois)
            $usersByMonth = \App\Models\User::selectRaw('DATE_FORMAT(created_at, "%Y-%m") as mois, COUNT(*) as total')
                ->where('created_at', '>=', now()->subMonths(12))
                ->groupBy('mois')
                ->orderBy('mois')
                ->get();

            return response()->json([
                'success' => true,
                'data' => [
                    'total_users' => $totalUsers,
                    'active_users' => $activeUsers,
                    'inactive_users' => $inactiveUsers,
                    'users_by_role' => $usersByRole,
                    'users_by_month' => $usersByMonth,
                    'activation_rate' => $totalUsers > 0 ? round(($activeUsers / $totalUsers) * 100, 2) : 0
                ]
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la génération des statistiques: ' . $e->getMessage()
            ], 500);
        }
    }
}

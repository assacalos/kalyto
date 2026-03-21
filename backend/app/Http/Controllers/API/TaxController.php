<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\Controller;
use App\Services\NotificationService;
use App\Traits\SendsNotifications;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use App\Models\Tax;
use App\Models\TaxCategory;
use App\Http\Resources\TaxResource;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;

class TaxController extends Controller
{
    use SendsNotifications;

    protected $notificationService;

    public function __construct(NotificationService $notificationService)
    {
        $this->notificationService = $notificationService;
    }
    /**
     * Liste des taxes avec filtrage par statut
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $user = $request->user();
            
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Utilisateur non authentifié'
                ], 401);
            }
            
            Log::info('API: Récupération des taxes', [
                'user_id' => $user->id,
                'filters' => $request->all()
            ]);

            $query = Tax::with(['comptable', 'validatedBy', 'rejectedBy']);

            // Filtrage par statut (pour les onglets)
            if ($request->has('status') && $request->status !== 'all') {
                $query->where('status', $request->status);
            }

            // Recherche
            if ($request->has('search') && !empty($request->search)) {
                $query->where(function($q) use ($request) {
                    $q->where('reference', 'like', '%' . $request->search . '%')
                      ->orWhere('period', 'like', '%' . $request->search . '%')
                      ->orWhere('description', 'like', '%' . $request->search . '%');
                });
            }

            // Tri
            $sortBy = $request->get('sort_by', 'created_at');
            $sortOrder = $request->get('sort_order', 'desc');
            $query->orderBy($sortBy, $sortOrder);

            $perPage = min((int) $request->get('per_page', 20), 100);
            $taxes = $query->paginate($perPage);

            $stats = [
                'en_attente' => Tax::where('status', 'en_attente')->count(),
                'valide' => Tax::where('status', 'valide')->count(),
                'rejete' => Tax::where('status', 'rejete')->count(),
                'paye' => Tax::where('status', 'paye')->count(),
                'total' => Tax::count()
            ];

            return response()->json([
                'success' => true,
                'data' => TaxResource::collection($taxes),
                'pagination' => [
                    'current_page' => $taxes->currentPage(),
                    'last_page' => $taxes->lastPage(),
                    'per_page' => $taxes->perPage(),
                    'total' => $taxes->total(),
                    'from' => $taxes->firstItem(),
                    'to' => $taxes->lastItem(),
                ],
                'stats' => $stats,
                'message' => 'Taxes récupérées avec succès',
            ], 200, [], JSON_UNESCAPED_UNICODE);

        } catch (\Exception $e) {
            Log::error('Erreur lors de la récupération des taxes', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
                'user_id' => $request->user()?->id,
            ]);

            $errorMessage = 'Erreur lors de la récupération des taxes';
            if (config('app.debug')) {
                $errorMessage .= ': ' . $e->getMessage();
            }

            return response()->json([
                'success' => false,
                'message' => $errorMessage
            ], 500);
        }
    }

    /**
     * Valider une taxe
     */
public function validateTax(Request $request, $id): JsonResponse
    {
        try {
            $tax = Tax::findOrFail($id);
            
            if ($tax->status !== 'en_attente') {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette taxe ne peut pas être validée dans son état actuel'
                ], 400);
            }

            $request->validate([
                'validation_comment' => 'nullable|string|max:1000'
            ]);

            $tax->update([
                'status' => 'valide',
                'validated_by' => auth()->id(),
                'validated_at' => now(),
                'validation_comment' => $request->validation_comment
            ]);

            // Notifier l'auteur de la taxe
            if ($tax->comptable_id) {
                $this->safeNotify(function () use ($tax) {
                    $tax->load('comptable');
                    $this->notificationService->notifyTaxeValidated($tax);
                });
            }

            Log::info('Taxe validée', [
                'tax_id' => $tax->id,
                'validated_by' => auth()->id()
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Taxe validée avec succès',
                'tax' => $tax->load(['validatedBy'])
            ]);

        } catch (\Exception $e) {
            Log::error('Erreur lors de la validation de la taxe', [
                'error' => $e->getMessage(),
                'tax_id' => $id,
                'user_id' => auth()->id()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la validation de la taxe',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Rejeter une taxe
     */
    public function reject(Request $request, $id): JsonResponse
    {
        try {
            $tax = Tax::findOrFail($id);
            
            if ($tax->status !== 'en_attente') {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette taxe ne peut pas être rejetée dans son état actuel'
                ], 400);
            }

            $request->validate([
                'rejection_reason' => 'required|string|max:255',
                'rejection_comment' => 'required|string|max:1000'
            ]);

            $tax->update([
                'status' => 'rejete',
                'rejected_by' => auth()->id(),
                'rejected_at' => now(),
                'rejection_reason' => $request->rejection_reason,
                'rejection_comment' => $request->rejection_comment
            ]);

            // Notifier l'auteur de la taxe
            if ($tax->comptable_id) {
                $reason = $request->rejection_reason;
                $this->safeNotify(function () use ($tax, $reason) {
                    $tax->load('comptable');
                    $this->notificationService->notifyTaxeRejected($tax, $reason);
                });
            }

            Log::info('Taxe rejetée', [
                'tax_id' => $tax->id,
                'rejected_by' => auth()->id(),
                'reason' => $request->rejection_reason
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Taxe rejetée avec succès',
                'tax' => $tax->load(['rejectedBy'])
            ]);

        } catch (\Exception $e) {
            Log::error('Erreur lors du rejet de la taxe', [
                'error' => $e->getMessage(),
                'tax_id' => $id,
                'user_id' => auth()->id()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du rejet de la taxe',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Statistiques des taxes
     */
    public function statistics(): JsonResponse
    {
        try {
            $stats = [
                'en_attente' => Tax::where('status', 'en_attente')->count(),
                'valide' => Tax::where('status', 'valide')->count(),
                'rejete' => Tax::where('status', 'rejete')->count(),
                'paye' => Tax::where('status', 'paye')->count(),
                'total' => Tax::count(),
                'montant_total_en_attente' => Tax::where('status', 'en_attente')->sum('total_amount'),
                'montant_total_valide' => Tax::where('status', 'valide')->sum('total_amount'),
                'montant_total_rejete' => Tax::where('status', 'rejete')->sum('total_amount'),
                'montant_total_paye' => Tax::where('status', 'paye')->sum('total_amount')
            ];

            return response()->json([
                'success' => true,
                'statistics' => $stats,
                'message' => 'Statistiques récupérées avec succès'
            ]);

        } catch (\Exception $e) {
            Log::error('Erreur lors de la récupération des statistiques', [
                'error' => $e->getMessage(),
                'user_id' => auth()->id()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des statistiques',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Afficher une taxe spécifique
     */
    public function show($id): JsonResponse
    {
        try {
            $tax = Tax::with(['comptable', 'validatedBy', 'rejectedBy', 'payments'])->findOrFail($id);

            return response()->json([
                'success' => true,
                'data' => new TaxResource($tax),
                'message' => 'Taxe récupérée avec succès'
            ]);

        } catch (\Exception $e) {
            Log::error('Erreur lors de la récupération de la taxe', [
                'error' => $e->getMessage(),
                'tax_id' => $id,
                'user_id' => auth()->id()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Taxe non trouvée',
                'error' => $e->getMessage()
            ], 404);
        }
    }

    /**
     * Créer une nouvelle taxe
     */
    public function store(Request $request): JsonResponse
    {
        try {
            // Normaliser les champs camelCase vers snake_case (compatibilité Flutter)
            $data = $request->all();
            
            // Convertir camelCase vers snake_case
            $normalized = [
                'category' => $data['category'] ?? $data['taxCategoryId'] ?? null, // Accepte category ou taxCategoryId (compatibilité)
                'comptable_id' => $data['comptableId'] ?? $data['comptable_id'] ?? auth()->id(),
                'base_amount' => $data['baseAmount'] ?? $data['base_amount'] ?? null,
                'period' => $data['period'] ?? null,
                'period_start' => $data['periodStart'] ?? $data['period_start'] ?? null,
                'period_end' => $data['periodEnd'] ?? $data['period_end'] ?? null,
                'due_date' => $data['dueDate'] ?? $data['due_date'] ?? null,
                'tax_rate' => $data['taxRate'] ?? $data['tax_rate'] ?? null,
                'tax_amount' => $data['taxAmount'] ?? $data['tax_amount'] ?? null,
                'total_amount' => $data['totalAmount'] ?? $data['total_amount'] ?? null,
                'description' => $data['description'] ?? null,
                'notes' => $data['notes'] ?? null,
                'reference' => $data['reference'] ?? null,
            ];

            // Si month et year sont fournis, générer period, period_start, period_end
            if (!isset($normalized['period']) && isset($data['month']) && isset($data['year'])) {
                $month = str_pad((string)$data['month'], 2, '0', STR_PAD_LEFT);
                $normalized['period'] = $data['year'] . '-' . $month;
                
                if (!isset($normalized['period_start'])) {
                    $normalized['period_start'] = $data['year'] . '-' . $month . '-01';
                }
                
                if (!isset($normalized['period_end'])) {
                    $lastDay = date('t', strtotime($normalized['period_start']));
                    $normalized['period_end'] = $data['year'] . '-' . $month . '-' . $lastDay;
                }
            }

            $request->merge($normalized);

            // Si category n'est pas fourni mais taxCategoryId l'est, récupérer le nom
            if (!isset($normalized['category']) && isset($data['taxCategoryId'])) {
                $categoryObj = TaxCategory::find($data['taxCategoryId']);
                if ($categoryObj) {
                    $normalized['category'] = $categoryObj->name;
                }
            }
            
            $request->merge($normalized);

            // Validation
            $validated = $request->validate([
                'category' => 'required|string|max:255',
                'comptable_id' => 'required|exists:users,id',
                'base_amount' => 'required|numeric|min:0',
                'period' => 'required|string',
                'period_start' => 'required|date',
                'period_end' => 'required|date|after_or_equal:period_start',
                'due_date' => 'required|date|after:period_end',
                'tax_rate' => 'nullable|numeric|min:0|max:100',
                'tax_amount' => 'nullable|numeric|min:0',
                'total_amount' => 'nullable|numeric|min:0',
                'description' => 'nullable|string|max:255',
                'notes' => 'nullable|string',
                'reference' => 'nullable|string|unique:taxes,reference'
            ]);

            DB::beginTransaction();

            // Générer la référence si non fournie
            if (!isset($validated['reference'])) {
                $validated['reference'] = Tax::generateReference($validated['category'], $validated['period']);
            }

            // Calculer tax_amount et total_amount si non fournis
            if (!isset($validated['tax_amount']) || !isset($validated['total_amount'])) {
                // Chercher la catégorie dans tax_categories pour obtenir le taux par défaut
                $taxCategory = TaxCategory::where('name', $validated['category'])->first();
                if ($taxCategory) {
                    $taxRate = $validated['tax_rate'] ?? $taxCategory->default_rate;
                    if (method_exists($taxCategory, 'calculateTax')) {
                        $taxAmount = $taxCategory->calculateTax($validated['base_amount']);
                    } else {
                        $taxAmount = ($validated['base_amount'] * $taxRate) / 100;
                    }
                } else {
                    // Si la catégorie n'existe pas dans tax_categories, utiliser le taux fourni ou 0
                    $taxRate = $validated['tax_rate'] ?? 0;
                    $taxAmount = ($validated['base_amount'] * $taxRate) / 100;
                }
                $validated['tax_rate'] = $taxRate;
                $validated['tax_amount'] = $taxAmount;
                $validated['total_amount'] = $validated['base_amount'] + $taxAmount;
            }

            // Définir le statut par défaut
            $validated['status'] = 'en_attente';
            
            $tax = Tax::create($validated);
            
            // Notifier le patron lors de la création
            $this->safeNotify(function () use ($tax) {
                $this->notificationService->notifyNewTaxe($tax);
            });

            DB::commit();

            return response()->json([
                'success' => true,
                'data' => $tax->load(['comptable']),
                'message' => 'Taxe créée avec succès'
            ], 201);

        } catch (\Illuminate\Validation\ValidationException $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Erreur de validation',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Erreur lors de la création de la taxe', [
                'error' => $e->getMessage(),
                'user_id' => auth()->id(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la création de la taxe: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Mettre à jour une taxe
     */
    public function update(Request $request, $id): JsonResponse
    {
        try {
            $tax = Tax::findOrFail($id);

            if (!$tax->canBeEdited()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette taxe ne peut plus être modifiée'
                ], 400);
            }

            // Normaliser les champs camelCase
            $data = $request->all();
            $normalized = [];
            
            if (isset($data['taxCategoryId'])) {
                // Convertir taxCategoryId en category name
                $categoryObj = TaxCategory::find($data['taxCategoryId']);
                if ($categoryObj) {
                    $normalized['category'] = $categoryObj->name;
                }
            }
            if (isset($data['category'])) $normalized['category'] = $data['category'];
            if (isset($data['baseAmount'])) $normalized['base_amount'] = $data['baseAmount'];
            if (isset($data['periodStart'])) $normalized['period_start'] = $data['periodStart'];
            if (isset($data['periodEnd'])) $normalized['period_end'] = $data['periodEnd'];
            if (isset($data['dueDate'])) $normalized['due_date'] = $data['dueDate'];
            if (isset($data['taxRate'])) $normalized['tax_rate'] = $data['taxRate'];
            if (isset($data['description'])) $normalized['description'] = $data['description'];
            if (isset($data['notes'])) $normalized['notes'] = $data['notes'];

            $request->merge(array_merge($request->all(), $normalized));

            $validated = $request->validate([
                'category' => 'sometimes|string|max:255',
                'base_amount' => 'sometimes|numeric|min:0',
                'period_start' => 'sometimes|date',
                'period_end' => 'sometimes|date',
                'due_date' => 'sometimes|date',
                'tax_rate' => 'nullable|numeric|min:0|max:100',
                'description' => 'nullable|string|max:255',
                'notes' => 'nullable|string'
            ]);

            $tax->update($validated);

            return response()->json([
                'success' => true,
                'data' => $tax->load(['comptable']),
                'message' => 'Taxe mise à jour avec succès'
            ]);

        } catch (\Exception $e) {
            Log::error('Erreur lors de la mise à jour de la taxe', [
                'error' => $e->getMessage(),
                'tax_id' => $id,
                'user_id' => auth()->id()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la mise à jour de la taxe: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Supprimer une taxe
     */
    public function destroy($id): JsonResponse
    {
        try {
            $tax = Tax::findOrFail($id);

            if (!$tax->canBeEdited()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette taxe ne peut plus être supprimée'
                ], 400);
            }

            $tax->delete();

            return response()->json([
                'success' => true,
                'message' => 'Taxe supprimée avec succès'
            ]);

        } catch (\Exception $e) {
            Log::error('Erreur lors de la suppression de la taxe', [
                'error' => $e->getMessage(),
                'tax_id' => $id,
                'user_id' => auth()->id()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la suppression de la taxe: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Calculer une taxe (met à jour les montants sans changer le statut)
     */
    public function calculate($id): JsonResponse
    {
        try {
            $tax = Tax::findOrFail($id);

            if ($tax->status !== 'en_attente') {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette taxe ne peut pas être calculée dans son état actuel'
                ], 400);
            }

            $taxAmount = $tax->calculateTax();

            if ($taxAmount > 0) {
                return response()->json([
                    'success' => true,
                    'data' => $tax->load(['comptable']),
                    'message' => 'Taxe calculée avec succès'
                ]);
            } else {
                return response()->json([
                    'success' => false,
                    'message' => 'Impossible de calculer la taxe (catégorie non trouvée)'
                ], 400);
            }

        } catch (\Exception $e) {
            Log::error('Erreur lors du calcul de la taxe', [
                'error' => $e->getMessage(),
                'tax_id' => $id,
                'user_id' => auth()->id()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du calcul de la taxe: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Marquer une taxe comme payée
     */
    public function markAsPaid($id): JsonResponse
    {
        try {
            $tax = Tax::findOrFail($id);

            if (!$tax->canBePaid()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette taxe ne peut pas être marquée comme payée'
                ], 400);
            }

            if ($tax->markAsPaid()) {
                return response()->json([
                    'success' => true,
                    'data' => $tax->load(['comptable']),
                    'message' => 'Taxe marquée comme payée avec succès'
                ]);
            } else {
                return response()->json([
                    'success' => false,
                    'message' => 'Impossible de marquer la taxe comme payée'
                ], 400);
            }

        } catch (\Exception $e) {
            Log::error('Erreur lors du marquage de la taxe comme payée', [
                'error' => $e->getMessage(),
                'tax_id' => $id,
                'user_id' => auth()->id()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du marquage: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les catégories de taxes (pour sélection dans Flutter)
     */
    public function categories(): JsonResponse
    {
        try {
            $categories = TaxCategory::active()->orderBy('name')->get();

            // Formater pour Flutter : retourner juste les noms et infos nécessaires
            $formattedCategories = $categories->map(function ($category) {
                return [
                    'id' => $category->id,
                    'name' => $category->name,
                    'code' => $category->code,
                    'description' => $category->description,
                    'default_rate' => $category->default_rate,
                    'type' => $category->type,
                    'frequency' => $category->frequency,
                ];
            });

            return response()->json([
                'success' => true,
                'data' => $formattedCategories,
                'message' => 'Catégories récupérées avec succès'
            ]);

        } catch (\Exception $e) {
            Log::error('Erreur lors de la récupération des catégories', [
                'error' => $e->getMessage(),
                'user_id' => auth()->id()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des catégories: ' . $e->getMessage()
            ], 500);
        }
    }
}
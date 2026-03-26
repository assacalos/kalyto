<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\Controller;
use App\Services\NotificationService;
use App\Traits\ScopesByCompany;
use App\Traits\SendsNotifications;
use App\Models\Expense;
use App\Models\ExpenseCategory;
use App\Models\ExpenseApproval;
use App\Models\ExpenseBudget;
use App\Models\User;
use App\Http\Resources\ExpenseResource;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Log;

class ExpenseController extends Controller
{
    use ScopesByCompany, SendsNotifications;

    protected $notificationService;

    public function __construct(NotificationService $notificationService)
    {
        $this->notificationService = $notificationService;
    }
    /**
     * Afficher la liste des dépenses
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
            
            $query = Expense::with(['expenseCategory', 'employee', 'comptable', 'approvals.approver']);

            // Filtrage par statut
            if ($request->has('status')) {
                $query->where('status', $request->status);
            }
            
            // Filtres de date
            if ($request->has('start_date')) {
                $query->whereDate('expense_date', '>=', $request->start_date);
            }
            if ($request->has('end_date')) {
                $query->whereDate('expense_date', '<=', $request->end_date);
            }

            // Si employé → filtre ses propres dépenses
            if ($user->isRH()) {
                $query->where('employee_id', $user->id);
            }
            $this->scopeByCompany($query, $request);

            $perPage = min((int) $request->get('per_page', 20), 100);
            $expenses = $query->orderBy('expense_date', 'desc')->paginate($perPage);

            return response()->json([
                'success' => true,
                'data' => ExpenseResource::collection($expenses),
                'pagination' => [
                    'current_page' => $expenses->currentPage(),
                    'last_page' => $expenses->lastPage(),
                    'per_page' => $expenses->perPage(),
                    'total' => $expenses->total(),
                    'from' => $expenses->firstItem(),
                    'to' => $expenses->lastItem(),
                ],
                'message' => 'Liste des dépenses récupérée avec succès',
            ], 200, [], JSON_UNESCAPED_UNICODE);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des dépenses: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Créer une nouvelle dépense
     * Accepte les formats frontend (camelCase) et backend (snake_case)
     */
    public function store(Request $request)
    {
        try {
            $validated = $request->validate([
                // Format backend
                'expense_category_id' => 'nullable|exists:expense_categories,id',
                'expense_date' => 'required_without:expenseDate|date',
                'amount' => 'required|numeric|min:0',
                'currency' => 'required|string|max:4', // Support FCFA (4 caractères)
                'description' => 'required_without:title|string|max:1000',
                'justification' => 'nullable|string|max:1000',
                'receipt' => 'nullable|file|mimes:pdf,jpg,jpeg,png|max:10240',
                // Format frontend (compatibilité)
                'category' => 'nullable|string', // String category code (office_supplies, travel, etc.)
                'expenseDate' => 'required_without:expense_date|date',
                'title' => 'nullable|string|max:255',
                'notes' => 'nullable|string|max:1000',
                'receiptPath' => 'nullable|string'
            ]);

            DB::beginTransaction();

            // Gérer expense_category_id : convertir category (string) en ID si nécessaire
            $expenseCategoryId = $validated['expense_category_id'] ?? null;
            if (!$expenseCategoryId && isset($validated['category'])) {
                // Rechercher la catégorie par nom (la colonne code n'existe peut-être pas encore)
                $category = null;
                
                // Essayer de rechercher par code si la colonne existe
                if (Schema::hasColumn('expense_categories', 'code')) {
                    $category = ExpenseCategory::where('code', $validated['category'])->first();
                }
                
                // Sinon, rechercher par nom
                if (!$category) {
                    $category = ExpenseCategory::where('name', 'LIKE', '%' . $validated['category'] . '%')
                        ->orWhere('name', 'LIKE', '%' . ucfirst(str_replace('_', ' ', $validated['category'])) . '%')
                        ->first();
                }
                
                if ($category) {
                    $expenseCategoryId = $category->id;
                } else {
                    // Créer une catégorie par défaut si elle n'existe pas
                    $categoryData = [
                        'name' => ucfirst(str_replace('_', ' ', $validated['category'])),
                        'description' => 'Catégorie créée automatiquement',
                    ];
                    
                    // Ajouter code seulement si la colonne existe
                    if (Schema::hasColumn('expense_categories', 'code')) {
                        $categoryData['code'] = $validated['category'];
                    }
                    
                    // Ajouter is_active seulement si la colonne existe
                    if (Schema::hasColumn('expense_categories', 'is_active')) {
                        $categoryData['is_active'] = true;
                    }
                    
                    // Ajouter requires_approval seulement si la colonne existe
                    if (Schema::hasColumn('expense_categories', 'requires_approval')) {
                        $categoryData['requires_approval'] = true;
                    }
                    
                    $category = ExpenseCategory::create($categoryData);
                    $expenseCategoryId = $category->id;
                }
            }

            if (!$expenseCategoryId) {
                throw new \Exception('Catégorie de dépense requise');
            }

            // Gérer les dates (format frontend ou backend)
            $expenseDate = $validated['expense_date'] ?? $validated['expenseDate'] ?? null;
            if (is_string($expenseDate)) {
                try {
                    $expenseDate = \Carbon\Carbon::parse($expenseDate)->format('Y-m-d');
                } catch (\Exception $e) {
                    $expenseDate = now()->format('Y-m-d');
                }
            }

            // Gérer description et title
            $description = $validated['description'] ?? $validated['title'] ?? 'Dépense sans description';

            // Gérer justification et notes (compatibilité frontend/backend)
            $justification = $validated['justification'] ?? $validated['notes'] ?? null;

            $userId = $request->user()->id;
            
            // employee_id = l'utilisateur qui crée la dépense (ou l'employé concerné si spécifié)
            // Pour l'instant, on utilise toujours l'utilisateur connecté
            // TODO: Si besoin futur, permettre à un admin de créer une dépense pour un autre employé
            $employeeId = $validated['employee_id'] ?? $userId;
            
            // Préparer les données pour la création
            $expenseData = [
                'expense_category_id' => $expenseCategoryId,
                'employee_id' => $employeeId, // Employé concerné par la dépense
                'expense_number' => Expense::generateExpenseNumber(),
                'expense_date' => $expenseDate,
                'submission_date' => now()->toDateString(),
                'amount' => $validated['amount'],
                'currency' => $validated['currency'] ?? 'FCFA',
                'title' => $validated['title'] ?? substr($description, 0, 255), // Utiliser title si fourni, sinon description tronquée
                'description' => $description,
                'justification' => $justification,
                'receipt_path' => $validated['receiptPath'] ?? null,
                'status' => 'draft'
            ];
            
            // Ajouter user_id si la colonne existe (compatibilité avec l'ancienne structure)
            // user_id = l'utilisateur qui a créé/soumis (peut être différent de employee_id)
            if (Schema::hasColumn('expenses', 'user_id')) {
                $expenseData['user_id'] = $userId; // Créateur/soumetteur
            }
            $companyId = $this->effectiveCompanyId($request);
            if ($companyId !== null) {
                $expenseData['company_id'] = $companyId;
            }

            $expense = Expense::create($expenseData);

            // Upload du justificatif si fourni
            if ($request->hasFile('receipt')) {
                $expense->uploadReceipt($request->file('receipt'));
            }

            DB::commit();

            return response()->json([
                'success' => true,
                'data' => new ExpenseResource($expense->load(['expenseCategory', 'employee', 'comptable', 'approvals.approver'])),
                'message' => 'Dépense créée avec succès'
            ], 201);

        } catch (\Illuminate\Validation\ValidationException $e) {
            DB::rollback();
            return response()->json([
                'success' => false,
                'message' => 'Erreur de validation',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            DB::rollback();
            \Log::error('Erreur lors de la création de la dépense: ' . $e->getMessage(), [
                'trace' => $e->getTraceAsString(),
                'request' => $request->all()
            ]);
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la création de la dépense: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Formater une dépense pour le frontend (camelCase)
     */
    private function formatExpenseForFrontend($expense)
    {
        // Déterminer le statut pour le frontend
        $status = $expense->status;
        if (in_array($status, ['draft', 'submitted', 'under_review'])) {
            $status = 'pending';
        }

        // Déterminer la catégorie pour le frontend
        $category = 'other';
        if ($expense->expenseCategory) {
            if ($expense->expenseCategory->code) {
                $category = $expense->expenseCategory->code;
            } else {
                // Convertir le nom en code (minuscules, espaces -> underscores)
                $category = strtolower(str_replace(' ', '_', $expense->expenseCategory->name));
            }
        }

        return [
            'id' => $expense->id,
            'title' => $expense->description, // Utiliser description comme title
            'description' => $expense->description,
            'amount' => (float)$expense->amount,
            'category' => $category,
            'status' => $status,
            'expense_date' => $expense->expense_date ? $expense->expense_date->format('Y-m-d') : null,
            'expenseDate' => $expense->expense_date ? $expense->expense_date->format('Y-m-d\TH:i:s.u\Z') : null,
            'receipt_path' => $expense->receipt_path,
            'receiptPath' => $expense->receipt_path,
            'notes' => $expense->justification,
            'created_at' => $expense->created_at ? $expense->created_at->format('Y-m-d H:i:s') : null,
            'updated_at' => $expense->updated_at ? $expense->updated_at->format('Y-m-d H:i:s') : null,
            'created_by' => $expense->employee_id,
            'approved_by' => $expense->approved_by,
            'rejection_reason' => $expense->rejection_reason,
            'rejectionReason' => $expense->rejection_reason,
            'approved_at' => $expense->approved_at ? $expense->approved_at->format('Y-m-d H:i:s') : null,
            'approvedAt' => $expense->approved_at ? $expense->approved_at->format('Y-m-d H:i:s') : null,
            'currency' => $expense->currency,
            'expense_number' => $expense->expense_number,
        ];
    }

    /**
     * Afficher une dépense spécifique
     */
    public function show($id)
    {
        try {
            $expense = Expense::with(['expenseCategory', 'employee', 'comptable', 'approvals.approver'])->find($id);

            if (!$expense) {
                return response()->json([
                    'success' => false,
                    'message' => 'Dépense non trouvée'
                ], 404);
            }

            return response()->json([
                'success' => true,
                'data' => new ExpenseResource($expense),
                'message' => 'Dépense récupérée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération de la dépense: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Mettre à jour une dépense
     */
    public function update(Request $request, $id)
    {
        try {
            $expense = Expense::find($id);

            if (!$expense) {
                return response()->json([
                    'success' => false,
                    'message' => 'Dépense non trouvée'
                ], 404);
            }

            if (!$expense->canBeEdited()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette dépense ne peut plus être modifiée'
                ], 400);
            }

            $validated = $request->validate([
                'expense_date' => 'sometimes|date',
                'amount' => 'sometimes|numeric|min:0',
                'description' => 'sometimes|string|max:1000',
                'justification' => 'nullable|string|max:1000',
                'receipt' => 'nullable|file|mimes:pdf,jpg,jpeg,png|max:10240'
            ]);

            $expense->update($validated);

            // Gérer la mise à jour du justificatif si fourni
            if ($request->hasFile('receipt')) {
                // Supprimer l'ancien fichier s'il existe
                if ($expense->has_receipt) {
                    $expense->deleteReceipt();
                }
                // Uploader le nouveau fichier
                $expense->uploadReceipt($request->file('receipt'));
            }

            return response()->json([
                'success' => true,
                'data' => new ExpenseResource($expense->load(['expenseCategory', 'employee', 'comptable', 'approvals.approver'])),
                'message' => 'Dépense mise à jour avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la mise à jour de la dépense: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Supprimer une dépense
     */
    public function destroy($id)
    {
        try {
            $expense = Expense::find($id);

            if (!$expense) {
                return response()->json([
                    'success' => false,
                    'message' => 'Dépense non trouvée'
                ], 404);
            }

            if (!$expense->canBeEdited()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette dépense ne peut plus être supprimée'
                ], 400);
            }

            // Supprimer le fichier receipt s'il existe
            if ($expense->has_receipt) {
                $expense->deleteReceipt();
            }

            $expense->delete();

            return response()->json([
                'success' => true,
                'message' => 'Dépense supprimée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la suppression de la dépense: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Soumettre une dépense pour approbation
     */
    public function submit($id)
    {
        try {
            $expense = Expense::find($id);

            if (!$expense) {
                return response()->json([
                    'success' => false,
                    'message' => 'Dépense non trouvée'
                ], 404);
            }

            if ($expense->submit()) {
                // Notifier le patron
                $this->safeNotify(function () use ($expense) {
                    $expense->load('employee');
                    $this->notificationService->notifyNewDepense($expense);
                });

                return response()->json([
                    'success' => true,
                    'message' => 'Dépense soumise pour approbation'
                ]);
            } else {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette dépense ne peut pas être soumise'
                ], 400);
            }

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la soumission: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Approuver une dépense
     */
    public function approve(Request $request, $id)
    {
        try {
            $expense = Expense::find($id);

            if (!$expense) {
                return response()->json([
                    'success' => false,
                    'message' => 'Dépense non trouvée'
                ], 404);
            }

            // Si la dépense est en draft, la soumettre d'abord
            if ($expense->status === 'draft') {
                if (!$expense->submit()) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Impossible de soumettre cette dépense pour approbation'
                    ], 400);
                }
                // Recharger la dépense après soumission
                $expense->refresh();
            }

            $comments = $request->get('comments');

            if ($expense->approve($request->user()->id, $comments)) {
                // Notifier l'auteur de la dépense
                if ($expense->employee_id) {
                    $this->safeNotify(function () use ($expense) {
                        $expense->load('employee');
                        $this->notificationService->notifyDepenseValidated($expense);
                    });
                }

                // Recharger la dépense avec ses relations
                $expense->refresh();
                $expense->load(['employee', 'expenseCategory', 'comptable', 'approvals.approver']);

                return response()->json([
                    'success' => true,
                    'data' => $expense,
                    'message' => 'Dépense approuvée avec succès'
                ]);
            } else {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette dépense ne peut pas être approuvée. Statut actuel: ' . $expense->status . '. Les statuts acceptés sont: submitted, under_review'
                ], 400);
            }

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'approbation: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Rejeter une dépense
     */
    public function reject(Request $request, $id)
    {
        try {
            $expense = Expense::find($id);

            if (!$expense) {
                return response()->json([
                    'success' => false,
                    'message' => 'Dépense non trouvée'
                ], 404);
            }

            // Si la dépense est en draft, la soumettre d'abord
            if ($expense->status === 'draft') {
                if (!$expense->submit()) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Impossible de soumettre cette dépense pour rejet'
                    ], 400);
                }
                // Recharger la dépense après soumission
                $expense->refresh();
            }

            $validated = $request->validate([
                'reason' => 'required|string|max:1000'
            ]);

            if ($expense->reject($request->user()->id, $validated['reason'])) {
                // Notifier l'auteur de la dépense
                if ($expense->employee_id) {
                    $reason = $validated['reason'];
                    $this->safeNotify(function () use ($expense, $reason) {
                        $expense->load('employee');
                        $this->notificationService->notifyDepenseRejected($expense, $reason);
                    });
                }

                // Recharger la dépense avec ses relations
                $expense->refresh();
                $expense->load(['employee', 'expenseCategory', 'comptable', 'approvals.approver']);

                return response()->json([
                    'success' => true,
                    'data' => $expense,
                    'message' => 'Dépense rejetée avec succès'
                ]);
            } else {
                return response()->json([
                    'success' => false,
                    'message' => 'Cette dépense ne peut pas être rejetée. Statut actuel: ' . $expense->status . '. Les statuts acceptés sont: submitted, under_review'
                ], 400);
            }

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du rejet: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Statistiques des dépenses
     */
    public function statistics(Request $request)
    {
        try {
            $startDate = $request->get('date_debut');
            $endDate = $request->get('date_fin');

            $stats = Expense::getExpenseStats($startDate, $endDate);

            return response()->json([
                'success' => true,
                'data' => $stats,
                'message' => 'Statistiques récupérées avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des statistiques: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les catégories de dépenses
     */
    public function categories()
    {
        try {
            $categories = ExpenseCategory::active()->orderBy('name')->get();

            return response()->json([
                'success' => true,
                'data' => $categories,
                'message' => 'Catégories de dépenses récupérées avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des catégories: ' . $e->getMessage()
            ], 500);
        }
    }
    
    /**
     * Compteur de dépenses avec filtres
     */
    public function count(Request $request)
    {
        try {
            $user = $request->user();
            
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Utilisateur non authentifié'
                ], 401);
            }
            
            $validated = $request->validate([
                'status' => 'nullable|string',
                'start_date' => 'nullable|date',
                'end_date' => 'nullable|date|after_or_equal:start_date',
                'employee_id' => 'nullable|integer|exists:employees,id',
            ]);
            
            $query = Expense::query();
            
            // Filtre par statut
            if (isset($validated['status'])) {
                $query->where('status', $validated['status']);
            }
            
            // Filtres de date
            if (isset($validated['start_date'])) {
                $query->whereDate('expense_date', '>=', $validated['start_date']);
            }
            if (isset($validated['end_date'])) {
                $query->whereDate('expense_date', '<=', $validated['end_date']);
            }
            
            // Filtre par employee_id
            if (isset($validated['employee_id'])) {
                $query->where('employee_id', $validated['employee_id']);
            }
            
            // Si employé → filtre ses propres dépenses
            if ($user->isRH()) {
                $query->where('employee_id', $user->id);
            }
            
            return response()->json([
                'success' => true,
                'count' => $query->count(),
            ], 200);
            
        } catch (\Exception $e) {
            \Log::error('ExpenseController::count - Erreur', [
                'message' => $e->getMessage(),
            ]);
            
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du comptage: ' . $e->getMessage(),
            ], 500);
        }
    }
    
    /**
     * Statistiques agrégées des dépenses (remplace statistics existant avec format standardisé)
     */
    public function stats(Request $request)
    {
        try {
            $user = $request->user();
            
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Utilisateur non authentifié'
                ], 401);
            }
            
            $validated = $request->validate([
                'status' => 'nullable|string',
                'start_date' => 'nullable|date',
                'end_date' => 'nullable|date|after_or_equal:start_date',
                'employee_id' => 'nullable|integer|exists:employees,id',
            ]);
            
            $query = Expense::query();
            
            // Filtres de date
            if (isset($validated['start_date'])) {
                $query->whereDate('expense_date', '>=', $validated['start_date']);
            }
            if (isset($validated['end_date'])) {
                $query->whereDate('expense_date', '<=', $validated['end_date']);
            }
            
            // Filtre par statut
            if (isset($validated['status'])) {
                $query->where('status', $validated['status']);
            }
            
            // Filtre par employee_id
            if (isset($validated['employee_id'])) {
                $query->where('employee_id', $validated['employee_id']);
            }
            
            // Si employé → filtre ses propres dépenses
            if ($user->isRH()) {
                $query->where('employee_id', $user->id);
            }
            
            return response()->json([
                'success' => true,
                'data' => [
                    'count' => $query->count(),
                    'total_amount' => $query->sum('amount'),
                    'average_amount' => $query->avg('amount'),
                    'min_amount' => $query->min('amount'),
                    'max_amount' => $query->max('amount'),
                ],
            ], 200);
            
        } catch (\Exception $e) {
            \Log::error('ExpenseController::stats - Erreur', [
                'message' => $e->getMessage(),
            ]);
            
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des statistiques: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Afficher le reçu d'une dépense (pour affichage dans le navigateur)
     */
    public function showReceipt($id)
    {
        try {
            $expense = Expense::find($id);

            if (!$expense) {
                return response()->json([
                    'success' => false,
                    'message' => 'Dépense non trouvée'
                ], 404);
            }

            if (!$expense->has_receipt) {
                return response()->json([
                    'success' => false,
                    'message' => 'Aucun reçu disponible pour cette dépense'
                ], 404);
            }

            $filePath = $expense->receipt_path;
            
            if (!\Storage::disk('private')->exists($filePath)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Fichier non trouvé'
                ], 404);
            }

            // Vérifier si c'est une image
            $mimeType = \Storage::disk('private')->mimeType($filePath);
            $isImage = strpos($mimeType, 'image/') === 0;

            if ($isImage) {
                // Pour les images, retourner directement le contenu avec les headers appropriés
                $fileContent = \Storage::disk('private')->get($filePath);
                return response($fileContent, 200)
                    ->header('Content-Type', $mimeType)
                    ->header('Content-Disposition', 'inline; filename="' . basename($filePath) . '"')
                    ->header('Cache-Control', 'public, max-age=3600');
            } else {
                // Pour les PDFs et autres fichiers, utiliser streamDownload
                return \Storage::disk('private')->response($filePath, basename($filePath), [
                    'Content-Type' => $mimeType ?? 'application/octet-stream',
                    'Content-Disposition' => 'inline; filename="' . basename($filePath) . '"',
                ]);
            }

        } catch (\Exception $e) {
            \Log::error('Expense receipt show error', [
                'expense_id' => $id,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'affichage: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Télécharger le reçu d'une dépense
     */
    public function downloadReceipt($id)
    {
        try {
            $expense = Expense::find($id);

            if (!$expense) {
                return response()->json([
                    'success' => false,
                    'message' => 'Dépense non trouvée'
                ], 404);
            }

            if (!$expense->has_receipt) {
                return response()->json([
                    'success' => false,
                    'message' => 'Aucun reçu disponible pour cette dépense'
                ], 404);
            }

            $filePath = $expense->receipt_path;
            
            if (!\Storage::disk('private')->exists($filePath)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Fichier non trouvé'
                ], 404);
            }

            // Extraire le nom du fichier original ou générer un nom basé sur l'ID de la dépense
            $fileName = basename($filePath);
            $originalName = $expense->expense_number . '_receipt.' . pathinfo($fileName, PATHINFO_EXTENSION);

            // Utiliser streamDownload pour éviter les problèmes de mémoire
            return \Storage::disk('private')->download($filePath, $originalName, [
                'Content-Type' => \Storage::disk('private')->mimeType($filePath) ?? 'application/octet-stream',
                'Content-Disposition' => 'attachment; filename="' . $originalName . '"',
            ]);

        } catch (\Exception $e) {
            \Log::error('Expense receipt download error', [
                'expense_id' => $id,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du téléchargement: ' . $e->getMessage()
            ], 500);
        }
    }
}
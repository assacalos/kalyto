<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\Controller;
use App\Services\NotificationService;
use App\Traits\SendsNotifications;
use App\Models\Stock;
use App\Models\StockMovement;
use App\Models\StockAlert;
use App\Models\StockOrder;
use App\Models\StockOrderItem;
use App\Http\Resources\StockResource;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class StockController extends Controller
{
    use SendsNotifications;

    protected $notificationService;

    public function __construct(NotificationService $notificationService)
    {
        $this->notificationService = $notificationService;
    }
    /**
     * Afficher la liste des stocks
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
            
            // Ne charger que les relations qui existent (movements, alerts)
            // Retirer creator et updater car created_by/updated_by n'existent pas dans la migration
            $query = Stock::with(['movements', 'alerts']);

            // Filtrage par statut
            if ($request->has('status')) {
                $query->where('status', $request->status);
            }

            // Filtrage par catégorie
            if ($request->has('category')) {
                $query->where('category', $request->category);
            }

            // Retirer les filtres sur des colonnes qui n'existent pas : supplier, location, brand, barcode

            // Filtrage par SKU
            if ($request->has('sku')) {
                $query->where('sku', 'like', '%' . $request->sku . '%');
            }

            // Filtrage par stock faible
            if ($request->has('low_stock')) {
                if ($request->low_stock === 'true') {
                    $query->lowStock();
                }
            }

            // Filtrage par stock épuisé
            if ($request->has('out_of_stock')) {
                if ($request->out_of_stock === 'true') {
                    $query->outOfStock();
                }
            }

            // Filtrage par surstock
            if ($request->has('overstock')) {
                if ($request->overstock === 'true') {
                    $query->overstock();
                }
            }

            // Filtrage par réapprovisionnement nécessaire
            if ($request->has('needs_reorder')) {
                if ($request->needs_reorder === 'true') {
                    $query->needsReorder();
                }
            }

            $perPage = min((int) $request->get('per_page', 20), 100);
            $stocks = $query->orderBy('name')->paginate($perPage);

            return response()->json([
                'success' => true,
                'data' => StockResource::collection($stocks),
                'pagination' => [
                    'current_page' => $stocks->currentPage(),
                    'last_page' => $stocks->lastPage(),
                    'per_page' => $stocks->perPage(),
                    'total' => $stocks->total(),
                    'from' => $stocks->firstItem(),
                    'to' => $stocks->lastItem(),
                ],
                'message' => 'Liste des stocks récupérée avec succès',
            ], 200, [], JSON_UNESCAPED_UNICODE);

        } catch (\Exception $e) {
            \Log::error('Erreur StockController@index: ' . $e->getMessage(), [
                'trace' => $e->getTraceAsString()
            ]);
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des stocks: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Afficher un stock spécifique
     */
    public function show($id)
    {
        try {
            // Ne charger que les relations qui existent
            $stock = Stock::with(['movements', 'alerts'])->find($id);

            if (!$stock) {
                return response()->json([
                    'success' => false,
                    'message' => 'Stock non trouvé'
                ], 404);
            }

            return response()->json([
                'success' => true,
                'data' => new StockResource($stock),
                'message' => 'Stock récupéré avec succès'
            ]);

        } catch (\Exception $e) {
            \Log::error('Erreur StockController@show: ' . $e->getMessage(), [
                'trace' => $e->getTraceAsString()
            ]);
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération du stock: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Créer un nouveau stock
     */
    public function store(Request $request)
    {
        try {
            // Validation adaptée aux champs envoyés par Flutter
            $validated = $request->validate([
                'name' => 'required|string|max:255',
                'description' => 'nullable|string', // Optionnel comme dans Flutter
                'category' => 'required|string|max:255',
                'sku' => 'required|string|max:255|unique:stocks,sku',
                // Supporte les deux formats de Flutter: quantity et current_quantity
                'quantity' => 'nullable|numeric|min:0',
                'current_quantity' => 'nullable|numeric|min:0',
                // Supporte les deux formats de Flutter: min_quantity et minimum_quantity
                'min_quantity' => 'nullable|numeric|min:0',
                'minimum_quantity' => 'nullable|numeric|min:0',
                // Supporte les deux formats de Flutter: max_quantity et maximum_quantity
                'max_quantity' => 'nullable|numeric|min:0',
                'maximum_quantity' => 'nullable|numeric|min:0',
                // Supporte les deux formats de Flutter: unit_price et unit_cost
                'unit_price' => 'nullable|numeric|min:0',
                'unit_cost' => 'nullable|numeric|min:0',
                // Supporte les deux formats de Flutter: commentaire et notes
                'commentaire' => 'nullable|string',
                'notes' => 'nullable|string',
                'status' => 'required|in:en_attente,valide,rejete', // Statuts de la migration
            ]);

            DB::beginTransaction();

            // Mapper les champs Flutter vers les noms de la DB/migration
            $quantity = $validated['current_quantity'] ?? $validated['quantity'] ?? 0;
            $minQuantity = $validated['minimum_quantity'] ?? $validated['min_quantity'] ?? 0;
            $maxQuantity = $validated['maximum_quantity'] ?? $validated['max_quantity'] ?? 0;
            $unitPrice = $validated['unit_cost'] ?? $validated['unit_price'] ?? 0;
            $commentaire = $validated['commentaire'] ?? $validated['notes'] ?? null;

            // Insérer directement avec les noms de colonnes de la migration
            $stockId = DB::table('stocks')->insertGetId([
                'name' => $validated['name'],
                'description' => $validated['description'] ?? null,
                'category' => $validated['category'],
                'sku' => $validated['sku'],
                'quantity' => $quantity,
                'min_quantity' => $minQuantity,
                'max_quantity' => $maxQuantity,
                'unit_price' => $unitPrice,
                'commentaire' => $commentaire,
                'status' => $validated['status'],
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            // Charger le modèle pour utiliser les méthodes
            $stock = Stock::find($stockId);

            // Vérifier les alertes
            $stock->checkAlerts();

            DB::commit();

            // Notifier le patron lors de la création si le stock est en attente
            if ($stock->status === 'en_attente' || $stock->status === 'pending') {
                $this->safeNotify(function () use ($stock) {
                    $this->notificationService->notifyNewStock($stock);
                });
            }

            return response()->json([
                'success' => true,
                'data' => $stock->load(['creator']),
                'message' => 'Stock créé avec succès'
            ], 201);

        } catch (\Exception $e) {
            DB::rollback();
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la création du stock: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Mettre à jour un stock
     */
    public function update(Request $request, $id)
    {
        try {
            $stock = Stock::find($id);

            if (!$stock) {
                return response()->json([
                    'success' => false,
                    'message' => 'Stock non trouvé'
                ], 404);
            }

            // Validation adaptée aux champs envoyés par Flutter (même que store)
            $validated = $request->validate([
                'name' => 'sometimes|string|max:255',
                'description' => 'nullable|string',
                'category' => 'sometimes|string|max:255',
                'sku' => 'sometimes|string|max:255|unique:stocks,sku,' . $id,
                // Supporte les deux formats de Flutter
                'quantity' => 'nullable|numeric|min:0',
                'current_quantity' => 'nullable|numeric|min:0',
                'min_quantity' => 'nullable|numeric|min:0',
                'minimum_quantity' => 'nullable|numeric|min:0',
                'max_quantity' => 'nullable|numeric|min:0',
                'maximum_quantity' => 'nullable|numeric|min:0',
                'unit_price' => 'nullable|numeric|min:0',
                'unit_cost' => 'nullable|numeric|min:0',
                'commentaire' => 'nullable|string',
                'notes' => 'nullable|string',
                'status' => 'sometimes|in:en_attente,valide,rejete',
            ]);

            // Mapper les champs Flutter vers les noms de la DB/migration
            $updateData = [];
            if (isset($validated['name'])) $updateData['name'] = $validated['name'];
            if (isset($validated['description'])) $updateData['description'] = $validated['description'];
            if (isset($validated['category'])) $updateData['category'] = $validated['category'];
            if (isset($validated['sku'])) $updateData['sku'] = $validated['sku'];
            if (isset($validated['quantity']) || isset($validated['current_quantity'])) {
                $updateData['quantity'] = $validated['current_quantity'] ?? $validated['quantity'];
            }
            if (isset($validated['min_quantity']) || isset($validated['minimum_quantity'])) {
                $updateData['min_quantity'] = $validated['minimum_quantity'] ?? $validated['min_quantity'];
            }
            if (isset($validated['max_quantity']) || isset($validated['maximum_quantity'])) {
                $updateData['max_quantity'] = $validated['maximum_quantity'] ?? $validated['max_quantity'];
            }
            if (isset($validated['unit_price']) || isset($validated['unit_cost'])) {
                $updateData['unit_price'] = $validated['unit_cost'] ?? $validated['unit_price'];
            }
            if (isset($validated['commentaire']) || isset($validated['notes'])) {
                $updateData['commentaire'] = $validated['commentaire'] ?? $validated['notes'];
            }
            if (isset($validated['status'])) $updateData['status'] = $validated['status'];

            // Utiliser DB::table() pour mettre à jour avec les noms de colonnes de la migration
            if (!empty($updateData)) {
                $updateData['updated_at'] = now();
                DB::table('stocks')->where('id', $id)->update($updateData);
                $stock = Stock::find($id); // Recharger le modèle
            }

            // Vérifier les alertes
            $stock->checkAlerts();

            return response()->json([
                'success' => true,
                'data' => $stock->load(['creator', 'updater']),
                'message' => 'Stock mis à jour avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la mise à jour du stock: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Supprimer un stock
     */
    public function destroy($id)
    {
        try {
            $stock = Stock::find($id);

            if (!$stock) {
                return response()->json([
                    'success' => false,
                    'message' => 'Stock non trouvé'
                ], 404);
            }

            $stock->delete();

            return response()->json([
                'success' => true,
                'message' => 'Stock supprimé avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la suppression du stock: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Ajouter du stock
     */
    public function addStock(Request $request, $id)
    {
        try {
            $stock = Stock::find($id);

            if (!$stock) {
                return response()->json([
                    'success' => false,
                    'message' => 'Stock non trouvé'
                ], 404);
            }

            $validated = $request->validate([
                'quantity' => 'required|numeric|min:0.001',
                'unit_cost' => 'nullable|numeric|min:0',
                'reason' => 'required|in:purchase,sale,transfer,adjustment,return,loss,damage,expired,other',
                'reference' => 'nullable|string|max:255',
                'notes' => 'nullable|string|max:1000'
            ]);

            $movement = $stock->addStock(
                $validated['quantity'],
                $validated['unit_cost'],
                $validated['reason'],
                $validated['reference'],
                $validated['notes'],
                $request->user()->id
            );

            return response()->json([
                'success' => true,
                'data' => $movement,
                'message' => 'Stock ajouté avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'ajout du stock: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Retirer du stock
     */
    public function removeStock(Request $request, $id)
    {
        try {
            $stock = Stock::find($id);

            if (!$stock) {
                return response()->json([
                    'success' => false,
                    'message' => 'Stock non trouvé'
                ], 404);
            }

            $validated = $request->validate([
                'quantity' => 'required|numeric|min:0.001',
                'reason' => 'required|in:purchase,sale,transfer,adjustment,return,loss,damage,expired,other',
                'reference' => 'nullable|string|max:255',
                'notes' => 'nullable|string|max:1000'
            ]);

            $movement = $stock->removeStock(
                $validated['quantity'],
                $validated['reason'],
                $validated['reference'],
                $validated['notes'],
                $request->user()->id
            );

            return response()->json([
                'success' => true,
                'data' => $movement,
                'message' => 'Stock retiré avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du retrait du stock: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Ajuster le stock
     */
    public function adjustStock(Request $request, $id)
    {
        try {
            $stock = Stock::find($id);

            if (!$stock) {
                return response()->json([
                    'success' => false,
                    'message' => 'Stock non trouvé'
                ], 404);
            }

            $validated = $request->validate([
                'new_quantity' => 'required|numeric|min:0',
                'reason' => 'required|in:purchase,sale,transfer,adjustment,return,loss,damage,expired,other',
                'notes' => 'nullable|string|max:1000'
            ]);

            $movement = $stock->adjustStock(
                $validated['new_quantity'],
                $validated['reason'],
                $validated['notes'],
                $request->user()->id
            );

            return response()->json([
                'success' => true,
                'data' => $movement,
                'message' => 'Stock ajusté avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'ajustement du stock: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Transférer du stock
     */
    public function transferStock(Request $request, $id)
    {
        try {
            $stock = Stock::find($id);

            if (!$stock) {
                return response()->json([
                    'success' => false,
                    'message' => 'Stock non trouvé'
                ], 404);
            }

            $validated = $request->validate([
                'quantity' => 'required|numeric|min:0.001',
                'location_to' => 'required|string|max:255',
                'notes' => 'nullable|string|max:1000'
            ]);

            $movement = $stock->transferStock(
                $validated['quantity'],
                $validated['location_to'],
                $validated['notes'],
                $request->user()->id
            );

            return response()->json([
                'success' => true,
                'data' => $movement,
                'message' => 'Stock transféré avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du transfert du stock: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Statistiques des stocks
     */
    public function statistics(Request $request)
    {
        try {
            $stats = Stock::getStockStats();

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
     * Récupérer les catégories de stocks (liste des catégories utilisées)
     */
    public function categories()
    {
        try {
            // Récupérer toutes les catégories distinctes depuis les stocks
            $categories = Stock::select('category')
                ->distinct()
                ->whereNotNull('category')
                ->where('category', '!=', '')
                ->orderBy('category')
                ->pluck('category')
                ->map(function ($categoryName) {
                    return [
                        'name' => $categoryName,
                        'value' => $categoryName,
                    ];
                })
                ->values();

            return response()->json([
                'success' => true,
                'data' => $categories,
                'message' => 'Catégories récupérées avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des catégories: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les stocks faibles
     */
    public function lowStock()
    {
        try {
            $stocks = Stock::getLowStockItems();

            return response()->json([
                'success' => true,
                'data' => $stocks,
                'message' => 'Stocks faibles récupérés avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des stocks faibles: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les stocks épuisés
     */
    public function outOfStock()
    {
        try {
            $stocks = Stock::getOutOfStockItems();

            return response()->json([
                'success' => true,
                'data' => $stocks,
                'message' => 'Stocks épuisés récupérés avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des stocks épuisés: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les surstocks
     */
    public function overstock()
    {
        try {
            $stocks = Stock::getOverstockItems();

            return response()->json([
                'success' => true,
                'data' => $stocks,
                'message' => 'Surstocks récupérés avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des surstocks: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les stocks nécessitant un réapprovisionnement
     */
    public function needsReorder()
    {
        try {
            $stocks = Stock::getItemsNeedingReorder();

            return response()->json([
                'success' => true,
                'data' => $stocks,
                'message' => 'Stocks nécessitant un réapprovisionnement récupérés avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des stocks nécessitant un réapprovisionnement: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Formater une quantité
     */
    private function formatQuantity($quantity)
    {
        return number_format($quantity ?? 0, 3, ',', ' ');
    }

    /**
     * Formater un coût
     */
    private function formatCost($cost)
    {
        return $cost ? number_format($cost, 2, ',', ' ') . ' FCFA' : 'N/A';
    }

    /**
     * Transformer un stock au format Flutter
     */
    private function transformStockForFlutter($stock)
    {
        return [
            'id' => $stock->id,
            'name' => $stock->name,
            'description' => $stock->description,
            'category' => $stock->category,
            'sku' => $stock->sku,
            'quantity' => $stock->quantity ?? $stock->current_quantity,
            'current_quantity' => $stock->current_quantity,
            'minimum_quantity' => $stock->minimum_quantity,
            'maximum_quantity' => $stock->maximum_quantity,
            'reorder_point' => $stock->reorder_point,
            'unit_price' => $stock->unit_price ?? $stock->unit_cost,
            'unit_cost' => $stock->unit_cost,
            'commentaire' => $stock->commentaire ?? $stock->notes,
            'notes' => $stock->notes,
            'status' => $stock->status,
            'status_libelle' => $stock->status_libelle,
            'created_at' => $stock->created_at->format('Y-m-d H:i:s'),
            'updated_at' => $stock->updated_at->format('Y-m-d H:i:s')
        ];
    }

    /**
     * Valider un stock
     */
    public function valider(Request $request, $id)
    {
        try {
            $stock = Stock::find($id);

            if (!$stock) {
                return response()->json([
                    'success' => false,
                    'message' => 'Stock non trouvé'
                ], 404);
            }

            // Vérifier que le stock est en attente
            if ($stock->status !== 'en_attente' && $stock->status !== 'pending') {
                return response()->json([
                    'success' => false,
                    'message' => 'Ce stock ne peut pas être validé'
                ], 422);
            }

            DB::beginTransaction();

            // Mettre à jour le statut du stock à 'valide'
            DB::table('stocks')->where('id', $id)->update([
                'status' => 'valide',
                'updated_at' => now()
            ]);

            DB::commit();

            // Recharger le stock
            $stock = Stock::find($id);

            // Notifier l'auteur du stock
            if ($stock->created_by) {
                $this->safeNotify(function () use ($stock) {
                    $stock->load('creator');
                    $this->notificationService->notifyStockValidated($stock);
                });
            }

            return response()->json([
                'success' => true,
                'data' => $this->transformStockForFlutter($stock),
                'message' => 'Stock validé avec succès'
            ]);

        } catch (\Exception $e) {
            DB::rollback();
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la validation du stock: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Rejeter un stock avec commentaire
     */
    public function rejeter(Request $request, $id)
    {
        try {
            $stock = Stock::find($id);

            if (!$stock) {
                return response()->json([
                    'success' => false,
                    'message' => 'Stock non trouvé'
                ], 404);
            }

            $validated = $request->validate([
                'commentaire' => 'required|string|max:1000'
            ]);

            DB::beginTransaction();

            // Mettre à jour le statut du stock à 'rejete'
            // Utiliser DB::table() car updated_by n'existe pas dans la migration
            DB::table('stocks')->where('id', $id)->update([
                'status' => 'rejete',
                'commentaire' => $validated['commentaire'],
                'updated_at' => now()
            ]);

            DB::commit();

            // Recharger le stock
            $stock = Stock::find($id);

            // Notifier l'auteur du stock
            if ($stock->created_by) {
                $commentaire = $validated['commentaire'];
                $this->safeNotify(function () use ($stock, $commentaire) {
                    $stock->load('creator');
                    $this->notificationService->notifyStockRejected($stock, $commentaire);
                });
            }

            return response()->json([
                'success' => true,
                'data' => $this->transformStockForFlutter($stock),
                'message' => 'Stock rejeté avec succès'
            ]);

        } catch (\Exception $e) {
            DB::rollback();
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du rejet du stock: ' . $e->getMessage()
            ], 500);
        }
    }
}
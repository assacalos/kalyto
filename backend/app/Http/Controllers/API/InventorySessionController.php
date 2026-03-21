<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\Controller;
use App\Traits\ScopesByCompany;
use App\Models\InventorySession;
use App\Models\InventoryLine;
use App\Models\Stock;
use App\Models\StockMovement;
use Illuminate\Http\Request;

class InventorySessionController extends Controller
{
    use ScopesByCompany;

    public function index(Request $request)
    {
        try {
            if (!$request->user()) {
                return response()->json(['success' => false, 'message' => 'Non authentifié'], 401);
            }

            $query = InventorySession::withCount('lines')->orderByDesc('created_at');
            $this->scopeByCompany($query, $request);

            $perPage = min((int) $request->get('per_page', 20), 100);
            $page = (int) $request->get('page', 1);

            $paginated = $query->paginate($perPage, ['*'], 'page', $page);
            $items = $paginated->items();

            $data = array_map(function ($session) {
                return [
                    'id' => $session->id,
                    'date' => $session->date?->format('Y-m-d'),
                    'depot' => $session->depot,
                    'status' => $session->status,
                    'closed_at' => $session->closed_at?->toIso8601String(),
                    'lines_count' => $session->lines_count,
                    'created_at' => $session->created_at?->toIso8601String(),
                    'updated_at' => $session->updated_at?->toIso8601String(),
                ];
            }, $items);

            return response()->json([
                'success' => true,
                'data' => $data,
                'pagination' => [
                    'current_page' => $paginated->currentPage(),
                    'last_page' => $paginated->lastPage(),
                    'per_page' => $paginated->perPage(),
                    'total' => $paginated->total(),
                ],
                'message' => 'Sessions récupérées',
            ], 200, [], JSON_UNESCAPED_UNICODE);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur: ' . $e->getMessage(),
            ], 500);
        }
    }

    public function store(Request $request)
    {
        try {
            if (!$request->user()) {
                return response()->json(['success' => false, 'message' => 'Non authentifié'], 401);
            }

            $date = $request->input('date');
            $depot = $request->input('depot');

            $session = new InventorySession();
            $companyId = $this->effectiveCompanyId($request);
            if ($companyId !== null) {
                $session->company_id = $companyId;
            }
            if ($date) {
                $session->date = \Carbon\Carbon::parse($date)->format('Y-m-d');
            }
            if ($depot !== null && $depot !== '') {
                $session->depot = $depot;
            }
            $session->status = InventorySession::STATUS_IN_PROGRESS;
            $session->save();

            return response()->json([
                'success' => true,
                'data' => [
                    'id' => $session->id,
                    'date' => $session->date?->format('Y-m-d'),
                    'depot' => $session->depot,
                    'status' => $session->status,
                    'closed_at' => null,
                    'lines_count' => 0,
                    'created_at' => $session->created_at?->toIso8601String(),
                    'updated_at' => $session->updated_at?->toIso8601String(),
                ],
                'message' => 'Session créée',
            ], 201, [], JSON_UNESCAPED_UNICODE);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur: ' . $e->getMessage(),
            ], 500);
        }
    }

    public function show(Request $request, int $id)
    {
        try {
            if (!$request->user()) {
                return response()->json(['success' => false, 'message' => 'Non authentifié'], 401);
            }

            $query = InventorySession::withCount('lines');
            $this->scopeByCompany($query, $request);
            $session = $query->find($id);
            if (!$session) {
                return response()->json(['success' => false, 'message' => 'Session non trouvée'], 404);
            }

            return response()->json([
                'success' => true,
                'data' => [
                    'id' => $session->id,
                    'date' => $session->date?->format('Y-m-d'),
                    'depot' => $session->depot,
                    'status' => $session->status,
                    'closed_at' => $session->closed_at?->toIso8601String(),
                    'lines_count' => $session->lines_count,
                    'created_at' => $session->created_at?->toIso8601String(),
                    'updated_at' => $session->updated_at?->toIso8601String(),
                ],
                'message' => 'Session récupérée',
            ], 200, [], JSON_UNESCAPED_UNICODE);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur: ' . $e->getMessage(),
            ], 500);
        }
    }

    public function lines(Request $request, int $id)
    {
        try {
            if (!$request->user()) {
                return response()->json(['success' => false, 'message' => 'Non authentifié'], 401);
            }

            $session = InventorySession::find($id);
            if (!$session) {
                return response()->json(['success' => false, 'message' => 'Session non trouvée'], 404);
            }

            $lines = $session->lines()->with('stock')->get();

            $data = $lines->map(function (InventoryLine $line) {
                $stock = $line->stock;
                return [
                    'id' => $line->id,
                    'session_id' => $line->inventory_session_id,
                    'stock_id' => $line->stock_id,
                    'sku' => $line->sku ?? $stock?->sku,
                    'product_name' => $line->product_name ?? $stock?->name,
                    'name' => $line->product_name ?? $stock?->name,
                    'unit' => $line->unit ?? 'pièce',
                    'theoretical_qty' => (float) $line->theoretical_qty,
                    'counted_qty' => $line->counted_qty !== null ? (float) $line->counted_qty : null,
                    'created_at' => $line->created_at?->toIso8601String(),
                    'updated_at' => $line->updated_at?->toIso8601String(),
                ];
            })->values()->all();

            return response()->json([
                'success' => true,
                'data' => $data,
                'message' => 'Lignes récupérées',
            ], 200, [], JSON_UNESCAPED_UNICODE);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur: ' . $e->getMessage(),
            ], 500);
        }
    }

    public function addLines(Request $request, int $id)
    {
        try {
            if (!$request->user()) {
                return response()->json(['success' => false, 'message' => 'Non authentifié'], 401);
            }

            $session = InventorySession::find($id);
            if (!$session) {
                return response()->json(['success' => false, 'message' => 'Session non trouvée'], 404);
            }
            if ($session->isClosed()) {
                return response()->json(['success' => false, 'message' => 'Session déjà clôturée'], 400);
            }

            $stockIds = $request->input('stock_ids');
            if (is_array($stockIds) && count($stockIds) > 0) {
                $stocks = Stock::whereIn('id', $stockIds)->get();
            } else {
                $stocks = Stock::all();
            }

            $created = [];
            foreach ($stocks as $stock) {
                $existing = InventoryLine::where('inventory_session_id', $session->id)
                    ->where('stock_id', $stock->id)
                    ->exists();
                if ($existing) {
                    continue;
                }
                $theoretical = (float) ($stock->current_quantity ?? $stock->quantity ?? 0);
                $line = InventoryLine::create([
                    'inventory_session_id' => $session->id,
                    'stock_id' => $stock->id,
                    'theoretical_qty' => $theoretical,
                    'counted_qty' => null,
                ]);
                $line->load('stock');
                $created[] = [
                    'id' => $line->id,
                    'session_id' => $line->inventory_session_id,
                    'stock_id' => $line->stock_id,
                    'sku' => $line->stock?->sku,
                    'product_name' => $line->stock?->name,
                    'unit' => $line->unit ?? 'pièce',
                    'theoretical_qty' => (float) $line->theoretical_qty,
                    'counted_qty' => null,
                    'created_at' => $line->created_at?->toIso8601String(),
                    'updated_at' => $line->updated_at?->toIso8601String(),
                ];
            }

            return response()->json([
                'success' => true,
                'data' => ['lines' => $created],
                'message' => count($created) . ' ligne(s) ajoutée(s)',
            ], 200, [], JSON_UNESCAPED_UNICODE);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur: ' . $e->getMessage(),
            ], 500);
        }
    }

    public function updateLine(Request $request, int $sessionId, int $lineId)
    {
        try {
            if (!$request->user()) {
                return response()->json(['success' => false, 'message' => 'Non authentifié'], 401);
            }

            $session = InventorySession::find($sessionId);
            if (!$session) {
                return response()->json(['success' => false, 'message' => 'Session non trouvée'], 404);
            }
            if ($session->isClosed()) {
                return response()->json(['success' => false, 'message' => 'Session déjà clôturée'], 400);
            }

            $line = InventoryLine::where('inventory_session_id', $sessionId)->where('id', $lineId)->first();
            if (!$line) {
                return response()->json(['success' => false, 'message' => 'Ligne non trouvée'], 404);
            }

            $counted = $request->input('counted_qty');
            if ($counted !== null) {
                $line->counted_qty = max(0, (float) $counted);
                $line->save();
            }

            $line->load('stock');
            return response()->json([
                'success' => true,
                'data' => [
                    'id' => $line->id,
                    'session_id' => $line->inventory_session_id,
                    'stock_id' => $line->stock_id,
                    'sku' => $line->stock?->sku,
                    'product_name' => $line->stock?->name,
                    'unit' => $line->unit ?? 'pièce',
                    'theoretical_qty' => (float) $line->theoretical_qty,
                    'counted_qty' => $line->counted_qty !== null ? (float) $line->counted_qty : null,
                    'created_at' => $line->created_at?->toIso8601String(),
                    'updated_at' => $line->updated_at?->toIso8601String(),
                ],
                'message' => 'Ligne mise à jour',
            ], 200, [], JSON_UNESCAPED_UNICODE);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur: ' . $e->getMessage(),
            ], 500);
        }
    }

    public function close(Request $request, int $id)
    {
        try {
            if (!$request->user()) {
                return response()->json(['success' => false, 'message' => 'Non authentifié'], 401);
            }

            $session = InventorySession::with('lines.stock')->find($id);
            if (!$session) {
                return response()->json(['success' => false, 'message' => 'Session non trouvée'], 404);
            }
            if ($session->isClosed()) {
                return response()->json(['success' => false, 'message' => 'Session déjà clôturée'], 400);
            }

            $userId = $request->user()->id;

            foreach ($session->lines as $line) {
                if ($line->counted_qty === null) {
                    continue;
                }
                $stock = $line->stock;
                if (!$stock) {
                    continue;
                }
                $counted = (float) $line->counted_qty;
                $current = (float) ($stock->current_quantity ?? $stock->quantity ?? 0);
                if ($counted === $current) {
                    continue;
                }
                if (method_exists($stock, 'adjustStock')) {
                    try {
                        $stock->adjustStock($counted, 'inventaire', 'Inventaire physique session #' . $session->id, $userId);
                    } catch (\Throwable $e) {
                        \Log::warning('Inventory close adjustStock: ' . $e->getMessage());
                        $this->updateStockQuantityDirect($stock, $counted);
                    }
                } else {
                    $this->updateStockQuantityDirect($stock, $counted);
                }
            }

            $session->status = InventorySession::STATUS_CLOSED;
            $session->closed_at = now();
            $session->save();

            return response()->json([
                'success' => true,
                'data' => [
                    'id' => $session->id,
                    'date' => $session->date?->format('Y-m-d'),
                    'depot' => $session->depot,
                    'status' => $session->status,
                    'closed_at' => $session->closed_at?->toIso8601String(),
                    'lines_count' => $session->lines()->count(),
                    'created_at' => $session->created_at?->toIso8601String(),
                    'updated_at' => $session->updated_at?->toIso8601String(),
                ],
                'message' => 'Inventaire clôturé',
            ], 200, [], JSON_UNESCAPED_UNICODE);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur: ' . $e->getMessage(),
            ], 500);
        }
    }

    private function updateStockQuantityDirect(Stock $stock, float $newQuantity): void
    {
        $stock->update(['current_quantity' => $newQuantity]);
    }
}

<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\Controller;
use App\Traits\CachesData;
use App\Traits\SendsNotifications;
use App\Models\EquipmentNew;
use App\Models\EquipmentCategory;
use App\Models\EquipmentMaintenance;
use App\Models\EquipmentAssignment;
use App\Http\Resources\EquipmentResource;
use App\Services\NotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class EquipmentController extends Controller
{
    use CachesData, SendsNotifications;

    protected $notificationService;

    public function __construct(NotificationService $notificationService)
    {
        $this->notificationService = $notificationService;
    }
    /**
     * Afficher la liste des équipements
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
            
            $query = EquipmentNew::with(['creator', 'updater', 'maintenance', 'assignments']);

            // Filtrage par statut
            if ($request->has('status')) {
                $query->where('status', $request->status);
            }

            // Filtrage par condition
            if ($request->has('condition')) {
                $query->where('condition', $request->condition);
            }

            // Filtrage par catégorie
            if ($request->has('category')) {
                $query->where('category', $request->category);
            }

            // Filtrage par localisation
            if ($request->has('location')) {
                $query->where('location', 'like', '%' . $request->location . '%');
            }

            // Filtrage par département
            if ($request->has('department')) {
                $query->where('department', $request->department);
            }

            // Filtrage par marque
            if ($request->has('brand')) {
                $query->where('brand', $request->brand);
            }

            // Filtrage par assignation
            if ($request->has('assigned_to')) {
                $query->where('assigned_to', 'like', '%' . $request->assigned_to . '%');
            }

            // Filtrage par date d'achat
            if ($request->has('purchase_date_from')) {
                $query->where('purchase_date', '>=', $request->purchase_date_from);
            }

            if ($request->has('purchase_date_to')) {
                $query->where('purchase_date', '<=', $request->purchase_date_to);
            }

            // Filtrage par garantie
            if ($request->has('warranty_expired')) {
                if ($request->warranty_expired === 'true') {
                    $query->warrantyExpired();
                } elseif ($request->warranty_expired === 'false') {
                    $query->where('warranty_expiry', '>', now());
                }
            }

            // Filtrage par maintenance
            if ($request->has('needs_maintenance')) {
                if ($request->needs_maintenance === 'true') {
                    $query->needsMaintenance();
                }
            }

            // Si technicien → filtre ses équipements assignés OU créés par lui
            if ($user->isTechnicien()) {
                $query->where(function($q) use ($user) {
                    $q->where('assigned_to', 'like', '%' . $user->prenom . ' ' . $user->nom . '%')
                      ->orWhere('created_by', $user->id);
                });
            }

            $perPage = min((int) $request->get('per_page', 20), 100);
            $equipment = $query->orderBy('name')->paginate($perPage);

            return response()->json([
                'success' => true,
                'data' => EquipmentResource::collection($equipment),
                'pagination' => [
                    'current_page' => $equipment->currentPage(),
                    'last_page' => $equipment->lastPage(),
                    'per_page' => $equipment->perPage(),
                    'total' => $equipment->total(),
                    'from' => $equipment->firstItem(),
                    'to' => $equipment->lastItem(),
                ],
                'message' => 'Liste des équipements récupérée avec succès',
            ], 200, [], JSON_UNESCAPED_UNICODE);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des équipements: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Afficher un équipement spécifique
     */
    public function show($id)
    {
        try {
            $equipment = EquipmentNew::with(['creator', 'updater', 'maintenance', 'assignments'])->find($id);

            if (!$equipment) {
                return response()->json([
                    'success' => false,
                    'message' => 'Équipement non trouvé'
                ], 404);
            }

            // Transformer les données pour correspondre au format de index()
            return response()->json([
                'success' => true,
                'data' => new EquipmentResource($equipment),
                'message' => 'Équipement récupéré avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération de l\'équipement: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Créer un nouvel équipement
     */
    public function store(Request $request)
    {
        try {
            $validated = $request->validate([
                'name' => 'required|string|max:255',
                'description' => 'required|string',
                'category' => 'required|string|max:255',
                'status' => 'required|in:active,inactive,maintenance,broken,retired',
                'condition' => 'required|in:excellent,good,fair,poor,critical',
                'serial_number' => 'nullable|string|max:255',
                'model' => 'nullable|string|max:255',
                'brand' => 'nullable|string|max:255',
                'location' => 'nullable|string|max:255',
                'department' => 'nullable|string|max:255',
                'assigned_to' => 'nullable|string|max:255',
                'purchase_date' => 'nullable|date',
                'warranty_expiry' => 'nullable|date',
                'last_maintenance' => 'nullable|date',
                'next_maintenance' => 'nullable|date',
                'purchase_price' => 'nullable|numeric|min:0',
                'current_value' => 'nullable|numeric|min:0',
                'supplier' => 'nullable|string|max:255',
                'notes' => 'nullable|string',
                'attachments' => 'nullable|array'
            ]);

            DB::beginTransaction();

            $equipment = EquipmentNew::create([
                'name' => $validated['name'],
                'description' => $validated['description'],
                'category' => $validated['category'],
                'status' => $validated['status'],
                'condition' => $validated['condition'],
                'serial_number' => $validated['serial_number'] ?? null,
                'model' => $validated['model'] ?? null,
                'brand' => $validated['brand'] ?? null,
                'location' => $validated['location'] ?? null,
                'department' => $validated['department'] ?? null,
                'assigned_to' => $validated['assigned_to'] ?? null,
                'purchase_date' => $validated['purchase_date'] ?? null,
                'warranty_expiry' => $validated['warranty_expiry'] ?? null,
                'last_maintenance' => $validated['last_maintenance'] ?? null,
                'next_maintenance' => $validated['next_maintenance'] ?? null,
                'purchase_price' => $validated['purchase_price'] ?? null,
                'current_value' => $validated['current_value'] ?? null,
                'supplier' => $validated['supplier'] ?? null,
                'notes' => $validated['notes'] ?? null,
                'attachments' => $validated['attachments'] ?? null,
                'created_by' => $request->user()->id
            ]);

            DB::commit();

            $equipment->load(['creator', 'updater', 'maintenance', 'assignments']);

            // Notifier le patron pour validation
            $this->safeNotify(function () use ($equipment) {
                $this->notificationService->notifyNewEquipement($equipment);
            });

            return response()->json([
                'success' => true,
                'data' => new EquipmentResource($equipment),
                'message' => 'Équipement créé avec succès'
            ], 201);

        } catch (\Exception $e) {
            DB::rollback();
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la création de l\'équipement: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Mettre à jour un équipement
     */
    public function update(Request $request, $id)
    {
        try {
            $equipment = EquipmentNew::find($id);

            if (!$equipment) {
                return response()->json([
                    'success' => false,
                    'message' => 'Équipement non trouvé'
                ], 404);
            }

            $validated = $request->validate([
                'name' => 'sometimes|string|max:255',
                'description' => 'sometimes|string',
                'category' => 'sometimes|string|max:255',
                'status' => 'sometimes|in:active,inactive,maintenance,broken,retired',
                'condition' => 'sometimes|in:excellent,good,fair,poor,critical',
                'serial_number' => 'nullable|string|max:255',
                'model' => 'nullable|string|max:255',
                'brand' => 'nullable|string|max:255',
                'location' => 'nullable|string|max:255',
                'department' => 'nullable|string|max:255',
                'assigned_to' => 'nullable|string|max:255',
                'purchase_date' => 'nullable|date',
                'warranty_expiry' => 'nullable|date',
                'last_maintenance' => 'nullable|date',
                'next_maintenance' => 'nullable|date',
                'purchase_price' => 'nullable|numeric|min:0',
                'current_value' => 'nullable|numeric|min:0',
                'supplier' => 'nullable|string|max:255',
                'notes' => 'nullable|string',
                'attachments' => 'nullable|array'
            ]);

            $equipment->update(array_merge($validated, [
                'updated_by' => $request->user()->id
            ]));

            $equipment->load(['creator', 'updater', 'maintenance', 'assignments']);

            return response()->json([
                'success' => true,
                'data' => new EquipmentResource($equipment),
                'message' => 'Équipement mis à jour avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la mise à jour de l\'équipement: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Supprimer un équipement
     */
    public function destroy($id)
    {
        try {
            $equipment = EquipmentNew::find($id);

            if (!$equipment) {
                return response()->json([
                    'success' => false,
                    'message' => 'Équipement non trouvé'
                ], 404);
            }

            $equipment->delete();

            return response()->json([
                'success' => true,
                'message' => 'Équipement supprimé avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la suppression de l\'équipement: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Assigner un équipement
     */
    public function assign(Request $request, $id)
    {
        try {
            $equipment = EquipmentNew::find($id);

            if (!$equipment) {
                return response()->json([
                    'success' => false,
                    'message' => 'Équipement non trouvé'
                ], 404);
            }

            $validated = $request->validate([
                'user_id' => 'required|exists:users,id',
                'notes' => 'nullable|string|max:1000'
            ]);

            $equipment->assignTo($validated['user_id'], $request->user()->id, $validated['notes']);

            return response()->json([
                'success' => true,
                'message' => 'Équipement assigné avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'assignation: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Retourner un équipement
     */
    public function return(Request $request, $id)
    {
        try {
            $equipment = EquipmentNew::find($id);

            if (!$equipment) {
                return response()->json([
                    'success' => false,
                    'message' => 'Équipement non trouvé'
                ], 404);
            }

            $validated = $request->validate([
                'notes' => 'nullable|string|max:1000'
            ]);

            $equipment->returnFrom($request->user()->id, $validated['notes']);

            return response()->json([
                'success' => true,
                'message' => 'Équipement retourné avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors du retour: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Programmer une maintenance
     */
    public function scheduleMaintenance(Request $request, $id)
    {
        try {
            $equipment = EquipmentNew::find($id);

            if (!$equipment) {
                return response()->json([
                    'success' => false,
                    'message' => 'Équipement non trouvé'
                ], 404);
            }

            $validated = $request->validate([
                'type' => 'required|in:preventive,corrective,emergency',
                'description' => 'required|string|max:1000',
                'scheduled_date' => 'required|date|after:now',
                'technician' => 'nullable|string|max:255'
            ]);

            $maintenance = $equipment->scheduleMaintenance(
                $validated['type'],
                $validated['description'],
                $validated['scheduled_date'],
                $validated['technician'],
                $request->user()->id
            );

            return response()->json([
                'success' => true,
                'data' => $maintenance,
                'message' => 'Maintenance programmée avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la programmation: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Statistiques des équipements
     */
    public function statistics(Request $request)
    {
        try {
            $dateKey = \Carbon\Carbon::now()->format('Y-m-d');
            $stats = $this->rememberDailyStats('equipment_stats', $dateKey, function () {
                return EquipmentNew::getEquipmentStats();
            });

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
     * Récupérer les catégories d'équipements
     */
    public function categories()
    {
        try {
            $categories = EquipmentCategory::getActiveCategories();

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
     * Récupérer les équipements nécessitant une maintenance
     */
    public function needsMaintenance()
    {
        try {
            $equipment = EquipmentNew::getEquipmentNeedingMaintenance();

            return response()->json([
                'success' => true,
                'data' => $equipment,
                'message' => 'Équipements nécessitant une maintenance récupérés avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des équipements nécessitant une maintenance: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les équipements avec garantie expirée
     */
    public function warrantyExpired()
    {
        try {
            $equipment = EquipmentNew::getEquipmentWithExpiredWarranty();

            return response()->json([
                'success' => true,
                'data' => $equipment,
                'message' => 'Équipements avec garantie expirée récupérés avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des équipements avec garantie expirée: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Récupérer les équipements avec garantie expirant bientôt
     */
    public function warrantyExpiringSoon()
    {
        try {
            $equipment = EquipmentNew::getEquipmentWithExpiringWarranty();

            return response()->json([
                'success' => true,
                'data' => $equipment,
                'message' => 'Équipements avec garantie expirant bientôt récupérés avec succès'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des équipements avec garantie expirant bientôt: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Transformer un équipement en tableau avec dates au format ISO8601
     */
    private function transformEquipment($item)
    {
        return [
            'id' => $item->id,
            'name' => $item->name,
            'description' => $item->description,
            'category' => $item->category,
            'status' => $item->status,
            'status_libelle' => $item->status_libelle,
            'condition' => $item->condition,
            'condition_libelle' => $item->condition_libelle,
            'serial_number' => $item->serial_number,
            'model' => $item->model,
            'brand' => $item->brand,
            'location' => $item->location,
            'department' => $item->department,
            'assigned_to' => $item->assigned_to,
            'purchase_date' => $item->purchase_date?->toIso8601String(),
            'warranty_expiry' => $item->warranty_expiry?->toIso8601String(),
            'last_maintenance' => $item->last_maintenance?->toIso8601String(),
            'next_maintenance' => $item->next_maintenance?->toIso8601String(),
            'purchase_price' => $item->purchase_price,
            'current_value' => $item->current_value,
            'formatted_purchase_price' => $item->formatted_purchase_price,
            'formatted_current_value' => $item->formatted_current_value,
            'supplier' => $item->supplier,
            'notes' => $item->notes,
            'attachments' => $item->attachments,
            'created_by' => $item->created_by,
            'creator_name' => $item->creator_name,
            'updated_by' => $item->updated_by,
            'updater_name' => $item->updater_name,
            'is_warranty_expired' => $item->is_warranty_expired,
            'is_warranty_expiring_soon' => $item->is_warranty_expiring_soon,
            'needs_maintenance' => $item->needs_maintenance,
            'age_in_years' => $item->age_in_years,
            'depreciation_rate' => $item->depreciation_rate,
            'maintenance' => $item->maintenance->map(function ($maintenance) {
                return [
                    'id' => $maintenance->id,
                    'type' => $maintenance->type,
                    'type_libelle' => $maintenance->type_libelle,
                    'status' => $maintenance->status,
                    'status_libelle' => $maintenance->status_libelle,
                    'description' => $maintenance->description,
                    'scheduled_date' => $maintenance->scheduled_date->toIso8601String(),
                    'start_date' => $maintenance->start_date?->toIso8601String(),
                    'end_date' => $maintenance->end_date?->toIso8601String(),
                    'technician' => $maintenance->technician,
                    'cost' => $maintenance->cost,
                    'formatted_cost' => $maintenance->formatted_cost,
                    'duration' => $maintenance->duration,
                    'is_overdue' => $maintenance->is_overdue,
                    'created_at' => $maintenance->created_at->toIso8601String()
                ];
            }),
            'assignments' => $item->assignments->map(function ($assignment) {
                return [
                    'id' => $assignment->id,
                    'user_id' => $assignment->user_id,
                    'user_name' => $assignment->user_name,
                    'assigned_date' => $assignment->assigned_date->toIso8601String(),
                    'return_date' => $assignment->return_date?->toIso8601String(),
                    'status' => $assignment->status,
                    'status_libelle' => $assignment->status_libelle,
                    'duration' => $assignment->duration,
                    'is_active' => $assignment->is_active,
                    'assigned_by' => $assignment->assigned_by,
                    'assigned_by_name' => $assignment->assigned_by_name,
                    'returned_by' => $assignment->returned_by,
                    'returned_by_name' => $assignment->returned_by_name,
                    'created_at' => $assignment->created_at->toIso8601String()
                ];
            }),
            'created_at' => $item->created_at->toIso8601String(),
            'updated_at' => $item->updated_at->toIso8601String()
        ];
    }
}
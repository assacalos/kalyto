<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Support\Facades\Route;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class RoleAuthorizationTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Route::middleware(['auth:sanctum', 'role:1,6'])
            ->get('/api/__authz/admin-or-patron', fn () => response()->json(['ok' => true]));

        Route::middleware(['auth:sanctum', 'role:1,5,6'])
            ->get('/api/__authz/admin-tech-patron', fn () => response()->json(['ok' => true]));

        Route::middleware(['auth:sanctum', 'role:5'])
            ->get('/api/__authz/technician-only', fn () => response()->json(['ok' => true]));

        // Matrices alignées sur routes/api.php (groupes critiques)
        Route::middleware(['auth:sanctum', 'role:1,2,3,6'])
            ->post('/api/__authz/devis-create', fn () => response()->json(['ok' => true]));

        Route::middleware(['auth:sanctum', 'role:1,3,6'])
            ->post('/api/__authz/factures-create', fn () => response()->json(['ok' => true]));

        Route::middleware(['auth:sanctum', 'role:1,6'])
            ->get('/api/__authz/users-pending-registrations', fn () => response()->json(['ok' => true]));

        // Endpoints de validation/rejet (sensibles patron/admin)
        Route::middleware(['auth:sanctum', 'role:1,6'])
            ->post('/api/__authz/devis-validate/1', fn () => response()->json(['ok' => true]));
        Route::middleware(['auth:sanctum', 'role:1,6'])
            ->post('/api/__authz/devis-reject/1', fn () => response()->json(['ok' => true]));

        Route::middleware(['auth:sanctum', 'role:1,6'])
            ->post('/api/__authz/factures-validate/1', fn () => response()->json(['ok' => true]));
        Route::middleware(['auth:sanctum', 'role:1,6'])
            ->post('/api/__authz/factures-reject/1', fn () => response()->json(['ok' => true]));

        Route::middleware(['auth:sanctum', 'role:1,6'])
            ->post('/api/__authz/clients-validate/1', fn () => response()->json(['ok' => true]));
        Route::middleware(['auth:sanctum', 'role:1,6'])
            ->post('/api/__authz/clients-reject/1', fn () => response()->json(['ok' => true]));
    }

    private function actingAsRole(int $role): void
    {
        $user = new User([
            'nom' => 'Test',
            'prenom' => 'User',
            'email' => "role{$role}@kalyto.test",
            'role' => $role,
            'is_active' => true,
        ]);

        Sanctum::actingAs($user);
    }

    public function test_unauthenticated_request_is_rejected(): void
    {
        $response = $this->getJson('/api/__authz/admin-or-patron');

        $response->assertStatus(401);
    }

    public function test_admin_and_patron_can_access_admin_or_patron_route(): void
    {
        $this->actingAsRole(1);
        $this->getJson('/api/__authz/admin-or-patron')->assertOk();

        $this->actingAsRole(6);
        $this->getJson('/api/__authz/admin-or-patron')->assertOk();
    }

    public function test_commercial_cannot_access_admin_or_patron_route(): void
    {
        $this->actingAsRole(2);

        $response = $this->getJson('/api/__authz/admin-or-patron');

        $response->assertStatus(403);
    }

    public function test_technician_can_access_technician_group_route(): void
    {
        $this->actingAsRole(5);

        $this->getJson('/api/__authz/admin-tech-patron')->assertOk();
        $this->getJson('/api/__authz/technician-only')->assertOk();
    }

    public function test_admin_cannot_bypass_technician_only_route(): void
    {
        $this->actingAsRole(1);

        $response = $this->getJson('/api/__authz/technician-only');

        $response->assertStatus(403);
    }

    public function test_devis_create_allows_expected_roles_only(): void
    {
        foreach ([1, 2, 3, 6] as $allowedRole) {
            $this->actingAsRole($allowedRole);
            $this->postJson('/api/__authz/devis-create')->assertOk();
        }

        foreach ([4, 5] as $forbiddenRole) {
            $this->actingAsRole($forbiddenRole);
            $this->postJson('/api/__authz/devis-create')->assertStatus(403);
        }
    }

    public function test_factures_create_blocks_commercial_and_technician(): void
    {
        foreach ([1, 3, 6] as $allowedRole) {
            $this->actingAsRole($allowedRole);
            $this->postJson('/api/__authz/factures-create')->assertOk();
        }

        foreach ([2, 4, 5] as $forbiddenRole) {
            $this->actingAsRole($forbiddenRole);
            $this->postJson('/api/__authz/factures-create')->assertStatus(403);
        }
    }

    public function test_pending_registrations_is_restricted_to_admin_and_patron(): void
    {
        foreach ([1, 6] as $allowedRole) {
            $this->actingAsRole($allowedRole);
            $this->getJson('/api/__authz/users-pending-registrations')->assertOk();
        }

        foreach ([2, 3, 4, 5] as $forbiddenRole) {
            $this->actingAsRole($forbiddenRole);
            $this->getJson('/api/__authz/users-pending-registrations')->assertStatus(403);
        }
    }

    public function test_devis_validation_and_rejection_are_restricted_to_admin_and_patron(): void
    {
        foreach ([1, 6] as $allowedRole) {
            $this->actingAsRole($allowedRole);
            $this->postJson('/api/__authz/devis-validate/1')->assertOk();
            $this->postJson('/api/__authz/devis-reject/1')->assertOk();
        }

        foreach ([2, 3, 4, 5] as $forbiddenRole) {
            $this->actingAsRole($forbiddenRole);
            $this->postJson('/api/__authz/devis-validate/1')->assertStatus(403);
            $this->postJson('/api/__authz/devis-reject/1')->assertStatus(403);
        }
    }

    public function test_facture_validation_and_rejection_are_restricted_to_admin_and_patron(): void
    {
        foreach ([1, 6] as $allowedRole) {
            $this->actingAsRole($allowedRole);
            $this->postJson('/api/__authz/factures-validate/1')->assertOk();
            $this->postJson('/api/__authz/factures-reject/1')->assertOk();
        }

        foreach ([2, 3, 4, 5] as $forbiddenRole) {
            $this->actingAsRole($forbiddenRole);
            $this->postJson('/api/__authz/factures-validate/1')->assertStatus(403);
            $this->postJson('/api/__authz/factures-reject/1')->assertStatus(403);
        }
    }

    public function test_client_validation_and_rejection_are_restricted_to_admin_and_patron(): void
    {
        foreach ([1, 6] as $allowedRole) {
            $this->actingAsRole($allowedRole);
            $this->postJson('/api/__authz/clients-validate/1')->assertOk();
            $this->postJson('/api/__authz/clients-reject/1')->assertOk();
        }

        foreach ([2, 3, 4, 5] as $forbiddenRole) {
            $this->actingAsRole($forbiddenRole);
            $this->postJson('/api/__authz/clients-validate/1')->assertStatus(403);
            $this->postJson('/api/__authz/clients-reject/1')->assertStatus(403);
        }
    }
}


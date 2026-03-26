<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Support\Facades\Route;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class RolePermissionMatrixTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        // Groupes alignés sur routes/api.php
        Route::middleware(['auth:sanctum', 'role:1,2,3,6'])
            ->post('/api/__matrix/devis-create', fn () => response()->json(['ok' => true]));

        Route::middleware(['auth:sanctum', 'role:1,3,6'])
            ->post('/api/__matrix/factures-create', fn () => response()->json(['ok' => true]));

        Route::middleware(['auth:sanctum', 'role:1,6'])
            ->post('/api/__matrix/tasks-create', fn () => response()->json(['ok' => true]));

        Route::middleware(['auth:sanctum', 'role:1,2,3,4,5,6'])
            ->put('/api/__matrix/tasks-update/1', fn () => response()->json(['ok' => true]));

        Route::middleware(['auth:sanctum', 'role:1,5,6'])
            ->post('/api/__matrix/interventions-create', fn () => response()->json(['ok' => true]));
    }

    private function actingAsRole(int $role): void
    {
        Sanctum::actingAs(new User([
            'nom' => 'Matrix',
            'prenom' => 'User',
            'email' => "matrix-role{$role}@kalyto.test",
            'role' => $role,
            'is_active' => true,
        ]));
    }

    private function assertRolesOnEndpoint(
        string $method,
        string $uri,
        array $allowed,
        array $forbidden
    ): void {
        foreach ($allowed as $role) {
            $this->actingAsRole($role);
            $this->json($method, $uri)->assertOk();
        }

        foreach ($forbidden as $role) {
            $this->actingAsRole($role);
            $this->json($method, $uri)->assertStatus(403);
        }
    }

    public function test_devis_create_role_matrix(): void
    {
        $this->assertRolesOnEndpoint(
            'POST',
            '/api/__matrix/devis-create',
            [1, 2, 3, 6],
            [4, 5]
        );
    }

    public function test_factures_create_role_matrix(): void
    {
        $this->assertRolesOnEndpoint(
            'POST',
            '/api/__matrix/factures-create',
            [1, 3, 6],
            [2, 4, 5]
        );
    }

    public function test_tasks_create_role_matrix(): void
    {
        $this->assertRolesOnEndpoint(
            'POST',
            '/api/__matrix/tasks-create',
            [1, 6],
            [2, 3, 4, 5]
        );
    }

    public function test_tasks_update_is_open_to_authenticated_roles(): void
    {
        foreach ([1, 2, 3, 4, 5, 6] as $role) {
            $this->actingAsRole($role);
            $this->putJson('/api/__matrix/tasks-update/1')->assertOk();
        }
    }

    public function test_interventions_create_role_matrix(): void
    {
        $this->assertRolesOnEndpoint(
            'POST',
            '/api/__matrix/interventions-create',
            [1, 5, 6],
            [2, 3, 4]
        );
    }
}


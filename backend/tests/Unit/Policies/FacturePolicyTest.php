<?php

namespace Tests\Unit\Policies;

use App\Models\Facture;
use App\Models\User;
use App\Policies\FacturePolicy;
use Tests\TestCase;

class FacturePolicyTest extends TestCase
{
    private function user(int $id, int $role, ?int $companyId): User
    {
        $user = new User([
            'nom' => 'U',
            'prenom' => 'T',
            'email' => "u{$id}-r{$role}@kalyto.test",
            'role' => $role,
            'company_id' => $companyId,
            'is_active' => true,
        ]);

        // id non fillable sur le modèle, on force l'attribut pour les tests de policy.
        $user->setAttribute('id', $id);

        return $user;
    }

    private function facture(int $ownerId, ?int $companyId, string $status = 'en_attente'): Facture
    {
        return new Facture([
            'user_id' => $ownerId,
            'company_id' => $companyId,
            'status' => $status,
        ]);
    }

    public function test_commercial_can_view_only_his_own_facture_in_same_company(): void
    {
        $policy = new FacturePolicy();
        $commercial = $this->user(10, 2, 100);

        $ownFacture = $this->facture(10, 100);
        $otherFacture = $this->facture(11, 100);

        $this->assertTrue($policy->view($commercial, $ownFacture));
        $this->assertFalse($policy->view($commercial, $otherFacture));
    }

    public function test_comptable_can_view_same_company_facture(): void
    {
        $policy = new FacturePolicy();
        $comptable = $this->user(20, 3, 100);
        $facture = $this->facture(30, 100);

        $this->assertTrue($policy->view($comptable, $facture));
    }

    public function test_rh_and_technician_cannot_view_facture_even_in_same_company(): void
    {
        $policy = new FacturePolicy();
        $rh = $this->user(40, 4, 100);
        $technician = $this->user(50, 5, 100);
        $facture = $this->facture(30, 100);

        $this->assertFalse($policy->view($rh, $facture));
        $this->assertFalse($policy->view($technician, $facture));
    }

    public function test_admin_can_view_cross_company_facture(): void
    {
        $policy = new FacturePolicy();
        $admin = $this->user(1, 1, null);
        $facture = $this->facture(30, 999);

        $this->assertTrue($policy->view($admin, $facture));
    }
}


<?php

namespace Tests\Unit\Policies;

use App\Models\Devis;
use App\Models\User;
use App\Policies\DevisPolicy;
use Tests\TestCase;

class DevisPolicyTest extends TestCase
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

    private function devis(int $ownerId, ?int $companyId, int $status = 0): Devis
    {
        return new Devis([
            'user_id' => $ownerId,
            'company_id' => $companyId,
            'status' => $status,
        ]);
    }

    public function test_commercial_access_is_limited_to_own_devis(): void
    {
        $policy = new DevisPolicy();
        $commercial = $this->user(10, 2, 100);

        $ownDevis = $this->devis(10, 100, 0);
        $otherDevis = $this->devis(11, 100, 0);

        $this->assertTrue($policy->view($commercial, $ownDevis));
        $this->assertFalse($policy->view($commercial, $otherDevis));
    }

    public function test_delete_requires_draft_status_even_for_admin(): void
    {
        $policy = new DevisPolicy();
        $admin = $this->user(1, 1, null);
        $notDraft = $this->devis(10, 100, 1);

        $this->assertFalse($policy->delete($admin, $notDraft));
    }

    public function test_validate_is_restricted_to_admin_or_patron_same_company(): void
    {
        $policy = new DevisPolicy();

        $patronSameCompany = $this->user(60, 6, 100);
        $patronOtherCompany = $this->user(61, 6, 200);
        $devis = $this->devis(10, 100, 0);

        $this->assertTrue($policy->validate($patronSameCompany, $devis));
        $this->assertFalse($policy->validate($patronOtherCompany, $devis));
    }
}


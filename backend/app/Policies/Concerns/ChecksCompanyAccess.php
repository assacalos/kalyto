<?php

namespace App\Policies\Concerns;

use App\Models\User;

trait ChecksCompanyAccess
{
    /**
     * Accès au modèle selon la société (admin : contrôlé par le scope requête dans le contrôleur).
     */
    protected function sameCompany(?User $user, object $model): bool
    {
        if (! $user) {
            return false;
        }
        if ($user->isAdmin()) {
            return true;
        }

        $modelCompanyId = $model->company_id ?? null;
        $userCompanyId = $user->company_id;

        if ($userCompanyId === null && $modelCompanyId === null) {
            return true;
        }

        return $userCompanyId !== null && $modelCompanyId !== null
            && (int) $modelCompanyId === (int) $userCompanyId;
    }
}

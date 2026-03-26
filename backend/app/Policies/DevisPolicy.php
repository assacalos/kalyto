<?php

namespace App\Policies;

use App\Models\Devis;
use App\Models\User;
use App\Policies\Concerns\ChecksCompanyAccess;

class DevisPolicy
{
    use ChecksCompanyAccess;

    /**
     * Liste / index : pas les rôles sans accès métier aux devis.
     */
    public function viewAny(User $user): bool
    {
        return $user->isAdmin()
            || $user->isCommercial()
            || $user->isComptable()
            || $user->isPatron();
    }

    public function view(User $user, Devis $devis): bool
    {
        if (! $this->sameCompany($user, $devis)) {
            return false;
        }
        if ($user->isCommercial()) {
            return (int) $devis->user_id === (int) $user->id;
        }

        return $user->isAdmin()
            || $user->isComptable()
            || $user->isPatron();
    }

    public function create(User $user): bool
    {
        return $user->isAdmin()
            || $user->isCommercial()
            || $user->isComptable()
            || $user->isPatron();
    }

    public function update(User $user, Devis $devis): bool
    {
        return $this->view($user, $devis);
    }

    /**
     * Brouillon uniquement (statut 0) — le contrôleur doit aussi vérifier.
     */
    public function delete(User $user, Devis $devis): bool
    {
        if ((int) $devis->status !== 0) {
            return false;
        }

        if (! $this->sameCompany($user, $devis)) {
            return false;
        }

        if ($user->isCommercial()) {
            return (int) $devis->user_id === (int) $user->id;
        }

        return $user->isAdmin()
            || $user->isComptable()
            || $user->isPatron();
    }

    /** Validation / acceptation par patron ou admin */
    public function validate(User $user, Devis $devis): bool
    {
        return $this->sameCompany($user, $devis)
            && ($user->isAdmin() || $user->isPatron());
    }

    public function reject(User $user, Devis $devis): bool
    {
        return $this->validate($user, $devis);
    }
}

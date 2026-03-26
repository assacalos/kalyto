<?php

namespace App\Policies;

use App\Models\Facture;
use App\Models\User;
use App\Policies\Concerns\ChecksCompanyAccess;

class FacturePolicy
{
    use ChecksCompanyAccess;

    /**
     * Liste / index : rôles avec accès aux factures (données financières sensibles).
     * Aligné sur l’usage métier : pas d’accès liste pour RH / technicien via l’API.
     */
    public function viewAny(User $user): bool
    {
        return $user->isAdmin()
            || $user->isCommercial()
            || $user->isComptable()
            || $user->isPatron();
    }

    public function view(User $user, Facture $facture): bool
    {
        if (! $this->sameCompany($user, $facture)) {
            return false;
        }
        if ($user->isCommercial()) {
            return (int) $facture->user_id === (int) $user->id;
        }

        return true;
    }

    /** Création : comptable, admin, patron (aligné routes role 1,3,6). */
    public function create(User $user): bool
    {
        return $user->isAdmin()
            || $user->isComptable()
            || $user->isPatron();
    }

    public function update(User $user, Facture $facture): bool
    {
        if (! $this->sameCompany($user, $facture)) {
            return false;
        }

        return $user->isAdmin()
            || $user->isComptable()
            || $user->isPatron();
    }

    public function markAsPaid(User $user, Facture $facture): bool
    {
        return $this->update($user, $facture);
    }

    /** Validation / rejet : patron ou admin */
    public function validate(User $user, Facture $facture): bool
    {
        return $this->sameCompany($user, $facture)
            && ($user->isAdmin() || $user->isPatron());
    }

    public function reject(User $user, Facture $facture): bool
    {
        return $this->validate($user, $facture);
    }

    public function cancelRejection(User $user, Facture $facture): bool
    {
        return $this->validate($user, $facture);
    }

    public function viewValidationHistory(User $user, Facture $facture): bool
    {
        return $this->view($user, $facture);
    }

    /** Rapports financiers : comptable, admin, patron */
    public function viewReports(User $user): bool
    {
        return $user->isAdmin()
            || $user->isComptable()
            || $user->isPatron();
    }

    /** Suppression si non payée (règle métier dans le contrôleur). */
    public function delete(User $user, Facture $facture): bool
    {
        if ($facture->status === 'payee') {
            return false;
        }

        return $this->update($user, $facture);
    }
}

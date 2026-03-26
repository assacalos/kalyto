<?php

namespace App\Traits;

use Illuminate\Http\Request;

trait ScopesByCompany
{
    /**
     * Retourne le company_id depuis la requête (query ou body).
     * Utilisé côté frontend pour le sélecteur (admin uniquement).
     */
    protected function requestCompanyId(Request $request): ?int
    {
        $id = $request->query('company_id') ?? $request->input('company_id');
        if ($id === null) {
            return null;
        }
        return is_numeric($id) ? (int) $id : null;
    }

    /**
     * Company_id effectif pour le scope : admin = celui de la requête, autres = société de l'utilisateur.
     * Garantit que les non-admin ne voient que les données de leur société.
     */
    protected function effectiveCompanyId(Request $request): ?int
    {
        $user = $request->user();
        if (!$user) {
            return null;
        }
        if ($user->isAdmin()) {
            return $this->requestCompanyId($request);
        }
        return $user->company_id ? (int) $user->company_id : null;
    }

    /**
     * Applique le scope company_id sur un query builder.
     * Admin : utilise le company_id de la requête ; autres rôles : société de l'utilisateur.
     *
     * @param \Illuminate\Database\Eloquent\Builder $query
     * @param Request $request
     * @param string $column nom de la colonne (défaut 'company_id')
     */
    protected function scopeByCompany($query, Request $request, string $column = 'company_id'): void
    {
        $companyId = $this->effectiveCompanyId($request);
        if ($companyId !== null) {
            $query->where($column, $companyId);
        }
    }
}

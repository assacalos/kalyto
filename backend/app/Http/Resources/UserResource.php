<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $roleName = method_exists($this->resource, 'getRoleName') ? $this->resource->getRoleName() : 'Utilisateur';
        $roleSlug = method_exists($this->resource, 'appRole')
            ? $this->resource->appRole()?->slug()
            : null;

        return [
            'id' => $this->id,
            'nom' => $this->nom ?? '',
            'prenom' => $this->prenom ?? '',
            'email' => $this->email,
            'avatar' => $this->avatar ? asset('storage/' . $this->avatar) : null,
            'role' => $this->role,
            'role_name' => $roleName,
            'role_slug' => $roleSlug,
            'company_id' => $this->company_id,
            'created_at' => $this->created_at?->format('Y-m-d H:i:s'),
            'updated_at' => $this->updated_at?->format('Y-m-d H:i:s'),
        ];
    }
}

<?php

namespace App\Models;

use App\Enums\AppRole;
// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'nom',
        'prenom',
        'email',
        'password',
        'avatar',
        'role',
        'company_id',
        'is_active',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array<int, string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'email_verified_at' => 'datetime',
        'is_active' => 'boolean',
    ];

    /**
     * Vérifier si l'utilisateur est admin
     */
    public function isAdmin()
    {
        return $this->hasAppRole(AppRole::Admin);
    }

    /**
     * Vérifier si l'utilisateur est commercial
     */
    public function isCommercial()
    {
        return $this->hasAppRole(AppRole::Commercial);
    }

    /**
     * Vérifier si l'utilisateur est comptable
     */
    public function isComptable()
    {
        return $this->hasAppRole(AppRole::Comptable);
    }

    /**
     * Vérifier si l'utilisateur est RH
     */
    public function isRH()
    {
        return $this->hasAppRole(AppRole::RH);
    }

    /**
     * Vérifier si l'utilisateur est technicien
     */
    public function isTechnicien()
    {
        return $this->hasAppRole(AppRole::Technicien);
    }

    /**
     * Vérifier si l'utilisateur est patron
     */
    public function isPatron()
    {
        return $this->hasAppRole(AppRole::Patron);
    }

    /**
     * Rôle métier typé (null si valeur inconnue en base).
     */
    public function appRole(): ?AppRole
    {
        return AppRole::tryFromId($this->role);
    }

    public function hasAppRole(AppRole $role): bool
    {
        return (int) $this->role === $role->value;
    }

    /** Admin ou patron (routes souvent groupées `role:1,6`). */
    public function isAdminOrPatron(): bool
    {
        return $this->isAdmin() || $this->isPatron();
    }

    /**
     * Obtenir le nom du rôle (avec cache)
     */
    public function getRoleName()
    {
        return \Illuminate\Support\Facades\Cache::remember("role_name:{$this->role}", 86400, function () {
            $roles = [
                1 => 'Admin',
                2 => 'Commercial',
                3 => 'Comptable',
                4 => 'RH',
                5 => 'Technicien',
                6 => 'Patron'
            ];

            return $roles[$this->role] ?? 'Inconnu';
        });
    }

    /**
     * Société à laquelle l'utilisateur est rattaché (null = admin ou non assigné).
     */
    public function company()
    {
        return $this->belongsTo(Company::class);
    }

    /**
     * Tâches assignées à cet utilisateur
     */
    public function assignedTasks()
    {
        return $this->hasMany(Task::class, 'assigned_to');
    }

    /**
     * Tâches créées par cet utilisateur (patron/admin)
     */
    public function createdTasks()
    {
        return $this->hasMany(Task::class, 'assigned_by');
    }

    /**
     * Relation avec les tokens d'appareil
     */
    public function deviceTokens()
    {
        return $this->hasMany(DeviceToken::class);
    }

    /**
     * Obtenir les tokens actifs de l'utilisateur
     */
    public function activeDeviceTokens()
    {
        return $this->deviceTokens()->where('is_active', true);
    }
}

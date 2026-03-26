<?php

namespace App\Enums;

/**
 * Rôles métier alignés sur la colonne users.role (1–6).
 *
 * Utiliser cet enum dans les nouveaux développements à la place des entiers bruts.
 * La migration vers spatie/laravel-permission pourra réutiliser les slugs {@see slug()}.
 */
enum AppRole: int
{
    case Admin = 1;
    case Commercial = 2;
    case Comptable = 3;
    case RH = 4;
    case Technicien = 5;
    case Patron = 6;

    public function label(): string
    {
        return match ($this) {
            self::Admin => 'Administrateur',
            self::Commercial => 'Commercial',
            self::Comptable => 'Comptable',
            self::RH => 'Ressources humaines',
            self::Technicien => 'Technicien',
            self::Patron => 'Patron',
        };
    }

    /**
     * Identifiant stable pour API / Spatie / clés de config.
     */
    public function slug(): string
    {
        return match ($this) {
            self::Admin => 'admin',
            self::Commercial => 'commercial',
            self::Comptable => 'comptable',
            self::RH => 'rh',
            self::Technicien => 'technicien',
            self::Patron => 'patron',
        };
    }

    public static function tryFromId(int|string|null $id): ?self
    {
        if ($id === null || $id === '') {
            return null;
        }
        $n = is_numeric($id) ? (int) $id : 0;

        return self::tryFrom($n);
    }
}

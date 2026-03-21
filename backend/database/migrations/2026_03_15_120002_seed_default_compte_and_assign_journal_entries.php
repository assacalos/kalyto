<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Créer le compte 51 - Caisse et affecter les écritures existantes à ce compte.
     */
    public function up(): void
    {
        $now = now();
        $comptes = [
            ['code' => '51', 'libelle' => 'Caisse', 'type' => 'actif'],
            ['code' => '411', 'libelle' => 'Clients', 'type' => 'actif'],
            ['code' => '401', 'libelle' => 'Fournisseurs', 'type' => 'passif'],
            ['code' => '6', 'libelle' => 'Charges', 'type' => 'charge'],
            ['code' => '7', 'libelle' => 'Produits', 'type' => 'produit'],
        ];
        $id51 = null;
        foreach ($comptes as $c) {
            $id = DB::table('comptes')->insertGetId([
                'code' => $c['code'],
                'libelle' => $c['libelle'],
                'type' => $c['type'],
                'actif' => true,
                'created_at' => $now,
                'updated_at' => $now,
            ]);
            if ($c['code'] === '51') {
                $id51 = $id;
            }
        }
        if ($id51 !== null) {
            DB::table('journal_entries')->whereNull('compte_id')->update(['compte_id' => $id51]);
        }
    }

    public function down(): void
    {
        DB::table('journal_entries')->update(['compte_id' => null]);
        DB::table('comptes')->whereIn('code', ['51', '411', '401', '6', '7'])->delete();
    }
};

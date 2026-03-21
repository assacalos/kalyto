<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     * Ordre: société → utilisateurs (rôles) → clients → devis → bordereaux → factures → paiements.
     */
    public function run(): void
    {
        $this->call([
            CompanySeeder::class,
            AdminSeeder::class,
            UsersDemoSeeder::class,
            ClientSeeder::class,
            DevisSeeder::class,
            BordereauSeeder::class,
            FactureSeeder::class,
            PaiementSeeder::class,
        ]);
    }
}

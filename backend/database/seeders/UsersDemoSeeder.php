<?php

namespace Database\Seeders;

use App\Enums\AppRole;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class UsersDemoSeeder extends Seeder
{
    /**
     * Crée un utilisateur par rôle pour la démo (mot de passe commun: demo123).
     */
    public function run(): void
    {
        $password = Hash::make('demo123');
        $users = [
            [
                'nom' => 'Admin',
                'prenom' => 'Système',
                'email' => 'admin@kalyto-demo.com',
                'role' => AppRole::Admin->value,
                'is_active' => true,
            ],
            [
                'nom' => 'Diallo',
                'prenom' => 'Mamadou',
                'email' => 'commercial@kalyto-demo.com',
                'role' => AppRole::Commercial->value,
                'is_active' => true,
            ],
            [
                'nom' => 'Koné',
                'prenom' => 'Aïcha',
                'email' => 'comptable@kalyto-demo.com',
                'role' => AppRole::Comptable->value,
                'is_active' => true,
            ],
            [
                'nom' => 'Ouattara',
                'prenom' => 'Fatou',
                'email' => 'rh@kalyto-demo.com',
                'role' => AppRole::RH->value,
                'is_active' => true,
            ],
            [
                'nom' => 'Bamba',
                'prenom' => 'Ibrahim',
                'email' => 'technicien@kalyto-demo.com',
                'role' => AppRole::Technicien->value,
                'is_active' => true,
            ],
            [
                'nom' => 'Traoré',
                'prenom' => 'Seydou',
                'email' => 'patron@kalyto-demo.com',
                'role' => AppRole::Patron->value,
                'is_active' => true,
            ],
        ];

        foreach ($users as $data) {
            User::firstOrCreate(
                ['email' => $data['email']],
                array_merge($data, ['password' => $password])
            );
        }

        $this->command->info('Utilisateurs démo créés (mot de passe: demo123).');
    }
}

<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class AdminSeeder extends Seeder
{
    /**
     * Créer un utilisateur administrateur dans la base de données
     */
    public function run(): void
    {
        User::create([
            'nom' => 'Admin',
            'prenom' => 'Système',
            'email' => 'admin@easyconnect.com',
            'password' => Hash::make('admin123'), // Changez ce mot de passe selon vos besoins
            'role' => 1, // 1 = Admin
            'is_active' => true,
        ]);

        $this->command->info('Administrateur créé avec succès!');
        $this->command->info('Email: admin@easyconnect.com');
        $this->command->info('Mot de passe: admin123');
    }
}


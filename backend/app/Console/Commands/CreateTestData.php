<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\User;
use App\Models\Attendance;

class CreateTestData extends Command
{
    protected $signature = 'test:create-data';
    protected $description = 'Créer des données de test pour l\'API';

    public function handle()
    {
        // Créer un utilisateur de test s'il n'existe pas
        $user = User::where('email', 'test@example.com')->first();
        if (!$user) {
            $user = User::create([
                'nom' => 'Test',
                'prenom' => 'User',
                'email' => 'test@example.com',
                'password' => bcrypt('password'),
                'role' => 2,
                'is_active' => true,
            ]);
            $this->info('Utilisateur créé');
        }

        // Créer un token
        $token = $user->createToken('test-token')->plainTextToken;
        $this->info("Token: $token");

        // Supprimer les anciens pointages
        Attendance::where('user_id', $user->id)->delete();

        // Créer quelques pointages de test
        $attendance1 = Attendance::create([
            'user_id' => $user->id,
            'check_in_time' => now()->subDays(1),
            'check_out_time' => now()->subDays(1)->addHours(8),
            'status' => 'present',
            'location' => [
                'latitude' => 48.8566,
                'longitude' => 2.3522,
                'address' => 'Paris, France'
            ],
            'notes' => 'Pointage de test 1'
        ]);

        $attendance2 = Attendance::create([
            'user_id' => $user->id,
            'check_in_time' => now()->subDays(2),
            'check_out_time' => now()->subDays(2)->addHours(7),
            'status' => 'late',
            'location' => [
                'latitude' => 48.8566,
                'longitude' => 2.3522,
                'address' => 'Paris, France'
            ],
            'notes' => 'Pointage de test 2 - en retard'
        ]);

        $attendance3 = Attendance::create([
            'user_id' => $user->id,
            'check_in_time' => now()->subDays(3),
            'check_out_time' => now()->subDays(3)->addHours(6),
            'status' => 'present',
            'location' => [
                'latitude' => 48.8566,
                'longitude' => 2.3522,
                'address' => 'Paris, France'
            ],
            'notes' => 'Pointage de test 3'
        ]);

        $this->info('Pointages créés');
        $this->info('Total utilisateurs: ' . User::count());
        $this->info('Total pointages: ' . Attendance::count());
        
        return 0;
    }
}
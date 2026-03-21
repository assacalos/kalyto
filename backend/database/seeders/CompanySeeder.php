<?php

namespace Database\Seeders;

use App\Models\Company;
use Illuminate\Database\Seeder;

class CompanySeeder extends Seeder
{
    public function run(): void
    {
        Company::firstOrCreate(
            ['code' => 'KALYTO-DEMO'],
            [
                'name' => 'Kalyto Demo',
                'ninea' => '123456789',
                'address' => 'Abidjan, Plateau, Avenue Terrasson de Fougères',
            ]
        );

        $this->command->info('Société de démo créée.');
    }
}

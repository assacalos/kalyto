<?php

namespace Database\Seeders;

use App\Models\Client;
use App\Models\Company;
use Illuminate\Database\Seeder;

class ClientSeeder extends Seeder
{
    public function run(): void
    {
        $companyId = Company::where('code', 'KALYTO-DEMO')->value('id') ?? Company::first()?->id;

        $clients = [
            [
                'nom' => 'Soro',
                'prenom' => 'Koffi',
                'email' => 'koffi.soro@demo-client.com',
                'contact' => '+225 07 00 00 01 01',
                'adresse' => 'Cocody, Angré 7e tranche',
                'situation_geographique' => 'Abidjan',
                'nom_entreprise' => 'Soro Informatique',
                'numero_contribuable' => 'CI00123456789',
                'ninea' => '123456789',
                'status' => 1,
            ],
            [
                'nom' => 'Yao',
                'prenom' => 'Marie',
                'email' => 'marie.yao@demo-client.com',
                'contact' => '+225 05 12 34 56 78',
                'adresse' => 'Marcory, Zone 4',
                'situation_geographique' => 'Abidjan',
                'nom_entreprise' => 'Yao Consulting',
                'numero_contribuable' => 'CI00987654321',
                'ninea' => '987654321',
                'status' => 1,
            ],
            [
                'nom' => 'Coulibaly',
                'prenom' => 'Jean',
                'email' => 'jean.coulibaly@demo-client.com',
                'contact' => '+225 01 98 76 54 32',
                'adresse' => 'Yopougon, Sicogi',
                'situation_geographique' => 'Abidjan',
                'nom_entreprise' => 'Coulibaly & Fils',
                'numero_contribuable' => null,
                'ninea' => null,
                'status' => 1,
            ],
            [
                'nom' => 'Konan',
                'prenom' => 'Aminata',
                'email' => 'aminata.konan@demo-client.com',
                'contact' => '+225 07 11 22 33 44',
                'adresse' => 'Plateau, rue du Commerce',
                'situation_geographique' => 'Abidjan',
                'nom_entreprise' => 'Konan Services',
                'numero_contribuable' => null,
                'ninea' => null,
                'status' => 0,
            ],
            [
                'nom' => 'Diabaté',
                'prenom' => 'Moussa',
                'email' => 'moussa.diabate@demo-client.com',
                'contact' => '+225 05 55 66 77 88',
                'adresse' => 'Treichville, avenue 12',
                'situation_geographique' => 'Abidjan',
                'nom_entreprise' => 'Diabaté Équipements',
                'numero_contribuable' => null,
                'ninea' => null,
                'status' => 1,
            ],
        ];

        foreach ($clients as $data) {
            Client::firstOrCreate(
                ['email' => $data['email']],
                array_merge($data, [
                    'company_id' => $companyId,
                    'user_id' => null,
                    'commentaire' => null,
                ])
            );
        }

        $this->command->info('Clients démo créés.');
    }
}

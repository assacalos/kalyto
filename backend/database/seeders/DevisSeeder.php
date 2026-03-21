<?php

namespace Database\Seeders;

use App\Models\Client;
use App\Models\Company;
use App\Models\Devis;
use App\Models\DevisItem;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Database\Seeder;

class DevisSeeder extends Seeder
{
    public function run(): void
    {
        $commercial = User::where('email', 'commercial@kalyto-demo.com')->first();
        $clients = Client::whereIn('email', [
            'koffi.soro@demo-client.com',
            'marie.yao@demo-client.com',
            'jean.coulibaly@demo-client.com',
            'aminata.konan@demo-client.com',
            'moussa.diabate@demo-client.com',
        ])->get()->keyBy('email');

        if (!$commercial || $clients->isEmpty()) {
            $this->command->warn('DevisSeeder: commercial ou clients manquants. Exécutez UsersDemoSeeder et ClientSeeder avant.');
            return;
        }

        $companyId = Company::where('code', 'KALYTO-DEMO')->value('id') ?? Company::first()?->id;

        $devisData = [
            ['client' => 'koffi.soro@demo-client.com', 'ref' => 'DEV-2024-001', 'days_offset' => -30],
            ['client' => 'marie.yao@demo-client.com', 'ref' => 'DEV-2024-002', 'days_offset' => -20],
            ['client' => 'jean.coulibaly@demo-client.com', 'ref' => 'DEV-2024-003', 'days_offset' => -10],
            ['client' => 'aminata.konan@demo-client.com', 'ref' => 'DEV-2024-004', 'days_offset' => 0],
            ['client' => 'moussa.diabate@demo-client.com', 'ref' => 'DEV-2024-005', 'days_offset' => 5],
        ];

        $designations = [
            ['d' => 'Poste informatique complet', 'q' => 2, 'p' => 350000],
            ['d' => 'Maintenance annuelle', 'q' => 1, 'p' => 500000],
            ['d' => 'Formation utilisateurs', 'q' => 3, 'p' => 75000],
            ['d' => 'Licence logiciel', 'q' => 5, 'p' => 45000],
            ['d' => 'Câblage réseau', 'q' => 1, 'p' => 280000],
        ];

        foreach ($devisData as $i => $row) {
            $client = $clients->get($row['client']);
            if (!$client) continue;

            $dateCreation = Carbon::now()->addDays($row['days_offset']);
            $dateValidite = $dateCreation->copy()->addDays(30);

            $devis = Devis::firstOrCreate(
                ['reference' => $row['ref']],
                [
                    'company_id' => $companyId ?? $client->company_id,
                    'client_id' => $client->id,
                    'user_id' => $commercial->id,
                    'date_creation' => $dateCreation,
                    'date_validite' => $dateValidite,
                    'status' => min($i + 1, 3),
                    'remise_globale' => $i === 0 ? 5 : 0,
                    'tva' => 18,
                    'conditions' => 'Paiement à 30 jours. Acompte 30% à la commande.',
                    'notes' => 'Devis démo.',
                    'titre' => 'Devis ' . $row['ref'],
                ]
            );

            if ($devis->wasRecentlyCreated && $devis->items()->count() === 0) {
                $items = array_slice($designations, 0, 2 + ($i % 3));
                foreach ($items as $item) {
                    DevisItem::create([
                        'devis_id' => $devis->id,
                        'designation' => $item['d'],
                        'quantite' => $item['q'],
                        'prix_unitaire' => $item['p'],
                    ]);
                }
            }
        }

        $this->command->info('Devis démo créés.');
    }
}

<?php

namespace Database\Seeders;

use App\Models\Bordereau;
use App\Models\BordereauItem;
use App\Models\Client;
use App\Models\Devis;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Database\Seeder;

class BordereauSeeder extends Seeder
{
    public function run(): void
    {
        $commercial = User::where('email', 'commercial@kalyto-demo.com')->first();
        $clients = Client::whereIn('email', [
            'koffi.soro@demo-client.com',
            'marie.yao@demo-client.com',
            'jean.coulibaly@demo-client.com',
        ])->get()->keyBy('email');

        if (!$commercial || $clients->isEmpty()) {
            $this->command->warn('BordereauSeeder: commercial ou clients manquants.');
            return;
        }

        $refs = ['BOR-2024-001', 'BOR-2024-002', 'BOR-2024-003', 'BOR-2024-004'];
        $clientEmails = ['koffi.soro@demo-client.com', 'marie.yao@demo-client.com', 'jean.coulibaly@demo-client.com', 'marie.yao@demo-client.com'];

        foreach ($refs as $idx => $ref) {
            $client = $clients->get($clientEmails[$idx]);
            if (!$client) continue;

            $dateCreation = Carbon::now()->addDays(-25 + $idx * 8);
            $devis = Devis::where('client_id', $client->id)->first();

            $bordereau = Bordereau::firstOrCreate(
                ['reference' => $ref],
                [
                    'company_id' => $client->company_id,
                    'client_id' => $client->id,
                    'devis_id' => $devis?->id,
                    'user_id' => $commercial->id,
                    'date_creation' => $dateCreation,
                    'date_validation' => $idx >= 2 ? $dateCreation->copy()->addDays(2) : null,
                    'status' => $idx >= 2 ? 2 : 1,
                    'titre' => 'Bordereau ' . $ref,
                    'notes' => 'Bordereau démo.',
                    'etat_livraison' => $idx === 3 ? 'livre' : 'en_attente',
                    'date_livraison' => $idx === 3 ? $dateCreation->copy()->addDays(5) : null,
                ]
            );

            if ($bordereau->wasRecentlyCreated && $bordereau->items()->count() === 0) {
                $items = [
                    ['designation' => 'Poste informatique', 'quantite' => 1, 'description' => 'Unité centrale + écran'],
                    ['designation' => 'Câble réseau', 'quantite' => 10, 'description' => 'RJ45 2m'],
                ];
                foreach ($items as $item) {
                    BordereauItem::create([
                        'bordereau_id' => $bordereau->id,
                        'designation' => $item['designation'],
                        'quantite' => $item['quantite'],
                        'description' => $item['description'] ?? null,
                    ]);
                }
            }
        }

        $this->command->info('Bordereaux démo créés.');
    }
}

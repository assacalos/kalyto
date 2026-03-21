<?php

namespace Database\Seeders;

use App\Models\Client;
use App\Models\Facture;
use App\Models\FactureItem;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Database\Seeder;

class FactureSeeder extends Seeder
{
    public function run(): void
    {
        $comptable = User::where('email', 'comptable@kalyto-demo.com')->first();
        $patron = User::where('email', 'patron@kalyto-demo.com')->first();
        $clients = Client::whereIn('email', [
            'koffi.soro@demo-client.com',
            'marie.yao@demo-client.com',
            'jean.coulibaly@demo-client.com',
            'moussa.diabate@demo-client.com',
        ])->get()->keyBy('email');

        if (!$comptable || $clients->isEmpty()) {
            $this->command->warn('FactureSeeder: comptable ou clients manquants.');
            return;
        }

        $invoices = [
            ['client' => 'koffi.soro@demo-client.com', 'num' => 'FAC-2024-001', 'ht' => 850000, 'status' => 'valide', 'validated' => true],
            ['client' => 'marie.yao@demo-client.com', 'num' => 'FAC-2024-002', 'ht' => 420000, 'status' => 'valide', 'validated' => true],
            ['client' => 'jean.coulibaly@demo-client.com', 'num' => 'FAC-2024-003', 'ht' => 1500000, 'status' => 'en_attente', 'validated' => false],
            ['client' => 'moussa.diabate@demo-client.com', 'num' => 'FAC-2024-004', 'ht' => 320000, 'status' => 'en_attente', 'validated' => false],
        ];

        foreach ($invoices as $i => $row) {
            $client = $clients->get($row['client']);
            if (!$client) continue;

            $tva = 18;
            $tvaAmount = round($row['ht'] * $tva / 100, 2);
            $ttc = $row['ht'] + $tvaAmount;
            $dateFacture = Carbon::now()->addDays(-20 + $i * 5);
            $dateEcheance = $dateFacture->copy()->addDays(30);

            $facture = Facture::firstOrCreate(
                ['numero_facture' => $row['num']],
                [
                    'company_id' => $client->company_id,
                    'client_id' => $client->id,
                    'user_id' => $comptable->id,
                    'date_facture' => $dateFacture,
                    'date_echeance' => $dateEcheance,
                    'montant_ht' => $row['ht'],
                    'tva' => $tva,
                    'montant_ttc' => $ttc,
                    'status' => $row['status'],
                    'type_paiement' => null,
                    'notes' => 'Facture démo.',
                    'terms' => 'Paiement sous 30 jours.',
                    'validated_by' => $row['validated'] ? $patron?->id : null,
                    'validated_at' => $row['validated'] ? $dateFacture->copy()->addDays(1) : null,
                    'validation_comment' => $row['validated'] ? 'Validé pour démo' : null,
                ]
            );

            if ($facture->wasRecentlyCreated && $facture->items()->count() === 0) {
                $qty = 2;
                $unitPrice = round($row['ht'] / $qty, 2);
                FactureItem::create([
                    'facture_id' => $facture->id,
                    'description' => 'Prestations / Fournitures démo',
                    'quantity' => $qty,
                    'unit_price' => $unitPrice,
                    'total_price' => $row['ht'],
                    'unit' => 'lot',
                ]);
            }
        }

        $this->command->info('Factures démo créées.');
    }
}

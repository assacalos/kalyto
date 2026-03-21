<?php

namespace Database\Seeders;

use App\Models\Facture;
use App\Models\Paiement;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Database\Seeder;

class PaiementSeeder extends Seeder
{
    public function run(): void
    {
        $comptable = User::where('email', 'comptable@kalyto-demo.com')->first();
        $patron = User::where('email', 'patron@kalyto-demo.com')->first();

        if (!$comptable) {
            $this->command->warn('PaiementSeeder: comptable manquant.');
            return;
        }

        $factures = Facture::whereIn('numero_facture', ['FAC-2024-001', 'FAC-2024-002'])->get()->keyBy('numero_facture');
        if ($factures->isEmpty()) {
            $this->command->warn('PaiementSeeder: exécutez FactureSeeder avant.');
            return;
        }

        $paiements = [
            ['num' => 'FAC-2024-001', 'ref' => 'PAY-2024-001', 'montant' => 501500, 'status' => 'paid'],
            ['num' => 'FAC-2024-001', 'ref' => 'PAY-2024-002', 'montant' => 502500, 'status' => 'paid'],
            ['num' => 'FAC-2024-002', 'ref' => 'PAY-2024-003', 'montant' => 495600, 'status' => 'paid'],
        ];

        foreach ($paiements as $row) {
            $facture = $factures->get($row['num']);
            if (!$facture) continue;

            $datePaiement = Carbon::now()->addDays(-15);

            Paiement::firstOrCreate(
                ['reference' => $row['ref']],
                [
                    'company_id' => $facture->company_id,
                    'facture_id' => $facture->id,
                    'client_id' => $facture->client_id,
                    'client_name' => $facture->client?->nom ?? null,
                    'client_email' => $facture->client?->email ?? null,
                    'client_address' => $facture->client?->adresse ?? null,
                    'payment_number' => $row['ref'],
                    'type' => 'one_time',
                    'montant' => $row['montant'],
                    'currency' => 'FCFA',
                    'date_paiement' => $datePaiement,
                    'due_date' => $facture->date_echeance,
                    'type_paiement' => 'virement',
                    'status' => $row['status'],
                    'reference' => $row['ref'],
                    'user_id' => $comptable->id,
                    'comptable_id' => $comptable->id,
                    'comptable_name' => $comptable->nom . ' ' . $comptable->prenom,
                    'validated_by' => $patron?->id,
                    'validated_at' => $datePaiement,
                    'paid_at' => $datePaiement,
                    'commentaire' => 'Paiement démo.',
                ]
            );
        }

        $this->command->info('Paiements démo créés.');
    }
}

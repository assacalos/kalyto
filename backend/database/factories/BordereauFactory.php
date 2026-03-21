<?php

namespace Database\Factories;

use App\Models\Bordereau;
use App\Models\Client;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class BordereauFactory extends Factory
{
    protected $model = Bordereau::class;

    public function definition(): array
    {
        return [
            'reference' => strtoupper($this->faker->unique()->bothify('BDR-#####')),
            'client_id' => Client::factory(),
            'commercial_id' => User::factory(),
            'date_creation' => $this->faker->date(),
            'date_validation' => null,
            'notes' => $this->faker->sentence(),
            'remise_globale' => $this->faker->randomFloat(2, 0, 15),
            'tva' => 20,
            'conditions' => $this->faker->sentence(),
            'status' => $this->faker->numberBetween(0, 3),
            'commentaire_rejet' => null,
        ];
    }
}

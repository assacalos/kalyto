<?php

namespace Database\Factories;

use App\Models\BordereauItem;
use App\Models\Bordereau;
use Illuminate\Database\Eloquent\Factories\Factory;

class BordereauItemFactory extends Factory
{
    protected $model = BordereauItem::class;

    public function definition(): array
    {
        return [
            'bordereau_id' => Bordereau::factory(),
            'designation' => $this->faker->word(),
            'quantite' => $this->faker->numberBetween(1, 20),
            'prix_unitaire' => $this->faker->randomFloat(2, 10, 500),
            'description' => $this->faker->sentence(),
        ];
    }
}

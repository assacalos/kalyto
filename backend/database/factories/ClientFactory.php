<?php

namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Client>
 */
class ClientFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'nom' => $this->faker->company,
            'prenom' => $this->faker->firstName,
            'email' => $this->faker->unique()->safeEmail,
            'contact' => $this->faker->phoneNumber,
            'adresse' => $this->faker->address,
            'nom_entreprise' => $this->faker->company,
            'situation_geographique' => $this->faker->city . ', ' . $this->faker->country,
            'status' => $this->faker->numberBetween(0, 2),
            //
        ];
    }
}

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     * Insère une société par défaut pour rétrocompatibilité.
     */
    public function up(): void
    {
        if (!DB::table('companies')->exists()) {
            DB::table('companies')->insert([
                [
                    'name' => 'Société principale',
                    'code' => 'SOC1',
                    'ninea' => null,
                    'address' => null,
                    'created_at' => now(),
                    'updated_at' => now(),
                ],
            ]);
        }
    }

    public function down(): void
    {
        DB::table('companies')->where('code', 'SOC1')->delete();
    }
};

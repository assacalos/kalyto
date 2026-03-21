<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Étend le champ nature pour accepter les natures technicien
     * (depannage_visite, depannage_bureau, depannage_telephonique, programmation).
     */
    public function up(): void
    {
        $driver = Schema::getConnection()->getDriverName();
        if ($driver === 'mysql') {
            DB::statement("ALTER TABLE reportings MODIFY nature VARCHAR(64) NULL");
        } else {
            Schema::table('reportings', function (Blueprint $table) {
                $table->string('nature', 64)->nullable()->change();
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        $driver = Schema::getConnection()->getDriverName();
        if ($driver === 'mysql') {
            DB::statement("ALTER TABLE reportings MODIFY nature ENUM('echange_telephonique', 'visite') NULL");
        } else {
            Schema::table('reportings', function (Blueprint $table) {
                $table->enum('nature', ['echange_telephonique', 'visite'])->nullable()->change();
            });
        }
    }
};

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('bordereaus', function (Blueprint $table) {
            $table->string('titre', 255)->nullable()->after('reference');
            $table->string('etat_livraison', 100)->nullable()->after('status');
            $table->string('garantie', 255)->nullable()->after('etat_livraison');
            $table->date('date_livraison')->nullable()->after('garantie');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('bordereaus', function (Blueprint $table) {
            $table->dropColumn(['titre', 'etat_livraison', 'garantie', 'date_livraison']);
        });
    }
};

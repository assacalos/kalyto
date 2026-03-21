<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Plan de comptes (comptabilité).
     */
    public function up(): void
    {
        Schema::create('comptes', function (Blueprint $table) {
            $table->id();
            $table->string('code', 20)->unique()->comment('Ex: 51, 411, 401');
            $table->string('libelle');
            $table->enum('type', ['actif', 'passif', 'charge', 'produit'])->default('actif');
            $table->boolean('actif')->default(true);
            $table->timestamps();
            $table->index('code');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('comptes');
    }
};

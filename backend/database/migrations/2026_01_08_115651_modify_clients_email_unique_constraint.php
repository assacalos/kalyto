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
        Schema::table('clients', function (Blueprint $table) {
            // Supprimer la contrainte unique sur email seul
            $table->dropUnique(['email']);
            
            // Ajouter une contrainte unique composite sur email + nom_entreprise
            $table->unique(['email', 'nom_entreprise'], 'clients_email_entreprise_unique');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('clients', function (Blueprint $table) {
            // Supprimer la contrainte unique composite
            $table->dropUnique('clients_email_entreprise_unique');
            
            // Restaurer la contrainte unique sur email seul
            $table->unique('email');
        });
    }
};

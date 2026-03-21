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
        Schema::create('evaluations', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id'); // Employé évalué
            $table->unsignedBigInteger('evaluateur_id'); // RH ou Manager qui évalue
            $table->string('type_evaluation'); // annuelle, trimestrielle, probation, etc.
            $table->date('date_evaluation');
            $table->date('periode_debut');
            $table->date('periode_fin');
            $table->json('criteres_evaluation'); // Critères d'évaluation (JSON)
            $table->decimal('note_globale', 4, 2); // Note sur 20 (max 99.99)
            $table->text('commentaires_evaluateur');
            $table->text('commentaires_employe')->nullable();
            $table->text('objectifs_futurs')->nullable();
            $table->string('statut')->default('en_cours'); // en_cours, finalisee, archivee
            $table->date('date_signature_employe')->nullable();
            $table->date('date_signature_evaluateur')->nullable();
            $table->boolean('confidentiel')->default(true);
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('evaluateur_id')->references('id')->on('users')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('evaluations');
    }
};

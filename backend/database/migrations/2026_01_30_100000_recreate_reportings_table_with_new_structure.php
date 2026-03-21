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
        // Supprimer l'ancienne table
        Schema::dropIfExists('reportings');
        
        // Créer la nouvelle table avec uniquement les nouveaux champs
        Schema::create('reportings', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->date('report_date')->default(now());
            
            // Nouveaux champs du formulaire
            $table->enum('nature', ['echange_telephonique', 'visite'])->nullable();
            $table->string('nom_societe')->nullable();
            $table->string('contact_societe')->nullable();
            $table->string('nom_personne')->nullable();
            $table->string('contact_personne')->nullable();
            $table->enum('moyen_contact', ['mail', 'whatsapp', 'linkedin'])->nullable();
            $table->string('produit_demarche')->nullable();
            $table->text('commentaire')->nullable();
            $table->enum('type_relance', ['telephonique', 'mail', 'rdv'])->nullable();
            $table->datetime('relance_date_heure')->nullable();
            
            // Statut et validation
            $table->enum('status', ['submitted', 'approved', 'rejected'])->default('submitted');
            $table->timestamp('submitted_at')->nullable();
            $table->timestamp('approved_at')->nullable();
            $table->unsignedBigInteger('approved_by')->nullable();
            $table->timestamp('rejected_at')->nullable();
            $table->unsignedBigInteger('rejected_by')->nullable();
            $table->text('rejection_reason')->nullable();
            
            // Commentaire du patron lors de l'approbation
            $table->text('patron_note')->nullable();
            
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('approved_by')->references('id')->on('users')->onDelete('set null');
            $table->foreign('rejected_by')->references('id')->on('users')->onDelete('set null');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('reportings');
    }
};


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
        Schema::create('reportings', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->date('report_date');
            $table->json('metrics'); // Métriques spécifiques selon le rôle
            $table->enum('status', ['draft', 'submitted', 'approved'])->default('submitted');
            $table->timestamp('submitted_at')->nullable();
            $table->timestamp('approved_at')->nullable();
            $table->unsignedBigInteger('approved_by')->nullable(); // Qui a approuvé
            $table->text('comments')->nullable();
            $table->text('patron_note')->nullable();
            
            // Notes pour les métriques commerciales (sans notes_chiffre_affaires)
            $table->text('notes_clients_prospectes')->nullable();
            $table->text('notes_rdv_obtenus')->nullable();
            $table->text('notes_devis_crees')->nullable();
            $table->text('notes_devis_acceptes')->nullable();
            $table->text('notes_nouveaux_clients')->nullable();
            $table->text('notes_appels_effectues')->nullable();
            $table->text('notes_emails_envoyes')->nullable();
            $table->text('notes_visites_realisees')->nullable();
            
            // Notes pour les métriques comptables
            $table->text('notes_factures_emises')->nullable();
            $table->text('notes_factures_payees')->nullable();
            $table->text('notes_montant_facture')->nullable();
            $table->text('notes_montant_encaissement')->nullable();
            $table->text('notes_bordereaux_traites')->nullable();
            $table->text('notes_bons_commande_traites')->nullable();
            $table->text('notes_clients_factures')->nullable();
            $table->text('notes_relances_effectuees')->nullable();
            $table->text('notes_encaissements')->nullable();
            
            // Notes pour les métriques techniques
            $table->text('notes_interventions_planifiees')->nullable();
            $table->text('notes_interventions_realisees')->nullable();
            $table->text('notes_interventions_annulees')->nullable();
            $table->text('notes_clients_visites')->nullable();
            $table->text('notes_problemes_resolus')->nullable();
            $table->text('notes_problemes_en_cours')->nullable();
            $table->text('notes_temps_travail')->nullable();
            $table->text('notes_deplacements')->nullable();
            $table->text('notes_techniques')->nullable();
            
            // Notes générales
            $table->text('notes_generales')->nullable();
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('approved_by')->references('id')->on('users')->onDelete('set null');
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

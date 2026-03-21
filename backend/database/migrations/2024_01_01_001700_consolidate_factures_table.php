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
        // Supprimer la table existante et la recréer avec la structure consolidée
        Schema::dropIfExists('factures');
        
        Schema::create('factures', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('client_id');
            $table->string('numero_facture')->unique();
            $table->date('date_facture');
            $table->date('date_echeance');
            $table->decimal('montant_ht', 10, 2);
            $table->decimal('tva', 5, 2)->default(18.0);
            $table->decimal('montant_ttc', 10, 2);
            $table->enum('status', ['en_attente', 'valide', 'rejete'])->default('en_attente');
            $table->enum('type_paiement', ['especes', 'virement', 'cheque', 'carte_bancaire', 'mobile_money'])->nullable();
            $table->text('notes')->nullable();
            $table->text('terms')->nullable();
            $table->unsignedBigInteger('user_id'); // Créateur
            
            // Champs pour la validation
            $table->unsignedBigInteger('validated_by')->nullable();
            $table->timestamp('validated_at')->nullable();
            $table->text('validation_comment')->nullable();
            
            // Champs pour le rejet
            $table->unsignedBigInteger('rejected_by')->nullable();
            $table->timestamp('rejected_at')->nullable();
            $table->string('rejection_reason')->nullable();
            $table->text('rejection_comment')->nullable();
            
            $table->timestamps();

            // Clés étrangères
            $table->foreign('client_id')->references('id')->on('clients')->onDelete('cascade');
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('validated_by')->references('id')->on('users')->onDelete('set null');
            $table->foreign('rejected_by')->references('id')->on('users')->onDelete('set null');
            
            // Index
            $table->index(['status', 'date_facture']);
            $table->index(['client_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('factures');
    }
};

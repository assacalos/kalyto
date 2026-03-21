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
        Schema::dropIfExists('taxes');
        
        Schema::create('taxes', function (Blueprint $table) {
            $table->id();
            $table->string('category'); // Utilise category au lieu de tax_category_id
            $table->unsignedBigInteger('comptable_id'); // Comptable responsable
            $table->string('reference')->unique(); // Référence unique
            $table->string('period'); // Période concernée (ex: 2025-01, 2025-Q1)
            $table->date('period_start');
            $table->date('period_end');
            $table->date('due_date'); // Date limite de paiement
            $table->decimal('base_amount', 15, 2); // Montant de base (HT)
            $table->decimal('tax_rate', 10, 2); // Taux appliqué
            $table->decimal('tax_amount', 15, 2); // Montant de la taxe
            $table->decimal('total_amount', 15, 2); // Montant total
            $table->enum('status', ['en_attente', 'valide', 'rejete', 'paye'])->default('en_attente');
            $table->text('description')->nullable();
            $table->text('notes')->nullable();
            $table->json('calculation_details')->nullable(); // Détails du calcul
            $table->timestamp('declared_at')->nullable(); // Date de déclaration
            $table->timestamp('paid_at')->nullable(); // Date de paiement
            
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
            $table->foreign('comptable_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('validated_by')->references('id')->on('users')->onDelete('set null');
            $table->foreign('rejected_by')->references('id')->on('users')->onDelete('set null');
            
            // Index
            $table->index(['period', 'category']);
            $table->index(['status', 'due_date']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('taxes');
    }
};

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
        Schema::dropIfExists('paiements');
        
        Schema::create('paiements', function (Blueprint $table) {
            $table->id();
            $table->string('payment_number')->nullable()->unique();
            $table->enum('type', ['one_time', 'monthly'])->default('one_time');
            $table->unsignedBigInteger('facture_id')->nullable();
            $table->unsignedBigInteger('client_id')->nullable();
            $table->decimal('montant', 10, 2);
            $table->string('currency', 4)->default('FCFA');
            $table->date('date_paiement');
            $table->date('due_date')->nullable();
            $table->enum('type_paiement', ['especes', 'virement', 'cheque', 'carte_bancaire', 'mobile_money']);
            $table->enum('status', ['draft', 'submitted', 'approved', 'rejected', 'paid', 'overdue', 'pending', 'calculated'])->default('draft');
            $table->string('reference')->unique();
            $table->text('commentaire')->nullable();
            $table->text('description')->nullable();
            $table->text('notes')->nullable();
            $table->unsignedBigInteger('user_id'); // Enregistré par
            $table->unsignedBigInteger('comptable_id')->nullable();
            $table->string('client_name')->nullable();
            $table->string('client_email')->nullable();
            $table->text('client_address')->nullable();
            $table->string('comptable_name')->nullable();
            $table->timestamp('submitted_at')->nullable();
            $table->timestamp('approved_at')->nullable();
            $table->timestamp('paid_at')->nullable();
            
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
            $table->foreign('facture_id')->references('id')->on('factures')->onDelete('set null');
            $table->foreign('client_id')->references('id')->on('clients')->onDelete('set null');
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('comptable_id')->references('id')->on('users')->onDelete('set null');
            $table->foreign('validated_by')->references('id')->on('users')->onDelete('set null');
            $table->foreign('rejected_by')->references('id')->on('users')->onDelete('set null');
            
            // Index
            $table->index(['status', 'date_paiement']);
            $table->index(['facture_id']);
            $table->index(['client_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('paiements');
    }
};

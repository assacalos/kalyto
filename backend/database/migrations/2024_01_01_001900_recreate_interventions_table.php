<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // Désactiver les vérifications de clés étrangères
        DB::statement('SET FOREIGN_KEY_CHECKS=0;');
        
        // Supprimer les tables obsolètes
        Schema::dropIfExists('intervention_reports');
        Schema::dropIfExists('intervention_types');
        Schema::dropIfExists('interventions');
        
        // Créer la nouvelle table interventions
        Schema::create('interventions', function (Blueprint $table) {
            $table->id();
            $table->string('type'); // 'external' ou 'on_site'
            $table->string('title');
            $table->text('description');
            $table->datetime('scheduled_date');
            $table->datetime('start_date')->nullable();
            $table->datetime('end_date')->nullable();
            $table->enum('status', ['pending', 'approved', 'in_progress', 'completed', 'rejected'])->default('pending');
            $table->string('priority')->default('medium'); // 'low', 'medium', 'high', 'urgent'
            $table->string('location')->nullable();
            $table->unsignedBigInteger('client_id')->nullable(); // Référence au client sélectionné
            $table->string('client_name')->nullable(); // Gardé pour compatibilité et affichage
            $table->string('client_phone')->nullable(); // Gardé pour compatibilité et affichage
            $table->string('client_email')->nullable(); // Gardé pour compatibilité et affichage
            $table->string('equipment')->nullable();
            $table->text('problem_description')->nullable();
            $table->text('solution')->nullable();
            $table->text('notes')->nullable();
            $table->json('attachments')->nullable();
            $table->decimal('estimated_duration', 8, 2)->nullable();
            $table->decimal('actual_duration', 8, 2)->nullable();
            $table->decimal('cost', 10, 2)->nullable();
            $table->unsignedBigInteger('created_by')->nullable();
            $table->unsignedBigInteger('approved_by')->nullable();
            $table->datetime('approved_at')->nullable();
            $table->text('rejection_reason')->nullable();
            $table->text('completion_notes')->nullable();
            $table->timestamps();
            
            // Clés étrangères
            $table->foreign('client_id')->references('id')->on('clients')->onDelete('set null');
            $table->foreign('created_by')->references('id')->on('users')->onDelete('set null');
            $table->foreign('approved_by')->references('id')->on('users')->onDelete('set null');
        });
        
        // Réactiver les vérifications de clés étrangères
        DB::statement('SET FOREIGN_KEY_CHECKS=1;');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('interventions');
    }
};


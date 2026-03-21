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
        Schema::table('notifications', function (Blueprint $table) {
            // Ajouter les nouveaux champs pour la nouvelle structure
            $table->string('title')->nullable()->after('titre');
            $table->boolean('is_read')->default(false)->after('statut');
            $table->string('entity_type')->nullable()->after('type');
            $table->unsignedBigInteger('entity_id')->nullable()->after('entity_type');
            $table->string('action_route')->nullable()->after('entity_id');
            $table->json('metadata')->nullable()->after('data');
            
            // metadata sera utilisé pour la nouvelle structure, data pour l'ancienne (compatibilité)
            
            // Ajouter des index pour améliorer les performances
            $table->index(['user_id', 'is_read']);
            $table->index(['entity_type', 'entity_id']);
            $table->index('created_at');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('notifications', function (Blueprint $table) {
            $table->dropIndex(['user_id', 'is_read']);
            $table->dropIndex(['entity_type', 'entity_id']);
            $table->dropIndex(['created_at']);
            
            $table->dropColumn([
                'title',
                'is_read',
                'entity_type',
                'entity_id',
                'action_route',
                'metadata'
            ]);
        });
    }
};

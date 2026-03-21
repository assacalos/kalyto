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
        Schema::create('tax_categories', function (Blueprint $table) {
            $table->id();
            $table->string('name'); // TVA, Impôt sur le revenu, etc.
            $table->string('code')->unique(); // TVA, IR, etc.
            $table->text('description')->nullable();
            $table->decimal('default_rate', 10, 2)->default(0); // Taux par défaut en % ou montant fixe
            $table->enum('type', ['percentage', 'fixed'])->default('percentage'); // Type de taxe
            $table->enum('frequency', ['monthly', 'quarterly', 'yearly'])->default('monthly'); // Fréquence de déclaration
            $table->boolean('is_active')->default(true);
            $table->json('applicable_to')->nullable(); // Types d'entités concernées (factures, salaires, etc.)
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('tax_categories');
    }
};

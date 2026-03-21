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
        Schema::create('bon_de_commande_items', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('bon_de_commande_id');
            $table->string('ref')->nullable(); // Référence de l'article
            $table->string('designation');
            $table->integer('quantite');
            $table->decimal('prix_unitaire', 10, 2);
            $table->text('description')->nullable();
            $table->timestamps();

            $table->foreign('bon_de_commande_id')->references('id')->on('bon_de_commandes')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('bon_de_commande_items');
    }
};

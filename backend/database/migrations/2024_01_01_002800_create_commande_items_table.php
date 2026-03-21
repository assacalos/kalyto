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
        Schema::create('commande_items', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('commande_entreprise_id');
            $table->string('designation');
            $table->string('unite');
            $table->integer('quantite');
            $table->decimal('prix_unitaire', 10, 2);
            $table->text('description')->nullable();
            $table->dateTime('date_livraison')->nullable();
            $table->timestamps();

            $table->foreign('commande_entreprise_id')->references('id')->on('commandes_entreprise')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('commande_items');
    }
};

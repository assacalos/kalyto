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
        Schema::create('bon_de_commandes', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('fournisseur_id');
            $table->string('numero_commande')->unique();
            $table->date('date_commande');
            $table->decimal('montant_total', 10, 2);
            $table->text('description')->nullable();
            $table->enum('statut', ['en_attente', 'valide', 'en_cours', 'livre', 'annule'])->default('en_attente');
            $table->text('commentaire')->nullable();
            $table->text('conditions_paiement')->nullable();
            $table->integer('delai_livraison')->nullable(); // en jours
            $table->date('date_validation')->nullable();
            $table->date('date_debut_traitement')->nullable();
            $table->date('date_annulation')->nullable();
            $table->unsignedBigInteger('user_id'); // Créateur
            $table->timestamps();

            $table->foreign('fournisseur_id')->references('id')->on('fournisseurs')->onDelete('cascade');
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('bon_de_commandes');
    }
};

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
        Schema::create('conges', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->string('type_conge'); // annuel, maladie, maternite, paternite, formation, etc.
            $table->date('date_debut');
            $table->date('date_fin');
            $table->integer('nombre_jours');
            $table->text('motif');
            $table->string('statut')->default('en_attente'); // en_attente, approuve, rejete
            $table->text('commentaire_rh')->nullable();
            $table->unsignedBigInteger('approuve_par')->nullable();
            $table->timestamp('date_approbation')->nullable();
            $table->text('raison_rejet')->nullable();
            $table->boolean('urgent')->default(false);
            $table->string('piece_jointe')->nullable();
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('approuve_par')->references('id')->on('users')->onDelete('set null');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('conges');
    }
};

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
        Schema::create('devis', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('client_id');
            $table->string('reference')->unique();
            $table->date('date_creation');
            $table->date('date_validite')->nullable();
            $table->text('notes')->nullable();
            $table->tinyInteger('status')->default(0); // 0: brouillon, 1: envoyé, 2: accepté, 3: refusé
            $table->decimal('remise_globale', 8, 2)->nullable();
            $table->decimal('tva', 8, 2)->nullable();
            $table->text('conditions')->nullable();
            $table->text('commentaire')->nullable();
            $table->unsignedBigInteger('user_id'); // commercial_id
            $table->timestamps();

            $table->foreign('client_id')->references('id')->on('clients')->onDelete('cascade');
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
        });

    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('devis');
    }
};

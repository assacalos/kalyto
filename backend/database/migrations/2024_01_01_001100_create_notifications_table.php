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
        Schema::create('notifications', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->string('type'); // pointage, conge, evaluation, facture, paiement, etc.
            $table->string('titre');
            $table->text('message');
            $table->json('data')->nullable(); // Données supplémentaires (JSON)
            $table->string('statut')->default('non_lue'); // non_lue, lue, archivee
            $table->string('priorite')->default('normale'); // basse, normale, haute, urgente
            $table->string('canal')->default('app'); // app, email, sms, push
            $table->timestamp('date_lecture')->nullable();
            $table->timestamp('date_expiration')->nullable();
            $table->boolean('envoyee')->default(false);
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('notifications');
    }
};

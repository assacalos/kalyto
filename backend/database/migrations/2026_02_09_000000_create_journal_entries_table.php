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
        Schema::create('journal_entries', function (Blueprint $table) {
            $table->id();
            $table->date('date');
            $table->string('reference', 100)->nullable();
            $table->string('libelle');
            $table->string('categorie', 100)->nullable();
            $table->enum('mode_paiement', [
                'especes',
                'virement',
                'cheque',
                'carte_bancaire',
                'mobile_money',
                'autre'
            ])->default('especes');
            $table->decimal('entree', 15, 2)->default(0)->comment('Montant entrée en CFA');
            $table->decimal('sortie', 15, 2)->default(0)->comment('Montant sortie en CFA');
            $table->unsignedBigInteger('user_id')->nullable()->comment('Créé par');
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->onDelete('set null');
            $table->index(['date']);
            $table->index(['date', 'created_at']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('journal_entries');
    }
};

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Besoins / demandes du technicien au patron, avec rappels automatiques
     * à la période définie par le technicien (hors intervention).
     */
    public function up(): void
    {
        if (Schema::hasTable('besoins')) {
            return;
        }

        Schema::create('besoins', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->text('description')->nullable();
            $table->unsignedBigInteger('created_by')->comment('Technicien');
            $table->string('reminder_frequency', 32)->default('weekly');
            $table->dateTime('next_reminder_at')->nullable();
            $table->string('status', 20)->default('pending');
            $table->dateTime('treated_at')->nullable();
            $table->unsignedBigInteger('treated_by')->nullable()->comment('Patron ou admin');
            $table->text('treated_note')->nullable();
            $table->timestamps();

            $table->foreign('created_by')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('treated_by')->references('id')->on('users')->onDelete('set null');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('besoins');
    }
};

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
        Schema::create('recruitment_interviews', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('application_id');
            $table->timestamp('scheduled_at');
            $table->string('location');
            $table->enum('type', ['phone', 'video', 'in_person'])->default('in_person');
            $table->string('meeting_link')->nullable();
            $table->text('notes')->nullable();
            $table->enum('status', ['scheduled', 'completed', 'cancelled'])->default('scheduled');
            $table->text('feedback')->nullable();
            $table->unsignedBigInteger('interviewer_id')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->timestamps();

            // Index pour améliorer les performances
            $table->index('application_id');
            $table->index('interviewer_id');
            $table->index('status');
            $table->index('scheduled_at');
            $table->index('type');
            
            // Clés étrangères
            $table->foreign('application_id')->references('id')->on('recruitment_applications')->onDelete('cascade');
            $table->foreign('interviewer_id')->references('id')->on('users')->onDelete('set null');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('recruitment_interviews');
    }
};



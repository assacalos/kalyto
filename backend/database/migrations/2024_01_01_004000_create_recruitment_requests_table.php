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
        Schema::create('recruitment_requests', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->string('department', 100);
            $table->string('position', 100);
            $table->text('description');
            $table->text('requirements');
            $table->text('responsibilities');
            $table->integer('number_of_positions')->default(1);
            $table->enum('employment_type', ['full_time', 'part_time', 'contract', 'internship'])->default('full_time');
            $table->enum('experience_level', ['entry', 'junior', 'mid', 'senior', 'expert'])->default('mid');
            $table->string('salary_range', 100);
            $table->string('location', 255);
            $table->dateTime('application_deadline');
            $table->enum('status', ['draft', 'published', 'closed', 'cancelled'])->default('draft');
            $table->text('rejection_reason')->nullable();
            $table->timestamp('published_at')->nullable();
            $table->unsignedBigInteger('published_by')->nullable();
            $table->timestamp('approved_at')->nullable();
            $table->unsignedBigInteger('approved_by')->nullable();
            $table->unsignedBigInteger('created_by')->nullable();
            $table->unsignedBigInteger('updated_by')->nullable();
            $table->timestamps();

            // Index pour améliorer les performances
            $table->index('status');
            $table->index('department');
            $table->index('position');
            $table->index('employment_type');
            $table->index('experience_level');
            $table->index('application_deadline');
            
            // Clés étrangères
            $table->foreign('published_by')->references('id')->on('users')->onDelete('set null');
            $table->foreign('approved_by')->references('id')->on('users')->onDelete('set null');
            $table->foreign('created_by')->references('id')->on('users')->onDelete('set null');
            $table->foreign('updated_by')->references('id')->on('users')->onDelete('set null');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('recruitment_requests');
    }
};


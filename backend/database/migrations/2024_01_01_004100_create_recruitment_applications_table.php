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
        Schema::create('recruitment_applications', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('recruitment_request_id');
            $table->string('candidate_name');
            $table->string('candidate_email');
            $table->string('candidate_phone', 50);
            $table->text('candidate_address')->nullable();
            $table->text('cover_letter')->nullable();
            $table->string('resume_path')->nullable();
            $table->string('portfolio_url')->nullable();
            $table->string('linkedin_url')->nullable();
            $table->enum('status', ['pending', 'reviewed', 'shortlisted', 'interviewed', 'rejected', 'hired'])->default('pending');
            $table->text('notes')->nullable();
            $table->text('rejection_reason')->nullable();
            $table->timestamp('reviewed_at')->nullable();
            $table->unsignedBigInteger('reviewed_by')->nullable();
            $table->timestamp('interview_scheduled_at')->nullable();
            $table->timestamp('interview_completed_at')->nullable();
            $table->text('interview_notes')->nullable();
            $table->timestamps();

            // Index pour améliorer les performances
            $table->index('recruitment_request_id');
            $table->index('candidate_email');
            $table->index('status');
            $table->index('reviewed_by');
            
            // Clés étrangères
            $table->foreign('recruitment_request_id')->references('id')->on('recruitment_requests')->onDelete('cascade');
            $table->foreign('reviewed_by')->references('id')->on('users')->onDelete('set null');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('recruitment_applications');
    }
};


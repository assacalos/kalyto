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
        // Vérifier si la table existe déjà
        if (Schema::hasTable('contracts')) {
            // La table existe déjà, on ne fait rien
            return;
        }

        Schema::create('contracts', function (Blueprint $table) {
            $table->id();
            $table->string('contract_number', 100)->unique();
            $table->unsignedBigInteger('employee_id');
            $table->string('employee_name', 255)->nullable();
            $table->string('employee_email', 255)->nullable();
            $table->enum('contract_type', ['permanent', 'fixed_term', 'temporary', 'internship', 'consultant']);
            $table->string('position', 100);
            $table->string('department', 100);
            $table->string('job_title', 100);
            $table->text('job_description');
            $table->decimal('gross_salary', 10, 2);
            $table->decimal('net_salary', 10, 2);
            $table->string('salary_currency', 10)->default('FCFA');
            $table->enum('payment_frequency', ['monthly', 'weekly', 'daily', 'hourly']);
            $table->date('start_date');
            $table->date('end_date')->nullable();
            $table->integer('duration_months')->nullable();
            $table->string('work_location', 255);
            $table->enum('work_schedule', ['full_time', 'part_time', 'flexible']);
            $table->integer('weekly_hours')->nullable();
            $table->enum('probation_period', ['none', '1_month', '3_months', '6_months'])->nullable();
            $table->string('reporting_manager', 255)->nullable();
            $table->text('health_insurance')->nullable();
            $table->text('retirement_plan')->nullable();
            $table->integer('vacation_days')->nullable();
            $table->text('other_benefits')->nullable();
            $table->enum('status', ['draft', 'pending', 'active', 'expired', 'terminated', 'cancelled'])->default('draft');
            $table->text('termination_reason')->nullable();
            $table->date('termination_date')->nullable();
            $table->text('notes')->nullable();
            $table->string('contract_template', 255)->nullable();
            $table->timestamp('approved_at')->nullable();
            $table->unsignedBigInteger('approved_by')->nullable();
            $table->text('rejection_reason')->nullable();
            $table->unsignedBigInteger('created_by')->nullable();
            $table->unsignedBigInteger('updated_by')->nullable();
            $table->timestamps();

            // Foreign keys
            $table->foreign('employee_id')->references('id')->on('employees')->onDelete('cascade');
            $table->foreign('created_by')->references('id')->on('users')->onDelete('set null');
            $table->foreign('updated_by')->references('id')->on('users')->onDelete('set null');
            $table->foreign('approved_by')->references('id')->on('users')->onDelete('set null');

            // Indexes
            $table->index('contract_number');
            $table->index('employee_id');
            $table->index('contract_type');
            $table->index('department');
            $table->index('status');
            $table->index('start_date');
            $table->index('end_date');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('contracts');
    }
};

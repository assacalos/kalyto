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
        // Supprimer les tables existantes et les recréer avec la structure consolidée
        Schema::dropIfExists('payroll_settings');
        Schema::dropIfExists('payrolls');
        Schema::dropIfExists('salary_items');
        Schema::dropIfExists('salaries');
        Schema::dropIfExists('salary_components');
        
        // Créer les tables dans l'ordre correct
        Schema::create('salary_components', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->text('description')->nullable();
            $table->enum('type', ['addition', 'deduction']);
            $table->decimal('amount', 10, 2)->default(0);
            $table->enum('status', ['en_attente', 'valide', 'rejete'])->default('en_attente');
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('salaries', function (Blueprint $table) {
            $table->id();
            $table->string('salary_number')->unique()->nullable();
            $table->unsignedBigInteger('employee_id'); // Référence à la table employees
            $table->string('period')->nullable();
            $table->date('period_start')->nullable();
            $table->date('period_end')->nullable();
            $table->decimal('base_salary', 10, 2);
            $table->decimal('gross_salary', 10, 2)->default(0);
            $table->decimal('net_salary', 10, 2)->default(0);
            $table->decimal('total_allowances', 10, 2)->default(0);
            $table->decimal('total_deductions', 10, 2)->default(0);
            $table->decimal('total_taxes', 10, 2)->default(0);
            $table->decimal('total_social_security', 10, 2)->default(0);
            $table->date('salary_date');
            $table->string('status', 50)->default('draft'); // Changé de enum à string
            $table->text('notes')->nullable();
            $table->json('justificatif')->nullable();
            $table->json('salary_breakdown')->nullable();
            $table->json('components')->nullable();
            $table->timestamp('calculated_at')->nullable();
            $table->timestamp('approved_at')->nullable();
            $table->unsignedBigInteger('approved_by')->nullable();
            $table->timestamp('paid_at')->nullable();
            $table->unsignedBigInteger('paid_by')->nullable();
            $table->timestamps();

            $table->foreign('employee_id')->references('id')->on('employees')->onDelete('cascade');
            $table->foreign('approved_by')->references('id')->on('users')->onDelete('set null');
            $table->foreign('paid_by')->references('id')->on('users')->onDelete('set null');
        });

        Schema::create('salary_items', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('salary_id');
            $table->unsignedBigInteger('component_id');
            $table->decimal('amount', 10, 2);
            $table->timestamps();

            $table->foreign('salary_id')->references('id')->on('salaries')->onDelete('cascade');
            $table->foreign('component_id')->references('id')->on('salary_components')->onDelete('cascade');
        });

        Schema::create('payrolls', function (Blueprint $table) {
            $table->id();
            $table->string('payroll_number')->unique();
            $table->date('payroll_date');
            $table->decimal('total_amount', 10, 2);
            $table->enum('status', ['en_attente', 'valide', 'rejete'])->default('en_attente');
            $table->unsignedBigInteger('user_id');
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
        });

        Schema::create('payroll_settings', function (Blueprint $table) {
            $table->id();
            $table->string('setting_name');
            $table->text('setting_value');
            $table->enum('status', ['en_attente', 'valide', 'rejete'])->default('en_attente');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('payroll_settings');
        Schema::dropIfExists('payrolls');
        Schema::dropIfExists('salary_items');
        Schema::dropIfExists('salaries');
        Schema::dropIfExists('salary_components');
    }
};

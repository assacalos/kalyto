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
        Schema::create('intervention_reports', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('intervention_id');
            $table->unsignedBigInteger('technician_id');
            $table->string('report_number')->unique();
            $table->text('work_performed');
            $table->text('findings')->nullable();
            $table->text('recommendations')->nullable();
            $table->json('parts_used')->nullable();
            $table->decimal('labor_hours', 8, 2)->nullable();
            $table->decimal('parts_cost', 10, 2)->nullable();
            $table->decimal('labor_cost', 10, 2)->nullable();
            $table->decimal('total_cost', 10, 2)->nullable();
            $table->json('photos')->nullable();
            $table->text('client_signature')->nullable();
            $table->text('technician_signature')->nullable();
            $table->datetime('report_date');
            $table->timestamps();
            
            // Clés étrangères
            $table->foreign('intervention_id')->references('id')->on('interventions')->onDelete('cascade');
            $table->foreign('technician_id')->references('id')->on('users')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('intervention_reports');
    }
};


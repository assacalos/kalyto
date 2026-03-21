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
        Schema::create('payment_schedules', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('payment_id');
            $table->date('start_date');
            $table->date('end_date');
            $table->integer('frequency'); // Nombre de jours entre les paiements
            $table->integer('total_installments');
            $table->integer('paid_installments')->default(0);
            $table->decimal('installment_amount', 10, 2);
            $table->enum('status', ['active', 'paused', 'completed', 'cancelled'])->default('active');
            $table->date('next_payment_date')->nullable();
            $table->text('notes')->nullable();
            $table->unsignedBigInteger('created_by');
            $table->unsignedBigInteger('updated_by')->nullable();
            $table->timestamps();

            // Clés étrangères
            $table->foreign('payment_id')->references('id')->on('paiements')->onDelete('cascade');
            $table->foreign('created_by')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('updated_by')->references('id')->on('users')->onDelete('set null');
            
            // Index
            $table->index(['status', 'next_payment_date']);
            $table->index(['payment_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('payment_schedules');
    }
};
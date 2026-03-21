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
        if (Schema::hasTable('leave_balances')) {
            return;
        }

        Schema::create('leave_balances', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('employee_id')->unique();
            $table->integer('annual_leave_days')->default(25);
            $table->integer('used_annual_leave')->default(0);
            $table->integer('remaining_annual_leave')->default(25);
            $table->integer('sick_leave_days')->default(10);
            $table->integer('used_sick_leave')->default(0);
            $table->integer('remaining_sick_leave')->default(10);
            $table->integer('personal_leave_days')->default(5);
            $table->integer('used_personal_leave')->default(0);
            $table->integer('remaining_personal_leave')->default(5);
            $table->timestamp('last_updated')->useCurrent()->useCurrentOnUpdate();
            
            $table->foreign('employee_id')->references('id')->on('employees')->onDelete('cascade');
            $table->index('employee_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('leave_balances');
    }
};

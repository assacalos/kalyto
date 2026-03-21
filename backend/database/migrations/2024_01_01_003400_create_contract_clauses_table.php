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
        if (Schema::hasTable('contract_clauses')) {
            return;
        }

        Schema::create('contract_clauses', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('contract_id');
            $table->string('title', 255);
            $table->text('content');
            $table->enum('type', ['standard', 'custom', 'legal', 'benefit'])->default('standard');
            $table->boolean('is_mandatory')->default(false);
            $table->integer('order')->default(0);
            $table->timestamps();

            // Foreign keys
            $table->foreign('contract_id')->references('id')->on('contracts')->onDelete('cascade');

            // Indexes
            $table->index('contract_id');
            $table->index('type');
            $table->index('order');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('contract_clauses');
    }
};

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('inventory_lines', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('inventory_session_id');
            $table->unsignedBigInteger('stock_id');
            $table->decimal('theoretical_qty', 15, 2)->default(0);
            $table->decimal('counted_qty', 15, 2)->nullable();
            $table->timestamps();

            $table->foreign('inventory_session_id')->references('id')->on('inventory_sessions')->onDelete('cascade');
            $table->foreign('stock_id')->references('id')->on('stocks')->onDelete('cascade');
            $table->unique(['inventory_session_id', 'stock_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('inventory_lines');
    }
};

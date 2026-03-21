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
        Schema::create('bordereau_items', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('bordereau_id');
            $table->string('designation');
            $table->integer('quantite');
            $table->text('description')->nullable();
            $table->timestamps();

            $table->foreign('bordereau_id')->references('id')->on('bordereaus')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('bordereau_items');
    }
};

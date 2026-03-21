<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('inventory_sessions', function (Blueprint $table) {
            $table->id();
            $table->date('date')->nullable();
            $table->string('depot', 100)->nullable();
            $table->string('status', 20)->default('in_progress'); // in_progress | closed
            $table->timestamp('closed_at')->nullable();
            $table->timestamps();
            $table->index('status');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('inventory_sessions');
    }
};

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
        Schema::table('bordereau_items', function (Blueprint $table) {
            $table->string('reference', 100)->nullable()->after('bordereau_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('bordereau_items', function (Blueprint $table) {
            $table->dropColumn('reference');
        });
    }
};

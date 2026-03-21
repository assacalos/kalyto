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
        Schema::table('devis_items', function (Blueprint $table) {
            $table->string('reference', 100)->nullable()->after('devis_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('devis_items', function (Blueprint $table) {
            $table->dropColumn('reference');
        });
    }
};

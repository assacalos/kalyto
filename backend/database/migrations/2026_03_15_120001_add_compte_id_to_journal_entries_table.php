<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Lier les écritures journal à un compte du plan de comptes.
     */
    public function up(): void
    {
        Schema::table('journal_entries', function (Blueprint $table) {
            $table->unsignedBigInteger('compte_id')->nullable()->after('id');
            $table->foreign('compte_id')->references('id')->on('comptes')->onDelete('set null');
            $table->index('compte_id');
        });
    }

    public function down(): void
    {
        Schema::table('journal_entries', function (Blueprint $table) {
            $table->dropForeign(['compte_id']);
            $table->dropColumn('compte_id');
        });
    }
};

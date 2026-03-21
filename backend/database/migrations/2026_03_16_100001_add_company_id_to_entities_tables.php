<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     * Ajoute company_id (nullable) aux tables métier pour le multi-société.
     */
    public function up(): void
    {
        $tables = [
            'clients',
            'factures',
            'paiements',
            'expenses',
            'salaries',
            'journal_entries',
            'bordereaus',
            'devis',
            'inventory_sessions',
        ];

        foreach ($tables as $tableName) {
            if (!Schema::hasTable($tableName)) {
                continue;
            }
            Schema::table($tableName, function (Blueprint $table) use ($tableName) {
                if (Schema::hasColumn($tableName, 'company_id')) {
                    return;
                }
                $table->unsignedBigInteger('company_id')->nullable()->after('id');
                $table->foreign('company_id')->references('id')->on('companies')->onDelete('set null');
                $table->index('company_id');
            });
        }
    }

    public function down(): void
    {
        $tables = [
            'clients',
            'factures',
            'paiements',
            'expenses',
            'salaries',
            'journal_entries',
            'bordereaus',
            'devis',
            'inventory_sessions',
        ];

        foreach (array_reverse($tables) as $tableName) {
            if (!Schema::hasTable($tableName)) {
                continue;
            }
            Schema::table($tableName, function (Blueprint $table) use ($tableName) {
                if (!Schema::hasColumn($tableName, 'company_id')) {
                    return;
                }
                $table->dropForeign(['company_id']);
                $table->dropColumn('company_id');
            });
        }
    }
};

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // Vérifier si la table existe
        if (!Schema::hasTable('employee_documents')) {
            return;
        }

        Schema::table('employee_documents', function (Blueprint $table) {
            // Ajouter les colonnes si elles n'existent pas
            if (!Schema::hasColumn('employee_documents', 'employee_id')) {
                $table->unsignedBigInteger('employee_id')->after('id');
            }
            if (!Schema::hasColumn('employee_documents', 'name')) {
                $table->string('name')->after('employee_id');
            }
            if (!Schema::hasColumn('employee_documents', 'type')) {
                $table->string('type')->nullable()->after('name');
            }
            if (!Schema::hasColumn('employee_documents', 'description')) {
                $table->text('description')->nullable()->after('type');
            }
            if (!Schema::hasColumn('employee_documents', 'file_path')) {
                $table->string('file_path')->nullable()->after('description');
            }
            if (!Schema::hasColumn('employee_documents', 'file_size')) {
                $table->integer('file_size')->nullable()->after('file_path');
            }
            if (!Schema::hasColumn('employee_documents', 'expiry_date')) {
                $table->date('expiry_date')->nullable()->after('file_size');
            }
            if (!Schema::hasColumn('employee_documents', 'is_required')) {
                $table->boolean('is_required')->default(false)->after('expiry_date');
            }
            if (!Schema::hasColumn('employee_documents', 'created_by')) {
                $table->unsignedBigInteger('created_by')->nullable()->after('is_required');
            }
        });

        // Ajouter les clés étrangères
        try {
            Schema::table('employee_documents', function (Blueprint $table) {
                // Vérifier si la clé étrangère existe déjà en essayant de la créer
                try {
                    $table->foreign('employee_id')->references('id')->on('employees')->onDelete('cascade');
                } catch (\Exception $e) {
                    // La clé existe déjà, on ignore
                }
                
                try {
                    $table->foreign('created_by')->references('id')->on('users')->onDelete('set null');
                } catch (\Exception $e) {
                    // La clé existe déjà, on ignore
                }
            });
        } catch (\Exception $e) {
            // Ignorer les erreurs de clés étrangères existantes
        }

        // Ajouter les index
        try {
            Schema::table('employee_documents', function (Blueprint $table) {
                try {
                    $table->index('employee_id');
                } catch (\Exception $e) {
                    // L'index existe déjà
                }
                
                try {
                    $table->index('type');
                } catch (\Exception $e) {
                    // L'index existe déjà
                }
                
                try {
                    $table->index('expiry_date');
                } catch (\Exception $e) {
                    // L'index existe déjà
                }
            });
        } catch (\Exception $e) {
            // Ignorer les erreurs d'index existants
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('employee_documents', function (Blueprint $table) {
            // Supprimer les clés étrangères si elles existent
            try {
                $table->dropForeign(['employee_id']);
            } catch (\Exception $e) {
                // La clé n'existe pas
            }
            
            try {
                $table->dropForeign(['created_by']);
            } catch (\Exception $e) {
                // La clé n'existe pas
            }
            
            // Supprimer les index
            try {
                $table->dropIndex(['employee_id']);
            } catch (\Exception $e) {
                // L'index n'existe pas
            }
            
            try {
                $table->dropIndex(['type']);
            } catch (\Exception $e) {
                // L'index n'existe pas
            }
            
            try {
                $table->dropIndex(['expiry_date']);
            } catch (\Exception $e) {
                // L'index n'existe pas
            }
            
            // Supprimer les colonnes si elles existent
            $columnsToDrop = [];
            if (Schema::hasColumn('employee_documents', 'employee_id')) {
                $columnsToDrop[] = 'employee_id';
            }
            if (Schema::hasColumn('employee_documents', 'name')) {
                $columnsToDrop[] = 'name';
            }
            if (Schema::hasColumn('employee_documents', 'type')) {
                $columnsToDrop[] = 'type';
            }
            if (Schema::hasColumn('employee_documents', 'description')) {
                $columnsToDrop[] = 'description';
            }
            if (Schema::hasColumn('employee_documents', 'file_path')) {
                $columnsToDrop[] = 'file_path';
            }
            if (Schema::hasColumn('employee_documents', 'file_size')) {
                $columnsToDrop[] = 'file_size';
            }
            if (Schema::hasColumn('employee_documents', 'expiry_date')) {
                $columnsToDrop[] = 'expiry_date';
            }
            if (Schema::hasColumn('employee_documents', 'is_required')) {
                $columnsToDrop[] = 'is_required';
            }
            if (Schema::hasColumn('employee_documents', 'created_by')) {
                $columnsToDrop[] = 'created_by';
            }
            
            if (!empty($columnsToDrop)) {
                $table->dropColumn($columnsToDrop);
            }
        });
    }
};

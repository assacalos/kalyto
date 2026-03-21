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
        Schema::table('expense_approvals', function (Blueprint $table) {
            // Vérifier si la colonne approved_by existe et la renommer en approver_id
            if (Schema::hasColumn('expense_approvals', 'approved_by') && !Schema::hasColumn('expense_approvals', 'approver_id')) {
                // Renommer approved_by en approver_id
                DB::statement('ALTER TABLE expense_approvals CHANGE COLUMN approved_by approver_id BIGINT UNSIGNED NOT NULL');
            }
            
            // Ajouter approver_id si elle n'existe pas du tout
            if (!Schema::hasColumn('expense_approvals', 'approver_id')) {
                $table->unsignedBigInteger('approver_id')->after('expense_id');
                $table->foreign('approver_id')->references('id')->on('users')->onDelete('cascade');
            }
            
            // Ajouter approval_level si n'existe pas
            if (!Schema::hasColumn('expense_approvals', 'approval_level')) {
                $table->string('approval_level')->nullable()->after('approver_id');
            }
            
            // Ajouter approval_order si n'existe pas
            if (!Schema::hasColumn('expense_approvals', 'approval_order')) {
                $table->integer('approval_order')->default(1)->after('approval_level');
            }
            
            // Ajouter is_required si n'existe pas
            if (!Schema::hasColumn('expense_approvals', 'is_required')) {
                $table->boolean('is_required')->default(true)->after('approval_order');
            }
            
            // Renommer approved_at en reviewed_at si nécessaire
            if (Schema::hasColumn('expense_approvals', 'approved_at') && !Schema::hasColumn('expense_approvals', 'reviewed_at')) {
                DB::statement('ALTER TABLE expense_approvals CHANGE COLUMN approved_at reviewed_at TIMESTAMP NULL');
            }
            
            // Ajouter reviewed_at si elle n'existe pas du tout
            if (!Schema::hasColumn('expense_approvals', 'reviewed_at')) {
                $table->timestamp('reviewed_at')->nullable()->after('comments');
            }
            
            // Modifier le statut pour utiliser les nouveaux statuts (pending, approved, rejected)
            // au lieu de (en_attente, valide, rejete)
            if (Schema::hasColumn('expense_approvals', 'status')) {
                // Mapper les anciennes valeurs vers les nouvelles
                DB::statement("UPDATE expense_approvals SET status = 'pending' WHERE status = 'en_attente'");
                DB::statement("UPDATE expense_approvals SET status = 'approved' WHERE status = 'valide'");
                DB::statement("UPDATE expense_approvals SET status = 'rejected' WHERE status = 'rejete'");
                
                // Modifier l'enum pour utiliser les nouveaux statuts
                DB::statement("ALTER TABLE expense_approvals MODIFY COLUMN status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending'");
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('expense_approvals', function (Blueprint $table) {
            // Mapper les nouvelles valeurs vers les anciennes
            if (Schema::hasColumn('expense_approvals', 'status')) {
                DB::statement("UPDATE expense_approvals SET status = 'en_attente' WHERE status = 'pending'");
                DB::statement("UPDATE expense_approvals SET status = 'valide' WHERE status = 'approved'");
                DB::statement("UPDATE expense_approvals SET status = 'rejete' WHERE status = 'rejected'");
                
                // Remettre l'ancien enum
                DB::statement("ALTER TABLE expense_approvals MODIFY COLUMN status ENUM('en_attente', 'valide', 'rejete') DEFAULT 'en_attente'");
            }
            
            // Renommer reviewed_at en approved_at si nécessaire
            if (Schema::hasColumn('expense_approvals', 'reviewed_at') && !Schema::hasColumn('expense_approvals', 'approved_at')) {
                DB::statement('ALTER TABLE expense_approvals CHANGE COLUMN reviewed_at approved_at TIMESTAMP NULL');
            }
            
            // Supprimer les colonnes ajoutées
            if (Schema::hasColumn('expense_approvals', 'is_required')) {
                $table->dropColumn('is_required');
            }
            if (Schema::hasColumn('expense_approvals', 'approval_order')) {
                $table->dropColumn('approval_order');
            }
            if (Schema::hasColumn('expense_approvals', 'approval_level')) {
                $table->dropColumn('approval_level');
            }
            
            // Renommer approver_id en approved_by si nécessaire
            if (Schema::hasColumn('expense_approvals', 'approver_id') && !Schema::hasColumn('expense_approvals', 'approved_by')) {
                DB::statement('ALTER TABLE expense_approvals CHANGE COLUMN approver_id approved_by BIGINT UNSIGNED NOT NULL');
            }
        });
    }
};

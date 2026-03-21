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
        Schema::table('devis', function (Blueprint $table) {
            $table->string('titre')->nullable()->after('commentaire');
            $table->string('delai_livraison')->nullable()->after('titre');
            $table->string('garantie')->nullable()->after('delai_livraison');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('devis', function (Blueprint $table) {
            $table->dropColumn(['titre', 'delai_livraison', 'garantie']);
        });
    }
};


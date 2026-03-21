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
        Schema::create('recruitment_documents', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('application_id');
            $table->string('file_name');
            $table->string('file_path');
            $table->string('file_type');
            $table->bigInteger('file_size'); // Taille en bytes
            $table->timestamp('uploaded_at');
            $table->timestamps();

            // Index pour améliorer les performances
            $table->index('application_id');
            $table->index('file_type');
            
            // Clé étrangère
            $table->foreign('application_id')->references('id')->on('recruitment_applications')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('recruitment_documents');
    }
};



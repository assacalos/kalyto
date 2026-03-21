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
        // Supprimer les tables existantes et les recréer avec la structure consolidée
        Schema::dropIfExists('stock_order_items');
        Schema::dropIfExists('stock_orders');
        Schema::dropIfExists('stock_alerts');
        Schema::dropIfExists('stock_movements');
        Schema::dropIfExists('stocks');
        Schema::dropIfExists('stock_categories'); // Supprimer la table des catégories
        
        // Créer les tables dans l'ordre correct (sans stock_categories)
        Schema::create('stocks', function (Blueprint $table) {
            $table->id();
            $table->string('category'); // Champ string au lieu de category_id
            $table->string('name');
            $table->text('description')->nullable();
            $table->string('sku')->unique();
            $table->decimal('quantity', 10, 2)->default(0);
            $table->decimal('min_quantity', 10, 2)->default(0);
            $table->decimal('max_quantity', 10, 2)->default(0);
            $table->decimal('unit_price', 10, 2)->default(0);
            $table->text('commentaire')->nullable();
            $table->enum('status', ['en_attente', 'valide', 'rejete'])->default('en_attente');
            $table->timestamps();
        });

        Schema::create('stock_movements', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('stock_id');
            $table->enum('type', ['in', 'out']);
            $table->decimal('quantity', 10, 2);
            $table->text('reason')->nullable();
            $table->enum('status', ['en_attente', 'valide', 'rejete'])->default('en_attente');
            $table->unsignedBigInteger('user_id');
            $table->timestamps();

            $table->foreign('stock_id')->references('id')->on('stocks')->onDelete('cascade');
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
        });

        Schema::create('stock_alerts', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('stock_id');
            $table->enum('type', ['low_stock', 'out_of_stock', 'expired']);
            $table->text('message');
            $table->enum('status', ['en_attente', 'valide', 'rejete'])->default('en_attente');
            $table->timestamps();

            $table->foreign('stock_id')->references('id')->on('stocks')->onDelete('cascade');
        });

        Schema::create('stock_orders', function (Blueprint $table) {
            $table->id();
            $table->string('order_number')->unique();
            $table->enum('type', ['purchase', 'sale', 'transfer']);
            $table->enum('status', ['en_attente', 'valide', 'rejete'])->default('en_attente');
            $table->decimal('total_amount', 10, 2)->default(0);
            $table->unsignedBigInteger('user_id');
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
        });

        Schema::create('stock_order_items', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('order_id');
            $table->unsignedBigInteger('stock_id');
            $table->decimal('quantity', 10, 2);
            $table->decimal('unit_price', 10, 2);
            $table->decimal('total_price', 10, 2);
            $table->timestamps();

            $table->foreign('order_id')->references('id')->on('stock_orders')->onDelete('cascade');
            $table->foreign('stock_id')->references('id')->on('stocks')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('stock_order_items');
        Schema::dropIfExists('stock_orders');
        Schema::dropIfExists('stock_alerts');
        Schema::dropIfExists('stock_movements');
        Schema::dropIfExists('stocks');
        Schema::dropIfExists('stock_categories');
    }
};

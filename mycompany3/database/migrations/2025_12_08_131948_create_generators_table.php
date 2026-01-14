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
        Schema::create('generators', function (Blueprint $table) {
            $table->id();
            
            // Supplier and generator information
            $table->string('supplier_name');
            $table->string('generator_name');
            $table->string('power_capacity'); // Example: 100KVA, 200KVA
            $table->decimal('monthly_rent', 10, 2);
            $table->decimal('yearly_total', 12, 2)->nullable();
            $table->enum('status', ['Working', 'Broken', 'Under Maintenance', 'Stopped']);
            
            // Fuel consumption
            $table->integer('diesel_consumption_liters_per_hour')->nullable();
            $table->decimal('monthly_diesel_cost', 10, 2)->nullable();
            
            // Relationships with buildings and housing
            $table->foreignId('building_id')->nullable()->constrained('buildings')->onDelete('cascade');
            $table->foreignId('housing_id')->nullable()->constrained('housings')->onDelete('cascade');
            
            // Additional details
            $table->date('installation_date')->nullable();
            $table->date('next_maintenance_date')->nullable();
            $table->integer('maintenance_interval_days')->default(90); // Every 90 days
            $table->integer('operating_hours')->default(0);

            $table->json('attachments')->nullable();
            $table->text('notes')->nullable();
            
            $table->timestamps();

            $table->index(['building_id', 'housing_id']);
            $table->index('status');
        });
    }


    public function down(): void
    {
        Schema::dropIfExists('generators');
    }
};
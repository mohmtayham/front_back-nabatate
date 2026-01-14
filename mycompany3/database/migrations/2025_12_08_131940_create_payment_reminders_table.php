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
        Schema::create('payment_reminders', function (Blueprint $table) {
            $table->id();
            
            // housing_id - required
            $table->foreignId('housing_id')
                  ->constrained('housings')
                  ->cascadeOnDelete();
            
            // building_id - optional
            $table->foreignId('building_id')
                  ->nullable()
                  ->constrained('buildings')
                  ->nullOnDelete();
            
            // Other fields
            $table->enum('payment_type', ['electricity', 'water', 'other']);
            $table->date('due_date');
            $table->decimal('amount', 10, 2);
            $table->boolean('payment_status')->default(false);
            $table->json('attachments')->nullable();
            $table->text('notes')->nullable();
            
            // Optional timestamp for payment completion
            $table->timestamp('paid_at')->nullable();
            
            $table->timestamps();
            
            // Add indexes for better performance
            $table->index(['housing_id', 'building_id']);
            $table->index('payment_status');
            $table->index('due_date');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('payment_reminders');
    }
};
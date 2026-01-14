<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('meters', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('serial_number');


            $table->foreignId('housing_id')->constrained('housings')->cascadeOnDelete();

   
            $table->foreignId('building_id')->nullable()->constrained('buildings')->nullOnDelete();

            $table->string('bill_number')->nullable();
            $table->decimal('bill_amount', 10, 2)->nullable();
            $table->enum('payment_status', ['مسدد', 'غير مسدد', 'مستحق']);
            $table->text('notes')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('meters');
    }
};

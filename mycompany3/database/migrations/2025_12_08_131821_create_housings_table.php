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
Schema::create('housings', function (Blueprint $table) {
    $table->id();
    $table->string('name');
    $table->string('housing_number')->nullable();
    $table->string('address')->nullable();
    $table->integer('buildings_count')->default(0);
    $table->integer('rooms_count')->default(0);
    $table->enum('housing_type', ['ملك', 'إيجار']);
$table->string('housing_license')->nullable();

    $table->decimal('housing_value', 12, 2)->nullable();
    $table->boolean('rent_due')->default(false);
    $table->date('rent_due_date')->nullable();
    $table->boolean('rent_paid')->default(false);
    $table->json('attachments')->nullable();
    $table->text('notes')->nullable();
    $table->timestamps();
});

    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('housings');
    }
};
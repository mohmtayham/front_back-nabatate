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
      Schema::create('cases', function (Blueprint $table) {
    $table->id();
    $table->foreignId('employee_id')->constrained('employees')->cascadeOnDelete();
    $table->string('case_type');
    $table->string('status');
    $table->text('notes')->nullable();
    $table->timestamps();
});

    }

  
    public function down(): void
    {
        Schema::dropIfExists('cases');
    }
};

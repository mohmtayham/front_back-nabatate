<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('employees', function (Blueprint $table) {
            $table->id();
            $table->string('sn')->nullable();
            $table->string('id_name')->nullable();
            $table->string('iqamah_number')->nullable();
            $table->string('id_number')->nullable();
            $table->string('nationality')->nullable();
            $table->string('passport_number')->nullable();
            $table->string('gender')->nullable();
            $table->string('job_title')->nullable();
            $table->string('housing_name')->nullable();
            $table->string('building_id')->nullable();
            $table->string('floor_id')->nullable();
            $table->string('room_id')->nullable();
            $table->string('contract_id')->nullable();
            $table->string('phone_number')->nullable();
            $table->string('email')->nullable();
            $table->date('joining_date')->nullable();
            $table->date('left_date')->nullable();
            $table->string('cases_issues')->nullable();
            $table->string('attachment')->nullable();
            $table->text('note')->nullable();

            // عمود المشروع
            $table->foreignId('project_id')->nullable()->constrained('projects')->nullOnDelete();
            $table->string('project_name')->nullable(); // للحفظ للعرض فقط
            $table->string('project_code')->nullable(); // العمود الجديد

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('employees');
    }
};

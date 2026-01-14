<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class EmployeeCase extends Model
{
    use HasFactory;

    // ✅ ربط الموديل بجدول cases
    protected $table = 'cases';

    protected $fillable = [
        'employee_id',
        'case_type',
        'status',
        'notes',
    ];

    public function employee()
    {
        return $this->belongsTo(Employee::class);
    }
}

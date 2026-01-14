<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class EmployeeAttachment extends Model
{
    use HasFactory;

    protected $fillable = [
        'employee_id',
        'file_path',
        'file_name',
    ];

    public function employee()
    {
        return $this->belongsTo(Employee::class);
    }
}

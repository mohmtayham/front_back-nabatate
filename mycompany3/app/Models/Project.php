<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Project extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'code',
        'location',
        'manager_name',
        'status',
        'notes',
    ];

public function employees()
{
    return $this->hasMany(Employee::class);
}

}

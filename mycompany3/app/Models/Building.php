<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Building extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'housing_id',
        'floors_count',
        'rooms_count',
    ];

    public function housing()
    {
        return $this->belongsTo(Housing::class, 'housing_id');
    }

    public function rooms()
    {
        return $this->hasMany(Room::class, 'building_id');
    }
    public function meters()
{
    return $this->hasMany(Meter::class, 'building_id');
}
   public function employees()
    {
        return $this->hasMany(Employee::class, 'building_id');
    }

     public function generators()
    {
        return $this->hasMany(Generator::class, 'building_id');
    }

}

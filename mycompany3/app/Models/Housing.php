<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Housing extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'housing_type',
        'housing_number',
        'address',
        'buildings_count',
        'rooms_count',
        'housing_license',
        'housing_value',
        'rent_due',
        'rent_due_date',
        'rent_paid',
        'notes',
    ];

    protected $casts = [
        'rent_due' => 'boolean',
        'rent_paid' => 'boolean',
        'buildings_count' => 'integer',
        'rooms_count' => 'integer',
        'housing_value' => 'decimal:2',
    ];

    protected $appends = ['housing_license_url'];

    public function getHousingLicenseUrlAttribute()
    {
        return $this->housing_license
            ? url('storage/' . $this->housing_license)
            : null;
    }

    // علاقة مع المباني
    public function buildings()
    {
        return $this->hasMany(Building::class, 'housing_id');
    }

    // علاقة مع الغرف من خلال المباني
    public function rooms()
    {
        return $this->hasManyThrough(Room::class, Building::class, 'housing_id', 'building_id');
    }
    public function meters()
{
    return $this->hasMany(Meter::class, 'housing_id');
}
    public function housing()
    {
        return $this->belongsTo(Housing::class);
    }


}

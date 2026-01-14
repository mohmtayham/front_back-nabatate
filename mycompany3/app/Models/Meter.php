<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Meter extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'serial_number',
        'housing_id',
        'bill_number',
        'bill_amount',
        'payment_status',
        'notes',
    ];

    protected $casts = [
        'bill_amount' => 'decimal:2',
    ];

  
    public function housing()
{
    return $this->belongsTo(Housing::class);
}

public function building()
{
    return $this->belongsTo(Building::class);
}

    
}

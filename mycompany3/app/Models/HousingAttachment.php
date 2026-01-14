<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class HousingAttachment extends Model
{
    use HasFactory;

    protected $fillable = [
        'housing_id',
        'file_name',
        'file_path',
        'file_size',
        'file_type',
    ];

    protected $appends = ['full_file_path'];

    public function getFullFilePathAttribute()
    {
        return url('storage/' . $this->file_path);
    }

    public function housing()
    {
        return $this->belongsTo(Housing::class);
    }
}
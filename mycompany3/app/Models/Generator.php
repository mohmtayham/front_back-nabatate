<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Generator extends Model
{
    use HasFactory;

    protected $fillable = [
        'supplier_name',
        'generator_name',
        'power_capacity',
        'monthly_rent',
        'yearly_total',
        'status',
        'diesel_consumption_liters_per_hour',
        'monthly_diesel_cost',
        'building_id',
        'housing_id',
        'installation_date',
        'next_maintenance_date',
        'maintenance_interval_days',
        'operating_hours',
        'attachments',
        'notes',
    ];

    protected $casts = [
        'attachments' => 'array',
        'installation_date' => 'date',
        'next_maintenance_date' => 'date',
        'monthly_rent' => 'decimal:2',
        'yearly_total' => 'decimal:2',
        'monthly_diesel_cost' => 'decimal:2',
    ];

    /**
     * العلاقة مع المبنى
     */
    public function building(): BelongsTo
    {
        return $this->belongsTo(Building::class);
    }

    /**
     * العلاقة مع السكن
     */
    public function housing(): BelongsTo
    {
        return $this->belongsTo(Housing::class);
    }

    /**
     * حساب التكلفة الشهرية الإجمالية
     */
    public function getTotalMonthlyCostAttribute(): float
    {
        $total = $this->monthly_rent;
        
        if ($this->monthly_diesel_cost) {
            $total += $this->monthly_diesel_cost;
        }
        
        return $total;
    }

    /**
     * الحصول على الاسم الكامل مع الموقع
     */
    public function getFullNameAttribute(): string
    {
        $location = '';
        
        if ($this->building) {
            $location = " - {$this->building->name}";
        } elseif ($this->housing) {
            $location = " - Housing #{$this->housing->id}";
        }
        
        return "{$this->generator_name}{$location}";
    }

    /**
     * التحقق إذا كان يحتاج صيانة
     */
    public function needsMaintenance(): bool
    {
        if (!$this->next_maintenance_date) {
            return false;
        }
        
        return now()->greaterThanOrEqualTo($this->next_maintenance_date);
    }

    /**
     * جدولة الصيانة القادمة
     */
    public function scheduleNextMaintenance(): void
    {
        $this->next_maintenance_date = now()->addDays($this->maintenance_interval_days);
        $this->save();
    }
}
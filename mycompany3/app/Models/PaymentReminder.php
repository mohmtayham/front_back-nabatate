<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PaymentReminder extends Model
{
    use HasFactory;

    protected $fillable = [
        'housing_id',
        'building_id',
        'payment_type',
        'due_date',
        'amount',
        'payment_status',
        'notes',
        'attachments',
        'paid_at', // ✅ إضافة paid_at
    ];

    protected $casts = [
        'due_date' => 'date',
        'amount' => 'decimal:2',
        'payment_status' => 'boolean',
        'attachments' => 'array',
        'paid_at' => 'datetime', // ✅ إضافة cast لـ paid_at
    ];

    // العلاقات
    public function housing()
    {
        return $this->belongsTo(Housing::class);
    }

    public function building()
    {
        return $this->belongsTo(Building::class);
    }

    /**
     * Accessor للحصول على حالة الدفع كنص
     */
    public function getPaymentStatusTextAttribute()
    {
        return $this->payment_status ? 'Paid' : 'Unpaid';
    }

    /**
     * Accessor للحصول على paid_at كنص
     */
    public function getPaidAtTextAttribute()
    {
        return $this->paid_at ? $this->paid_at->format('Y-m-d H:i:s') : 'Not paid yet';
    }

    /**
     * Accessor للحصول على روابط المرفقات
     */
    public function getAttachmentUrlsAttribute()
    {
        if (empty($this->attachments)) {
            return [];
        }

        $urls = [];
        foreach ($this->attachments as $attachment) {
            $urls[] = [
                'name' => $attachment,
                'url' => asset('storage/attachments/' . $attachment),
            ];
        }

        return $urls;
    }

    /**
     * Scope للفلاتر
     */
    public function scopeFilter($query, $filters)
    {
        if (isset($filters['payment_status'])) {
            $query->where('payment_status', $filters['payment_status']);
        }

        if (isset($filters['payment_type'])) {
            $query->where('payment_type', $filters['payment_type']);
        }

        if (isset($filters['housing_id'])) {
            $query->where('housing_id', $filters['housing_id']);
        }

        if (isset($filters['building_id'])) {
            $query->where('building_id', $filters['building_id']);
        }

        if (isset($filters['date_from'])) {
            $query->where('due_date', '>=', $filters['date_from']);
        }

        if (isset($filters['date_to'])) {
            $query->where('due_date', '<=', $filters['date_to']);
        }

        return $query;
    }

    /**
     * حذف المرفقات من التخزين
     */
    public function deleteAttachments()
    {
        if (empty($this->attachments)) {
            return;
        }

        foreach ($this->attachments as $attachment) {
            $path = storage_path('app/public/attachments/' . $attachment);
            if (file_exists($path)) {
                unlink($path);
            }
        }
    }

    /**
     * التحقق إذا كان التذكير متأخراً
     */
    public function getIsOverdueAttribute()
    {
        return !$this->payment_status && $this->due_date < now();
    }

    /**
     * التحقق إذا كان التذكير مدفوعاً
     */
    public function getIsPaidAttribute()
    {
        return $this->payment_status && $this->paid_at !== null;
    }
}
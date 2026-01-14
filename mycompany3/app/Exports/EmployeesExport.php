<?php

namespace App\Exports;

use App\Models\Employee;
use Maatwebsite\Excel\Concerns\FromQuery;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithMapping;
use Maatwebsite\Excel\Concerns\WithChunkReading;

class EmployeesExport implements 
    FromQuery,
    WithHeadings,
    WithMapping,
    WithChunkReading
{
    protected $search;

    public function __construct($search = null)
    {
        $this->search = $search;
    }

    /**
     * حجم الـ chunk (مهم جدًا للأداء)
     */
    public function chunkSize(): int
    {
        return 1000;
    }

    /**
     * الاستعلام
     */
    public function query()
    {
        $query = Employee::query();

        if (!empty($this->search)) {
            $query->where(function ($q) {
                $q->where('id_name', 'like', '%' . $this->search . '%')
                  ->orWhere('iqamah_number', 'like', '%' . $this->search . '%')
                  ->orWhere('id_number', 'like', '%' . $this->search . '%');
            });
        }

        return $query;
    }

    /**
     * عناوين الأعمدة
     */
    public function headings(): array
    {
        return [
            'ID',
            'S.N',
            'اسم الموظف',
            'رقم الإقامة',
            'رقم الهوية',
            'الجنسية',
            'رقم الجواز',
            'الجنس',
            'المسمى الوظيفي',
            'اسم السكن',
            'رقم المبنى',
            'رقم الطابق',
            'رقم الغرفة',
            'اسم المشروع',
            'كود المشروع',
            'نوع العقد',
            'رقم الهاتف',
            'البريد الإلكتروني',
            'تاريخ الانضمام',
            'تاريخ المغادرة',
            'ملاحظات',
        ];
    }

    /**
     * Mapping لكل صف
     */
    public function map($e): array
    {
        return [
            $e->id,
            $e->sn,
            $e->id_name,
            $e->iqamah_number,
            $e->id_number,
            $e->nationality,
            $e->passport_number,
            $e->gender,
            $e->job_title,
            $e->housing_name,
            $e->building_id,
            $e->floor_id,
            $e->room_id,
            $e->project_name,
            $e->project_code,
            $e->contract_id,
            $e->phone_number,
            $e->email,
            $e->joining_date,
            $e->left_date,
            $e->note,
        ];
    }
}

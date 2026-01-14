<?php

namespace App\Imports;

use App\Models\Employee;
use Maatwebsite\Excel\Concerns\ToCollection;
use Maatwebsite\Excel\Concerns\WithHeadingRow;
use Maatwebsite\Excel\Concerns\WithChunkReading;
use Illuminate\Support\Collection;
use Carbon\Carbon;
use Maatwebsite\Excel\Imports\HeadingRowFormatter;
use Illuminate\Support\Facades\Log;

use Illuminate\Contracts\Queue\ShouldQueue;

class EmployeesImport implements ToCollection, WithHeadingRow, WithChunkReading, ShouldQueue
{
    // ... باقي الكود

    private $imported = 0;
    private $failed = 0;
    private $errors = [];

    public function __construct()
    {
        HeadingRowFormatter::default('slug');
    }

    public function collection(Collection $rows)
    {
        Log::info('📥 Starting Excel import with ' . $rows->count() . ' rows');
        
        $batch = [];

        foreach ($rows as $index => $row) {
            try {
                // ⭐⭐ **تسجيل بيانات الصف للمساعدة في التصحيح** ⭐⭐
                Log::info("Processing row " . ($index + 1) . ": " . json_encode($row));
                
                // ⭐⭐ **المشكلة: contract_id يأتي كنص "Original" ولكن Laravel يتوقع رقم** ⭐⭐
                $contractId = $this->parseContractId($row['contract_id'] ?? null);
                
                // ⭐⭐ **المشكلة: building_id, floor_id, room_id قد تكون نصوص وليست أرقام** ⭐⭐
                $buildingId = $this->parseNumber($row['building_id'] ?? null);
                $floorId = $this->parseNumber($row['floor_id'] ?? null);
                $roomId = $this->parseNumber($row['room_id'] ?? null);
                
                $employeeData = [
                    'sn' => $this->cleanValue($row['s_n'] ?? null),
                    'id_name' => $this->cleanValue($row['id_name'] ?? null, true),
                    'iqamah_number' => $this->cleanValue($row['iqamah_number'] ?? null),
                    'id_number' => $this->cleanValue($row['id_number'] ?? null),
                    'nationality' => $this->cleanValue($row['nationality'] ?? null),
                    'passport_number' => $this->cleanValue($row['passport_number'] ?? null),
                    'gender' => $this->parseGender($row['gender'] ?? null),
                    'job_title' => $this->cleanValue($row['job_title'] ?? null),
                    'housing_name' => $this->cleanValue($row['housing_name'] ?? null),
                    
                    // ⭐⭐ **المشكلة تم إصلاحها: تحويل القيم الرقمية** ⭐⭐
                    'building_id' => $buildingId,
                    'floor_id' => $floorId,
                    'room_id' => $roomId,
                    
                    'project_name' => $this->cleanValue($row['project_name'] ?? null),
                    'project_code' => $this->cleanValue($row['project_code'] ?? null),
                    
                    // ⭐⭐ **المشكلة الرئيسية: contract_id** ⭐⭐
                    'contract_id' => $contractId,
                    
                    'phone_number' => $this->formatPhone($row['phone_number'] ?? null),
                    'email' => $this->cleanEmail($row['email'] ?? null),
                    'joining_date' => $this->parseDate($row['joining_date'] ?? null),
                    'left_date' => $this->parseDate($row['left_date'] ?? null),
                    'cases_issues' => $this->cleanValue($row['cases_issues'] ?? null),
                    'attachment' => $this->cleanValue($row['attachment'] ?? null),
                    'note' => $this->cleanValue($row['note'] ?? null),
                    'created_at' => now(),
                    'updated_at' => now(),
                ];
                
                // ⭐⭐ **تسجيل البيانات بعد المعالجة** ⭐⭐
                Log::info("Processed row data: " . json_encode($employeeData));
                
                $batch[] = $employeeData;
                $this->imported++;

            } catch (\Exception $e) {
                $this->failed++;
                $errorMessage = "سطر " . ($index + 1) . ": " . $e->getMessage();
                $this->errors[] = $errorMessage;
                
                // ⭐⭐ **تسجيل الخطأ بالتفصيل** ⭐⭐
                Log::error("Import error at row " . ($index + 1) . ": " . $e->getMessage());
                Log::error("Row data: " . json_encode($row));
                Log::error("Trace: " . $e->getTraceAsString());
            }
        }

        if (!empty($batch)) {
            try {
                Log::info("Inserting batch of " . count($batch) . " employees");
                Employee::insert($batch);
                Log::info("✅ Batch inserted successfully");
            } catch (\Exception $e) {
                Log::error("🔥 Batch insert failed: " . $e->getMessage());
                Log::error("🔥 Batch data sample: " . json_encode($batch[0] ?? []));
                throw $e;
            }
        }
    }

    // ⭐⭐ **الدالة الجديدة: معالجة contract_id** ⭐⭐
    private function parseContractId($contractId)
    {
        if (!$contractId || $contractId === 'يحتاج لتعبئة') {
            return 'يحتاج لتعبئة';
        }
        
        $contractId = trim((string)$contractId);
        
        // إذا كان رقم، أرجعه كما هو
        if (is_numeric($contractId)) {
            return $contractId;
        }
        
        // تحويل النصوص إلى أرقام
        $contractMap = [
            'original' => 1,
            'Original' => 1,
            'أصلي' => 1,
            'rental' => 2,
            'Rental' => 2,
            'إيجار' => 2,
            'external' => 3,
            'External' => 3,
            'خارجي' => 3,
        ];
        
        $lowerContractId = strtolower($contractId);
        
        // حاول العثور على تطابق
        foreach ($contractMap as $key => $value) {
            if (strtolower($key) === $lowerContractId) {
                return $value;
            }
        }
        
        // إذا لم يتطابق، حاول البحث جزئياً
        if (str_contains($lowerContractId, 'origin') || str_contains($contractId, 'أصلي')) {
            return 1;
        }
        if (str_contains($lowerContractId, 'rent') || str_contains($contractId, 'إيجار')) {
            return 2;
        }
        if (str_contains($lowerContractId, 'extern') || str_contains($contractId, 'خارجي')) {
            return 3;
        }
        
        // إذا فشل كل شيء، أرجع النص الأصلي
        return $contractId;
    }

    // ⭐⭐ **الدالة الجديدة: تحويل القيم الرقمية** ⭐⭐
    private function parseNumber($value)
    {
        if (!$value || $value === 'يحتاج لتعبئة' || trim($value) === '') {
            return null;
        }
        
        $value = trim((string)$value);
        
        // إذا كان رقم بالفعل
        if (is_numeric($value)) {
            return (int)$value;
        }
        
        // إذا كان نص يحتوي على أرقام فقط
        if (preg_match('/^\d+$/', $value)) {
            return (int)$value;
        }
        
        // إذا كان نص مثل "123-ABC" أو "B-1"
        if (preg_match('/\d+/', $value, $matches)) {
            return (int)$matches[0];
        }
        
        // إذا فشل التحويل، أرجع النص
        return $value;
    }

    // ⭐⭐ **الدالة الجديدة: تنظيف القيم** ⭐⭐
    private function cleanValue($value, $required = false)
    {
        if (!$value || trim($value) === '') {
            return $required ? 'يحتاج لتعبئة' : null;
        }
        
        $value = trim((string)$value);
        
        // تحويل "null" أو "NULL" أو "Null" إلى null حقيقي
        if (strtolower($value) === 'null') {
            return $required ? 'يحتاج لتعبئة' : null;
        }
        
        // تحويل "undefined" أو "N/A" إلى null
        if (strtolower($value) === 'undefined' || 
            strtolower($value) === 'n/a' || 
            strtolower($value) === 'na') {
            return $required ? 'يحتاج لتعبئة' : null;
        }
        
        return $value;
    }

    // ⭐⭐ **الدالة الجديدة: تنظيف البريد الإلكتروني** ⭐⭐
    private function cleanEmail($email)
    {
        if (!$email || trim($email) === '') {
            return null;
        }
        
        $email = trim($email);
        
        // تحقق من صحة البريد الإلكتروني
        if (filter_var($email, FILTER_VALIDATE_EMAIL)) {
            return $email;
        }
        
        // إذا كان غير صالح، أرجع null
        return null;
    }

    private function parseGender($gender)
    {
        if (!$gender) return 'يحتاج لتعبئة';
        $gender = strtolower(trim((string)$gender));
        if (in_array($gender, ['ذكر', 'male', 'm', 'رجل', 'ذكرى', 'mذكر'])) return 'ذكر';
        if (in_array($gender, ['أنثى', 'female', 'f', 'امرأة', 'انثى', 'fأنثى'])) return 'أنثى';
        
        // محاولة اكتشاف الجنس من النص
        if (str_contains($gender, 'ذكر') || str_contains($gender, 'male') || str_contains($gender, 'm')) {
            return 'ذكر';
        }
        if (str_contains($gender, 'أنثى') || str_contains($gender, 'female') || str_contains($gender, 'f')) {
            return 'أنثى';
        }
        
        return 'يحتاج لتعبئة';
    }

    private function parseDate($date)
    {
        if (!$date || trim($date) === '') {
            return null;
        }
        
        try {
            // إذا كان تاريخ Excel (رقم)
            if (is_numeric($date)) {
                $unixTimestamp = ($date - 25569) * 86400;
                return Carbon::createFromTimestamp($unixTimestamp)->format('Y-m-d');
            }
            
            $date = trim((string)$date);
            
            // محاولة تحليل التاريخ بعدة صيغ
            $formats = [
                'Y-m-d',
                'd/m/Y',
                'd-m-Y',
                'm/d/Y',
                'Y/m/d',
                'd F Y',
                'F d, Y',
            ];
            
            foreach ($formats as $format) {
                try {
                    $carbonDate = Carbon::createFromFormat($format, $date);
                    if ($carbonDate !== false) {
                        return $carbonDate->format('Y-m-d');
                    }
                } catch (\Exception $e) {
                    continue;
                }
            }
            
            // محاولة باستخدام strtotime كحل أخير
            $timestamp = strtotime($date);
            if ($timestamp !== false) {
                return date('Y-m-d', $timestamp);
            }
            
            return null;
        } catch (\Exception $e) {
            Log::warning("Date parsing failed for '$date': " . $e->getMessage());
            return null;
        }
    }

    private function formatPhone($phone)
    {
        if (!$phone || $phone === 'يحتاج لتعبئة') return 'يحتاج لتعبئة';
        
        $phone = trim((string)$phone);
        
        // إزالة جميع الأحرف غير الرقمية إلا علامة +
        $phone = preg_replace('/[^0-9+]/', '', $phone);
        
        if (empty($phone)) return 'يحتاج لتعبئة';

        // إذا بدأ بـ 00966 أو +966
        if (str_starts_with($phone, '00966')) {
            return '+966' . substr($phone, 5);
        }
        
        if (str_starts_with($phone, '+966')) {
            return $phone;
        }

        // إذا بدأ بـ 05 (رقم سعودي)
        if (str_starts_with($phone, '05')) {
            return '+966' . substr($phone, 1);
        }

        // إذا بدأ بـ 5 وطوله 9 أرقام
        if (str_starts_with($phone, '5') && strlen($phone) == 9) {
            return '+966' . $phone;
        }

        // إذا كان طوله 10 أرقام وبدون رمز الدولة
        if (strlen($phone) == 10 && str_starts_with($phone, '0')) {
            return '+966' . substr($phone, 1);
        }

        return $phone;
    }

    public function chunkSize(): int
    {
        return 2000; // تقليل الحجم للمعالجة الأفضل
    }

    public function getImportedCount()
    {
        return $this->imported;
    }

    public function getFailedCount()
    {
        return $this->failed;
    }

    public function getErrors()
    {
        return $this->errors;
    }
}
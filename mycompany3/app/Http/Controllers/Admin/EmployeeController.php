<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Employee;
use App\Models\EmployeeAttachment;
use Illuminate\Support\Facades\Storage;
use App\Imports\EmployeesImport; 
use App\Exports\EmployeesExport;
use App\Models\Housing;
use Illuminate\Support\Facades\Log;
use Maatwebsite\Excel\Facades\Excel;
use Illuminate\Support\Str;
use Symfony\Component\HttpFoundation\StreamedResponse;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Support\Facades\Auth;
use ZipArchive;





class EmployeeController extends Controller
{
public function index(Request $request)
{
    try {
        Log::info('--- بدأت عملية جلب الموظفين ---');
        Log::info('المستخدم الحالي: ' . Auth::id());

        // التحقق من الصلاحية قبل البدء
      if (!Auth::user()->hasPermission('view_employees') && !Auth::user()->hasPermission('view_all')) { // تطابق مع مصفوفة الصلاحيات لديك
            Log::warning('فشل الصلاحية للمستخدم: ' . Auth::id());
            return response()->json(['message' => 'Forbidden'], 403);
        }

        // استخدام select لتخفيف العبء عن الذاكرة ومنع جلب بيانات ضخمة غير ضرورية
        $query = Employee::with('attachments')
            ->select('id', 'id_name', 'iqamah_number', 'id_number', 'job_title') 
            ->whereNotNull('id_name')
            ->where('id_name', '!=', 'يحتاج لتعبئة');

        if ($request->filled('search')) {
            $query->where(function($q) use ($request) {
                $q->where('id_name', 'like', "%{$request->search}%")
                  ->orWhere('iqamah_number', 'like', "%{$request->search}%");
            });
        }

        // تحديد العدد بـ 15 سجل فقط للتجربة وضمان عدم انهيار الذاكرة
        $employees = $query->paginate(15);

        Log::info('تم جلب البيانات بنجاح. العدد في هذه الصفحة: ' . $employees->count());

        return response()->json([
            'status' => 'success',
            'employees' => $employees
        ]);

    } catch (\Exception $e) {
        Log::error('خطأ فادح في EmployeeController@index: ' . $e->getMessage());
        Log::error($e->getTraceAsString()); // سيظهر لك السطر المسبب للمشكلة في الـ logs

        return response()->json([
            'status' => 'error',
            'message' => 'حدث خطأ في الخادم: ' . $e->getMessage()
        ], 500);
    }
}
public function bulkDelete(Request $request)
{
    $request->validate(['ids' => 'required|array']);
    Employee::whereIn('id', $request->ids)->each(function ($emp) {
    $emp->attachments()->delete(); // حذف المرفقات أولاً
    $emp->delete();
});

    return response()->json(['status' => 'success', 'message' => 'تم حذف الموظفين المحددين']);
}

public function bulkTransfer(Request $request)
{
    $request->validate([
        'ids' => 'required|array',
        'housing_id' => 'required|exists:housings,id',
    ]);

    Employee::whereIn('id', $request->ids)->update([
        'housing_id' => $request->housing_id,
        'housing_name' => Housing::find($request->housing_id)?->name,
        // أضف building/floor/room لو عايز
    ]);

    return response()->json(['status' => 'success', 'message' => 'تم نقل الموظفين بنجاح']);
}
public function export(Request $request)
{
   while (ob_get_level() > 0) {
        ob_end_clean();
    }

    $fileName = 'employees_' . now()->format('Y-m-d_H-i-s') . '.xlsx';

    return Excel::download(
        new EmployeesExport($request->search),
        $fileName
    );
}

    public function download($file)
    {
        $path = "exports/{$file}";

        if (!Storage::disk('public')->exists($path)) {
            abort(404, 'File not found');
        }

        return Storage::disk('public')->download($path);
    }
  
    public function show($id)
    {
        if (!Auth::user()->hasPermission('show_employees')) {
            return response()->json([
                'status' => 'error',
                'message' => 'Forbidden'
            ], 403);
        }

        $employee = Employee::with(['attachments', 'project', 'housing', 'building'])->find($id);
        
        if (!$employee) {
            return response()->json([
                'status' => 'error',
                'message' => 'Employee not found'
            ], 404);
        }
        
        return response()->json([
            'status' => 'success',
            'employee' => $employee
        ]);
    }
    

    public function import(Request $request)
    {
        $request->validate([
            'file' => 'required|file|mimes:xlsx,xls,csv|max:102400',
        ]);

        try {
            $file = $request->file('file');
            $importer = new EmployeesImport();
            Excel::import($importer, $file);

            return response()->json([
                'status' => 'success',
                'message' => 'File imported successfully',
                'data' => [
                    'imported' => $importer->getImportedCount(),
                    'failed' => $importer->getFailedCount(),
                    'errors' => $importer->getErrors(),
                    'file_name' => $file->getClientOriginalName(),
                    'file_size' => $this->formatBytes($file->getSize()),
                    'import_time' => now()->format('Y-m-d H:i:s')
                ]
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Import error',
                'error' => $e->getMessage()
            ], 500);
        }
    }

  


    public function uploadAttachment(Request $request, $id)
    {
        $request->validate([
            'file' => 'required|file|max:10240',
        ]);

        $employee = Employee::find($id);
        
        if (!$employee) {
            return response()->json([
                'status' => 'error',
                'message' => 'Employee not found'
            ], 404);
        }

        $path = $request->file('file')->store('employee_attachments', 'public');

        $attachment = $employee->attachments()->create([
            'file_name' => $request->file('file')->getClientOriginalName(),
            'file_path' => $path,
            'file_size' => $request->file('file')->getSize(),
            'file_type' => $request->file('file')->getClientMimeType(),
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'File uploaded successfully',
            'attachment' => $attachment
        ]);
    }

    public function deleteAttachment($attachment_id)
    {
        $attachment = EmployeeAttachment::find($attachment_id);

        if (!$attachment) {
            return response()->json([
                'status' => 'error',
                'message' => 'Attachment not found'
            ], 404);
        }

        if (Storage::disk('public')->exists($attachment->file_path)) {
            Storage::disk('public')->delete($attachment->file_path);
        }

        $attachment->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Attachment deleted successfully'
        ]);
    }

    public function attachments($id)
    {
        $employee = Employee::with('attachments')->find($id);
        
        if (!$employee) {
            return response()->json([
                'status' => 'error',
                'message' => 'Employee not found'
            ], 404);
        }

        return response()->json([
            'status' => 'success',
            'employee' => $employee->id_name,
            'attachments' => $employee->attachments
        ]);
    }


public function store(Request $request)
{
    // تحويل contract_id إلى الحالة الصحيحة
    if ($request->has('contract_id') && $request->contract_id !== null) {
        $request->merge([
            'contract_id' => $this->normalizeContractId($request->contract_id)
        ]);
    }
    
    $data = $request->validate([
        'sn' => 'nullable|string|max:50',
        'id_name' => 'nullable|string|max:255', // ⭐⭐ غيرت من required إلى nullable ⭐⭐
        'iqamah_number' => 'nullable|string|max:50',
        'id_number' => 'nullable|string|max:50',
        'nationality' => 'nullable|string|max:50',
        'passport_number' => 'nullable|string|max:50',
        'gender' => 'nullable|in:ذكر,أنثى', // ⭐⭐ غيرت من required إلى nullable ⭐⭐
        'job_title' => 'nullable|string|max:100',
        'housing_name' => 'nullable|string|max:100',
        'building_id' => 'nullable|string|max:50',
        'floor_id' => 'nullable|string|max:50',
        'room_id' => 'nullable|string|max:50',
        'project_id' => 'nullable|exists:projects,id',
        'project_name' => 'nullable|string|max:100',
        'project_code' => 'nullable|string|max:50',
        'contract_id' => 'nullable|in:Original,Rental,External,original,rental,external',
        'phone_number' => 'nullable|string|max:20',
        'email' => 'nullable|email|max:100',
        'joining_date' => 'nullable|date',
        'left_date' => 'nullable|date',
        'cases_issues' => 'nullable|string',
        'note' => 'nullable|string',
    ]);

    // تعيين القيم الافتراضية للحقول المطلوبة سابقاً
    if (empty($data['id_name'])) {
        $data['id_name'] = 'يحتاج لتعبئة';
    }
    
    if (empty($data['gender'])) {
        $data['gender'] = 'يحتاج لتعبئة';
    }
    
    // تأكد من توحيد الحالة لـ contract_id إذا كان موجوداً
    if (!empty($data['contract_id'])) {
        $data['contract_id'] = ucfirst(strtolower($data['contract_id']));
    }

    $employee = Employee::create($data);

    return response()->json([
        'status' => 'success',
        'message' => 'تمت إضافة الموظف بنجاح',
        'employee' => $employee
    ], 201);
}

public function update(Request $request, $id)
{
    if (!Auth::user()->hasPermission('update_employees')) {
        return response()->json([
            'message' => 'Forbidden you do not have permission to update employees'
        ], 403);
    }
    $employee = Employee::find($id);
    
    if (!$employee) {
        return response()->json([
            'status' => 'error',
            'message' => 'الموظف غير موجود'
        ], 404);
    }

    // تحويل contract_id إلى الحالة الصحيحة
    if ($request->has('contract_id') && $request->contract_id !== null) {
        $request->merge([
            'contract_id' => $this->normalizeContractId($request->contract_id)
        ]);
    }

    $data = $request->validate([
        'sn' => 'nullable|string|max:50',
        'id_name' => 'nullable|string|max:255', // ⭐⭐ غيرت من required إلى nullable ⭐⭐
        'iqamah_number' => 'nullable|string|max:50',
        'id_number' => 'nullable|string|max:50',
        'nationality' => 'nullable|string|max:50',
        'passport_number' => 'nullable|string|max:50',
        'gender' => 'nullable|in:ذكر,أنثى', // ⭐⭐ غيرت من required إلى nullable ⭐⭐
        'job_title' => 'nullable|string|max:100',
        'housing_name' => 'nullable|string|max:100',
        'building_id' => 'nullable|string|max:50',
        'floor_id' => 'nullable|string|max:50',
        'room_id' => 'nullable|string|max:50',
        'project_id' => 'nullable|exists:projects,id',
        'project_name' => 'nullable|string|max:100',
        'project_code' => 'nullable|string|max:50',
        'contract_id' => 'nullable|in:Original,Rental,External,original,rental,external',
        'phone_number' => 'nullable|string|max:20',
        'email' => 'nullable|email|max:100',
        'joining_date' => 'nullable|date',
        'left_date' => 'nullable|date',
        'cases_issues' => 'nullable|string',
        'note' => 'nullable|string',
    ]);

    // لا نغير القيم الموجودة إذا كانت فارغة
    foreach ($data as $key => $value) {
        if ($value === null || $value === '') {
            unset($data[$key]); // لا نحدث الحقل إذا كان فارغاً
        }
    }
    
    // تأكد من توحيد الحالة لـ contract_id إذا كان موجوداً
    if (!empty($data['contract_id'])) {
        $data['contract_id'] = ucfirst(strtolower($data['contract_id']));
    }

    $employee->update($data);

    return response()->json([
        'status' => 'success',
        'message' => 'تم تحديث بيانات الموظف بنجاح',
        'employee' => $employee
    ]);
}

   public function deleteAllEmployees()
    {
        if (!Auth::user()->hasPermission('delete_employees')) {
            return response()->json([
                'status' => 'error',
                'message' => 'Forbidden'
            ], 403);
        }
        try {
            // حذف الموظفين على دفعات 100 لتقليل الضغط على السيرفر
            Employee::chunkById(100, function($employees) {
                foreach ($employees as $emp) {
                    $emp->delete();
                }
            });

            return response()->json([
                'status' => 'success',
                'message' => 'All employees deleted successfully',
                'success' => true,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Failed to delete all employees: ' . $e->getMessage(),
                'success' => false,
            ]);
        }
    }

/**
 * دالة مساعدة لتوحيد حالة contract_id
 */
private function normalizeContractId($contractId)
{
    if (empty($contractId)) {
        return null;
    }
    
    $contractId = strtolower(trim($contractId));
    
    $map = [
        'original' => 'Original',
        'rental' => 'Rental', 
        'external' => 'External',
        'أصلي' => 'Original',
        'إيجار' => 'Rental',
        'خارجي' => 'External',
    ];
    
    return $map[$contractId] ?? ucfirst($contractId);
}

    public function destroy($id)
    {
        if (!Auth::user()->hasPermission('delete_employees')) {
            return response()->json([
                'status' => 'error',
                'message' => 'Forbidden'
            ], 403);
        }
        $employee = Employee::find($id);
        
        if (!$employee) {
            return response()->json([
                'status' => 'error',
                'message' => 'Employee not found'
            ], 404);
        }
        
        $employee->attachments()->each(function ($attachment) {
            if (Storage::disk('public')->exists($attachment->file_path)) {
                Storage::disk('public')->delete($attachment->file_path);
            }
            $attachment->delete();
        });
        
        $employee->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Employee deleted successfully'
        ]);
    }

    private function formatBytes($bytes, $precision = 2)
    {
        $units = ['B', 'KB', 'MB', 'GB'];
        $bytes = max($bytes, 0);
        $pow = floor(($bytes ? log($bytes) : 0) / log(1024));
        $pow = min($pow, count($units) - 1);
        $bytes /= pow(1024, $pow);

        return round($bytes, $precision) . ' ' . $units[$pow];
    }
    //   return Storage::disk('public')->download(
    //                     $attachment->file_path,
    //                     $attachment->file_name
    //                 );

    public function downloadAttachment($attachment_id)
    {
        Log::info("Download Attachment ID: " . $attachment_id);
        
        try {
            $attachment = EmployeeAttachment::find($attachment_id);
            
            if (!$attachment) {
                Log::error("Attachment not found: " . $attachment_id);
                return response()->json([
                    'status' => 'error',
                    'message' => 'Attachment not found'
                ], 404);
            }
            
            $filePath = 'app/public/' . $attachment->file_path;
            $fullPath = storage_path($filePath);
            
            if (file_exists($fullPath)) {
                return response()->download(
                    $fullPath,
                    $attachment->file_name,
                    [
                        'Content-Type' => mime_content_type($fullPath) ?: 'application/octet-stream',
                        'Content-Disposition' => 'attachment; filename="' . $attachment->file_name . '"',
                    ]
                );
            } else {
                
                if (Storage::disk('public')->exists($attachment->file_path)) {
                /** @noinspection PhpUndefinedMethodInspection */

            return Storage::disk('public')->download(
                        $attachment->file_path,
                        $attachment->file_name
                    ); 
                } else {
                    Log::error("File not found: " . $fullPath);
                    
                    return response()->json([
                        'status' => 'error',
                        'message' => 'File not found'
                    ], 404);
                }
            }
            
        } catch (\Exception $e) {
            Log::error("Download error: " . $e->getMessage());
            
            return response()->json([
                'status' => 'error',
                'message' => 'Download error: ' . $e->getMessage()
            ], 500);
        }


    }
    
  public function countEmployeesWithName()
{
    try {
        // حساب فقط الموظفين الذين لديهم بيانات فعلية
        $countWithName = Employee::where('id_name', '!=', 'يحتاج لتعبئة')
                                ->whereNotNull('id_name')
                                ->count();
        
        $totalEmployees = Employee::count();
        
        return response()->json([
            'status' => 'success',
            'data' => [
                'count_with_name' => $countWithName,
                'total_employees' => $totalEmployees, // تأكد من هذا الرقم في الـ Database
                'percentage' => $totalEmployees > 0 ? round(($countWithName / $totalEmployees) * 100, 2) : 0,
            ]
        ]);
    } catch (\Exception $e) {
        return response()->json(['status' => 'error', 'message' => $e->getMessage()], 500);
    }
}
public function batchDelete(Request $request) {
  $request->validate([
    'ids' => 'required|array',
    'ids.*' => 'integer|exists:employees,id',
  ]);

  Employee::whereIn('id', $request->ids)->delete();

  return response()->json([
    'success' => true,
    'message' => 'تم الحذف بنجاح',
  ]);
}

public function batchUpdateHousing(Request $request) {
  $request->validate([
    'ids' => 'required|array',
    'ids.*' => 'integer|exists:employees,id',
    'housing_name' => 'required|string',
  ]);

  Employee::whereIn('id', $request->ids)->update([
    'housing_name' => $request->housing_name,
  ]);

  return response()->json([
    'success' => true,
    'message' => 'تم التحديث بنجاح',
  ]);
}








public function printAll()
{
    if (!Auth::user()->hasPermission('print_employees')) {
        return response()->json([
            'message' => 'Forbidden'
        ], 403);
    }
    try {

        // 🔍 Log كل شيء
        Log::info('PRINT EMPLOYEES REQUEST', [
            'auth_check' => Auth::check(),
            'user' => Auth::user(),
            'guard' => Auth::getDefaultDriver(),
            'headers' => request()->headers->all(),
        ]);

        $user = Auth::user();

        if (!$user) {
            Log::warning('PRINT FAILED: No authenticated user');
            return response()->json([
                'message' => 'Unauthenticated'
            ], 401);
        }

        if (!$user->hasPermission('print_employees')) {
            Log::warning('PRINT FAILED: No permission', [
                'user_id' => $user->id,
                'permissions' => $user->permissions ?? null,
            ]);

            return response()->json([
                'message' => 'Forbidden'
            ], 403);
        }

        Log::info('PRINT ALLOWED', [
            'user_id' => $user->id
        ]);

        // ✅ كود الطباعة هنا
          if (!Auth::user()->hasPermission('print_employees')) {
        return response()->json([
            'message' => 'Forbidden'
        ], 403);
    }
    set_time_limit(0);
    ini_set('memory_limit', '1024M');

    $MAX_EMPLOYEES = 1500;
    $CHUNK_SIZE = 150;

    $zipFileName = 'employees_' . now()->format('Ymd_His') . '.zip';
    $zipPath = storage_path("app/$zipFileName");

    $zip = new ZipArchive();
    $zip->open($zipPath, ZipArchive::CREATE | ZipArchive::OVERWRITE);

    $page = 1;
    $processed = 0;

    Employee::with(['housing', 'building', 'room'])
        ->orderBy('id')
        ->chunk($CHUNK_SIZE, function ($employees) use (
            &$zip,
            &$page,
            &$processed,
            $MAX_EMPLOYEES
        ) {

            // stop at 2000
            if ($processed >= $MAX_EMPLOYEES) {
                return false; // stop chunking
            }

            // trim chunk if exceeds limit
            if ($processed + $employees->count() > $MAX_EMPLOYEES) {
                $employees = $employees->take($MAX_EMPLOYEES - $processed);
            }

            $pdf = Pdf::loadView('pdf.employees', [
                'employees' => $employees,
                'page' => $page,
            ])->setPaper('A4', 'landscape');

            $zip->addFromString(
                "employees_page_$page.pdf",
                $pdf->output()
            );

            $processed += $employees->count();
            $page++;
        });

    $zip->close();

    return response()->download($zipPath)->deleteFileAfterSend(true);
        return response()->json([
            'message' => 'Print started'
        ]);

    } catch (\Throwable $e) {

        Log::error('PRINT EXCEPTION', [
            'message' => $e->getMessage(),
            'file' => $e->getFile(),
            'line' => $e->getLine(),
            'trace' => $e->getTraceAsString(),
        ]);

        return response()->json([
            'message' => 'Server error'
        ], 500);
    }
}

}
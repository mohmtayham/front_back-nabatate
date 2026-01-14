<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Admin\AuthController;
use App\Http\Controllers\Admin\UserController;
use App\Http\Controllers\Admin\EmployeeController;
use App\Http\Controllers\Admin\HousingController;
use App\Http\Controllers\Admin\BuildingController;
use App\Http\Controllers\Admin\RoomController;
use App\Http\Controllers\Admin\ProjectController;
use App\Http\Controllers\Admin\EmployeeCaseController;
use App\Http\Controllers\Admin\MeterController;
use App\Http\Controllers\Admin\PaymentReminderController;
use App\Http\Controllers\Admin\GeneratorController;
use App\Http\Controllers\Admin\EmployeeFilterController; 

use App\Http\Controllers\EmployeeExportController;

Route::prefix('admin')->group(function () {
    Route::post('/login', [AuthController::class, 'login']);
});
Route::prefix('admin')->group(function () {
  Route::post('/employees/batch-update-housing', [EmployeeController::class, 'batchUpdateHousing']);
  Route::post('/employees/batch-delete', [EmployeeController::class, 'batchDelete']);

});
Route::post('/signUp', [AuthController::class, 'singnUp']);
// routes/web.php
Route::middleware('auth:sanctum')->group(function () {

    Route::post('/admin/change-password', [AuthController::class, 'changePassword']);

});

Route::get('admin/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');
Route::post('/admin/remaberPassword', [AuthController::class, 'remaberPassword']);

Route::middleware('auth:sanctum')->group(function () {

Route::patch('/givePermissions/{user}', [UserController::class, 'givePermissionsByAdmin']);
});
Route::middleware('auth:sanctum')->group(function () {


});

Route::prefix('employees')->group(function () {
    Route::get('/', [EmployeeController::class, 'index']); // عرض جميع الموظفين
    Route::get('/{id}', [EmployeeController::class, 'show']); // عرض موظف واحد
});

Route::prefix('admin')->middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/users', [UserController::class, 'index']);
});

Route::prefix('admin')->middleware('auth:sanctum')->group(function () {
    Route::get('/users', [UserController::class, 'index']);
    Route::post('/users', [UserController::class, 'store']);
    Route::get('/users/{user}', [UserController::class, 'show']);
    Route::put('/users/{user}', [UserController::class, 'update']);
    Route::delete('/users/{user}', [UserController::class, 'destroy']);


        Route::get('/employees/count-with-name', [EmployeeController::class, 'countEmployeesWithName']); 
    });

        Route::delete('/employees/delete-all', [EmployeeController::class, 'deleteAllEmployees']);


Route::prefix('admin')->middleware('auth:sanctum')->group(function () {
    // ==================== Routes الخاصة بالفلترة ====================
    Route::get('/employees/filter-options', [EmployeeFilterController::class, 'getFilterOptions']); // تغيير الـ Controller
    Route::get('/employees/filter', [EmployeeFilterController::class, 'filter']); // تغيير الـ Controller
    Route::get('/employees/distinct-values', [EmployeeFilterController::class, 'getDistinctValues']);
// إضافة API جديدة
    

    // ==================== CRUD الأساسية ====================
    Route::apiResource('/employees', EmployeeController::class)->except(['show', 'update', 'destroy']);
    
    // ==================== Routes بمعلمة ID مع constraint ====================
    Route::get('/employees/{employee}', [EmployeeController::class, 'show'])
        ->whereNumber('employee');
    
    Route::put('/employees/{employee}', [EmployeeController::class, 'update'])
        ->whereNumber('employee');
    
    Route::delete('/employees/{employee}', [EmployeeController::class, 'destroy'])
        ->whereNumber('employee');
    
    // ==================== Routes المرفقات ====================
    Route::get('/employees/{employee}/attachments', [EmployeeController::class, 'attachments'])
        ->whereNumber('employee');
    
    Route::post('/employees/{employee}/attachments', [EmployeeController::class, 'uploadAttachment'])
        ->whereNumber('employee');
    
    Route::delete('/attachments/{attachment}', [EmployeeController::class, 'deleteAttachment'])
        ->whereNumber('attachment');
    
    Route::get('employee/attachment/download/{attachment}', [EmployeeController::class, 'downloadAttachment'])
        ->whereNumber('attachment');
    
    // ==================== Routes أخرى ====================
    Route::post('/employees/import', [EmployeeController::class, 'import']);
 
 
});

Route::prefix('admin')->middleware('auth:sanctum')->group(function () {
    Route::get('/employees/export', [EmployeeController::class, 'export']);
});
Route::get('/exports/{file}', [EmployeeController::class, 'download']);


Route::prefix('admin')->middleware('auth:sanctum')->group(function () {
    Route::get('/housings', [HousingController::class, 'index']);
    Route::post('/housings', [HousingController::class, 'store']);
    Route::get('/housings/{id}', [HousingController::class, 'show']);
    Route::post('/housings/{id}', [HousingController::class, 'update']);
    Route::delete('/housings/{id}', [HousingController::class, 'destroy']);
    Route::get('/housings/{id}/attachments', [HousingController::class, 'getAttachments']);
});

Route::prefix('admin')->group(function () {
    Route::get('/buildings', [BuildingController::class, 'index']);
    Route::post('/buildings', [BuildingController::class, 'store']);
    Route::put('/buildings/{id}', [BuildingController::class, 'update']);
    Route::delete('/buildings/{id}', [BuildingController::class, 'destroy']);
});

Route::prefix('admin')->group(function () {
    Route::get('/rooms', [RoomController::class, 'index']);
    Route::post('/rooms', [RoomController::class, 'store']);
    Route::put('/rooms/{id}', [RoomController::class, 'update']);
    Route::delete('/rooms/{id}', [RoomController::class, 'destroy']);
});

Route::prefix('admin')->group(function () {
    Route::get('/projects', [ProjectController::class, 'index']);
    Route::post('/projects', [ProjectController::class, 'store']);
    Route::put('/projects/{id}', [ProjectController::class, 'update']);
    Route::delete('/projects/{id}', [ProjectController::class, 'destroy']);
});
Route::middleware('auth:sanctum')->group(function () {
Route::prefix('admin')->group(function () {
    Route::get('/employees/print', [EmployeeController::class, 'printAll']);
    
     Route::delete('/employees/delete-all', [EmployeeController::class, 'deleteAllEmployees']);
});
});

Route::prefix('admin')->group(function () {

    Route::get(
        '/employees/{employee}/cases',
        [EmployeeCaseController::class, 'index']
    );

    Route::post(
        '/employees/{employee}/cases',
        [EmployeeCaseController::class, 'store']
    );

    Route::put(
        '/cases/{employeeCase}',
        [EmployeeCaseController::class, 'update']
    );
Route::middleware('auth:sanctum')->group(function () {

    Route::delete(
        '/cases/{employeeCase}',
        [EmployeeCaseController::class, 'destroy']
    );
});
});


Route::prefix('admin')->group(function () {
    Route::get('/meters', [MeterController::class, 'index']);
    Route::get('/meters/{id}', [MeterController::class, 'show']);
    Route::post('/meters', [MeterController::class, 'store']);
    Route::put('/meters/{id}', [MeterController::class, 'update']);
    Route::delete('/meters/{id}', [MeterController::class, 'destroy']);
});

Route::prefix('admin')->group(function () {
    Route::apiResource('payment-reminders', PaymentReminderController::class);
    
    // طرق إضافية للملفات
    Route::get('payment-reminders/{id}/attachments', [PaymentReminderController::class, 'getAttachments']);
    Route::post('payment-reminders/{id}/upload-attachments', [PaymentReminderController::class, 'uploadAttachments']);
    Route::post('payment-reminders/{id}/delete-attachments', [PaymentReminderController::class, 'deleteAttachments']);
    Route::get('payment-reminders/{id}/download/{fileName}', [PaymentReminderController::class, 'downloadAttachment']);
});

Route::prefix('admin')->group(function () {
    Route::apiResource('generators', GeneratorController::class);
    
    // Additional routes
    Route::get('generators/building/{buildingId}', [GeneratorController::class, 'getByBuilding']);
    Route::get('generators/housing/{housingId}', [GeneratorController::class, 'getByHousing']);
    Route::get('generators/status/{status}', [GeneratorController::class, 'getByStatus']);
    Route::get('generators/needing-maintenance', [GeneratorController::class, 'getNeedingMaintenance']);
    Route::get('generators/{id}/download/{fileName}', [GeneratorController::class, 'downloadAttachment']);
    Route::post('generators/{id}/upload-attachments', [GeneratorController::class, 'uploadAttachments']);
    Route::post('generators/{id}/delete-attachments', [GeneratorController::class, 'deleteAttachments']);
    Route::get('generators/statistics', [GeneratorController::class, 'statistics']);
    Route::post('generators/{id}/mark-maintenance', [GeneratorController::class, 'markForMaintenance']);
    Route::post('generators/{id}/complete-maintenance', [GeneratorController::class, 'completeMaintenance']);
});

Route::get('/employees/{id}', [EmployeeController::class, 'show']);

// Fallback route
Route::fallback(function () {
    return response()->json([
        'status' => 'error',
        'message' => 'API endpoint not found'
    ], 404);
});
<?php
namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Employee;
use App\Models\EmployeeCase;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class EmployeeCaseController extends Controller
{
    /**
     * List cases for one employee
     */
   public function index(Employee $employee)
{
    $cases = $employee->cases()
        ->latest()
        ->paginate(20);

    return response()->json([
        'status' => 'success',
        'cases' => $cases
    ]);
}


    /**
     * Store new case for employee
     */
    public function store(Request $request, Employee $employee)
    {
        $data = $request->validate([
            'case_type' => 'required|string|max:255',
            'status' => 'required|string|max:50',
            'notes' => 'nullable|string',
        ]);

        $case = $employee->cases()->create($data);

        return response()->json([
            'status' => 'success',
            'case' => $case
        ], 201);
    }

    /**
     * Update case
     */
    public function update(Request $request, EmployeeCase $employeeCase)
    {
        $data = $request->validate([
            'case_type' => 'required|string|max:255',
            'status' => 'required|string|max:50',
            'notes' => 'nullable|string',
        ]);

        $employeeCase->update($data);

        return response()->json([
            'status' => 'success',
            'case' => $employeeCase
        ]);
    }

    /**
     * Delete case
     */
    public function destroy(EmployeeCase $employeeCase)
    {
        if (!Auth::user()->hasPermission('delete_cases')) {
            return response()->json([
                'status' => 'error',
                'message' => 'Forbidden'
            ], 403);
        }
        
        
        $employeeCase->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'تم حذف القضية بنجاح'
        ]);
    }
}

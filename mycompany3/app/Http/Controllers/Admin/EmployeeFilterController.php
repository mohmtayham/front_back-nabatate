<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Employee;
use App\Models\Project;
use App\Models\Building;
use App\Models\Housing;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class EmployeeFilterController extends Controller
{
    /**
     * Get filter options
     */
    public function getFilterOptions()
    {
        try {
            $employee = new Employee();
            $options = $employee->getFilterOptions();

            return response()->json([
                'status' => 'success',
                'filters' => $options
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Failed to get filter options',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Search employees with filters and relations
     */
    public function filter(Request $request)
    {
        try {
            Log::info('Filter request parameters:', $request->all());
            
            // Start with all employees
            $query = Employee::query()->with(['project', 'building', 'housing']);
            
            Log::info('Total employees before filters: ' . $query->count());
            
            // Apply search filter
            if ($request->has('search') && !empty($request->search)) {
                Log::info('Applying search filter: ' . $request->search);
                $query->where(function($q) use ($request) {
                    $q->where('id_name', 'like', '%' . $request->search . '%')
                      ->orWhere('id_number', 'like', '%' . $request->search . '%')
                      ->orWhere('iqamah_number', 'like', '%' . $request->search . '%')
                      ->orWhere('job_title', 'like', '%' . $request->search . '%');
                });
            }
            
            // Apply project filter - دعم project_id و project_name
            if ($request->has('project_id') && !empty($request->project_id)) {
                Log::info('Applying project id filter: ' . $request->project_id);
                $query->where('project_id', $request->project_id);
            }
            
            if ($request->has('project_name') && !empty($request->project_name)) {
                Log::info('Applying project name filter: ' . $request->project_name);
                $query->where('project_name', $request->project_name);
            }
            
            // Apply building filter
            if ($request->has('building_id') && !empty($request->building_id)) {
                Log::info('Applying building filter: ' . $request->building_id);
                $query->where('building_id', $request->building_id);
            }
            
            // Apply housing filter
            if ($request->has('housing_id') && !empty($request->housing_id)) {
                Log::info('Applying housing filter: ' . $request->housing_id);
                $query->where('housing_id', $request->housing_id);
            }
            
            // دعم housing_name
            if ($request->has('housing_name') && !empty($request->housing_name)) {
                Log::info('Applying housing name filter: ' . $request->housing_name);
                $housing = Housing::where('name', $request->housing_name)->first();
                if ($housing) {
                    $query->where('housing_id', $housing->id);
                } else {
                    $query->where('housing_name', $request->housing_name);
                }
            }
            
            // Apply contract type filter
            if ($request->has('contract_type') && !empty($request->contract_type)) {
                Log::info('Applying contract type filter: ' . $request->contract_type);
                $query->where('contract_id', $request->contract_type);
            }
            
            // دعم contract_id مباشرة
            if ($request->has('contract_id') && !empty($request->contract_id)) {
                Log::info('Applying contract id filter: ' . $request->contract_id);
                $query->where('contract_id', $request->contract_id);
            }
            
            // Count after filters
            $countAfterFilters = $query->count();
            Log::info('Total employees after filters: ' . $countAfterFilters);
            
            // Apply sorting
            $sortBy = $request->get('sort_by', 'created_at');
            $sortOrder = $request->get('sort_order', 'desc');
            
            $allowedSortColumns = ['id_name', 'joining_date', 'created_at', 'id_number', 'job_title'];
            if (!in_array($sortBy, $allowedSortColumns)) {
                $sortBy = 'created_at';
            }
            
            $query->orderBy($sortBy, $sortOrder);
            
            // Pagination
            $perPage = $request->get('per_page', 20);
            $perPage = max(1, min(100, $perPage));
            $page = $request->get('page', 1);
            
            // Get SQL for debugging
            $sql = $query->toSql();
            $bindings = $query->getBindings();
            Log::info('SQL Query: ' . $sql);
            Log::info('Query Bindings: ', $bindings);
            
            // Get paginated results
            $employees = $query->paginate($perPage, ['*'], 'page', $page);
            
            // Calculate statistics
            $contractStats = [
                'total' => $countAfterFilters,
                'original' => (clone $query)->where('contract_id', 'original')->count(),
                'rental' => (clone $query)->where('contract_id', 'rental')->count(),
                'external' => (clone $query)->where('contract_id', 'external')->count(),
            ];
            
            // Format employees for response
            $formattedEmployees = $employees->map(function ($employee) {
                return [
                    'id' => $employee->id,
                    'sn' => $employee->sn,
                    'id_name' => $employee->id_name,
                    'iqamah_number' => $employee->iqamah_number,
                    'id_number' => $employee->id_number,
                    'nationality' => $employee->nationality,
                    'job_title' => $employee->job_title,
                    'housing_id' => $employee->housing_id,
                    'housing_name' => $employee->housing_name,
                    'building_id' => $employee->building_id,
                    'project_id' => $employee->project_id,
                    'project_name' => $employee->project_name,
                    'contract_id' => $employee->contract_id,
                    'contract_name' => $employee->getContractNameAttribute(),
                    'phone_number' => $employee->phone_number,
                    'email' => $employee->email,
                    'joining_date' => $employee->joining_date ? $employee->joining_date->format('Y-m-d') : null,
                    'created_at' => $employee->created_at->format('Y-m-d H:i:s'),
                    'project' => $employee->project ? [
                        'id' => $employee->project->id,
                        'name' => $employee->project->name
                    ] : null,
                    'building' => $employee->building ? [
                        'id' => $employee->building->id,
                        'name' => $employee->building->name
                    ] : null,
                    'housing' => $employee->housing ? [
                        'id' => $employee->housing->id,
                        'name' => $employee->housing->name
                    ] : null,
                ];
            });
            
            return response()->json([
                'status' => 'success',
                'debug' => [
                    'total_before_filters' => Employee::count(),
                    'total_after_filters' => $countAfterFilters,
                    'sql_query' => $sql,
                    'query_bindings' => $bindings,
                    'request_params' => $request->all(),
                ],
                'employees' => [
                    'data' => $formattedEmployees,
                    'current_page' => $employees->currentPage(),
                    'last_page' => $employees->lastPage(),
                    'per_page' => $employees->perPage(),
                    'total' => $employees->total(),
                ],
                'total' => $employees->total(),
                'contract_stats' => $contractStats,
                'current_page' => $employees->currentPage(),
                'last_page' => $employees->lastPage(),
                'per_page' => $employees->perPage(),
            ]);
            
        } catch (\Exception $e) {
            Log::error('Filter error: ' . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'Error in search',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get all distinct values for specific fields
     */
    public function getDistinctValues(Request $request)
    {
        try {
            $field = $request->get('field');
            
            // جميع الحقول المسموح بها
            $allowedFields = [
                'housing_name', 
                'job_title', 
                'nationality',
                'building_id',
                'project_name',
                'project_id',
                'contract_id',
                'contract_type',
                'id_name',
                'id_number',
                'iqamah_number',
                'phone_number',
                'email',
                'gender',
                'passport_number',
                'floor_id',
                'room_id',
                'project_code',
            ];
            
            if (!in_array($field, $allowedFields)) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Invalid field requested. Allowed fields: ' . implode(', ', $allowedFields)
                ], 400);
            }
            
            // استعلام خاص لاستبعاد القيم الفارغة وغير المرغوبة
            $query = Employee::query()
                ->select($field)
                ->whereNotNull($field)
                ->where($field, '!=', '')
                ->where($field, '!=', 'يحتاج لتعبئة');
            
            // ترتيب خاص للمباني
            if ($field === 'building_id') {
                $query->distinct()->orderByRaw("CAST($field AS UNSIGNED), $field");
            } else {
                $query->distinct()->orderBy($field);
            }
            
            $values = $query->pluck($field)
                ->map(function ($value) {
                    return [
                        'name' => $value,
                        'value' => $value,
                        'display_name' => $value
                    ];
                })
                ->toArray();
            
            Log::info("Distinct values for $field: " . count($values) . " found");
            
            // لـ project_name، يمكننا إضافة خيار "كل المشاريع"
            if ($field === 'project_name' && !empty($values)) {
                array_unshift($values, [
                    'name' => 'كل المشاريع',
                    'value' => '',
                    'display_name' => 'كل المشاريع'
                ]);
            }
            
            // لـ building_id، إضافة خيار "كل المباني"
            if ($field === 'building_id' && !empty($values)) {
                array_unshift($values, [
                    'name' => 'كل المباني',
                    'value' => '',
                    'display_name' => 'كل المباني'
                ]);
            }
            
            return response()->json([
                'status' => 'success',
                'field' => $field,
                'values' => $values
            ]);
            
        } catch (\Exception $e) {
            Log::error('Failed to get distinct values: ' . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'Failed to get distinct values',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get comprehensive filter options including distinct values
     */
    public function getEnhancedFilterOptions()
    {
        try {
            // جلب جميع الخيارات دفعة واحدة
            $distinctFields = ['project_name', 'building_id', 'housing_name', 'job_title', 'nationality', 'contract_id'];
            $allOptions = [];
            
            foreach ($distinctFields as $field) {
                try {
                    $result = $this->getDistinctValues(new Request(['field' => $field]));
                    $data = json_decode($result->getContent(), true);
                    
                    if ($data['status'] === 'success') {
                        $allOptions[$field] = $data['values'];
                    }
                } catch (\Exception $e) {
                    Log::warning("Failed to get distinct values for $field: " . $e->getMessage());
                }
            }
            
            // الحصول على الخيارات الأساسية
            $employee = new Employee();
            $basicOptions = $employee->getFilterOptions();
            
            // دمج النتائج
            $mergedOptions = array_merge($basicOptions, $allOptions);
            
            return response()->json([
                'status' => 'success',
                'filters' => $mergedOptions
            ]);
            
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Failed to get enhanced filter options',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
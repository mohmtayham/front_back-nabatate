<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Generator;
use App\Models\Building;
use App\Models\Housing;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class GeneratorController extends Controller
{
    /**
     * Display all generators
     */
    public function index()
    {
        $generators = Generator::with(['building', 'housing'])
            ->latest()
            ->get();
        
        return response()->json([
            'success' => true,
            'data' => $generators,
            'count' => $generators->count()
        ]);
    }

    /**
     * Create new generator - FIXED VERSION
     */
    public function store(Request $request)
    {
        // ⭐⭐⭐ FIX: Handle empty building_id and housing_id before validation ⭐⭐⭐
        if ($request->has('building_id') && ($request->building_id === '' || $request->building_id === '0')) {
            $request->merge(['building_id' => null]);
        }
        
        if ($request->has('housing_id') && ($request->housing_id === '' || $request->housing_id === '0')) {
            $request->merge(['housing_id' => null]);
        }

        $validator = Validator::make($request->all(), [
            'supplier_name' => 'required|string|max:255',
            'generator_name' => 'required|string|max:255',
            'power_capacity' => 'required|string|max:100',
            'monthly_rent' => 'required|numeric|min:0',
            'yearly_total' => 'nullable|numeric|min:0',
            'status' => 'required|in:Working,Broken,Under Maintenance,Stopped',
            'diesel_consumption_liters_per_hour' => 'nullable|integer|min:0',
            'monthly_diesel_cost' => 'nullable|numeric|min:0',
            // ⭐⭐⭐ FIX: Changed from exists to integer to allow null ⭐⭐⭐
            'building_id' => 'nullable|integer',
            'housing_id' => 'nullable|integer',
            'installation_date' => 'nullable|date',
            'next_maintenance_date' => 'nullable|date',
            'maintenance_interval_days' => 'nullable|integer|min:1',
            'operating_hours' => 'nullable|integer|min:0',
            'notes' => 'nullable|string',
            'attachments' => 'nullable|array',
            'attachments.*' => 'nullable|file|mimes:jpg,jpeg,png,pdf,doc,docx,xls,xlsx|max:5120',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors()
            ], 422);
        }

        $validated = $validator->validated();

        // ⭐⭐⭐ FIX: Check if building_id exists if provided ⭐⭐⭐
        if (!empty($validated['building_id']) && $validated['building_id'] > 0) {
            if (!Building::where('id', $validated['building_id'])->exists()) {
                $validated['building_id'] = null;
            }
        } else {
            $validated['building_id'] = null;
        }

        // ⭐⭐⭐ FIX: Check if housing_id exists if provided ⭐⭐⭐
        if (!empty($validated['housing_id']) && $validated['housing_id'] > 0) {
            if (!Housing::where('id', $validated['housing_id'])->exists()) {
                $validated['housing_id'] = null;
            }
        } else {
            $validated['housing_id'] = null;
        }

        // Process attachments
        $attachments = [];
        if ($request->hasFile('attachments')) {
            foreach ($request->file('attachments') as $file) {
                if ($file->isValid()) {
                    $fileName = 'generator_' . time() . '_' . Str::random(10) . '.' . $file->getClientOriginalExtension();
                    $file->storeAs('public/generators', $fileName);
                    $attachments[] = $fileName;
                }
            }
        }

        $validated['attachments'] = !empty($attachments) ? $attachments : null;

        // Calculate yearly total if not provided
        if (empty($validated['yearly_total']) && !empty($validated['monthly_rent'])) {
            $validated['yearly_total'] = $validated['monthly_rent'] * 12;
        }

        // Set next maintenance date if not provided
        if (empty($validated['next_maintenance_date']) && !empty($validated['installation_date'])) {
            $interval = $validated['maintenance_interval_days'] ?? 90;
            $validated['next_maintenance_date'] = \Carbon\Carbon::parse($validated['installation_date'])
                ->addDays($interval);
        }

        $generator = Generator::create($validated);

        return response()->json([
            'success' => true,
            'message' => 'Generator created successfully',
            'data' => $generator->load(['building', 'housing'])
        ], 201);
    }

    /**
     * Display specific generator
     */
    public function show($id)
    {
        $generator = Generator::with(['building', 'housing'])->find($id);

        if (!$generator) {
            return response()->json([
                'success' => false,
                'message' => 'Generator not found'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $generator
        ]);
    }

    /**
     * Update generator - FIXED VERSION
     */
    public function update(Request $request, $id)
    {
        $generator = Generator::find($id);

        if (!$generator) {
            return response()->json([
                'success' => false,
                'message' => 'Generator not found'
            ], 404);
        }

        // ⭐⭐⭐ FIX: Handle empty building_id and housing_id before validation ⭐⭐⭐
        if ($request->has('building_id') && ($request->building_id === '' || $request->building_id === '0')) {
            $request->merge(['building_id' => null]);
        }
        
        if ($request->has('housing_id') && ($request->housing_id === '' || $request->housing_id === '0')) {
            $request->merge(['housing_id' => null]);
        }

        $validator = Validator::make($request->all(), [
            'supplier_name' => 'sometimes|string|max:255',
            'generator_name' => 'sometimes|string|max:255',
            'power_capacity' => 'sometimes|string|max:100',
            'monthly_rent' => 'sometimes|numeric|min:0',
            'yearly_total' => 'nullable|numeric|min:0',
            'status' => 'sometimes|in:Working,Broken,Under Maintenance,Stopped',
            'diesel_consumption_liters_per_hour' => 'nullable|integer|min:0',
            'monthly_diesel_cost' => 'nullable|numeric|min:0',
            // ⭐⭐⭐ FIX: Changed from exists to integer ⭐⭐⭐
            'building_id' => 'nullable|integer',
            'housing_id' => 'nullable|integer',
            'installation_date' => 'nullable|date',
            'next_maintenance_date' => 'nullable|date',
            'maintenance_interval_days' => 'nullable|integer|min:1',
            'operating_hours' => 'nullable|integer|min:0',
            'notes' => 'nullable|string',
            'attachments' => 'nullable|array',
            'attachments.*' => 'nullable|file|mimes:jpg,jpeg,png,pdf,doc,docx,xls,xlsx|max:5120',
            'delete_attachments' => 'nullable|array',
            'delete_attachments.*' => 'string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors()
            ], 422);
        }

        $validated = $validator->validated();

        // ⭐⭐⭐ FIX: Check if building_id exists if provided ⭐⭐⭐
        if (!empty($validated['building_id']) && $validated['building_id'] > 0) {
            if (!Building::where('id', $validated['building_id'])->exists()) {
                $validated['building_id'] = null;
            }
        } else {
            $validated['building_id'] = null;
        }

        // ⭐⭐⭐ FIX: Check if housing_id exists if provided ⭐⭐⭐
        if (!empty($validated['housing_id']) && $validated['housing_id'] > 0) {
            if (!Housing::where('id', $validated['housing_id'])->exists()) {
                $validated['housing_id'] = null;
            }
        } else {
            $validated['housing_id'] = null;
        }

        // Delete specified attachments
        if (!empty($validated['delete_attachments'])) {
            $currentAttachments = $generator->attachments ?? [];
            foreach ($validated['delete_attachments'] as $fileName) {
                $path = storage_path('app/public/generators/' . $fileName);
                if (file_exists($path)) {
                    unlink($path);
                }
                // Remove from array
                $currentAttachments = array_diff($currentAttachments, [$fileName]);
            }
            $validated['attachments'] = array_values($currentAttachments);
        }

        // Add new attachments
        $newAttachments = [];
        if ($request->hasFile('attachments')) {
            foreach ($request->file('attachments') as $file) {
                if ($file->isValid()) {
                    $fileName = 'generator_' . time() . '_' . Str::random(10) . '.' . $file->getClientOriginalExtension();
                    $file->storeAs('public/generators', $fileName);
                    $newAttachments[] = $fileName;
                }
            }
            
            // Merge new files with old ones
            $currentAttachments = $validated['attachments'] ?? ($generator->attachments ?? []);
            $validated['attachments'] = array_merge($currentAttachments, $newAttachments);
        }

        // Recalculate yearly total if monthly rent changed
        if (isset($validated['monthly_rent']) && empty($validated['yearly_total'])) {
            $validated['yearly_total'] = $validated['monthly_rent'] * 12;
        }

        $generator->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Generator updated successfully',
            'data' => $generator->fresh(['building', 'housing'])
        ]);
    }

    /**
     * Delete generator
     */
    public function destroy($id)
    {
        $generator = Generator::find($id);

        if (!$generator) {
            return response()->json([
                'success' => false,
                'message' => 'Generator not found'
            ], 404);
        }

        // Delete attachments
        if ($generator->attachments) {
            foreach ($generator->attachments as $fileName) {
                $path = storage_path('app/public/generators/' . $fileName);
                if (file_exists($path)) {
                    unlink($path);
                }
            }
        }

        $generator->delete();

        return response()->json([
            'success' => true,
            'message' => 'Generator deleted successfully'
        ]);
    }

    /**
     * Get generators by building
     */
    public function getByBuilding($buildingId)
    {
        $generators = Generator::with(['building', 'housing'])
            ->where('building_id', $buildingId)
            ->latest()
            ->get();

        return response()->json([
            'success' => true,
            'data' => $generators,
            'count' => $generators->count()
        ]);
    }

    /**
     * Get generators by housing
     */
    public function getByHousing($housingId)
    {
        $generators = Generator::with(['building', 'housing'])
            ->where('housing_id', $housingId)
            ->latest()
            ->get();

        return response()->json([
            'success' => true,
            'data' => $generators,
            'count' => $generators->count()
        ]);
    }

    /**
     * Get generators by status
     */
    public function getByStatus($status)
    {
        $validator = Validator::make(['status' => $status], [
            'status' => 'required|in:Working,Broken,Under Maintenance,Stopped'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid status',
                'errors' => $validator->errors()
            ], 422);
        }

        $generators = Generator::with(['building', 'housing'])
            ->where('status', $status)
            ->latest()
            ->get();

        return response()->json([
            'success' => true,
            'data' => $generators,
            'count' => $generators->count()
        ]);
    }

    /**
     * Get generators needing maintenance
     */
    public function getNeedingMaintenance()
    {
        $generators = Generator::with(['building', 'housing'])
            ->where('next_maintenance_date', '<=', now())
            ->orWhere('status', 'Under Maintenance')
            ->latest()
            ->get();

        return response()->json([
            'success' => true,
            'data' => $generators,
            'count' => $generators->count()
        ]);
    }

    /**
     * Upload attachments separately
     */
    public function uploadAttachments(Request $request, $id)
    {
        $generator = Generator::find($id);

        if (!$generator) {
            return response()->json([
                'success' => false,
                'message' => 'Generator not found'
            ], 404);
        }

        $validator = Validator::make($request->all(), [
            'attachments' => 'required|array',
            'attachments.*' => 'required|file|mimes:jpg,jpeg,png,pdf,doc,docx,xls,xlsx|max:5120',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors()
            ], 422);
        }

        $newAttachments = [];
        foreach ($request->file('attachments') as $file) {
            if ($file->isValid()) {
                $fileName = 'generator_' . time() . '_' . Str::random(10) . '.' . $file->getClientOriginalExtension();
                $file->storeAs('public/generators', $fileName);
                $newAttachments[] = $fileName;
            }
        }

        // Merge new files with old ones
        $currentAttachments = $generator->attachments ?? [];
        $generator->attachments = array_merge($currentAttachments, $newAttachments);
        $generator->save();

        return response()->json([
            'success' => true,
            'message' => 'Files uploaded successfully',
            'data' => $generator
        ]);
    }
     
    /**
     * Delete attachments separately
     */
    public function deleteAttachments(Request $request, $id)
    {
        $generator = Generator::find($id);

        if (!$generator) {
            return response()->json([
                'success' => false,
                'message' => 'Generator not found'
            ], 404);
        }

        $validator = Validator::make($request->all(), [
            'file_names' => 'required|array',
            'file_names.*' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid data',
                'errors' => $validator->errors()
            ], 422);
        }

        $currentAttachments = $generator->attachments ?? [];
        foreach ($request->file_names as $fileName) {
            $path = storage_path('app/public/generators/' . $fileName);
            if (file_exists($path)) {
                unlink($path);
            }
            // Remove from array
            $currentAttachments = array_diff($currentAttachments, [$fileName]);
        }

        $generator->attachments = array_values($currentAttachments);
        $generator->save();

        return response()->json([
            'success' => true,
            'message' => 'Files deleted successfully',
            'data' => $generator
        ]);
    }

    /**
     * Download attachment
     */
    public function downloadAttachment($id, $fileName)
    {
        $generator = Generator::find($id);

        if (!$generator) {
            return response()->json([
                'success' => false,
                'message' => 'Generator not found'
            ], 404);
        }

        if (!in_array($fileName, $generator->attachments ?? [])) {
            return response()->json([
                'success' => false,
                'message' => 'File not found'
            ], 404);
        }

        $path = storage_path('app/public/generators/' . $fileName);
        
        if (!file_exists($path)) {
            return response()->json([
                'success' => false,
                'message' => 'File not found'
            ], 404);
        }

        return response()->download($path, $fileName);
    }

    /**
     * Get statistics
     */
    public function statistics()
    {
        $totalGenerators = Generator::count();
        $working = Generator::where('status', 'Working')->count();
        $broken = Generator::where('status', 'Broken')->count();
        $underMaintenance = Generator::where('status', 'Under Maintenance')->count();
        $stopped = Generator::where('status', 'Stopped')->count();
        
        $totalMonthlyRent = Generator::sum('monthly_rent');
        $totalYearlyCost = Generator::sum('yearly_total');
        $totalMonthlyDieselCost = Generator::sum('monthly_diesel_cost');
        
        $totalMonthlyCost = $totalMonthlyRent + $totalMonthlyDieselCost;
        $totalYearlyCostEstimated = $totalMonthlyCost * 12;

        return response()->json([
            'success' => true,
            'data' => [
                'counts' => [
                    'total' => $totalGenerators,
                    'working' => $working,
                    'broken' => $broken,
                    'under_maintenance' => $underMaintenance,
                    'stopped' => $stopped,
                ],
                'costs' => [
                    'total_monthly_rent' => $totalMonthlyRent,
                    'total_monthly_diesel_cost' => $totalMonthlyDieselCost,
                    'total_monthly_cost' => $totalMonthlyCost,
                    'total_yearly_cost' => $totalYearlyCost,
                    'estimated_yearly_cost' => $totalYearlyCostEstimated,
                ],
                'maintenance' => [
                    'needing_maintenance' => Generator::where('next_maintenance_date', '<=', now())->count(),
                    'next_30_days' => Generator::whereBetween('next_maintenance_date', [now(), now()->addDays(30)])->count(),
                ]
            ]
        ]);
    }

    /**
     * Mark generator as needing maintenance
     */
    public function markForMaintenance($id)
    {
        $generator = Generator::find($id);

        if (!$generator) {
            return response()->json([
                'success' => false,
                'message' => 'Generator not found'
            ], 404);
        }

        $generator->update([
            'status' => 'Under Maintenance'
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Generator marked for maintenance',
            'data' => $generator
        ]);
    }

    /**
     * Complete maintenance
     */
    public function completeMaintenance($id)
    {
        $generator = Generator::find($id);

        if (!$generator) {
            return response()->json([
                'success' => false,
                'message' => 'Generator not found'
            ], 404);
        }

        $generator->update([
            'status' => 'Working',
            'next_maintenance_date' => now()->addDays($generator->maintenance_interval_days ?? 90),
            'operating_hours' => $generator->operating_hours + 24 // Assuming 24 hours of operation after maintenance
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Maintenance completed successfully',
            'data' => $generator
        ]);
    }
}
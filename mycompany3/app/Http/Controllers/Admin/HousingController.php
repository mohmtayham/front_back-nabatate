<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Employee;
use Illuminate\Http\Request;
use App\Models\Housing;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class HousingController extends Controller
{
    /**
     * عرض جميع السكن
     */
    public function index()
    {
        $housings = Housing::orderBy('created_at', 'desc')->get();

        return response()->json([
            'status' => 'success',
            'housings' => $housings
        ]);
    }

    /**
     * إضافة سكن
     */
    public function store(Request $request)
    {
        $data = $request->all();

        // تحويل boolean
        $data['rent_due']  = filter_var($request->rent_due, FILTER_VALIDATE_BOOLEAN);
        $data['rent_paid'] = filter_var($request->rent_paid, FILTER_VALIDATE_BOOLEAN);

        $validator = Validator::make($data, [
            'name' => 'required|string|max:255',
            'housing_type' => 'required|in:ملك,إيجار',
            'housing_license' => 'nullable|file|mimes:pdf,jpg,jpeg,png|max:5120',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        // رفع الرخصة
        if ($request->hasFile('housing_license')) {
            $file = $request->file('housing_license');
            $fileName = time().'_'.$file->getClientOriginalName();

            $file->storeAs('public/housing_licenses', $fileName);
            $data['housing_license'] = 'housing_licenses/'.$fileName;
        }

        $housing = Housing::create($data);

        return response()->json([
            'status' => 'success',
            'message' => 'تم إضافة السكن بنجاح',
            'housing' => $housing
        ], 201);
    }

    /**
     * عرض سكن واحد
     */
    public function show($id)
    {
        $housing = Housing::find($id);

        if (!$housing) {
            return response()->json(['message' => 'السكن غير موجود'], 404);
        }

        return response()->json([
            'status' => 'success',
            'housing' => $housing
        ]);
    }

    /**
     * تحديث سكن + استبدال الرخصة
     */
    public function update(Request $request, $id)
    {
        $housing = Housing::find($id);

        if (!$housing) {
            return response()->json(['message' => 'السكن غير موجود'], 404);
        }

        $data = $request->all();

        // رفع رخصة جديدة
        if ($request->hasFile('housing_license')) {

            // حذف القديمة
            if ($housing->housing_license && Storage::disk('public')->exists($housing->housing_license)) {
                Storage::disk('public')->delete($housing->housing_license);
            }

            $file = $request->file('housing_license');
            $fileName = time().'_'.$file->getClientOriginalName();
            $file->storeAs('public/housing_licenses', $fileName);

            $data['housing_license'] = 'housing_licenses/'.$fileName;
        }

        $housing->update($data);

        return response()->json([
            'status' => 'success',
            'message' => 'تم تحديث السكن',
            'housing' => $housing
        ]);
    }

    /**
     * حذف سكن + رخصته
     */
    public function destroy($id)
    {
        $housing = Housing::find($id);

        if (!$housing) {
            return response()->json(['message' => 'السكن غير موجود'], 404);
        }

        if ($housing->housing_license && Storage::disk('public')->exists($housing->housing_license)) {
            Storage::disk('public')->delete($housing->housing_license);
        }

        $housing->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'تم حذف السكن'
        ]);
    }

    public function transferHousing(Request $request, $id)
{
    $request->validate([
        'housing_id' => 'required|exists:housings,id',
        'building_id' => 'nullable|exists:buildings,id',
        'floor_id' => 'nullable|integer',
        'room_id' => 'nullable|integer',
    ]);

    $employee = Employee::findOrFail($id);
    $employee->update([
        'housing_id' => $request->housing_id,
        'building_id' => $request->building_id ?? null,
        'floor_id' => $request->floor_id ?? null,
        'room_id' => $request->room_id ?? null,
        'housing_name' => Housing::find($request->housing_id)?->name, // اختياري
    ]);

    return response()->json(['status' => 'success', 'message' => 'تم نقل الموظف بنجاح']);
}
}

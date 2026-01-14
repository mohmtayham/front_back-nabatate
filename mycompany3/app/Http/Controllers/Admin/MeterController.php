<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Meter;
use App\Models\Housing;

class MeterController extends Controller
{

    public function index()
    {
        $meters = Meter::with('housing')->get();
        return response()->json([
            'status' => 'success',
            'meters' => $meters
        ]);
    }

  
    public function show($id)
    {
        $meter = Meter::with('housing')->findOrFail($id);
        return response()->json([
            'status' => 'success',
            'meter' => $meter
        ]);
    }


    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'serial_number' => 'required|string|max:255',
            'housing_id' => 'required|exists:housings,id',
            'bill_number' => 'nullable|string|max:255',
            'bill_amount' => 'nullable|numeric',
            'payment_status' => 'required|in:مسدد,غير مسدد,مستحق',
            'notes' => 'nullable|string',
        ]);

        $meter = Meter::create($data);

        return response()->json([
            'status' => 'success',
            'meter' => $meter
        ], 201);
    }


    public function update(Request $request, $id)
    {
        $meter = Meter::findOrFail($id);

        $data = $request->validate([
            'name' => 'required|string|max:255',
            'serial_number' => 'required|string|max:255',
            'housing_id' => 'required|exists:housings,id',
            'bill_number' => 'nullable|string|max:255',
            'bill_amount' => 'nullable|numeric',
            'payment_status' => 'required|in:مسدد,غير مسدد,مستحق',
            'notes' => 'nullable|string',
        ]);

        $meter->update($data);

        return response()->json([
            'status' => 'success',
            'meter' => $meter
        ]);
    }


    public function destroy($id)
    {
        $meter = Meter::findOrFail($id);
        $meter->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'تم حذف العداد بنجاح'
        ]);
    }
}

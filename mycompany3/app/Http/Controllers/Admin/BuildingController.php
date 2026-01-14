<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Building;

class BuildingController extends Controller
{

    public function index()
    {
        $buildings = Building::with('housing', 'rooms')->get();

        return response()->json([
            'status' => 'success',
            'buildings' => $buildings
        ]);
    }


    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'housing_id' => 'required|integer|exists:housings,id',
            'floors_count' => 'nullable|integer|min:0',
            'rooms_count' => 'nullable|integer|min:0',
        ]);

        $building = Building::create($data);

        return response()->json([
            'status' => 'success',
            'building' => $building
        ], 201);
    }


    public function update(Request $request, $id)
    {
        $building = Building::findOrFail($id);

        $data = $request->validate([
            'name' => 'required|string|max:255',
            'housing_id' => 'required|integer|exists:housings,id',
            'floors_count' => 'nullable|integer|min:0',
            'rooms_count' => 'nullable|integer|min:0',
        ]);

        $building->update($data);

        return response()->json([
            'status' => 'success',
            'building' => $building
        ]);
    }


    public function destroy($id)
    {
        $building = Building::findOrFail($id);
        $building->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'تم حذف البناية بنجاح'
        ]);
    }
}

<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Room;
use App\Models\Building;

class RoomController extends Controller
{
    // عرض جميع الغرف أو حسب المبنى
    public function index(Request $request)
    {
        $query = Room::with('building');

        if ($request->filled('building_id')) {
            $query->where('building_id', $request->building_id);
        }

        $rooms = $query->get();

        return response()->json([
            'status' => 'success',
            'rooms' => $rooms
        ]);
    }

    // إنشاء غرفة جديدة
    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'building_id' => 'required|exists:buildings,id',
            'beds_count' => 'nullable|integer|min:0',
            'residents_count' => 'nullable|integer|min:0',
            'status' => 'required|in:مشغولة,فارغة,تحت الصيانة,مغلقة',
            'notes' => 'nullable|string',
        ]);

        $room = Room::create($data);

        return response()->json([
            'status' => 'success',
            'room' => $room
        ], 201);
    }

    // تعديل غرفة
    public function update(Request $request, $id)
    {
        $room = Room::findOrFail($id);

        $data = $request->validate([
            'name' => 'required|string|max:255',
            'building_id' => 'required|exists:buildings,id',
            'beds_count' => 'nullable|integer|min:0',
            'residents_count' => 'nullable|integer|min:0',
            'status' => 'required|in:مشغولة,فارغة,تحت الصيانة,مغلقة',
            'notes' => 'nullable|string',
        ]);

        $room->update($data);

        return response()->json([
            'status' => 'success',
            'room' => $room
        ]);
    }

    // حذف غرفة
    public function destroy($id)
    {
        $room = Room::findOrFail($id);
        $room->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'تم حذف الغرفة بنجاح'
        ]);
    }
}

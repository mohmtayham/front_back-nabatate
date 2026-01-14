<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Project;

class ProjectController extends Controller
{
    // عرض جميع المشاريع
    public function index(Request $request)
    {
        $query = Project::query();

        if ($request->filled('search')) {
            $query->where('name', 'like', "%{$request->search}%")
                  ->orWhere('code', 'like', "%{$request->search}%");
        }

        $projects = $query->get();

        return response()->json([
            'status' => 'success',
            'projects' => $projects
        ]);
    }

    // إنشاء مشروع جديد
    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'code' => 'required|string|max:50|unique:projects,code',
            'location' => 'nullable|string|max:255',
            'manager_name' => 'nullable|string|max:100',
            'status' => 'required|in:منتهي,قائم,سلم,يتمدد',
            'notes' => 'nullable|string',
        ]);

        $project = Project::create($data);

        return response()->json([
            'status' => 'success',
            'project' => $project
        ], 201);
    }

    // تعديل مشروع
    public function update(Request $request, $id)
    {
        $project = Project::findOrFail($id);

        $data = $request->validate([
            'name' => 'required|string|max:255',
            'code' => 'required|string|max:50|unique:projects,code,'.$id,
            'location' => 'nullable|string|max:255',
            'manager_name' => 'nullable|string|max:100',
            'status' => 'required|in:منتهي,قائم,سلم,يتمدد',
            'notes' => 'nullable|string',
        ]);

        $project->update($data);

        return response()->json([
            'status' => 'success',
            'project' => $project
        ]);
    }

    // حذف مشروع
    public function destroy($id)
    {
        $project = Project::findOrFail($id);
        $project->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'تم حذف المشروع بنجاح'
        ]);
    }
}

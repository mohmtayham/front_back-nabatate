<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Employee;
use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;

class UserController extends Controller
{
    public function index()
    {
        $users = User::where('type', 'user')->get();

        return response()->json([
            'status' => 'success',
            'users' => $users
        ]);
    }

   public function store(Request $request)
{
     if (!$request->user()->hasPermission('add_users')) {
    return response()->json(['message' => 'Forbidden'], 403);
}

    $data = $request->validate([
        'name' => 'required|string|max:255',
        'email' => 'required|email|unique:users',
        'password' => 'required|string|min:6',
        'permissions' => 'nullable',
    ]);

    $user = User::create([
        'name' => $data['name'],
        'email' => $data['email'],
        'password' => Hash::make($data['password']),
        'type' => 'user',
        'permissions' => $data['permissions'] ?? [],
    ]);

    return response()->json([
        'status' => 'success',
        'user' => $user,
    ], 201);
}


    public function show($id)
    {  
       
        $user = User::where('type', 'user')->findOrFail($id);

        return response()->json([
            'status' => 'success',
            'user' => $user
        ]);
      //  ["view_all","add_employees","print_employees","update_employees","destroy_employees","update_users","store_users","destroy_users"]
    }

   public function update(Request $request, $id)
{
    if (!Auth::user()->hasPermission('update_users')) {
        return response()->json([
            'message' => 'Forbidden'
        ], 403);
    }
    $user = User::where('type', 'user')->findOrFail($id);

    $data = $request->validate([
        'name' => 'required|string|max:255',
        'email' => 'required|email|unique:users,email,' . $user->id,
        'password' => 'nullable|string|min:6',
        'permissions' => 'nullable|array',
    ]);

    if (!empty($data['password'])) {
        $data['password'] = Hash::make($data['password']);
    } else {
        unset($data['password']);
    }

    $user->update($data);

    return response()->json([
        'status' => 'success',
        'message' => 'تم تحديث المستخدم بنجاح',
        'user' => $user
    ]);
}

    public function destroy($id)
    {

    if(!Auth::user()->hasPermission('destroy_users')) {
        return response()->json([
            'message' => 'Forbidden'
        ], 403);
    }

        $user = User::where('type', 'user')->findOrFail($id);
        $user->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'تم حذف المستخدم بنجاح'
        ]);
    }
  

public function givePermissionsByAdmin(Request $request, $id)
{
    $admin = $request->user();

    if ($admin->type !== 'admin') {
        return response()->json(['message' => 'Forbidden'], 403);
    }

    $data = $request->validate([
        'permissions' => 'required|array',
        'permissions.*' => 'boolean',
    ]);

    $user = User::where('type', 'user')->findOrFail($id);

    $user->permissions = $data['permissions'];
    $user->save();

    return response()->json([
        'status' => 'success',
        'permissions' => $user->permissions
    ]);
}

// في app/Models/User.php

public function showUserPermissions($id)
{
    $user = User::where('type', 'user')->findOrFail($id);

    return response()->json([
        'status' => 'success',
        'permissions' => $user->permissions
    ]);
}

}
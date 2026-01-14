<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{   
     
  

    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'message' => 'بيانات الدخول غير صحيحة'
            ], 401);
        }
        
        // إنشاء توكن
        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'token' => $token,
             'id' => $user->id,
             'name' => $user->name,
             'email' => $user->email,
             'type' => $user->type,
            'permissions' => $user->permissionsMap(),
            
            'message' => 'تم الدخول بنجاح'
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'تم تسجيل الخروج'
        ]);
    }


public function changePassword(Request $request)
{
    Log::info('🔑 Change password request received', [
        'user_id' => $request->user()?->id,
        'ip' => $request->ip(),
        'headers' => $request->headers->all(),
    ]);

    try {
        // 1. التحقق من البيانات
        $validated = $request->validate([
            'current_password' => 'required|string',
            'new_password' => 'required|string|min:8|confirmed',
            'new_password_confirmation' => 'required', // مهم لو confirmed
        ]);

        Log::info('✅ Validation passed');

        // 2. جلب الـ user
        $user = $request->user();

        if (!$user) {
            Log::warning('❌ No authenticated user found (token invalid or missing)');
            return response()->json([
                'message' => 'غير مصرح لك (غير مسجل دخول)'
            ], 401);
        }

        Log::info('👤 Authenticated user found', ['user_id' => $user->id, 'email' => $user->email]);

        // 3. التحقق من كلمة المرور الحالية
        if (!Hash::check($request->current_password, $user->password)) {
            Log::warning('❌ Current password incorrect for user', ['user_id' => $user->id]);
            return response()->json([
                'message' => 'كلمة المرور الحالية غير صحيحة'
            ], 400);
        }

        Log::info('✅ Current password correct');

        // 4. تحديث كلمة المرور
        $user->password = Hash::make($request->new_password);
        $user->save();

        Log::info('✅ Password changed successfully for user', ['user_id' => $user->id]);

        return response()->json([
            'message' => 'تم تغيير كلمة المرور بنجاح'
        ], 200);

    } catch (\Illuminate\Validation\ValidationException $e) {
        Log::error('❌ Validation failed', ['errors' => $e->errors()]);
        return response()->json([
            'message' => 'بيانات غير صالحة',
            'errors' => $e->errors()
        ], 422);

    } catch (\Exception $e) {
        Log::error('🔥 Unexpected error in changePassword', [
            'message' => $e->getMessage(),
            'file' => $e->getFile(),
            'line' => $e->getLine(),
            'trace' => $e->getTraceAsString()
        ]);

        return response()->json([
            'message' => 'حدث خطأ داخلي، جاري المعالجة'
        ], 500);
    }
}
    public function remaberPassword(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'new_password' => 'required|min:8|confirmed',
        ]);
 //Mail::to($request->email)->send(new \App\Mail\WelcomeMail());
        $user = User::where('email', $request->email)->first();

        if (!$user) {
            return response()->json([
                'message' => 'البريد الإلكتروني غير موجود'
            ], 404);
        }
        
        $user->password = Hash::make($request->new_password);
        $user->save();
         
        return response()->json([
            'message' => 'تم تغيير كلمة المرور بنجاح'
        ]);
    }
    

}
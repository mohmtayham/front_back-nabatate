<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class AdminUserSeeder extends Seeder
{
    public function run(): void
    {
        $resources = [
            'employees', 'projects', 'housings', 'buildings',
            'rooms', 'cases', 'meters', 'payment_reminders', 'generators',
        ];

        $permissions = [];
        foreach ($resources as $resource) {
            // ✅ الطريقة الصحيحة: مصفوفة نصوص بسيطة ليقرأها Flutter بسهولة
            $permissions[] = "view_{$resource}";
            $permissions[] = "create_{$resource}";
            $permissions[] = "edit_{$resource}";
            $permissions[] = "delete_{$resource}";
        }
        
        $permissions[] = "manage_users";
        $permissions[] = "print";

        // ✅ تأكد من تحديث المستخدم الموجود فعلياً
        User::updateOrCreate(
            ['email' => 'admin2@example.com'],
            [
                'name' => 'Admin',
                'password' => Hash::make('password123'),
                'type' => 'admin',
                // ❌ لا تستخدم json_encode هنا أبداً
                // ✅ أرسل المصفوفة مباشرة و Laravel سيتكفل بالباقي
                'permissions' => $permissions, 
            ]
        );
    }
}
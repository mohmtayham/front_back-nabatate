<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use App\Helpers\PermissionHelper;


class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;
 use \Illuminate\Auth\Passwords\CanResetPassword;
    protected $fillable = [
        'name',
        'email',
        'password',
        'type',
        'permissions',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected $casts = [
    'permissions' => 'array', // or 'json'
    'password' => 'hashed',
];

    public function isAdmin(): bool
    {
        return $this->type === 'admin';
    }


public function hasPermission(string $permission): bool
{
    if ($this->type === 'admin') return true;

    if (!is_array($this->permissions)) return false;

    // مصفوفة تحويل المسميات لضمان التوافق
    $alias = [
        
        'create_employees' => 'store_employees',
       'edit_employees' => 'update_employees',
        'delete_employees' => 'destroy_employees',
          'create_users' => 'store_users',
       'edit_users' => 'update_users',
        'delete_users' => 'destroy_users',

    ];

    $checkPermission = $alias[$permission] ?? $permission;

    return in_array($checkPermission, $this->permissions);
}


public function permissionsMap(): array
{
    $map = [];
    if (!is_array($this->permissions)) {
        return $map;
    }

    foreach ($this->permissions as $key => $value) {
        // إذا كانت الصلاحية نصاً في مصفوفة بسيطة [ "view_employees" ]
        if (is_int($key)) {
            $permission = $value;
        } else {
            // إذا كانت مصفوفة مفاتيح [ "view_employees" => true ]
            if ($value !== true) continue;
            $permission = $key;
        }

        if (!str_contains($permission, '_')) continue;

        [$action, $module] = explode('_', $permission, 2);

        // توحيد المسميات (مهم جداً لتوافق Flutter)
        $action = match ($action) {
           
            'create' => 'store',
            'edit' => 'update',
            'delete' => 'destroy',
            default => $action
        };

        $map[$module][$action] = true;
    }

    return $map;
}

    // دالة لتحويل الصلاحيات المبسطة إلى تفصيلية (كما هي)
    public function getDetailedPermissions(): array
    {
        $simplePermissions = $this->permissions ?? [];
        $detailedPermissions = [];
        
        $resources = ['users', 'employees', 'housings', 'buildings', 'rooms', 'projects', 'cases', 'meters', 'payment-reminders', 'generators','all'];
        $actions = ['index', 'add', 'show', 'update', 'destroy','view'];
        
        // إذا كان لديه صلاحية 'all' أو 'manage' أو 'admin'
        if (in_array('all', $simplePermissions) || 
            in_array('manage', $simplePermissions) || 
            in_array('admin', $simplePermissions)) {
            // منح كل الصلاحيات
            foreach ($resources as $resource) {
                foreach ($actions as $action) {
                    $detailedPermissions[] = "{$action}_{$resource}";
                }
            }
            return $detailedPermissions;
        }
        
        // تحويل الصلاحيات المبسطة
        foreach ($simplePermissions as $permission) {
            switch ($permission) {
                case 'view':
                    foreach ($resources as $resource) {
                        $detailedPermissions[] = "index_{$resource}";
                        $detailedPermissions[] = "show_{$resource}";
                        $detailedPermissions[] = "view_{$resource}";
                    }
                    break;
                case 'add':
                    foreach ($resources as $resource) {
                        $detailedPermissions[] = "store_{$resource}";
                    }
                    break;
                case 'edit':
                    foreach ($resources as $resource) {
                        $detailedPermissions[] = "update_{$resource}";
                    }
                    break;
                case 'delete':
                    foreach ($resources as $resource) {
                        $detailedPermissions[] = "destroy_{$resource}";
                    }
                    break;
                case 'search':
                    // البحث عادة يكون جزء من index
                    foreach ($resources as $resource) {
                        $detailedPermissions[] = "index_{$resource}";
                    }
                    break;
                case 'print':
                    // الطباعة عادة تكون part of view
                    foreach ($resources as $resource) {
                        $detailedPermissions[] = "index_{$resource}";
                    }
                    break;
                    
                default:
                    // إذا كانت صلاحية تفصيلية، أضفها كما هي
                    $detailedPermissions[] = $permission;
            }
        }
        
        return array_unique($detailedPermissions);
    }
}
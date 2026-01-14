<?php

namespace App\Helpers;

class PermissionHelper
{
    public static function format(array $permissions): array
    {
        $formatted = [];

        foreach ($permissions as $permission) {
            // example: update_users
            [$action, $module] = explode('_', $permission, 2);

            $formatted[$module][$action] = true;
        }

        return $formatted;
    }
}

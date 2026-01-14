<?php

namespace App\Policies;

use App\Models\User;
use Illuminate\Auth\Access\HandlesAuthorization;

class UserPolicy
{
    use HandlesAuthorization;

    // فقط الادمن يمكنه إدارة المستخدمين
    public function viewAny(User $user)
{
    return $user->type === 'admin' || $user->hasPermission('read_user');
}
    public function create(User $user)
    {
        return $user->isAdmin();
    }

    public function update(User $user)
    {
        return $user->isAdmin();
    }

    public function delete(User $user)
    {
        return $user->isAdmin();
    }
}

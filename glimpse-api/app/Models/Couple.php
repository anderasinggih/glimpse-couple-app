<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Couple extends Model
{
    protected $fillable = ['anniversary_start_date', 'disconnect_requested_by', 'is_active', 'invited_by'];

    public function users()
    {
        return $this->hasMany(User::class);
    }
}

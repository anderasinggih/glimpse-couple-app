<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Couple extends Model
{
    protected $fillable = ['anniversary_start_date'];

    public function users()
    {
        return $this->hasMany(User::class);
    }
}

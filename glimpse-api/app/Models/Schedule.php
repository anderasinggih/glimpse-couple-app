<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Schedule extends Model
{
    protected $fillable = [
        'couple_id',
        'creator_id',
        'title',
        'scheduled_at',
        'reminder_minutes',
        'status',
    ];

    protected $casts = [
        'scheduled_at' => 'datetime',
    ];

    public function creator()
    {
        return $this->belongsTo(User::class, 'creator_id');
    }

    public function couple()
    {
        return $this->belongsTo(Couple::class, 'couple_id');
    }
}

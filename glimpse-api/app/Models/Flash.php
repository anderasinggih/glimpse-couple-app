<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Flash extends Model
{
    protected $fillable = [
        'couple_id',
        'sender_id',
        'photo_url',
        'latitude',
        'longitude',
        'location_name',
        'status_note',
        'battery_level'
    ];

    public function sender()
    {
        return $this->belongsTo(User::class, 'sender_id');
    }

    public function couple()
    {
        return $this->belongsTo(Couple::class, 'couple_id');
    }
}

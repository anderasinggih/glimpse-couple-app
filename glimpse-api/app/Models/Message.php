<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Message extends Model
{
    protected $fillable = ['couple_id', 'sender_id', 'message', 'room_id'];

    protected $casts = [
        'id' => 'integer',
        'couple_id' => 'integer',
        'sender_id' => 'integer',
        'room_id' => 'integer',
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

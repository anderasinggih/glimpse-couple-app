<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;

use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    /** @use HasFactory<\Database\Factories\UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'name',
        'email',
        'born_date',
        'gender',
        'password',
        'invite_code',
        'couple_id',
        'latitude',
        'longitude',
        'location_name',
        'status_note',
        'battery_level',
        'latest_photo_url',
        'profile_photo_url',
        'last_seen_message_id',
        'location_history',
        'last_active_at',
    ];

    protected static function boot()
    {
        parent::boot();
        static::creating(function ($user) {
            $user->invite_code = strtoupper(bin2hex(random_bytes(4)));
        });
        static::saving(function ($user) {
            $cacheKey = "user_{$user->id}_location_history";
            if (\Cache::has($cacheKey)) {
                $user->location_history = \Cache::get($cacheKey);
            }
        });
    }

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'location_history' => 'array',
            'is_charging' => 'boolean',
            'last_active_at' => 'datetime',
        ];
    }
}

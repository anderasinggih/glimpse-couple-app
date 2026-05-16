<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\Couple;
use Illuminate\Support\Facades\Hash;

class CoupleSeeder extends Seeder
{
    public function run(): void
    {
        $couple = Couple::create([
            'anniversary_start_date' => now()->subYear(),
        ]);

        User::create([
            'name' => 'User One',
            'email' => 'user1@example.com',
            'password' => Hash::make('password'),
            'couple_id' => $couple->id,
            'latitude' => -6.9740,
            'longitude' => 107.6303,
            'location_name' => 'Home',
            'status_note' => 'I love you!',
            'battery_level' => 100,
        ]);

        User::create([
            'name' => 'User Two',
            'email' => 'user2@example.com',
            'password' => Hash::make('password'),
            'couple_id' => $couple->id,
            'latitude' => -6.9750,
            'longitude' => 107.6313,
            'location_name' => 'Work',
            'status_note' => 'Missing you ❤️',
            'battery_level' => 85,
        ]);
    }
}

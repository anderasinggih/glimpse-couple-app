<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\User;
use App\Models\Couple;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;

class SeedLoadTestUsers extends Command
{
    protected $signature = 'glimpse:seed-load-test {users=1000 : Number of users to seed, must be even} {--clean : Delete all load test users and couples}';
    protected $description = 'Seed or clean up active paired couples for Locust load testing';

    public function handle()
    {
        if ($this->option('clean')) {
            $this->info('Cleaning up existing load test users and couples...');
            
            // Find users with @glimpse.test email domain
            $testUsers = User::where('email', 'like', '%@glimpse.test')->get();
            $coupleIds = $testUsers->pluck('couple_id')->filter()->unique();

            DB::transaction(function () use ($testUsers, $coupleIds) {
                // Delete user tokens to prevent orphaned records in personal_access_tokens
                foreach ($testUsers as $user) {
                    $user->tokens()->delete();
                    $user->delete();
                }

                // Delete couples
                if ($coupleIds->isNotEmpty()) {
                    Couple::whereIn('id', $coupleIds)->delete();
                }
            });

            $this->info('Cleanup completed successfully!');
            return 0;
        }

        $usersCount = (int)$this->argument('users');
        if ($usersCount % 2 !== 0) {
            $this->error('Number of users must be even.');
            return 1;
        }

        $couplesCount = $usersCount / 2;
        $this->info("Seeding {$couplesCount} couples ({$usersCount} users)...");

        DB::transaction(function () use ($couplesCount) {
            for ($i = 1; $i <= $couplesCount; $i++) {
                $couple = Couple::create([
                    'anniversary_start_date' => now()->subYear(),
                    'is_active' => 1,
                ]);

                User::create([
                    'name' => "Test User {$i} A",
                    'email' => "test_user_{$i}_a@glimpse.test",
                    'password' => Hash::make('password'),
                    'couple_id' => $couple->id,
                    'latitude' => -6.2088 + (rand(-100, 100) / 10000),
                    'longitude' => 106.8456 + (rand(-100, 100) / 10000),
                    'battery_level' => rand(50, 100),
                ]);

                User::create([
                    'name' => "Test User {$i} B",
                    'email' => "test_user_{$i}_b@glimpse.test",
                    'password' => Hash::make('password'),
                    'couple_id' => $couple->id,
                    'latitude' => -6.2088 + (rand(-100, 100) / 10000),
                    'longitude' => 106.8456 + (rand(-100, 100) / 10000),
                    'battery_level' => rand(50, 100),
                ]);
            }
        });

        $this->info('Seeding completed successfully!');
        return 0;
    }
}

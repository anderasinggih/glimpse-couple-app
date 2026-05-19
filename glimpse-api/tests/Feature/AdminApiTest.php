<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use App\Models\User;
use App\Models\Couple;
use App\Models\Message;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Event;

class AdminApiTest extends TestCase
{
    use RefreshDatabase;

    private string $adminToken = 'LVNPC2026123';

    protected function setUp(): void
    {
        parent::setUp();
        
        // Ensure admin token table exists and has hash or we fallback to default token
        DB::table('admin_tokens')->updateOrInsert(
            ['id' => 1],
            [
                'token_hash' => password_hash($this->adminToken, PASSWORD_BCRYPT),
                'created_at' => now(),
                'updated_at' => now()
            ]
        );
    }

    public function test_unauthorized_if_no_or_invalid_token(): void
    {
        $response = $this->postJson('/admin/api', [
            'action' => 'get_data',
        ]);

        $response->assertStatus(401);
    }

    public function test_get_chat_history_with_rooms(): void
    {
        $couple = Couple::create([
            'is_active' => true,
            'anniversary_start_date' => now()->format('Y-m-d H:i:s')
        ]);
        $user1 = User::factory()->create(['couple_id' => $couple->id]);
        $user2 = User::factory()->create(['couple_id' => $couple->id]);

        // Create main and custom chat rooms
        $room1Id = DB::table('chat_rooms')->insertGetId([
            'couple_id' => $couple->id,
            'name' => 'Main Room',
            'is_main' => true,
            'created_at' => now(),
            'updated_at' => now()
        ]);

        $room2Id = DB::table('chat_rooms')->insertGetId([
            'couple_id' => $couple->id,
            'name' => 'Secret Room',
            'is_main' => false,
            'created_at' => now(),
            'updated_at' => now()
        ]);

        // Create messages
        Message::create([
            'couple_id' => $couple->id,
            'sender_id' => $user1->id,
            'message' => 'Hello in main room',
            'room_id' => null
        ]);

        Message::create([
            'couple_id' => $couple->id,
            'sender_id' => $user2->id,
            'message' => 'Secret message',
            'room_id' => $room2Id
        ]);

        $response = $this->postJson('/admin/api', [
            'action' => 'get_chat_history',
            'couple_id' => $couple->id,
            'token' => $this->adminToken
        ]);

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'couple' => [
                    'id',
                    'users'
                ],
                'rooms',
                'messages'
            ]);

        $data = $response->json();
        $this->assertCount(2, $data['rooms']);
        $this->assertCount(2, $data['messages']);
    }

    public function test_inject_spy_message_with_room_id(): void
    {
        $couple = Couple::create([
            'is_active' => true,
            'anniversary_start_date' => now()->format('Y-m-d H:i:s')
        ]);
        $user1 = User::factory()->create(['couple_id' => $couple->id]);

        $room1Id = DB::table('chat_rooms')->insertGetId([
            'couple_id' => $couple->id,
            'name' => 'Main Room',
            'is_main' => true,
            'created_at' => now(),
            'updated_at' => now()
        ]);

        $response = $this->postJson('/admin/api', [
            'action' => 'inject_spy_message',
            'couple_id' => $couple->id,
            'sender_id' => $user1->id,
            'message' => 'Spy injected message in main',
            'room_id' => $room1Id,
            'token' => $this->adminToken
        ]);

        $response->assertStatus(200);

        $this->assertDatabaseHas('messages', [
            'couple_id' => $couple->id,
            'sender_id' => $user1->id,
            'message' => 'Spy injected message in main',
            'room_id' => $room1Id
        ]);
    }

    public function test_push_diagnostics_battery_lowPreset(): void
    {
        $user = User::factory()->create(['battery_level' => 100, 'is_charging' => true]);

        $response = $this->postJson('/admin/api', [
            'action' => 'push_diagnostics',
            'user_id' => $user->id,
            'type' => 'battery_low',
            'token' => $this->adminToken
        ]);

        $response->assertStatus(200);

        $user->refresh();
        $this->assertEquals(12, $user->battery_level);
        $this->assertFalse($user->is_charging);
    }

    public function test_push_diagnostics_custom(): void
    {
        $user = User::factory()->create(['battery_level' => 100, 'is_charging' => true]);

        $response = $this->postJson('/admin/api', [
            'action' => 'push_diagnostics',
            'user_id' => $user->id,
            'type' => 'custom',
            'battery_level' => 45,
            'is_charging' => false,
            'status_note' => 'Custom Simulated Note',
            'latitude' => -6.2,
            'longitude' => 106.8,
            'location_name' => 'Simulated Starbucks',
            'token' => $this->adminToken
        ]);

        $response->assertStatus(200);

        $user->refresh();
        $this->assertEquals(45, $user->battery_level);
        $this->assertFalse($user->is_charging);
        $this->assertEquals('Custom Simulated Note', $user->status_note);
        $this->assertEquals(-6.2, $user->latitude);
        $this->assertEquals(106.8, $user->longitude);
        $this->assertEquals('Simulated Starbucks', $user->location_name);
    }
}

<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use App\Models\User;
use App\Models\Couple;
use App\Models\Message;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Event;

class ChatRoomDeleteFlowTest extends TestCase
{
    use RefreshDatabase;

    private User $user1;
    private User $user2;
    private Couple $couple;
    private int $mainRoomId;
    private int $customRoomId;

    protected function setUp(): void
    {
        parent::setUp();

        $this->couple = Couple::create([
            'is_active' => true,
            'anniversary_start_date' => now()->format('Y-m-d H:i:s')
        ]);

        $this->user1 = User::factory()->create(['couple_id' => $this->couple->id]);
        $this->user2 = User::factory()->create(['couple_id' => $this->couple->id]);

        $this->mainRoomId = DB::table('chat_rooms')->insertGetId([
            'couple_id' => $this->couple->id,
            'name' => 'General',
            'is_main' => true,
            'created_at' => now(),
            'updated_at' => now()
        ]);

        $this->customRoomId = DB::table('chat_rooms')->insertGetId([
            'couple_id' => $this->couple->id,
            'name' => 'Secret Custom',
            'is_main' => false,
            'created_at' => now(),
            'updated_at' => now()
        ]);
    }

    public function test_get_chat_rooms_includes_delete_requested_by(): void
    {
        DB::table('chat_rooms')->where('id', $this->mainRoomId)->update([
            'delete_requested_by' => $this->user1->id
        ]);

        $response = $this->actingAs($this->user1)
            ->getJson('/api/glimpse/chat-rooms');

        $response->assertStatus(200);
        $data = $response->json();
        
        $mainRoomData = collect($data)->firstWhere('id', $this->mainRoomId);
        $this->assertEquals($this->user1->id, $mainRoomData['delete_requested_by']);
    }

    public function test_request_delete_chat_room(): void
    {
        Event::fake();

        $response = $this->actingAs($this->user1)
            ->postJson("/api/glimpse/chat-rooms/{$this->mainRoomId}/request-delete");

        $response->assertStatus(200)
            ->assertJson([
                'status' => 'ok',
                'delete_requested_by' => $this->user1->id
            ]);

        $this->assertDatabaseHas('chat_rooms', [
            'id' => $this->mainRoomId,
            'delete_requested_by' => $this->user1->id
        ]);
    }

    public function test_decline_delete_chat_room(): void
    {
        Event::fake();

        DB::table('chat_rooms')->where('id', $this->mainRoomId)->update([
            'delete_requested_by' => $this->user1->id
        ]);

        $response = $this->actingAs($this->user2)
            ->postJson("/api/glimpse/chat-rooms/{$this->mainRoomId}/decline-delete");

        $response->assertStatus(200)
            ->assertJson([
                'status' => 'ok'
            ]);

        $this->assertDatabaseHas('chat_rooms', [
            'id' => $this->mainRoomId,
            'delete_requested_by' => null
        ]);
    }

    public function test_confirm_delete_main_chat_room_clears_messages(): void
    {
        Event::fake();

        DB::table('chat_rooms')->where('id', $this->mainRoomId)->update([
            'delete_requested_by' => $this->user1->id
        ]);

        Message::create([
            'couple_id' => $this->couple->id,
            'sender_id' => $this->user1->id,
            'message' => 'Hello',
            'room_id' => $this->mainRoomId
        ]);

        $response = $this->actingAs($this->user2)
            ->postJson("/api/glimpse/chat-rooms/{$this->mainRoomId}/confirm-delete");

        $response->assertStatus(200)
            ->assertJson([
                'status' => 'cleared'
            ]);

        $this->assertDatabaseMissing('messages', [
            'room_id' => $this->mainRoomId
        ]);

        $this->assertDatabaseHas('chat_rooms', [
            'id' => $this->mainRoomId,
            'delete_requested_by' => null
        ]);
    }

    public function test_confirm_delete_custom_chat_room_deletes_room(): void
    {
        Event::fake();

        DB::table('chat_rooms')->where('id', $this->customRoomId)->update([
            'delete_requested_by' => $this->user1->id
        ]);

        $response = $this->actingAs($this->user2)
            ->postJson("/api/glimpse/chat-rooms/{$this->customRoomId}/confirm-delete");

        $response->assertStatus(200)
            ->assertJson([
                'status' => 'deleted'
            ]);

        $this->assertDatabaseMissing('chat_rooms', [
            'id' => $this->customRoomId
        ]);
    }
}

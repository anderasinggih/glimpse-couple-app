<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use App\Models\User;
use App\Models\Couple;

class GlimpseStateTest extends TestCase
{
    use RefreshDatabase;

    public function test_get_state_success_without_couple(): void
    {
        $user = User::factory()->create([
            'name' => 'Single User',
            'email' => 'single@example.com',
            'last_active_at' => now(),
        ]);

        $response = $this->actingAs($user, 'sanctum')->getJson('/api/glimpse/state');

        $response->assertStatus(200)
            ->assertJsonPath('user.name', 'Single User')
            ->assertJsonPath('user.couple_id', null)
            ->assertJsonPath('partner_data', null)
            ->assertJsonPath('couple_active', false);
    }

    public function test_get_state_success_with_couple_active(): void
    {
        $couple = Couple::create([
            'is_active' => true,
            'anniversary_start_date' => '2020-01-01 00:00:00'
        ]);

        $user = User::factory()->create([
            'name' => 'User A',
            'couple_id' => $couple->id,
            'last_active_at' => now(),
        ]);

        $partner = User::factory()->create([
            'name' => 'User B',
            'couple_id' => $couple->id,
            'last_active_at' => now()->subMinutes(5),
        ]);

        $response = $this->actingAs($user, 'sanctum')->getJson('/api/glimpse/state');

        $response->assertStatus(200)
            ->assertJsonPath('user.name', 'User A')
            ->assertJsonPath('user.couple_id', $couple->id)
            ->assertJsonPath('partner_data.name', 'User B')
            ->assertJsonPath('couple_active', true);
    }

    public function test_get_state_self_heals_ghost_couple(): void
    {
        $user = User::factory()->create([
            'name' => 'Ghost User',
            'couple_id' => 9999, // non-existent couple
        ]);

        $response = $this->actingAs($user, 'sanctum')->getJson('/api/glimpse/state');

        $response->assertStatus(200)
            ->assertJsonPath('user.couple_id', null)
            ->assertJsonPath('partner_data', null);

        $user->refresh();
        $this->assertNull($user->couple_id);
    }
}

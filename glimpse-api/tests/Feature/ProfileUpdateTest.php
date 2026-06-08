<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use App\Models\User;
use App\Models\Couple;

class ProfileUpdateTest extends TestCase
{
    use RefreshDatabase;

    public function test_update_profile_success(): void
    {
        $user = User::factory()->create([
            'name' => 'Old Name',
            'email' => 'old@example.com',
            'born_date' => '1995-01-01',
            'gender' => 'male',
        ]);

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/user/update', [
            'name' => 'New Name',
            'born_date' => '2000-12-31',
            'gender' => 'female',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('user.name', 'New Name')
            ->assertJsonPath('user.born_date', '2000-12-31')
            ->assertJsonPath('user.gender', 'female');

        $user->refresh();
        $this->assertEquals('New Name', $user->name);
        $this->assertEquals('2000-12-31', $user->born_date);
        $this->assertEquals('female', $user->gender);
    }

    public function test_update_profile_validation_error(): void
    {
        $user = User::factory()->create();

        // Invalid gender and invalid date format
        $response = $this->actingAs($user, 'sanctum')->postJson('/api/user/update', [
            'gender' => 'other',
            'born_date' => 'not-a-date',
        ]);

        $response->assertStatus(422);
    }

    public function test_update_anniversary_success(): void
    {
        $couple = Couple::create([
            'is_active' => true,
            'anniversary_start_date' => '2020-01-01 00:00:00'
        ]);
        $user = User::factory()->create(['couple_id' => $couple->id]);

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/couple/anniversary', [
            'anniversary_date' => '2025-05-17 12:00:00',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('anniversary_date', '2025-05-17 12:00:00');

        $couple->refresh();
        $this->assertEquals('2025-05-17 12:00:00', $couple->anniversary_start_date);
    }

    public function test_send_delete_account_otp_success(): void
    {
        \Illuminate\Support\Facades\Mail::fake();
        $user = User::factory()->create(['email' => 'test@glimpse.test']);

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/user/delete/send-otp');

        $response->assertStatus(200)
            ->assertJsonPath('message', 'Verification code sent successfully');

        $this->assertNotNull(\Illuminate\Support\Facades\Cache::get("delete_account_otp_{$user->id}"));
        \Illuminate\Support\Facades\Mail::assertSent(\App\Mail\DeleteAccountVerificationMail::class);
    }

    public function test_delete_account_with_password_success(): void
    {
        $user = User::factory()->create([
            'password' => \Illuminate\Support\Facades\Hash::make('secretpassword')
        ]);

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/user/delete', [
            'agreement' => true,
            'method' => 'password',
            'password' => 'secretpassword'
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('message', 'Account deleted successfully');

        $this->assertDatabaseMissing('users', ['id' => $user->id]);
    }

    public function test_delete_account_with_otp_success(): void
    {
        $user = User::factory()->create();
        \Illuminate\Support\Facades\Cache::put("delete_account_otp_{$user->id}", '123456', 900);

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/user/delete', [
            'agreement' => true,
            'method' => 'email',
            'otp' => '123456'
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('message', 'Account deleted successfully');

        $this->assertDatabaseMissing('users', ['id' => $user->id]);
        $this->assertNull(\Illuminate\Support\Facades\Cache::get("delete_account_otp_{$user->id}"));
    }

    public function test_delete_account_validation_error(): void
    {
        $user = User::factory()->create();

        // Missing agreement
        $response = $this->actingAs($user, 'sanctum')->postJson('/api/user/delete', [
            'method' => 'password',
            'password' => 'wrongpassword'
        ]);
        $response->assertStatus(422);

        // Incorrect password
        $response = $this->actingAs($user, 'sanctum')->postJson('/api/user/delete', [
            'agreement' => true,
            'method' => 'password',
            'password' => 'wrongpassword'
        ]);
        $response->assertStatus(422);
    }
}

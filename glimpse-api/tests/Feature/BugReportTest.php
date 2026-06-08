<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use App\Models\User;
use App\Models\BugReport;

class BugReportTest extends TestCase
{
    use RefreshDatabase;

    public function test_unauthenticated_user_cannot_report_bug(): void
    {
        $response = $this->postJson('/api/user/report-bug', [
            'title' => 'Crash on login',
            'description' => 'App crashes when I click login button',
        ]);

        $response->assertStatus(401);
    }

    public function test_authenticated_user_can_report_bug_successfully(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/user/report-bug', [
            'title' => 'Crash on login',
            'description' => 'App crashes when I click login button',
            'device_info' => 'Device: iPhone 15 | iOS: 17.2 | App: 1.2.0 (5)',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('message', 'Bug report submitted successfully')
            ->assertJsonStructure([
                'bug_report' => ['id', 'user_id', 'title', 'description', 'device_info', 'created_at', 'updated_at']
            ]);

        $this->assertDatabaseHas('bug_reports', [
            'user_id' => $user->id,
            'title' => 'Crash on login',
            'description' => 'App crashes when I click login button',
            'device_info' => 'Device: iPhone 15 | iOS: 17.2 | App: 1.2.0 (5)',
        ]);
    }

    public function test_report_bug_validation(): void
    {
        $user = User::factory()->create();

        // Empty title/description
        $response = $this->actingAs($user, 'sanctum')->postJson('/api/user/report-bug', [
            'title' => '',
            'description' => '',
        ]);

        $response->assertStatus(422);
    }

    public function test_admin_can_retrieve_bug_reports(): void
    {
        $user = User::factory()->create();
        BugReport::create([
            'user_id' => $user->id,
            'title' => 'UI bug',
            'description' => 'Alignment is off in Profile page',
        ]);

        $response = $this->postJson('/admin/api', [
            'action' => 'get_data',
            'token' => 'LVNPC2026123', // Admin secret token fallback
        ]);

        $response->assertStatus(200)
            ->assertJsonStructure([
                'bug_reports' => [
                    '*' => ['id', 'user_id', 'title', 'description', 'device_info', 'created_at', 'updated_at', 'user']
                ]
            ]);

        $this->assertCount(1, $response->json('bug_reports'));
    }

    public function test_admin_can_delete_bug_report(): void
    {
        $user = User::factory()->create();
        $report = BugReport::create([
            'user_id' => $user->id,
            'title' => 'UI bug',
            'description' => 'Alignment is off in Profile page',
        ]);

        $response = $this->postJson('/admin/api', [
            'action' => 'delete_bug_report',
            'report_id' => $report->id,
            'token' => 'LVNPC2026123',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('message', 'Bug report deleted successfully!');

        $this->assertDatabaseMissing('bug_reports', ['id' => $report->id]);
    }
}

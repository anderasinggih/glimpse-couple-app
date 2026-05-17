<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use App\Events\PartnerStateUpdated;

class GlimpseController extends Controller
{
    public function getState(Request $request)
    {
        $user = $request->user();
        
        // Find partner if in a couple
        $partner = null;
        $couple = null;
        if ($user->couple_id) {
            $partner = \App\Models\User::where('couple_id', $user->couple_id)
                ->where('id', '!=', $user->id)
                ->first();
            
            $couple = \App\Models\Couple::find($user->couple_id);
        }

        $photoUrl = $user->profile_photo_url;
        if ($photoUrl && !str_starts_with($photoUrl, 'http')) {
            $photoUrl = url($photoUrl);
        }

        $latestPhotoUrl = $user->latest_photo_url;
        if ($latestPhotoUrl && !str_starts_with($latestPhotoUrl, 'http')) {
            $latestPhotoUrl = url($latestPhotoUrl);
        }

        $partnerLatestPhotoUrl = null;
        if ($partner) {
            $partnerPhotoUrl = $partner->profile_photo_url;
            if ($partnerPhotoUrl && !str_starts_with($partnerPhotoUrl, 'http')) {
                $partnerPhotoUrl = url($partnerPhotoUrl);
            }
            $partnerLatestPhotoUrl = $partner->latest_photo_url;
            if ($partnerLatestPhotoUrl && !str_starts_with($partnerLatestPhotoUrl, 'http')) {
                $partnerLatestPhotoUrl = url($partnerLatestPhotoUrl);
            }
            $partnerData = $partner->toArray();
            $partnerData['profile_photo_url'] = $partnerPhotoUrl ?? "https://ui-avatars.com/api/?name=" . urlencode($partner->name);
        }

        $togetherStreak = 0;
        $totalMeetings = 0;
        $isTogether = false;

        if ($couple) {
            $today = now()->toDateString();
            $yesterday = now()->subDay()->toDateString();

            // Reset streak if last meeting was before yesterday and not today
            if ($couple->last_meeting_date && $couple->last_meeting_date !== $today && $couple->last_meeting_date !== $yesterday) {
                $couple->together_streak = 0;
                $couple->save();
            }

            $togetherStreak = $couple->together_streak;
            $totalMeetings = $couple->total_meetings;

            if ($partner) {
                $isTogether = $this->checkAndRecordMeeting($user, $partner);
                $couple->refresh();
                $togetherStreak = $couple->together_streak;
                $totalMeetings = $couple->total_meetings;
            }
        }

        $loveBurstInfo = \Illuminate\Support\Facades\Cache::get("couple_{$user->couple_id}_love_burst");
        $loveBurstTimestamp = 0.0;
        if ($loveBurstInfo && $loveBurstInfo['sender_id'] !== $user->id) {
            $loveBurstTimestamp = (double)$loveBurstInfo['timestamp'];
        }

        return response()->json([
            'user' => [
                'id' => (int)$user->id,
                'name' => $user->name,
                'email' => $user->email,
                'invite_code' => $user->invite_code,
                'profile_photo_url' => $photoUrl ?? "https://ui-avatars.com/api/?name=" . urlencode($user->name),
                'couple_id' => $user->couple_id !== null ? (int)$user->couple_id : null,
                'latitude' => $user->latitude !== null ? (double)$user->latitude : null,
                'longitude' => $user->longitude !== null ? (double)$user->longitude : null,
                'location_name' => $user->location_name,
                'battery_level' => $user->battery_level !== null ? (int)$user->battery_level : null,
                'is_charging' => (bool)$user->is_charging,
                'status_note' => $user->status_note,
                'latest_photo_url' => $latestPhotoUrl,
                'last_updated' => $user->updated_at->toIso8601String(),
            ],
            'partner_data' => $partner ? [
                'id' => (int)$partner->id,
                'name' => $partner->name,
                'email' => $partner->email,
                'profile_photo_url' => $partnerPhotoUrl ?? "https://ui-avatars.com/api/?name=" . urlencode($partner->name),
                'couple_id' => $partner->couple_id !== null ? (int)$partner->couple_id : null,
                'latitude' => $partner->latitude !== null ? (double)$partner->latitude : null,
                'longitude' => $partner->longitude !== null ? (double)$partner->longitude : null,
                'location_name' => $partner->location_name,
                'battery_level' => $partner->battery_level !== null ? (int)$partner->battery_level : null,
                'is_charging' => (bool)$partner->is_charging,
                'status_note' => $partner->status_note,
                'latest_photo_url' => $partnerLatestPhotoUrl,
                'last_updated' => $partner->updated_at->toIso8601String(),
            ] : null,
            'anniversary_start_date' => $couple ? $couple->anniversary_start_date : null,
            'disconnect_requested_by' => $couple && $couple->disconnect_requested_by !== null ? (int)$couple->disconnect_requested_by : null,
            'couple_active' => $couple ? (bool) $couple->is_active : false,
            'invited_by' => $couple && $couple->invited_by !== null ? (int)$couple->invited_by : null,
            'is_together' => $isTogether,
            'together_streak' => (int)$togetherStreak,
            'total_meetings' => (int)$totalMeetings,
            'love_burst_timestamp' => $loveBurstTimestamp,
        ]);
    }

    public function updateProfile(Request $request)
    {
        $user = $request->user();
        $request->validate([
            'name' => 'sometimes|string|max:30',
            'email' => 'sometimes|email|max:100|unique:users,email,' . $user->id,
            'profile_photo' => 'sometimes|image|max:5120'
        ]);

        if ($request->has('name')) $user->name = $request->name;
        if ($request->has('email')) $user->email = $request->email;
        
        if ($request->hasFile('profile_photo')) {
            if ($user->profile_photo_url && !str_contains($user->profile_photo_url, 'ui-avatars')) {
                Storage::disk('public')->delete('avatars/' . basename($user->profile_photo_url));
            }
            $path = $request->file('profile_photo')->store('avatars', 'public');
            $user->profile_photo_url = Storage::url($path);
        }

        $user->save();
        
        $photoUrl = $user->profile_photo_url;
        if ($photoUrl && !str_starts_with($photoUrl, 'http')) {
            $photoUrl = url($photoUrl);
        }

        return response()->json([
            'message' => 'Profile updated!', 
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'profile_photo_url' => $photoUrl ?? "https://ui-avatars.com/api/?name=" . urlencode($user->name),
            ]
        ]);
    }

    public function updateRelationship(Request $request)
    {
        $user = $request->user();
        if (!$user->couple_id) return response()->json(['message' => 'Not in a relationship'], 400);

        $request->validate(['anniversary_date' => 'required|date']);
        
        $couple = \App\Models\Couple::updateOrCreate(
            ['id' => $user->couple_id],
            ['anniversary_start_date' => $request->anniversary_date]
        );

        return response()->json(['message' => 'Relationship updated!', 'anniversary_date' => $couple->anniversary_start_date]);
    }

    public function connect(Request $request)
    {
        $request->validate(['invite_code' => 'required|string']);
        $user = $request->user();
        
        $targetUser = \App\Models\User::where('invite_code', $request->invite_code)->first();
        
        if (!$targetUser) {
            return response()->json(['message' => 'Invalid invite code'], 404);
        }
        
        if ($targetUser->id === $user->id) {
            return response()->json(['message' => 'You cannot invite yourself'], 400);
        }

        if ($targetUser->couple_id || $user->couple_id) {
            return response()->json(['message' => 'User is already in a relationship'], 400);
        }

        $couple = \App\Models\Couple::create([
            'anniversary_start_date' => now(),
            'is_active' => 0,
            'invited_by' => $user->id
        ]);
        $coupleId = $couple->id;
        $user->update(['couple_id' => $coupleId]);
        $targetUser->update(['couple_id' => $coupleId]);

        return response()->json(['message' => 'Invite sent successfully!', 'couple_id' => $coupleId]);
    }

    public function acceptConnect(Request $request)
    {
        $user = $request->user();
        if ($user->couple_id) {
            $couple = \App\Models\Couple::find($user->couple_id);
            if ($couple && $couple->is_active == 0) {
                $couple->update(['is_active' => 1]);
                return response()->json(['message' => 'Connected successfully!']);
            }
        }
        return response()->json(['message' => 'No pending connect request found'], 400);
    }

    public function declineConnect(Request $request)
    {
        $user = $request->user();
        if ($user->couple_id) {
            $coupleId = $user->couple_id;
            \App\Models\User::where('couple_id', $coupleId)->update(['couple_id' => null]);
            \App\Models\Couple::where('id', $coupleId)->delete();
            return response()->json(['message' => 'Connect request declined']);
        }
        return response()->json(['message' => 'No request found'], 400);
    }

    public function disconnect(Request $request)
    {
        $user = $request->user();
        if ($user->couple_id) {
            $couple = \App\Models\Couple::find($user->couple_id);
            if ($couple) {
                $couple->update(['disconnect_requested_by' => $user->id]);
            }
        }
        return response()->json(['message' => 'Disconnect request sent']);
    }

    public function approveDisconnect(Request $request)
    {
        $user = $request->user();
        if ($user->couple_id) {
            $coupleId = $user->couple_id;
            \App\Models\User::where('couple_id', $coupleId)->update(['couple_id' => null]);
            \App\Models\Couple::where('id', $coupleId)->delete();
        }
        return response()->json(['message' => 'Partner disconnected']);
    }

    public function cancelDisconnect(Request $request)
    {
        $user = $request->user();
        if ($user->couple_id) {
            $couple = \App\Models\Couple::find($user->couple_id);
            if ($couple) {
                $couple->update(['disconnect_requested_by' => null]);
            }
        }
        return response()->json(['message' => 'Disconnect request cancelled']);
    }

    public function uploadPhoto(Request $request)
    {
        $request->validate([
            'photo' => 'required|image|max:10240', // Max 10MB
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
            'battery_level' => 'nullable|integer',
            'status_note' => 'nullable|string|max:30',
            'location_name' => 'nullable|string|max:255',
        ]);

        $user = $request->user();
        
        // Update presence data
        if ($request->has('latitude')) $user->latitude = $request->latitude;
        if ($request->has('longitude')) $user->longitude = $request->longitude;
        if ($request->has('battery_level')) $user->battery_level = $request->battery_level;
        if ($request->has('status_note')) $user->status_note = $request->status_note;
        if ($request->has('location_name')) $user->location_name = $request->location_name;

        if ($request->hasFile('photo')) {
            $path = $request->file('photo')->store('glimpse_photos', 'public');
            $user->latest_photo_url = Storage::url($path);
            $user->save();

            if ($user->couple_id) {
                \App\Models\Flash::create([
                    'couple_id' => $user->couple_id,
                    'sender_id' => $user->id,
                    'photo_url' => $user->latest_photo_url,
                    'latitude' => $user->latitude,
                    'longitude' => $user->longitude,
                    'location_name' => $user->location_name,
                    'status_note' => $user->status_note,
                    'battery_level' => $user->battery_level
                ]);
                
                try {
                    broadcast(new PartnerStateUpdated($user))->toOthers();
                } catch (\Exception $e) {
                    \Illuminate\Support\Facades\Log::warning("Websocket broadcast failed: " . $e->getMessage());
                }
            }

            return response()->json([
                'message' => 'Kabar updated successfully!',
                'photo_url' => $user->latest_photo_url,
                'user' => $user
            ]);
        }

        return response()->json(['message' => 'No photo uploaded'], 400);
    }

    public function getFlashes(Request $request)
    {
        $user = $request->user();
        if (!$user->couple_id) {
            return response()->json([]);
        }

        // Clean up flashes older than 7 days along with their images
        $oldFlashes = \App\Models\Flash::where('created_at', '<', now()->subDays(7))->get();
        foreach ($oldFlashes as $oldFlash) {
            if ($oldFlash->photo_url) {
                \Illuminate\Support\Facades\Storage::disk('public')->delete(str_replace('/storage/', '', $oldFlash->photo_url));
            }
            $oldFlash->delete();
        }

        $flashes = \App\Models\Flash::where('couple_id', $user->couple_id)
            ->with('sender')
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(function ($flash) {
                $photoUrl = $flash->photo_url;
                if ($photoUrl && !str_starts_with($photoUrl, 'http')) {
                    $photoUrl = url($photoUrl);
                }
                return [
                    'id' => $flash->id,
                    'sender_id' => $flash->sender_id,
                    'sender_name' => $flash->sender->name,
                    'photo_url' => $photoUrl,
                    'latitude' => (double)$flash->latitude,
                    'longitude' => (double)$flash->longitude,
                    'location_name' => $flash->location_name,
                    'status_note' => $flash->status_note,
                    'battery_level' => $flash->battery_level,
                    'created_at' => $flash->created_at->toIso8601String()
                ];
            });

        return response()->json($flashes);
    }

    public function getMessages(Request $request)
    {
        $user = $request->user();
        if (!$user->couple_id) {
            return response()->json(['message' => 'No active couple relationship'], 400);
        }

        $couple = \App\Models\Couple::find($user->couple_id);
        if (!$couple || $couple->is_active == 0) {
            return response()->json(['message' => 'Relationship is not active'], 400);
        }

        $messages = \App\Models\Message::where('couple_id', $user->couple_id)
            ->orderBy('created_at', 'asc')
            ->take(100)
            ->get();

        return response()->json($messages);
    }

    public function sendMessage(Request $request)
    {
        $request->validate(['message' => 'required|string|max:500']);
        $user = $request->user();

        if (!$user->couple_id) {
            return response()->json(['message' => 'No active couple relationship'], 400);
        }

        $couple = \App\Models\Couple::find($user->couple_id);
        if (!$couple || $couple->is_active == 0) {
            return response()->json(['message' => 'Relationship is not active'], 400);
        }

        $msg = \App\Models\Message::create([
            'couple_id' => $user->couple_id,
            'sender_id' => $user->id,
            'message' => $request->message
        ]);

        // Broadcast MessageSent event to the partner over WebSockets
        try {
            broadcast(new \App\Events\MessageSent($msg))->toOthers();
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::warning("Websocket broadcast failed: " . $e->getMessage());
        }

        return response()->json($msg);
    }

    public function updateStatus(Request $request)
    {
        $request->validate([
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
            'battery_level' => 'nullable|integer',
            'is_charging' => 'nullable|boolean',
            'status_note' => 'nullable|string|max:30',
            'location_name' => 'nullable|string|max:255',
        ]);

        $user = $request->user();
        
        if ($request->has('latitude')) $user->latitude = $request->latitude;
        if ($request->has('longitude')) $user->longitude = $request->longitude;
        if ($request->has('battery_level')) $user->battery_level = $request->battery_level;
        if ($request->has('is_charging')) $user->is_charging = $request->is_charging ? 1 : 0;
        if ($request->has('status_note')) $user->status_note = $request->status_note;
        if ($request->has('location_name')) $user->location_name = $request->location_name;

        $user->save();

        // Broadcast live state updates to the partner instantly over WebSockets
        try {
            broadcast(new \App\Events\PartnerStateUpdated($user))->toOthers();
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::warning("Websocket broadcast failed: " . $e->getMessage());
        }

        return response()->json([
            'message' => 'Status updated successfully!',
            'user' => $user
        ]);
    }

    private function checkAndRecordMeeting($user, $partner)
    {
        if (!$user || !$partner || !$user->couple_id) return false;
        if (!$user->latitude || !$user->longitude || !$partner->latitude || !$partner->longitude) return false;

        $lat1 = (double)$user->latitude;
        $lon1 = (double)$user->longitude;
        $lat2 = (double)$partner->latitude;
        $lon2 = (double)$partner->longitude;

        $earthRadius = 6371000; // meters
        $latFrom = deg2rad($lat1);
        $lonFrom = deg2rad($lon1);
        $latTo = deg2rad($lat2);
        $lonTo = deg2rad($lon2);
        $latDelta = $latTo - $latFrom;
        $lonDelta = $lonTo - $lonFrom;
        $angle = 2 * asin(sqrt(pow(sin($latDelta / 2), 2) + cos($latFrom) * cos($latTo) * pow(sin($lonDelta / 2), 2)));
        $distance = $angle * $earthRadius;

        $isTogether = ($distance <= 100); // 100 meters threshold

        if ($isTogether) {
            $couple = \App\Models\Couple::find($user->couple_id);
            if ($couple) {
                $today = now()->toDateString();
                $yesterday = now()->subDay()->toDateString();

                if ($couple->last_meeting_date !== $today) {
                    if ($couple->last_meeting_date === $yesterday) {
                        $couple->together_streak += 1;
                    } else {
                        $couple->together_streak = 1;
                    }
                    $couple->total_meetings += 1;
                    $couple->last_meeting_date = $today;
                    $couple->save();
                    
                    // Broadcast meeting milestone event
                    try {
                        broadcast(new PartnerStateUpdated($user))->toOthers();
                    } catch (\Exception $e) {
                        \Illuminate\Support\Facades\Log::warning("Websocket broadcast failed: " . $e->getMessage());
                    }
                }
            }
        }

        return $isTogether;
    }

    public function sendLoveBurst(Request $request)
    {
        $user = $request->user();
        if (!$user->couple_id) {
            return response()->json(['message' => 'No active relationship'], 400);
        }

        $timestamp = microtime(true);
        \Illuminate\Support\Facades\Cache::put("couple_{$user->couple_id}_love_burst", [
            'timestamp' => $timestamp,
            'sender_id' => $user->id
        ], 60);

        // Broadcast LoveBurstSent event to partner instantly over WebSockets
        try {
            broadcast(new \App\Events\LoveBurstSent($user->couple_id, $user->id, $timestamp))->toOthers();
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::warning("Websocket broadcast failed: " . $e->getMessage());
        }

        return response()->json([
            'message' => 'Love burst triggered!',
            'timestamp' => $timestamp
        ]);
    }

    public function broadcastTyping(Request $request)
    {
        $request->validate(['is_typing' => 'required|boolean']);
        $user = $request->user();
        if (!$user->couple_id) {
            return response()->json(['message' => 'No active couple'], 400);
        }

        // Broadcast typing status with 0 database queries
        try {
            broadcast(new \App\Events\PartnerTyping($user->couple_id, $user->id, $request->is_typing))->toOthers();
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::warning("Websocket broadcast failed: " . $e->getMessage());
        }

        return response()->json(['status' => 'ok']);
    }
}

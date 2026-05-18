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
        $cacheKey = "glimpse_state_user_{$user->id}";

        $responseData = \Illuminate\Support\Facades\Cache::remember($cacheKey, 120, function() use ($user) {
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

            $activeSchedule = null;
            if ($user->couple_id) {
                $activeSchedule = \App\Models\Schedule::where('couple_id', $user->couple_id)
                    ->where('scheduled_at', '>=', now())
                    ->whereIn('status', ['pending', 'accepted'])
                    ->orderBy('scheduled_at', 'asc')
                    ->first();
            }

            return [
                'user' => [
                    'id' => (int)$user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'invite_code' => $user->invite_code,
                    'profile_photo_url' => $photoUrl ?? "https://ui-avatars.com/api/?name=" . urlencode($user->name),
                    'born_date' => $user->born_date,
                    'couple_id' => $user->couple_id !== null ? (int)$user->couple_id : null,
                    'latitude' => $user->latitude !== null ? (double)$user->latitude : null,
                    'longitude' => $user->longitude !== null ? (double)$user->longitude : null,
                    'location_name' => $user->location_name,
                    'battery_level' => $user->battery_level !== null ? (int)$user->battery_level : null,
                    'is_charging' => (bool)$user->is_charging,
                    'status_note' => $user->status_note,
                    'latest_photo_url' => $latestPhotoUrl,
                    'last_updated' => $user->updated_at->toIso8601String(),
                    'last_seen_message_id' => $user->last_seen_message_id !== null ? (int)$user->last_seen_message_id : null,
                    'location_history' => $this->getFilteredHistory($user->location_history),
                ],
                'partner_data' => $partner ? [
                    'id' => (int)$partner->id,
                    'name' => $partner->name,
                    'email' => $partner->email,
                    'profile_photo_url' => $partnerPhotoUrl ?? "https://ui-avatars.com/api/?name=" . urlencode($partner->name),
                    'born_date' => $partner->born_date,
                    'couple_id' => $partner->couple_id !== null ? (int)$partner->couple_id : null,
                    'latitude' => $partner->latitude !== null ? (double)$partner->latitude : null,
                    'longitude' => $partner->longitude !== null ? (double)$partner->longitude : null,
                    'location_name' => $partner->location_name,
                    'battery_level' => $partner->battery_level !== null ? (int)$partner->battery_level : null,
                    'is_charging' => (bool)$partner->is_charging,
                    'status_note' => $partner->status_note,
                    'latest_photo_url' => $partnerLatestPhotoUrl,
                    'last_updated' => $partner->updated_at->toIso8601String(),
                    'last_seen_message_id' => $partner->last_seen_message_id !== null ? (int)$partner->last_seen_message_id : null,
                    'location_history' => $this->getFilteredHistory($partner->location_history),
                ] : null,
                'anniversary_start_date' => $couple ? $couple->anniversary_start_date : null,
                'paired_at' => $couple && $couple->created_at ? $couple->created_at->toIso8601String() : null,
                'disconnect_requested_by' => $couple && $couple->disconnect_requested_by !== null ? (int)$couple->disconnect_requested_by : null,
                'couple_active' => $couple ? (bool) $couple->is_active : false,
                'invited_by' => $couple && $couple->invited_by !== null ? (int)$couple->invited_by : null,
                'is_together' => $isTogether,
                'together_streak' => (int)$togetherStreak,
                'highest_together_streak' => $couple ? (int)$couple->highest_together_streak : 0,
                'total_meetings' => (int)$totalMeetings,
                'love_burst_timestamp' => $loveBurstTimestamp,
                'active_schedule' => $this->formatSchedule($activeSchedule),
            ];
        });

        return response()->json($responseData);
    }

    public function updateProfile(Request $request)
    {
        $user = $request->user();
        $request->validate([
            'name' => 'sometimes|string|max:30',
            'email' => 'sometimes|email|max:100|unique:users,email,' . $user->id,
            'born_date' => 'sometimes|nullable|date',
            'profile_photo' => 'sometimes|image|max:5120'
        ]);

        if ($request->has('name')) $user->name = $request->name;
        if ($request->has('email')) $user->email = $request->email;
        if ($request->has('born_date')) $user->born_date = $request->born_date;
        
        if ($request->hasFile('profile_photo')) {
            if ($user->profile_photo_url && !str_contains($user->profile_photo_url, 'ui-avatars')) {
                Storage::disk('public')->delete('avatars/' . basename($user->profile_photo_url));
            }
            $path = $request->file('profile_photo')->store('avatars', 'public');
            $user->profile_photo_url = Storage::url($path);
        }

        $user->save();
        $this->clearGlimpseCache($user->id);
        
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
                'born_date' => $user->born_date,
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
        $this->clearGlimpseCache($user->id);

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
                $this->clearGlimpseCache($user->id);
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
            $this->clearGlimpseCache($user->id);
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
                $this->clearGlimpseCache($user->id);
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
            $this->clearGlimpseCache($user->id);
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
                $this->clearGlimpseCache($user->id);
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
        $user->status_note = $request->input('status_note');
        if ($request->has('location_name')) $user->location_name = $request->location_name;

        if ($request->has('latitude') && $request->has('longitude')) {
            $this->appendLocationHistory($user, $request->latitude, $request->longitude);
        }

        if ($request->hasFile('photo')) {
            $path = $request->file('photo')->store('glimpse_photos', 'public');
            $user->latest_photo_url = Storage::url($path);
            $user->save();
            $this->clearGlimpseCache($user->id);

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

    public function markAsRead(Request $request)
    {
        $request->validate(['message_id' => 'required|integer']);
        $user = $request->user();

        $user->last_seen_message_id = $request->message_id;
        $user->save();
        $this->clearGlimpseCache($user->id);

        try {
            broadcast(new \App\Events\PartnerStateUpdated($user))->toOthers();
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::warning("Websocket broadcast failed: " . $e->getMessage());
        }

        return response()->json(['status' => 'ok', 'last_seen_message_id' => $user->last_seen_message_id]);
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

        // 🏡 Smart Place Anchor & Cozy Labeling (Zenly Style)
        $lat = $user->latitude;
        $lng = $user->longitude;
        if ($lat !== null && $lng !== null) {
            $hour = (int)now()->format('H');
            $dayOfWeek = (int)now()->format('N'); // 1 (Mon) - 7 (Sun)
            
            // Check if stationary (within ~30 meters of last coordinate in history)
            $isStationary = false;
            $history = $user->location_history ?? [];
            if (!empty($history)) {
                $last = end($history);
                $latDiff = abs($last['latitude'] - $lat);
                $lngDiff = abs($last['longitude'] - $lng);
                if ($latDiff < 0.0003 && $lngDiff < 0.0003) {
                    $isStationary = true;
                }
            } else {
                $isStationary = true;
            }
            
            if ($isStationary) {
                if ($hour >= 20 || $hour < 6) {
                    $user->location_name = "Home";
                } elseif ($hour >= 9 && $hour <= 17) {
                    if ($dayOfWeek >= 1 && $dayOfWeek <= 5) {
                        $user->location_name = "Work";
                    } else {
                        $user->location_name = "School";
                    }
                }
            }
        }

        if ($request->has('latitude') && $request->has('longitude')) {
            $this->appendLocationHistory($user, $request->latitude, $request->longitude);
        }

        $user->save();
        $this->clearGlimpseCache($user->id);

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
                    
                    if ($couple->together_streak > $couple->highest_together_streak) {
                        $couple->highest_together_streak = $couple->together_streak;
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

    private function appendLocationHistory($user, $lat, $lng)
    {
        if ($lat === null || $lng === null) return;

        $history = $user->location_history ?? [];
        
        // Prevent duplicate consecutive updates
        if (!empty($history)) {
            $last = end($history);
            if (abs($last['latitude'] - $lat) < 0.00001 && abs($last['longitude'] - $lng) < 0.00001) {
                return;
            }
        }

        $history[] = [
            'latitude' => (double)$lat,
            'longitude' => (double)$lng,
            'timestamp' => now()->timestamp
        ];

        // ⏱️ Zenly Trail Decay: Auto-delete coordinates older than 3 hours (10,800 seconds)
        $threeHoursAgo = now()->timestamp - 10800;
        $history = array_filter($history, function($entry) use ($threeHoursAgo) {
            return isset($entry['timestamp']) && $entry['timestamp'] >= $threeHoursAgo;
        });
        $history = array_values($history);

        // Keep last 30 coordinates for the footprints trail
        if (count($history) > 30) {
            array_shift($history);
        }

        $user->location_history = $history;
    }

    private function getFilteredHistory($history)
    {
        if (empty($history)) return [];
        $threeHoursAgo = now()->timestamp - 10800;
        $filtered = array_filter($history, function($entry) use ($threeHoursAgo) {
            return isset($entry['timestamp']) && $entry['timestamp'] >= $threeHoursAgo;
        });
        return array_values($filtered);
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

    private function clearGlimpseCache($userId)
    {
        \Illuminate\Support\Facades\Cache::forget("glimpse_state_user_{$userId}");
        $user = \App\Models\User::find($userId);
        if ($user && $user->couple_id) {
            $partner = \App\Models\User::where('couple_id', $user->couple_id)
                ->where('id', '!=', $userId)
                ->first();
            if ($partner) {
                \Illuminate\Support\Facades\Cache::forget("glimpse_state_user_{$partner->id}");
            }
        }
    }

    public function createSchedule(Request $request)
    {
        $request->validate([
            'title' => 'required|string|max:200',
            'scheduled_at' => 'required|date',
            'reminder_minutes' => 'required|integer|min:0|max:1440',
        ]);

        $user = $request->user();
        if (!$user->couple_id) {
            return response()->json(['message' => 'No active relationship'], 400);
        }

        $schedule = \App\Models\Schedule::create([
            'couple_id' => $user->couple_id,
            'creator_id' => $user->id,
            'title' => $request->title,
            'scheduled_at' => $request->scheduled_at,
            'reminder_minutes' => $request->reminder_minutes,
            'status' => 'pending'
        ]);

        // Clear cache for both users
        $this->clearGlimpseCache($user->id);

        // Broadcast state update to both partners
        try {
            broadcast(new \App\Events\PartnerStateUpdated($user))->toOthers();
        } catch (\Exception $e) {}

        return response()->json($this->formatSchedule($schedule));
    }

    public function respondSchedule(Request $request, $id)
    {
        $request->validate([
            'response' => 'required|string|in:accepted,declined'
        ]);

        $user = $request->user();
        if (!$user->couple_id) {
            return response()->json(['message' => 'No active relationship'], 400);
        }

        $schedule = \App\Models\Schedule::where('couple_id', $user->couple_id)
            ->where('id', $id)
            ->firstOrFail();

        $schedule->status = $request->response;
        $schedule->save();

        // Clear cache
        $this->clearGlimpseCache($user->id);

        // Broadcast state update
        try {
            broadcast(new \App\Events\PartnerStateUpdated($user))->toOthers();
        } catch (\Exception $e) {}

        return response()->json($this->formatSchedule($schedule));
    }

    public function getSchedules(Request $request)
    {
        $user = $request->user();
        if (!$user->couple_id) {
            return response()->json([]);
        }

        $schedules = \App\Models\Schedule::where('couple_id', $user->couple_id)
            ->orderBy('scheduled_at', 'desc')
            ->get();

        $formatted = $schedules->map(function ($s) {
            return $this->formatSchedule($s);
        });

        return response()->json($formatted);
    }

    private function formatSchedule($schedule)
    {
        if (!$schedule) {
            return null;
        }
        return [
            'id' => (int)$schedule->id,
            'couple_id' => (int)$schedule->couple_id,
            'creator_id' => (int)$schedule->creator_id,
            'title' => (string)$schedule->title,
            'scheduled_at' => $schedule->scheduled_at instanceof \Carbon\Carbon ? $schedule->scheduled_at->toIso8601String() : \Carbon\Carbon::parse($schedule->scheduled_at)->toIso8601String(),
            'reminder_minutes' => (int)$schedule->reminder_minutes,
            'status' => (string)$schedule->status,
            'created_at' => $schedule->created_at ? ($schedule->created_at instanceof \Carbon\Carbon ? $schedule->created_at->toIso8601String() : \Carbon\Carbon::parse($schedule->created_at)->toIso8601String()) : null,
            'updated_at' => $schedule->updated_at ? ($schedule->updated_at instanceof \Carbon\Carbon ? $schedule->updated_at->toIso8601String() : \Carbon\Carbon::parse($schedule->updated_at)->toIso8601String()) : null,
        ];
    }
}

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
        \Illuminate\Support\Facades\Log::info("getState: Request received for user {$user->id}");

        $user->last_active_at = now();
        $user->save();
        $this->clearGlimpseCache($user->id);

        try {
            broadcast(new \App\Events\PartnerStateUpdated($user))->toOthers();
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::warning("Websocket broadcast failed in getState: " . $e->getMessage());
        }

        try {
            $cacheKey = "glimpse_state_user_{$user->id}";

            // Allow clients to force a fresh read (e.g. after profile/anniversary update)
            if ($request->boolean('fresh')) {
                \Illuminate\Support\Facades\Cache::forget($cacheKey);
                \Illuminate\Support\Facades\Log::info("getState: Cleared cache key {$cacheKey} (forced fresh request)");
            }

            $responseData = \Illuminate\Support\Facades\Cache::remember($cacheKey, 5, function() use ($user) {
                \Illuminate\Support\Facades\Log::info("getState: Cache miss for user {$user->id}. Building state.");
                // Find partner if in a couple
                $partner = null;
                $couple = null;
                if ($user->couple_id) {
                    $couple = \App\Models\Couple::find($user->couple_id);
                    
                    // Self-healing: if couple record doesn't exist, reset the ghost reference
                    if (!$couple) {
                        \Illuminate\Support\Facades\Log::warning("getState: Ghost couple reference detected for user {$user->id}. Resetting couple_id.");
                        $user->update(['couple_id' => null]);
                        $user->refresh();
                    } else {
                        $partner = \App\Models\User::where('couple_id', $user->couple_id)
                            ->where('id', '!=', $user->id)
                            ->first();
                        \Illuminate\Support\Facades\Log::info("getState: User {$user->id} belongs to couple {$user->couple_id}. Partner ID: " . ($partner ? $partner->id : 'none'));
                    }
                } else {
                    \Illuminate\Support\Facades\Log::info("getState: User {$user->id} is not in a couple.");
                }

                // Apply temp coordinates from cache if available to prevent database lag reads
                if ($tempUserCoord = \Cache::get("user_{$user->id}_temp_coordinate")) {
                    if (isset($tempUserCoord['latitude'])) $user->latitude = $tempUserCoord['latitude'];
                    if (isset($tempUserCoord['longitude'])) $user->longitude = $tempUserCoord['longitude'];
                    if (isset($tempUserCoord['location_name'])) $user->location_name = $tempUserCoord['location_name'];
                    if (isset($tempUserCoord['battery_level'])) $user->battery_level = $tempUserCoord['battery_level'];
                    if (isset($tempUserCoord['is_charging'])) $user->is_charging = $tempUserCoord['is_charging'];
                    if (isset($tempUserCoord['status_note'])) $user->status_note = $tempUserCoord['status_note'];
                }
                if ($partner && ($tempPartnerCoord = \Cache::get("user_{$partner->id}_temp_coordinate"))) {
                    if (isset($tempPartnerCoord['latitude'])) $partner->latitude = $tempPartnerCoord['latitude'];
                    if (isset($tempPartnerCoord['longitude'])) $partner->longitude = $tempPartnerCoord['longitude'];
                    if (isset($tempPartnerCoord['location_name'])) $partner->location_name = $tempPartnerCoord['location_name'];
                    if (isset($tempPartnerCoord['battery_level'])) $partner->battery_level = $tempPartnerCoord['battery_level'];
                    if (isset($tempPartnerCoord['is_charging'])) $partner->is_charging = $tempPartnerCoord['is_charging'];
                    if (isset($tempPartnerCoord['status_note'])) $partner->status_note = $tempPartnerCoord['status_note'];
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
                $pendingInvitation = null;
                if ($user->couple_id) {
                    // Get the closest accepted upcoming schedule
                    $activeSchedule = \App\Models\Schedule::where('couple_id', $user->couple_id)
                        ->where('scheduled_at', '>=', now())
                        ->where('status', 'accepted')
                        ->orderBy('scheduled_at', 'asc')
                        ->first();
                    
                    // Get the closest pending invitation from the partner
                    $pendingInvitation = \App\Models\Schedule::where('couple_id', $user->couple_id)
                        ->where('scheduled_at', '>=', now())
                        ->where('status', 'pending')
                        ->where('creator_id', '!=', $user->id)
                        ->orderBy('scheduled_at', 'asc')
                        ->first();

                    // Fallback: if no accepted schedule, show pending schedule created by the user
                    if (!$activeSchedule) {
                        $activeSchedule = \App\Models\Schedule::where('couple_id', $user->couple_id)
                            ->where('scheduled_at', '>=', now())
                            ->where('status', 'pending')
                            ->where('creator_id', $user->id)
                            ->orderBy('scheduled_at', 'asc')
                            ->first();
                    }
                }

                $userLatestFlash = null;
                if ($user->latest_photo_url) {
                    $userLatestFlash = \App\Models\Flash::where('sender_id', $user->id)->latest()->first();
                }
                
                $partnerLatestFlash = null;
                if ($partner && $partner->latest_photo_url) {
                    $partnerLatestFlash = \App\Models\Flash::where('sender_id', $partner->id)->latest()->first();
                }

                return [
                    'user' => [
                        'id' => (int)$user->id,
                        'name' => $user->name,
                        'email' => $user->email,
                        'email_verified_at' => $user->email_verified_at ? (\Carbon\Carbon::parse($user->email_verified_at)->toIso8601String()) : null,
                        'invite_code' => $user->invite_code,
                        'profile_photo_url' => $photoUrl ?? "https://ui-avatars.com/api/?name=" . urlencode($user->name),
                        'born_date' => $user->born_date,
                        'gender' => $user->gender,
                        'couple_id' => $user->couple_id !== null ? (int)$user->couple_id : null,
                        'latitude' => $user->latitude !== null ? (double)$user->latitude : null,
                        'longitude' => $user->longitude !== null ? (double)$user->longitude : null,
                        'location_name' => $user->location_name,
                        'battery_level' => $user->battery_level !== null ? (int)$user->battery_level : null,
                        'is_charging' => (bool)$user->is_charging,
                        'is_sleeping' => (bool)\Cache::get("user_{$user->id}_is_sleeping", false),
                        'status_note' => $user->status_note,
                        'latest_photo_url' => $latestPhotoUrl,
                        'latest_photo_latitude' => $userLatestFlash ? (double)$userLatestFlash->latitude : null,
                        'latest_photo_longitude' => $userLatestFlash ? (double)$userLatestFlash->longitude : null,
                        'latest_photo_location_name' => $userLatestFlash ? $userLatestFlash->location_name : null,
                        'latest_photo_status_note' => $userLatestFlash ? $userLatestFlash->status_note : null,
                        'latest_photo_battery_level' => $userLatestFlash ? ($userLatestFlash->battery_level !== null ? (int)$userLatestFlash->battery_level : null) : null,
                        'latest_photo_created_at' => $userLatestFlash && $userLatestFlash->created_at ? $userLatestFlash->created_at->toIso8601String() : null,
                        'last_updated' => $user->updated_at->toIso8601String(),
                        'last_active_at' => $user->last_active_at ? ($user->last_active_at instanceof \Carbon\Carbon ? $user->last_active_at->toIso8601String() : \Carbon\Carbon::parse($user->last_active_at)->toIso8601String()) : null,
                        'last_seen_message_id' => $user->last_seen_message_id !== null ? (int)$user->last_seen_message_id : null,
                        'location_history' => $this->getFilteredHistory($this->getUserLocationHistory($user)),
                    ],
                    'partner_data' => $partner ? [
                        'id' => (int)$partner->id,
                        'name' => $partner->name,
                        'email' => $partner->email,
                        'email_verified_at' => $partner->email_verified_at ? (\Carbon\Carbon::parse($partner->email_verified_at)->toIso8601String()) : null,
                        'profile_photo_url' => $partnerPhotoUrl ?? "https://ui-avatars.com/api/?name=" . urlencode($partner->name),
                        'born_date' => $partner->born_date,
                        'gender' => $partner->gender,
                        'couple_id' => $partner->couple_id !== null ? (int)$partner->couple_id : null,
                        'latitude' => $partner->latitude !== null ? (double)$partner->latitude : null,
                        'longitude' => $partner->longitude !== null ? (double)$partner->longitude : null,
                        'location_name' => $partner->location_name,
                        'battery_level' => $partner->battery_level !== null ? (int)$partner->battery_level : null,
                        'is_charging' => (bool)$partner->is_charging,
                        'is_sleeping' => (bool)\Cache::get("user_{$partner->id}_is_sleeping", false),
                        'status_note' => $partner->status_note,
                        'latest_photo_url' => $partnerLatestPhotoUrl,
                        'latest_photo_latitude' => $partnerLatestFlash ? (double)$partnerLatestFlash->latitude : null,
                        'latest_photo_longitude' => $partnerLatestFlash ? (double)$partnerLatestFlash->longitude : null,
                        'latest_photo_location_name' => $partnerLatestFlash ? $partnerLatestFlash->location_name : null,
                        'latest_photo_status_note' => $partnerLatestFlash ? $partnerLatestFlash->status_note : null,
                        'latest_photo_battery_level' => $partnerLatestFlash ? ($partnerLatestFlash->battery_level !== null ? (int)$partnerLatestFlash->battery_level : null) : null,
                        'latest_photo_created_at' => $partnerLatestFlash && $partnerLatestFlash->created_at ? $partnerLatestFlash->created_at->toIso8601String() : null,
                        'last_updated' => $partner->updated_at->toIso8601String(),
                        'last_active_at' => $partner->last_active_at ? ($partner->last_active_at instanceof \Carbon\Carbon ? $partner->last_active_at->toIso8601String() : \Carbon\Carbon::parse($partner->last_active_at)->toIso8601String()) : null,
                        'last_seen_message_id' => $partner->last_seen_message_id !== null ? (int)$partner->last_seen_message_id : null,
                        'location_history' => $this->getFilteredHistory($this->getUserLocationHistory($partner)),
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
                    'daily_bumps' => $couple ? (int)\Cache::get("couple_{$couple->id}_bumps_on_" . now()->toDateString(), 0) : 0,
                    'love_burst_timestamp' => $loveBurstTimestamp,
                    'active_schedule' => $this->formatSchedule($activeSchedule),
                    'pending_invitation' => $this->formatSchedule($pendingInvitation),
                ];
            });

            return response()->json($responseData);

        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::error("getState exception for user {$user->id}: " . $e->getMessage() . "\n" . $e->getTraceAsString());
            return response()->json([
                'message' => 'Internal server error in getState',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function updateProfile(Request $request)
    {
        $user = $request->user();
        $request->validate([
            'name' => 'sometimes|string|max:30',
            'email' => 'sometimes|email|max:100|unique:users,email,' . $user->id,
            'born_date' => 'sometimes|nullable|date',
            'gender' => 'sometimes|nullable|string|in:male,female',
            'profile_photo' => 'sometimes|file|mimes:jpeg,png,jpg,gif,svg,webp|max:5120'
        ]);

        if ($request->has('name')) $user->name = $request->name;
        if ($request->has('born_date')) $user->born_date = $request->born_date;
        if ($request->has('gender')) $user->gender = $request->gender;
        
        if ($request->hasFile('profile_photo')) {
            if ($user->profile_photo_url && !str_contains($user->profile_photo_url, 'ui-avatars')) {
                Storage::disk('public')->delete('avatars/' . basename($user->profile_photo_url));
            }
            $path = $request->file('profile_photo')->store('avatars', 'public');
            $user->profile_photo_url = Storage::url($path);
        }

        $emailChangePending = false;
        if ($request->has('email') && $request->email !== $user->email) {
            $emailChangePending = true;
            $newEmail = $request->email;
            
            // Generate and cache OTP for new email
            $otp = sprintf("%06d", mt_rand(100000, 999999));
            \Illuminate\Support\Facades\Cache::put("pending_email_{$user->id}", $newEmail, 900);
            \Illuminate\Support\Facades\Cache::put("pending_email_otp_{$user->id}", $otp, 900);
            
            // Send verification email to the new address
            try {
                \Illuminate\Support\Facades\Mail::to($newEmail)->send(new \App\Mail\EmailVerificationMail($user, $otp));
                \Illuminate\Support\Facades\Log::info("Profile email change verification sent to {$newEmail}");
            } catch (\Exception $e) {
                \Illuminate\Support\Facades\Log::error("SMTP ERROR sending profile email verification: " . $e->getMessage());
            }
        }

        $user->save();
        $this->clearGlimpseCache($user->id);
        
        $photoUrl = $user->profile_photo_url;
        if ($photoUrl && !str_starts_with($photoUrl, 'http')) {
            $photoUrl = url($photoUrl);
        }

        if ($emailChangePending) {
            return response()->json([
                'message' => 'Profile updated. Verification code sent to your new email.',
                'email_change_pending' => true,
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email, // keep current email
                    'born_date' => $user->born_date,
                    'gender' => $user->gender,
                    'profile_photo_url' => $photoUrl ?? "https://ui-avatars.com/api/?name=" . urlencode($user->name),
                ]
            ]);
        }

        return response()->json([
            'message' => 'Profile updated!', 
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'born_date' => $user->born_date,
                'gender' => $user->gender,
                'profile_photo_url' => $photoUrl ?? "https://ui-avatars.com/api/?name=" . urlencode($user->name),
            ]
        ]);
    }

    public function verifyEmailChange(Request $request)
    {
        $request->validate([
            'otp' => 'required|string|size:6'
        ]);

        $user = $request->user();
        $pendingEmail = \Illuminate\Support\Facades\Cache::get("pending_email_{$user->id}");
        $cachedOtp = \Illuminate\Support\Facades\Cache::get("pending_email_otp_{$user->id}");

        if (!$pendingEmail || !$cachedOtp) {
            return response()->json(['message' => 'No pending email change request found or verification code has expired.'], 422);
        }

        if ($cachedOtp !== $request->otp) {
            return response()->json(['message' => 'Invalid or expired verification code'], 422);
        }

        // Save the new email and mark as verified
        $user->email = $pendingEmail;
        $user->email_verified_at = now();
        $user->save();

        // Clear cache
        \Illuminate\Support\Facades\Cache::forget("pending_email_{$user->id}");
        \Illuminate\Support\Facades\Cache::forget("pending_email_otp_{$user->id}");
        $this->clearGlimpseCache($user->id);

        $photoUrl = $user->profile_photo_url;
        if ($photoUrl && !str_starts_with($photoUrl, 'http')) {
            $photoUrl = url($photoUrl);
        }

        return response()->json([
            'message' => 'Email updated successfully!',
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'born_date' => $user->born_date,
                'gender' => $user->gender,
                'profile_photo_url' => $photoUrl ?? "https://ui-avatars.com/api/?name=" . urlencode($user->name),
            ]
        ]);
    }

    public function resendEmailChangeVerification(Request $request)
    {
        $user = $request->user();
        $pendingEmail = \Illuminate\Support\Facades\Cache::get("pending_email_{$user->id}");

        if (!$pendingEmail) {
            return response()->json(['message' => 'No pending email change request found.'], 422);
        }

        $otp = sprintf("%06d", mt_rand(100000, 999999));
        \Illuminate\Support\Facades\Cache::put("pending_email_otp_{$user->id}", $otp, 900);

        try {
            \Illuminate\Support\Facades\Mail::to($pendingEmail)->send(new \App\Mail\EmailVerificationMail($user, $otp));
            return response()->json(['message' => 'Verification code resent successfully to ' . $pendingEmail]);
        } catch (\Exception $e) {
            return response()->json(['message' => 'Failed to send verification code. Please try again.'], 500);
        }
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
        
        // Self-healing: Clear ghost couple references for current user
        if ($user->couple_id) {
            if (!\App\Models\Couple::where('id', $user->couple_id)->exists()) {
                $user->update(['couple_id' => null]);
                \Illuminate\Support\Facades\Cache::forget("glimpse_state_user_{$user->id}");
            }
        }
        
        $targetUser = \App\Models\User::where('invite_code', $request->invite_code)->first();
        
        if (!$targetUser) {
            return response()->json(['message' => 'Invalid invite code'], 404);
        }
        
        // Self-healing: Clear ghost couple references for target user
        if ($targetUser->couple_id) {
            if (!\App\Models\Couple::where('id', $targetUser->couple_id)->exists()) {
                $targetUser->update(['couple_id' => null]);
                \Illuminate\Support\Facades\Cache::forget("glimpse_state_user_{$targetUser->id}");
            }
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

        // Evict caches immediately so targetUser sees the invitation without any delay
        $this->clearGlimpseCache($user->id);
        $this->clearGlimpseCache($targetUser->id);

        // Broadcast so the target user's app gets the pending invite instantly via WebSocket
        try {
            broadcast(new \App\Events\CoupleStatusChanged($coupleId, null, false));
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::warning("Connect broadcast failed: " . $e->getMessage());
        }

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

                // Broadcast to notify the inviter that their request was accepted
                try {
                    broadcast(new \App\Events\CoupleStatusChanged($user->couple_id, null, true));
                } catch (\Exception $e) {
                    \Illuminate\Support\Facades\Log::warning("Accept connect broadcast failed: " . $e->getMessage());
                }

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
            
            // Find ALL users in this couple BEFORE clearing anything
            $coupleUsers = \App\Models\User::where('couple_id', $coupleId)->get();
            
            // Clear cache for ALL couple members
            foreach ($coupleUsers as $u) {
                \Illuminate\Support\Facades\Cache::forget("glimpse_state_user_{$u->id}");
            }
            
            // Now break the relationship
            \App\Models\User::where('couple_id', $coupleId)->update(['couple_id' => null]);
            \App\Models\Couple::where('id', $coupleId)->delete();
            
            // Broadcast so partner's app reacts instantly
            try {
                broadcast(new \App\Events\CoupleStatusChanged($coupleId, null, false));
            } catch (\Exception $e) {
                \Illuminate\Support\Facades\Log::warning("Decline connect broadcast failed: " . $e->getMessage());
            }
            
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
                try {
                    broadcast(new \App\Events\CoupleStatusChanged($user->couple_id, $user->id, true))->toOthers();
                } catch (\Exception $e) {
                    \Illuminate\Support\Facades\Log::warning("Disconnect broadcast failed: " . $e->getMessage());
                }
            }
        }
        return response()->json(['message' => 'Disconnect request sent']);
    }

    public function approveDisconnect(Request $request)
    {
        $user = $request->user();
        if ($user->couple_id) {
            $coupleId = $user->couple_id;
            try {
                broadcast(new \App\Events\CoupleStatusChanged($coupleId, null, false))->toOthers();
            } catch (\Exception $e) {
                \Illuminate\Support\Facades\Log::warning("Approve disconnect broadcast failed: " . $e->getMessage());
            }
            
            // CRITICAL: Clear cache BEFORE breaking relationship! Otherwise partner cannot be found!
            $this->clearGlimpseCache($user->id);
            
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
                $this->clearGlimpseCache($user->id);
                try {
                    broadcast(new \App\Events\CoupleStatusChanged($user->couple_id, null, true))->toOthers();
                } catch (\Exception $e) {
                    \Illuminate\Support\Facades\Log::warning("Cancel disconnect broadcast failed: " . $e->getMessage());
                }
            }
        }
        return response()->json(['message' => 'Disconnect request cancelled']);
    }

    public function uploadPhoto(Request $request)
    {
        $request->validate([
            'photo' => 'required|file|mimes:jpeg,png,jpg,gif,svg,webp|max:10240', // Max 10MB
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

        // Clean up flashes older than 24 hours along with their images
        $oldFlashes = \App\Models\Flash::where('created_at', '<', now()->subDays(1))->get();
        foreach ($oldFlashes as $oldFlash) {
            $this->deleteFlashFile($oldFlash->photo_url);
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

        $roomId = $request->query('room_id');
        
        // Find or create Main Room if none exists for this couple
        $mainRoom = \DB::table('chat_rooms')
            ->where('couple_id', $user->couple_id)
            ->where('is_main', true)
            ->first();
            
        if (!$mainRoom) {
            $mainRoomId = \DB::table('chat_rooms')->insertGetId([
                'couple_id' => $user->couple_id,
                'name' => 'General Chat',
                'is_main' => true,
                'created_at' => now(),
                'updated_at' => now()
            ]);
        } else {
            $mainRoomId = $mainRoom->id;
        }

        $query = \App\Models\Message::where('couple_id', $user->couple_id);
        
        if ($roomId) {
            $query->where('room_id', $roomId);
        } else {
            // Default to General Chat messages (either room_id = mainRoomId or room_id is null for compatibility with old messages!)
            $query->where(function($q) use ($mainRoomId) {
                $q->where('room_id', $mainRoomId)
                  ->orWhereNull('room_id');
            });
        }

        $messages = $query->orderBy('created_at', 'asc')
            ->take(100)
            ->get();

        return response()->json($messages);
    }

    public function sendMessage(Request $request)
    {
        $messageText = '';
        $roomId = null;
        $isProtobuf = $request->header('Content-Type') === 'application/x-protobuf';

        if ($isProtobuf) {
            $protoData = $request->getContent();
            $decoded = \App\Helpers\GlimpseProtobuf::decodeMessage($protoData);
            $messageText = $decoded['message'] ?? '';
            $roomId = $decoded['room_id'] ?? null;
        } else {
            $request->validate([
                'message' => 'required|string|max:500',
                'room_id' => 'nullable|integer'
            ]);
            $messageText = $request->input('message');
            $roomId = $request->input('room_id');
        }

        $user = $request->user();

        if (!$user->couple_id) {
            return response()->json(['message' => 'No active couple relationship'], 400);
        }

        $couple = \App\Models\Couple::find($user->couple_id);
        if (!$couple || $couple->is_active == 0) {
            return response()->json(['message' => 'Relationship is not active'], 400);
        }

        if (!$roomId) {
            // Find or create Main Room
            $mainRoom = \DB::table('chat_rooms')
                ->where('couple_id', $user->couple_id)
                ->where('is_main', true)
                ->first();
                
            if (!$mainRoom) {
                $roomId = \DB::table('chat_rooms')->insertGetId([
                    'couple_id' => $user->couple_id,
                    'name' => 'General Chat',
                    'is_main' => true,
                    'created_at' => now(),
                    'updated_at' => now()
                ]);
            } else {
                $roomId = $mainRoom->id;
            }
        }

        $msg = \App\Models\Message::create([
            'couple_id' => $user->couple_id,
            'sender_id' => $user->id,
            'message' => $messageText,
            'room_id' => $roomId
        ]);

        // Automatically mark all messages in this room as read for the sender!
        if ($msg->id > $user->last_seen_message_id) {
            $user->last_seen_message_id = $msg->id;
        }
        $map = json_decode($user->last_seen_room_messages ?: '{}', true) ?: [];
        $map[$roomId ?: 0] = (int)$msg->id;
        $user->last_seen_room_messages = json_encode($map);
        $user->last_active_at = now();
        $user->save();
        $this->clearGlimpseCache($user->id);

        // Broadcast MessageSent event to the partner over WebSockets
        try {
            broadcast(new \App\Events\MessageSent($msg))->toOthers();
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::warning("Websocket broadcast failed: " . $e->getMessage());
        }

        if ($isProtobuf || $request->header('Accept') === 'application/x-protobuf') {
            $protobufBinary = \App\Helpers\GlimpseProtobuf::encodeMessage($msg);
            return response($protobufBinary)
                ->header('Content-Type', 'application/x-protobuf');
        }

        return response()->json($msg);
    }

    public function markAsRead(Request $request)
    {
        $request->validate(['message_id' => 'required|integer']);
        $user = $request->user();

        $message = \App\Models\Message::find($request->message_id);
        if ($message) {
            $roomId = $message->room_id ?: 0;
            $map = json_decode($user->last_seen_room_messages ?: '{}', true) ?: [];
            
            $currentLastSeen = $map[$roomId] ?? 0;
            if ($request->message_id > $currentLastSeen) {
                $map[$roomId] = (int)$request->message_id;
                $user->last_seen_room_messages = json_encode($map);
            }
        }

        if ($request->message_id > $user->last_seen_message_id) {
            $user->last_seen_message_id = $request->message_id;
        }

        $user->save();
        $this->clearGlimpseCache($user->id);

        try {
            broadcast(new \App\Events\PartnerStateUpdated($user))->toOthers();
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::warning("Websocket broadcast failed: " . $e->getMessage());
        }

        return response()->json([
            'status' => 'ok', 
            'last_seen_message_id' => $user->last_seen_message_id,
            'last_seen_room_messages' => json_decode($user->last_seen_room_messages ?: '{}', true)
        ]);
    }

    public function requestSyncLocation(Request $request)
    {
        $user = $request->user();
        if (!$user->couple_id) {
            return response()->json(['message' => 'No couple ID found'], 400);
        }
        
        $targetUserId = $request->input('target_user_id', $user->id);
        
        event(new \App\Events\SyncLocationRequested($user->couple_id, $targetUserId));

        return response()->json(['message' => 'Sync location requested']);
    }

    public function updateStatus(Request $request)
    {
        $isProtobuf = $request->header('Content-Type') === 'application/x-protobuf';
        $data = [];

        if ($isProtobuf) {
            $protoData = $request->getContent();
            $data = \App\Helpers\GlimpseProtobuf::decodeUserStatus($protoData);
        } else {
            $request->validate([
                'latitude' => 'nullable|numeric',
                'longitude' => 'nullable|numeric',
                'battery_level' => 'nullable|integer',
                'is_charging' => 'nullable|boolean',
                'status_note' => 'nullable|string|max:30',
                'location_name' => 'nullable|string|max:255',
                'wifi_bssid' => 'nullable|string|max:255',
            ]);
            $data = $request->all();
        }

        $user = $request->user();
        
        if ($request->has('is_sleeping')) {
            $isSleeping = filter_var($request->input('is_sleeping'), FILTER_VALIDATE_BOOLEAN);
            if ($isSleeping) {
                \Cache::put("user_{$user->id}_is_sleeping", true, 86400);
            } else {
                \Cache::forget("user_{$user->id}_is_sleeping");
            }
        }
        
        if (array_key_exists('latitude', $data) && $data['latitude'] !== null) $user->latitude = $data['latitude'];
        if (array_key_exists('longitude', $data) && $data['longitude'] !== null) $user->longitude = $data['longitude'];
        if (array_key_exists('battery_level', $data) && $data['battery_level'] !== null) $user->battery_level = $data['battery_level'];
        if (array_key_exists('is_charging', $data) && $data['is_charging'] !== null) {
            $user->is_charging = $data['is_charging'] ? 1 : 0;
        }
        if (array_key_exists('status_note', $data) && $data['status_note'] !== null) $user->status_note = $data['status_note'];
        if (array_key_exists('location_name', $data) && $data['location_name'] !== null) $user->location_name = $data['location_name'];

        // 🏡 Smart Place Anchor & Cozy Labeling (Zenly Style)
        $lat = $user->latitude;
        $lng = $user->longitude;
        $wifiBssid = $data['wifi_bssid'] ?? null;

        if ($lat !== null && $lng !== null) {
            $today = now()->format('Y-m-d');
            $hour = (int)now()->format('H');
            $dayOfWeek = (int)now()->format('N'); // 1 (Mon) - 7 (Sun)
            
            // Check if stationary (within ~30 meters of last coordinate in history)
            $isStationary = false;
            $history = $this->getUserLocationHistory($user);
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
                // Get or initialize the user's place visits log from Cache
                $placeLog = \Cache::get("user_{$user->id}_place_visits_log", [
                    'work_visits' => [],
                    'home_visits' => []
                ]);
                
                $roundedLat = round($lat, 4);
                $roundedLng = round($lng, 4);
                
                // 1. Log visits based on timeslots
                if ($hour >= 9 && $hour <= 17 && $dayOfWeek >= 1 && $dayOfWeek <= 5) {
                    // Day slot (Work) - Mon to Fri
                    $placeLog['work_visits'][$today] = [
                        'lat' => $roundedLat,
                        'lng' => $roundedLng
                    ];
                }
                
                if ($hour >= 20 || $hour < 6) {
                    // Night slot (Home)
                    $placeLog['home_visits'][$today] = [
                        'lat' => $roundedLat,
                        'lng' => $roundedLng,
                        'wifi' => $wifiBssid
                    ];
                }
                
                // Keep only the last 7 days of logs to avoid bloating
                $sevenDaysAgo = now()->subDays(7)->format('Y-m-d');
                $placeLog['work_visits'] = array_filter($placeLog['work_visits'], function($date) use ($sevenDaysAgo) {
                    return $date >= $sevenDaysAgo;
                }, ARRAY_FILTER_USE_KEY);
                $placeLog['home_visits'] = array_filter($placeLog['home_visits'], function($date) use ($sevenDaysAgo) {
                    return $date >= $sevenDaysAgo;
                }, ARRAY_FILTER_USE_KEY);
                
                \Cache::put("user_{$user->id}_place_visits_log", $placeLog, 86400 * 7); // Cache for 7 days
                
                // 2. Classify based on 3 consecutive days rule
                $isHomeClassified = false;
                $isWorkClassified = false;
                
                // Check Home: 3 consecutive days during night hours
                $consecutiveHomeDays = 0;
                $matchingWifiName = false;
                
                for ($i = 0; $i < 3; $i++) {
                    $checkDate = now()->subDays($i)->format('Y-m-d');
                    if (isset($placeLog['home_visits'][$checkDate])) {
                        $visit = $placeLog['home_visits'][$checkDate];
                        if (abs($visit['lat'] - $roundedLat) < 0.0005 && abs($visit['lng'] - $roundedLng) < 0.0005) {
                            $consecutiveHomeDays++;
                            if ($visit['wifi'] !== null && $wifiBssid !== null && $visit['wifi'] === $wifiBssid) {
                                $matchingWifiName = true;
                            }
                        }
                    }
                }
                
                if ($consecutiveHomeDays >= 3) {
                    $user->location_name = "Home";
                    $isHomeClassified = true;
                    
                    // 3. Sleep Detection (ZZZ): 
                    // If at Home, at night (20:00 - 06:00), and stationary for more than 3 hours
                    if (!$request->has('is_sleeping')) {
                        if ($hour >= 20 || $hour < 6) {
                            $homeArrival = \Cache::get("user_{$user->id}_home_arrival_time");
                            if ($homeArrival === null) {
                                \Cache::put("user_{$user->id}_home_arrival_time", now()->timestamp, 86400);
                            } else {
                                $duration = now()->timestamp - $homeArrival;
                                if ($duration >= 10800) { // 3 hours
                                    \Cache::put("user_{$user->id}_is_sleeping", true, 86400);
                                }
                            }
                        } else {
                            // Reset sleep state during daytime
                            \Cache::forget("user_{$user->id}_home_arrival_time");
                            \Cache::forget("user_{$user->id}_is_sleeping");
                        }
                    }
                } else {
                    if (!$request->has('is_sleeping')) {
                        \Cache::forget("user_{$user->id}_home_arrival_time");
                        \Cache::forget("user_{$user->id}_is_sleeping");
                    }
                }
                
                // Check Work: 3 consecutive days during 9-17 Mon-Fri
                if (!$isHomeClassified) {
                    $consecutiveWorkDays = 0;
                    for ($i = 0; $i < 3; $i++) {
                        $checkDate = now()->subDays($i)->format('Y-m-d');
                        if (isset($placeLog['work_visits'][$checkDate])) {
                            $visit = $placeLog['work_visits'][$checkDate];
                            if (abs($visit['lat'] - $roundedLat) < 0.0005 && abs($visit['lng'] - $roundedLng) < 0.0005) {
                                $consecutiveWorkDays++;
                            }
                        }
                    }
                    
                    if ($consecutiveWorkDays >= 3) {
                        $user->location_name = "Work";
                        $isWorkClassified = true;
                    }
                }
                
                // If not classified as Home or Work, keep the geocoded address or set to null
                if (!$isHomeClassified && !$isWorkClassified) {
                    if (in_array($user->location_name, ["Home", "Work", "School"])) {
                        $user->location_name = null; // Remove standard labels if not qualified!
                    }
                }
            } else {
                // If moving, user is definitely not sleeping!
                \Cache::forget("user_{$user->id}_home_arrival_time");
                \Cache::forget("user_{$user->id}_is_sleeping");
                if (in_array($user->location_name, ["Home", "Work", "School"])) {
                    $user->location_name = null;
                }
            }
        }

        if (isset($data['latitude']) && isset($data['longitude']) && $data['latitude'] !== null && $data['longitude'] !== null) {
            $this->appendLocationHistory($user, $data['latitude'], $data['longitude']);
        }

        // --- Database Write Throttling (Zenly Speed Optimization) ---
        $lastDbWrite = (int)\Cache::get("user_{$user->id}_last_db_write", 0);
        $currentTime = time();
        $shouldSaveToDb = ($currentTime - $lastDbWrite) >= 10; // Save to DB at most once every 10 seconds
        if ($shouldSaveToDb) {
            $user->save();
            \Cache::put("user_{$user->id}_last_db_write", $currentTime, 3600);
        } else {
            // If throttling DB, we still save the coordinate in Cache to prevent stale reads
            \Cache::put("user_{$user->id}_temp_coordinate", [
                'latitude' => $user->latitude,
                'longitude' => $user->longitude,
                'location_name' => $user->location_name,
                'battery_level' => $user->battery_level,
                'is_charging' => $user->is_charging,
                'status_note' => $user->status_note,
                'updated_at' => now()->toIso8601String()
            ], 60);
        }

        // Always invalidate state caches so clients fetch fresh temp coordinates instantly
        $this->clearGlimpseCache($user->id);

        // Broadcast live state updates to the partner instantly over WebSockets (ALWAYS broadcast!)
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

        $isTogether = ($distance <= 250); // 250 meters threshold for GPS drift stability

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

    private function getUserLocationHistory($user)
    {
        $cacheKey = "user_{$user->id}_location_history";
        $history = \Cache::get($cacheKey);
        if ($history === null) {
            $history = is_array($user->location_history) ? $user->location_history : [];
            \Cache::put($cacheKey, $history, 10800); // 3 hours cache
        }
        return $history;
    }

    private function appendLocationHistory($user, $lat, $lng)
    {
        if ($lat === null || $lng === null) return;

        $history = $this->getUserLocationHistory($user);
        
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

        // Keep last 2 coordinates for the dead-reckoning (speed & heading extrapolation)
        if (count($history) > 2) {
            $history = array_slice($history, -2);
        }

        \Cache::put("user_{$user->id}_location_history", $history, 10800);
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
        $reaction = $request->input('reaction');
        
        \Illuminate\Support\Facades\Cache::put("couple_{$user->couple_id}_love_burst", [
            'timestamp' => $timestamp,
            'sender_id' => $user->id,
            'reaction' => $reaction
        ], 60);

        // Broadcast LoveBurstSent event to partner instantly over WebSockets
        try {
            broadcast(new \App\Events\LoveBurstSent($user->couple_id, $user->id, $timestamp, $reaction))->toOthers();
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::warning("Websocket broadcast failed: " . $e->getMessage());
        }

        return response()->json([
            'message' => 'Love burst triggered!',
            'timestamp' => $timestamp
        ]);
    }

    public function triggerBump(Request $request)
    {
        $user = $request->user();
        if (!$user->couple_id) {
            return response()->json(['message' => 'No active relationship'], 400);
        }

        $couple = \App\Models\Couple::find($user->couple_id);
        if (!$couple) {
            return response()->json(['message' => 'Couple not found'], 404);
        }

        $partner = \App\Models\User::where('couple_id', $user->couple_id)
            ->where('id', '!=', $user->id)
            ->first();

        if (!$partner) {
            return response()->json(['message' => 'Partner not found'], 404);
        }

        // Cache handshake keys
        $partnerShakeKey = "couple_{$couple->id}_shake_by_{$partner->id}";
        $myShakeKey = "couple_{$couple->id}_shake_by_{$user->id}";

        if (\Cache::has($partnerShakeKey)) {
            // Both shook at the same time! Register the bump!
            \Cache::forget($partnerShakeKey);
            \Cache::forget($myShakeKey);

            $today = now()->toDateString();
            $yesterday = now()->subDay()->toDateString();

            // Track daily bump count in cache
            $cacheKey = "couple_{$couple->id}_bumps_on_{$today}";
            $dailyBumps = (int)\Cache::get($cacheKey, 0);
            $dailyBumps++;
            \Cache::put($cacheKey, $dailyBumps, 86400); // 1 day TTL

            if ($couple->last_meeting_date !== $today) {
                // First bump/meetup of the day!
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
            }

            $this->clearGlimpseCache($user->id);

            // Broadcast bump count and total meetings
            try {
                broadcast(new \App\Events\LoveBumpSent($user->couple_id, $user->id, (int)$couple->total_meetings, $dailyBumps))->toOthers();
            } catch (\Exception $e) {
                \Illuminate\Support\Facades\Log::warning("Websocket broadcast failed: " . $e->getMessage());
            }

            return response()->json([
                'status' => 'success',
                'message' => 'Bump registered!',
                'total_meetings' => (int)$couple->total_meetings,
                'daily_bumps' => $dailyBumps
            ]);
        } else {
            // Record current user shake and wait for partner (10 seconds timeout)
            \Cache::put($myShakeKey, true, 10);

            return response()->json([
                'status' => 'waiting',
                'message' => 'Waiting for partner to shake'
            ]);
        }
    }

    public function broadcastTyping(Request $request)
    {
        $request->validate([
            'is_typing' => 'required|boolean',
            'room_id' => 'nullable|integer'
        ]);
        $user = $request->user();
        if (!$user->couple_id) {
            return response()->json(['message' => 'No active couple'], 400);
        }

        $user->last_active_at = now();
        $user->save();
        $this->clearGlimpseCache($user->id);

        try {
            broadcast(new \App\Events\PartnerTyping($user->couple_id, $user->id, $request->is_typing, $request->room_id))->toOthers();
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::warning("Websocket broadcast failed: " . $e->getMessage());
        }

        return response()->json(['status' => 'ok']);
    }

    public function ping(Request $request)
    {
        $user = $request->user();
        $user->last_active_at = now();
        $user->save();

        try {
            broadcast(new \App\Events\PartnerStateUpdated($user))->toOthers();
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::warning("Websocket broadcast failed in ping: " . $e->getMessage());
        }

        return response()->json(['status' => 'ok']);
    }

    public function goOffline(Request $request)
    {
        $user = $request->user();
        $user->last_active_at = now()->subSeconds(700); // Backdate last_active_at so they appear offline (> 660s threshold)
        $user->save();

        $this->clearGlimpseCache($user->id);

        try {
            broadcast(new \App\Events\PartnerStateUpdated($user))->toOthers();
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::warning("Websocket broadcast failed in goOffline: " . $e->getMessage());
        }

        return response()->json(['status' => 'ok']);
    }

    private function clearGlimpseCache($userId)
    {
        \Illuminate\Support\Facades\Cache::forget("glimpse_state_user_{$userId}");
        $user = \App\Models\User::find($userId);
        if ($user && $user->couple_id) {
            $users = \App\Models\User::where('couple_id', $user->couple_id)->get();
            foreach ($users as $u) {
                \Illuminate\Support\Facades\Cache::forget("glimpse_state_user_{$u->id}");
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

    public function deleteSchedule(Request $request, $id)
    {
        $user = $request->user();
        if (!$user->couple_id) {
            return response()->json(['message' => 'Not in a couple relationship'], 400);
        }

        $schedule = \App\Models\Schedule::where('couple_id', $user->couple_id)
            ->where('id', $id)
            ->first();

        if (!$schedule) {
            return response()->json(['message' => 'Schedule not found'], 404);
        }

        if ($schedule->creator_id !== $user->id) {
            return response()->json(['message' => 'Only the creator can delete this invitation'], 403);
        }

        $schedule->delete();

        try {
            broadcast(new \App\Events\PartnerStateUpdated($user))->toOthers();
        } catch (\Exception $e) {}

        return response()->json(['message' => 'Schedule successfully deleted']);
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

    public function getChatRooms(Request $request)
    {
        $user = $request->user();
        if (!$user->couple_id) {
            return response()->json(['message' => 'No active couple relationship'], 400);
        }

        // 1. Ensure Main Room (General Chat) exists
        $mainRoom = \DB::table('chat_rooms')
            ->where('couple_id', $user->couple_id)
            ->where('is_main', true)
            ->first();

        if (!$mainRoom) {
            \DB::table('chat_rooms')->insert([
                'couple_id' => $user->couple_id,
                'name' => 'General Chat',
                'is_main' => true,
                'created_at' => now(),
                'updated_at' => now()
            ]);
        }

        // 2. Fetch all rooms
        $rooms = \DB::table('chat_rooms')
            ->where('couple_id', $user->couple_id)
            ->orderBy('is_main', 'desc')
            ->orderBy('created_at', 'asc')
            ->get();

        $formattedRooms = [];
        foreach ($rooms as $room) {
            // Find latest message in this room
            // For Main Room, it can also include messages with room_id = null (backward compatibility)
            $latestQuery = \App\Models\Message::where('couple_id', $user->couple_id);
            if ($room->is_main) {
                $latestQuery->where(function($q) use ($room) {
                    $q->where('room_id', $room->id)
                      ->orWhereNull('room_id');
                });
            } else {
                $latestQuery->where('room_id', $room->id);
            }
            
            $latestMessage = $latestQuery->orderBy('created_at', 'desc')->first();

            // Calculate unread count
            $unreadQuery = \App\Models\Message::where('couple_id', $user->couple_id)
                ->where('sender_id', '!=', $user->id);
                
            if ($room->is_main) {
                $unreadQuery->where(function($q) use ($room) {
                    $q->where('room_id', $room->id)
                      ->orWhereNull('room_id');
                });
            } else {
                $unreadQuery->where('room_id', $room->id);
            }

            $roomIdKey = $room->is_main ? 0 : $room->id;
            $map = json_decode($user->last_seen_room_messages ?: '{}', true) ?: [];
            $roomLastSeen = $map[$roomIdKey] ?? ($map[$room->id] ?? null);

            if ($roomLastSeen !== null) {
                $unreadQuery->where('id', '>', $roomLastSeen);
            } else {
                if ($user->last_seen_message_id !== null) {
                    $unreadQuery->where('id', '>', $user->last_seen_message_id);
                }
            }

            $unreadCount = $unreadQuery->count();

            $formattedRooms[] = [
                'id' => (int)$room->id,
                'couple_id' => (int)$room->couple_id,
                'name' => (string)$room->name,
                'is_main' => (bool)$room->is_main,
                'theme_color' => $room->theme_color,
                'background_color' => $room->background_color,
                'delete_requested_by' => $room->delete_requested_by ? (int)$room->delete_requested_by : null,
                'latest_message' => $latestMessage ? [
                    'id' => (int)$latestMessage->id,
                    'message' => (string)$latestMessage->message,
                    'sender_id' => (int)$latestMessage->sender_id,
                    'created_at' => $latestMessage->created_at instanceof \Carbon\Carbon ? $latestMessage->created_at->toIso8601String() : \Carbon\Carbon::parse($latestMessage->created_at)->toIso8601String(),
                ] : null,
                'unread_count' => (int)$unreadCount,
                'created_at' => \Carbon\Carbon::parse($room->created_at)->toIso8601String(),
                'updated_at' => \Carbon\Carbon::parse($room->updated_at)->toIso8601String(),
            ];
        }

        return response()->json($formattedRooms);
    }

    public function createChatRoom(Request $request)
    {
        $request->validate(['name' => 'required|string|max:100']);
        $user = $request->user();

        if (!$user->couple_id) {
            return response()->json(['message' => 'No active couple relationship'], 400);
        }

        $id = \DB::table('chat_rooms')->insertGetId([
            'couple_id' => $user->couple_id,
            'name' => $request->name,
            'is_main' => false,
            'created_at' => now(),
            'updated_at' => now()
        ]);

        $room = \DB::table('chat_rooms')->find($id);

        $formatted = [
            'id' => (int)$room->id,
            'couple_id' => (int)$room->couple_id,
            'name' => (string)$room->name,
            'is_main' => (bool)$room->is_main,
            'delete_requested_by' => null,
            'latest_message' => null,
            'unread_count' => 0,
            'created_at' => \Carbon\Carbon::parse($room->created_at)->toIso8601String(),
            'updated_at' => \Carbon\Carbon::parse($room->updated_at)->toIso8601String(),
        ];

        // Broadcast real-time Pusher event
        try {
            broadcast(new \App\Events\ChatRoomCreated($user->couple_id, $formatted))->toOthers();
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::warning("Websocket broadcast failed: " . $e->getMessage());
        }

        return response()->json($formatted);
    }

    public function deleteChatRoom(Request $request, $id)
    {
        $user = $request->user();
        if (!$user->couple_id) {
            return response()->json(['message' => 'No active couple relationship'], 400);
        }

        $room = \DB::table('chat_rooms')
            ->where('couple_id', $user->couple_id)
            ->where('id', $id)
            ->first();

        if (!$room) {
            return response()->json(['message' => 'Chat room not found'], 404);
        }

        if ($room->is_main) {
            return response()->json(['message' => 'Cannot delete main chat room'], 400);
        }

        // Delete the room (cascade will automatically delete messages!)
        \DB::table('chat_rooms')->where('id', $id)->delete();

        // Broadcast real-time delete event
        try {
            broadcast(new \App\Events\ChatRoomDeleted($user->couple_id, (int)$id))->toOthers();
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::warning("Websocket broadcast failed: " . $e->getMessage());
        }

        return response()->json(['status' => 'ok']);
    }

    public function renameChatRoom(Request $request, $id)
    {
        $user = $request->user();
        if (!$user->couple_id) {
            return response()->json(['message' => 'No active couple relationship'], 400);
        }

        $request->validate([
            'name' => 'required|string|max:50'
        ]);

        $room = \DB::table('chat_rooms')
            ->where('couple_id', $user->couple_id)
            ->where('id', $id)
            ->first();

        if (!$room) {
            return response()->json(['message' => 'Chat room not found'], 404);
        }

        if ($room->is_main) {
            return response()->json(['message' => 'Cannot rename main chat room'], 400);
        }

        $newName = $request->input('name');
        \DB::table('chat_rooms')->where('id', $id)->update([
            'name' => $newName,
            'updated_at' => now()
        ]);

        try {
            broadcast(new \App\Events\ChatRoomUpdated($user->couple_id, (int)$id, $newName))->toOthers();
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::warning("Websocket broadcast failed: " . $e->getMessage());
        }

        return response()->json([
            'status' => 'ok',
            'room' => [
                'id' => (int)$id,
                'name' => $newName
            ]
        ]);
    }

    public function updateChatRoomTheme(Request $request, $id)
    {
        $user = $request->user();
        if (!$user->couple_id) {
            return response()->json(['message' => 'No active couple relationship'], 400);
        }

        $request->validate([
            'theme_color' => 'nullable|string|max:20',
            'background_color' => 'nullable|string|max:20'
        ]);

        $room = \DB::table('chat_rooms')
            ->where('couple_id', $user->couple_id)
            ->where('id', $id)
            ->first();

        if (!$room) {
            return response()->json(['message' => 'Chat room not found'], 404);
        }

        $themeColor = $request->input('theme_color');
        $backgroundColor = $request->input('background_color');

        \DB::table('chat_rooms')->where('id', $id)->update([
            'theme_color' => $themeColor,
            'background_color' => $backgroundColor,
            'updated_at' => now()
        ]);

        try {
            broadcast(new \App\Events\ChatRoomThemeUpdated($user->couple_id, (int)$id, $themeColor, $backgroundColor))->toOthers();
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::warning("Websocket broadcast failed: " . $e->getMessage());
        }

        return response()->json([
            'status' => 'ok',
            'room' => [
                'id' => (int)$id,
                'theme_color' => $themeColor,
                'background_color' => $backgroundColor
            ]
        ]);
    }

    public function acknowledgeFlash(Request $request, $id)
    {
        $user = $request->user();
        if (!$user->couple_id) {
            return response()->json(['message' => 'No active couple relationship'], 400);
        }

        $flash = \App\Models\Flash::where('couple_id', $user->couple_id)
            ->where('id', $id)
            ->first();

        if ($flash) {
            $this->deleteFlashFile($flash->photo_url);
            $flash->delete();
        }

        return response()->json(['status' => 'ok']);
    }

    private function deleteFlashFile($photoUrl)
    {
        if (!$photoUrl) return;
        $path = parse_url($photoUrl, PHP_URL_PATH);
        $path = preg_replace('/^\/?storage\//', '', $path);
        \Illuminate\Support\Facades\Storage::disk('public')->delete($path);
    }

    public function clearChatRoom(Request $request, $id)
    {
        $user = $request->user();
        if (!$user->couple_id) {
            return response()->json(['message' => 'No active couple relationship'], 400);
        }

        $room = \DB::table('chat_rooms')
            ->where('id', $id)
            ->where('couple_id', $user->couple_id)
            ->first();

        if (!$room) {
            return response()->json(['message' => 'Room not found'], 404);
        }

        // Fetch all audio messages in this room to delete their files from storage
        $audioMessages = \App\Models\Message::where('couple_id', $user->couple_id)
            ->where(function($q) use ($id, $room) {
                $q->where('room_id', $id);
                if ($room->is_main) {
                    $q->orWhereNull('room_id');
                }
            })
            ->where('is_audio', true)
            ->whereNotNull('audio_path')
            ->get();

        foreach ($audioMessages as $msg) {
            if (\Illuminate\Support\Facades\Storage::disk('public')->exists($msg->audio_path)) {
                \Illuminate\Support\Facades\Storage::disk('public')->delete($msg->audio_path);
            }
        }

        // Delete all messages in this room
        \App\Models\Message::where('room_id', $id)
            ->where('couple_id', $user->couple_id)
            ->delete();

        // Also delete messages with null room_id if it's the main room just in case
        if ($room->is_main) {
            \App\Models\Message::whereNull('room_id')
                ->where('couple_id', $user->couple_id)
                ->delete();
        }

        return response()->json(['status' => 'ok']);
    }

    public function requestDeleteChatRoom(Request $request, $id)
    {
        $user = $request->user();
        if (!$user->couple_id) {
            return response()->json(['message' => 'No active couple relationship'], 400);
        }

        $room = \DB::table('chat_rooms')
            ->where('couple_id', $user->couple_id)
            ->where('id', $id)
            ->first();

        if (!$room) {
            return response()->json(['message' => 'Chat room not found'], 404);
        }

        \DB::table('chat_rooms')->where('id', $id)->update([
            'delete_requested_by' => $user->id,
            'updated_at' => now()
        ]);

        try {
            broadcast(new \App\Events\ChatRoomDeleteStatusChanged($user->couple_id, (int)$id, (int)$user->id))->toOthers();
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::warning("Websocket broadcast failed: " . $e->getMessage());
        }

        return response()->json(['status' => 'ok', 'delete_requested_by' => $user->id]);
    }

    public function declineDeleteChatRoom(Request $request, $id)
    {
        $user = $request->user();
        if (!$user->couple_id) {
            return response()->json(['message' => 'No active couple relationship'], 400);
        }

        $room = \DB::table('chat_rooms')
            ->where('couple_id', $user->couple_id)
            ->where('id', $id)
            ->first();

        if (!$room) {
            return response()->json(['message' => 'Chat room not found'], 404);
        }

        \DB::table('chat_rooms')->where('id', $id)->update([
            'delete_requested_by' => null,
            'updated_at' => now()
        ]);

        try {
            broadcast(new \App\Events\ChatRoomDeleteStatusChanged($user->couple_id, (int)$id, null))->toOthers();
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::warning("Websocket broadcast failed: " . $e->getMessage());
        }

        return response()->json(['status' => 'ok']);
    }

    public function confirmDeleteChatRoom(Request $request, $id)
    {
        $user = $request->user();
        if (!$user->couple_id) {
            return response()->json(['message' => 'No active couple relationship'], 400);
        }

        $room = \DB::table('chat_rooms')
            ->where('couple_id', $user->couple_id)
            ->where('id', $id)
            ->first();

        if (!$room) {
            return response()->json(['message' => 'Chat room not found'], 404);
        }

        if ($room->delete_requested_by === null) {
            return response()->json(['message' => 'No delete request active for this room'], 400);
        }

        if ($room->is_main) {
            // Delete all audio files from storage first
            $audioMessages = \App\Models\Message::where('couple_id', $user->couple_id)
                ->where(function($q) use ($room) {
                    $q->where('room_id', $room->id)
                      ->orWhereNull('room_id');
                })
                ->where('is_audio', true)
                ->whereNotNull('audio_path')
                ->get();

            foreach ($audioMessages as $msg) {
                if (\Illuminate\Support\Facades\Storage::disk('public')->exists($msg->audio_path)) {
                    \Illuminate\Support\Facades\Storage::disk('public')->delete($msg->audio_path);
                }
            }

            // Delete all messages in this room
            \DB::table('messages')
                ->where('couple_id', $user->couple_id)
                ->where(function($q) use ($room) {
                    $q->where('room_id', $room->id)
                      ->orWhereNull('room_id');
                })
                ->delete();

            \DB::table('chat_rooms')->where('id', $id)->update([
                'delete_requested_by' => null,
                'updated_at' => now()
            ]);

            try {
                broadcast(new \App\Events\ChatRoomDeleteStatusChanged($user->couple_id, (int)$id, null))->toOthers();
                broadcast(new \App\Events\ChatRoomDeleted($user->couple_id, (int)$id))->toOthers();
            } catch (\Exception $e) {
                \Illuminate\Support\Facades\Log::warning("Websocket broadcast failed: " . $e->getMessage());
            }

            return response()->json(['status' => 'cleared']);
        } else {
            // Delete all audio files from storage first for the non-main room
            $audioMessages = \App\Models\Message::where('couple_id', $user->couple_id)
                ->where('room_id', $id)
                ->where('is_audio', true)
                ->whereNotNull('audio_path')
                ->get();

            foreach ($audioMessages as $msg) {
                if (\Illuminate\Support\Facades\Storage::disk('public')->exists($msg->audio_path)) {
                    \Illuminate\Support\Facades\Storage::disk('public')->delete($msg->audio_path);
                }
            }

            \DB::table('chat_rooms')->where('id', $id)->delete();

            try {
                broadcast(new \App\Events\ChatRoomDeleted($user->couple_id, (int)$id))->toOthers();
            } catch (\Exception $e) {
                \Illuminate\Support\Facades\Log::warning("Websocket broadcast failed: " . $e->getMessage());
            }

            return response()->json(['status' => 'deleted']);
        }
    }

    public function uploadAudio(Request $request)
    {
        $request->validate([
            'audio' => 'required|file|mimes:m4a,mp4,audio/mp4,audio/x-m4a,application/octet-stream|max:5120',
            'duration' => 'required|numeric',
            'room_id' => 'nullable|integer'
        ]);

        $user = $request->user();

        if (!$user->couple_id) {
            return response()->json(['message' => 'No active couple relationship'], 400);
        }

        $couple = \App\Models\Couple::find($user->couple_id);
        if (!$couple || $couple->is_active == 0) {
            return response()->json(['message' => 'Relationship is not active'], 400);
        }

        $roomId = $request->input('room_id');
        if (!$roomId) {
            $mainRoom = \DB::table('chat_rooms')
                ->where('couple_id', $user->couple_id)
                ->where('is_main', true)
                ->first();
                
            if (!$mainRoom) {
                $roomId = \DB::table('chat_rooms')->insertGetId([
                    'couple_id' => $user->couple_id,
                    'name' => 'General Chat',
                    'is_main' => true,
                    'created_at' => now(),
                    'updated_at' => now()
                ]);
            } else {
                $roomId = $mainRoom->id;
            }
        }

        $path = $request->file('audio')->store('chat_audios', 'public');

        $msg = \App\Models\Message::create([
            'couple_id' => $user->couple_id,
            'sender_id' => $user->id,
            'message' => '🎵 Sent a voice note',
            'room_id' => $roomId,
            'is_audio' => true,
            'audio_path' => $path,
            'audio_duration' => (double)$request->input('duration'),
            'audio_expired' => false
        ]);

        if ($msg->id > $user->last_seen_message_id) {
            $user->last_seen_message_id = $msg->id;
        }
        $map = json_decode($user->last_seen_room_messages ?: '{}', true) ?: [];
        $map[$roomId ?: 0] = (int)$msg->id;
        $user->last_seen_room_messages = json_encode($map);
        $user->save();
        $this->clearGlimpseCache($user->id);

        try {
            broadcast(new \App\Events\MessageSent($msg))->toOthers();
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::warning("Websocket broadcast failed: " . $e->getMessage());
        }

        if ($request->header('Accept') === 'application/x-protobuf') {
            $protobufBinary = \App\Helpers\GlimpseProtobuf::encodeMessage($msg);
            return response($protobufBinary)->header('Content-Type', 'application/x-protobuf');
        }

        return response()->json($msg);
    }

    public function downloadAudio(Request $request, $id)
    {
        $user = $request->user();
        if (!$user->couple_id) {
            return response()->json(['message' => 'No active couple relationship'], 400);
        }

        $msg = \App\Models\Message::where('id', $id)
            ->where('couple_id', $user->couple_id)
            ->first();

        if (!$msg || !$msg->is_audio) {
            return response()->json(['message' => 'Audio message not found'], 404);
        }

        if ($msg->audio_expired || !$msg->audio_path) {
            return response()->json(['message' => 'Voice note has expired'], 410);
        }

        $filePath = $msg->audio_path;

        if (!\Storage::disk('public')->exists($filePath)) {
            $msg->update([
                'audio_expired' => true,
                'audio_path' => null
            ]);
            return response()->json(['message' => 'Audio file missing'], 404);
        }

        $fileContent = \Storage::disk('public')->get($filePath);
        $mimeType = \Storage::disk('public')->mimeType($filePath) ?: 'audio/x-m4a';

        // Delete from server storage disk only if downloaded by the partner (not the sender)
        if ((int)$user->id !== (int)$msg->sender_id) {
            $deleted = \Storage::disk('public')->delete($filePath);
            if (!$deleted) {
                \Illuminate\Support\Facades\Log::warning("Failed to delete audio file from public storage: {$filePath}");
            }
            $msg->update([
                'audio_path' => null,
                'audio_expired' => true
            ]);
        }

        return response($fileContent)
            ->header('Content-Type', $mimeType)
            ->header('Content-Disposition', 'attachment; filename="voice_whisper_' . $id . '.m4a"');
    }
}

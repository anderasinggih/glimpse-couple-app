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

        $partnerData = null;
        if ($partner) {
            $partnerPhotoUrl = $partner->profile_photo_url;
            if ($partnerPhotoUrl && !str_starts_with($partnerPhotoUrl, 'http')) {
                $partnerPhotoUrl = url($partnerPhotoUrl);
            }
            $partnerData = $partner->toArray();
            $partnerData['profile_photo_url'] = $partnerPhotoUrl ?? "https://ui-avatars.com/api/?name=" . urlencode($partner->name);
        }

        return response()->json([
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'invite_code' => $user->invite_code,
                'profile_photo_url' => $photoUrl ?? "https://ui-avatars.com/api/?name=" . urlencode($user->name),
                'couple_id' => $user->couple_id
            ],
            'partner_data' => $partnerData,
            'anniversary_start_date' => $couple ? $couple->anniversary_start_date : null
        ]);
    }

    public function updateProfile(Request $request)
    {
        $user = $request->user();
        $request->validate([
            'name' => 'sometimes|string|max:255',
            'email' => 'sometimes|email|unique:users,email,' . $user->id,
            'profile_photo' => 'sometimes|image|max:5120'
        ]);

        if ($request->has('name')) $user->name = $request->name;
        if ($request->has('email')) $user->email = $request->email;
        
        if ($request->hasFile('profile_photo')) {
            if ($user->profile_photo_url && !str_contains($user->profile_photo_url, 'ui-avatars')) {
                Storage::disk('public')->delete(str_replace('/storage/', '', $user->profile_photo_url));
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

        $coupleId = rand(10000, 99999);
        $user->update(['couple_id' => $coupleId]);
        $targetUser->update(['couple_id' => $coupleId]);

        return response()->json(['message' => 'Connected successfully!', 'couple_id' => $coupleId]);
    }

    public function uploadPhoto(Request $request)
    {
        $request->validate([
            'photo' => 'required|image|max:10240', // Max 10MB
        ]);

        $user = $request->user();
        
        if ($request->hasFile('photo')) {
            // Delete old photo if exists
            if ($user->latest_photo_url) {
                Storage::disk('public')->delete(str_replace('/storage/', '', $user->latest_photo_url));
            }

            $path = $request->file('photo')->store('glimpse_photos', 'public');
            $user->latest_photo_url = Storage::url($path);
            $user->save();

            if ($user->couple_id) {
                broadcast(new PartnerStateUpdated($user))->toOthers();
            }

            return response()->json([
                'message' => 'Photo uploaded successfully',
                'photo_url' => $user->latest_photo_url
            ]);
        }

        return response()->json(['message' => 'No photo uploaded'], 400);
    }
}

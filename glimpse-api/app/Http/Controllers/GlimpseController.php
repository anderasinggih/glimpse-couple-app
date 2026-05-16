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
        if ($user->couple_id) {
            $partner = \App\Models\User::where('couple_id', $user->couple_id)
                ->where('id', '!=', $user->id)
                ->first();
        }

        return response()->json([
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'invite_code' => $user->invite_code,
                'profile_photo_url' => $user->profile_photo_url ?? "https://ui-avatars.com/api/?name=" . urlencode($user->name),
                'couple_id' => $user->couple_id
            ],
            'partner_data' => $partner,
            'anniversary_start_date' => $user->couple_id ? "2023-10-20T00:00:00Z" : null // Mock for now
        ]);
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

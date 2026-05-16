<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use App\Events\PartnerStateUpdated;

class GlimpseController extends Controller
{
    public function sync(Request $request)
    {
        $user = $request->user();
        
        $user->update($request->only([
            'latitude', 
            'longitude', 
            'location_name', 
            'battery_level', 
            'status_note'
        ]));

        if ($user->couple_id) {
            broadcast(new PartnerStateUpdated($user))->toOthers();
        }

        return response()->json([
            'user' => $user,
            'partner' => $user->partner()
        ]);
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

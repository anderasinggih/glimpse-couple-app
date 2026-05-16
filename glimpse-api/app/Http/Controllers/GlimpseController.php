<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\User;
use App\Models\Couple;
use App\Events\PartnerStateUpdated;
use Illuminate\Support\Facades\Storage;

class GlimpseController extends Controller
{
    public function getState(Request $request)
    {
        $user = $request->user();
        if (!$user->couple_id) {
            return response()->json(['error' => 'No partner linked'], 404);
        }

        $partner = User::where('couple_id', $user->couple_id)
            ->where('id', '!=', $user->id)
            ->first();

        $couple = Couple::find($user->couple_id);

        return response()->json([
            'partner' => $partner,
            'couple' => $couple
        ]);
    }

    public function updateStatus(Request $request)
    {
        $user = $request->user();
        $request->validate([
            'status_note' => 'string|nullable',
            'latitude' => 'numeric|nullable',
            'longitude' => 'numeric|nullable',
            'location_name' => 'string|nullable',
            'battery_level' => 'integer|nullable'
        ]);

        $user->update($request->only([
            'status_note', 'latitude', 'longitude', 'location_name', 'battery_level'
        ]));

        broadcast(new PartnerStateUpdated($user))->toOthers();

        return response()->json(['status' => 'updated', 'user' => $user]);
    }

    public function uploadPhoto(Request $request)
    {
        $user = $request->user();
        $request->validate([
            'photo' => 'required|image|max:5120'
        ]);

        if ($request->hasFile('photo')) {
            $path = $request->file('photo')->store('glimpse_photos', 'public');
            $url = Storage::url($path);
            
            $user->update(['latest_photo_url' => $url]);
            
            broadcast(new PartnerStateUpdated($user))->toOthers();
            
            return response()->json(['url' => $url]);
        }

        return response()->json(['error' => 'No photo provided'], 400);
    }
}

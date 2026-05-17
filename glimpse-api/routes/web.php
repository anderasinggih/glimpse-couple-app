<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Http\Request;
use App\Models\User;
use App\Models\Couple;
use App\Models\Message;

Route::get('/', function () {
    return view('welcome');
});

Route::post('/admin/api', function (Request $request) {
    // 1. Verify access token
    $token = $request->header('X-Admin-Token') ?: $request->input('token');
    $secretToken = env('ADMIN_TOKEN');

    if (!$secretToken || !$token || $token !== $secretToken) {
        return response()->json(['error' => 'Unauthorized. Invalid Admin Token.'], 401);
    }

    $action = $request->input('action');

    switch ($action) {
        case 'get_data':
            $users = User::all();
            $couples = Couple::with('users')->get();
            $messagesCount = Message::count();
            
            // Format nice couple listings
            $couplesFormatted = $couples->map(function ($couple) {
                return [
                    'id' => $couple->id,
                    'anniversary_start_date' => $couple->anniversary_start_date,
                    'is_active' => (bool)$couple->is_active,
                    'users' => $couple->users->map(fn($u) => ['id' => $u->id, 'name' => $u->name, 'email' => $u->email]),
                ];
            });

            return response()->json([
                'stats' => [
                    'total_users' => $users->count(),
                    'total_couples' => $couples->count(),
                    'total_messages' => $messagesCount,
                    'active_sessions' => User::whereNotNull('updated_at')->count(),
                ],
                'users' => $users,
                'couples' => $couplesFormatted,
            ]);

        case 'update_battery':
            $userId = $request->input('user_id');
            $battery = (int)$request->input('battery_level');
            $user = User::findOrFail($userId);
            $user->battery_level = $battery;
            $user->save();

            // Broadcast state update event
            event(new \App\Events\PartnerStateUpdated($user->couple_id, $user->id, 'battery_update'));

            return response()->json(['success' => true, 'message' => "Battery updated successfully for {$user->name}."]);

        case 'update_location':
            $userId = $request->input('user_id');
            $lat = (double)$request->input('latitude');
            $lon = (double)$request->input('longitude');
            $locName = $request->input('location_name');

            $user = User::findOrFail($userId);
            $user->latitude = $lat;
            $user->longitude = $lon;
            $user->location_name = $locName;
            $user->save();

            // Broadcast state update event
            event(new \App\Events\PartnerStateUpdated($user->couple_id, $user->id, 'location_update'));

            return response()->json(['success' => true, 'message' => "Location updated successfully for {$user->name}."]);

        case 'clear_chat':
            $coupleId = $request->input('couple_id');
            Message::where('couple_id', $coupleId)->delete();
            return response()->json(['success' => true, 'message' => 'Chat history cleared successfully.']);

        case 'delete_user':
            $userId = $request->input('user_id');
            $user = User::findOrFail($userId);
            $user->delete();
            return response()->json(['success' => true, 'message' => "User deleted successfully."]);

        default:
            return response()->json(['error' => 'Unknown action.'], 400);
    }
});

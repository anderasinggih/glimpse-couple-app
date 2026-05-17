<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use App\Models\User;
use App\Models\Couple;
use App\Models\Message;
use App\Models\Flash;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/admin', function () {
    return view('admin');
});

Route::get('/admin/login', function () {
    return view('admin-login');
});

Route::get('/admin/diagnose', function (Request $request) {
    $testToken = $request->query('token', '');
    
    $diagnostics = [
        'laravel_version' => app()->version(),
        'admin_tokens_table_exists' => Schema::hasTable('admin_tokens'),
    ];
    
    if ($diagnostics['admin_tokens_table_exists']) {
        $record = DB::table('admin_tokens')->first();
        if ($record) {
            $diagnostics['database_record'] = [
                'id' => $record->id,
                'token_hash' => $record->token_hash,
                'created_at' => $record->created_at,
                'updated_at' => $record->updated_at,
            ];
            if (!empty($testToken)) {
                $diagnostics['test_verify_database'] = password_verify($testToken, $record->token_hash);
            }
        } else {
            $diagnostics['database_record'] = 'Table is EMPTY';
        }
    } else {
        $diagnostics['database_record'] = 'Table does NOT exist';
    }
    
    $diagnostics['env_config'] = [
        'config_app_admin_token' => config('app.admin_token'),
        'env_admin_token' => env('ADMIN_TOKEN'),
    ];
    
    if (!empty($testToken)) {
        $fallbackToken = trim(config('app.admin_token') ?: (env('ADMIN_TOKEN') ?: 'LVNPC2026123'));
        $diagnostics['test_verify_fallback'] = ($testToken === $fallbackToken);
    }
    
    return response()->json($diagnostics);
});

Route::get('/privacy', function () {
    return '
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Privacy Policy - Glimpse</title>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;600;700&display=swap" rel="stylesheet">
    <style>
        body {
            background-color: #0b071e;
            color: #ffffff;
            font-family: "Outfit", sans-serif;
            margin: 0;
            padding: 20px 10px;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
        }
        .container {
            width: 96%;
            max-width: 1400px;
            background: rgba(255, 255, 255, 0.03);
            backdrop-filter: blur(20px);
            border: 1px solid rgba(255, 255, 255, 0.08);
            border-radius: 24px;
            padding: 30px 20px;
            box-shadow: 0 20px 50px rgba(0, 0, 0, 0.3);
        }
        h1 {
            font-size: 2.5rem;
            font-weight: 700;
            background: linear-gradient(135deg, #a855f7 0%, #06b6d4 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            margin-bottom: 10px;
            text-align: center;
        }
        .subtitle {
            text-align: center;
            color: rgba(255, 255, 255, 0.6);
            margin-bottom: 40px;
            font-size: 1.1rem;
        }
        h2 {
            font-size: 1.4rem;
            color: #06b6d4;
            margin-top: 30px;
            margin-bottom: 10px;
            border-bottom: 1px solid rgba(255, 255, 255, 0.1);
            padding-bottom: 8px;
        }
        p, li {
            font-size: 1rem;
            line-height: 1.6;
            color: rgba(255, 255, 255, 0.85);
        }
        ul {
            padding-left: 20px;
        }
        li {
            margin-bottom: 8px;
        }
        .footer {
            margin-top: 50px;
            text-align: center;
            font-size: 0.9rem;
            color: rgba(255, 255, 255, 0.4);
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Glimpse Privacy Policy</h1>
        <p class="subtitle">Effective Date: May 17, 2026</p>
        
        <p>Welcome to Glimpse, an intimate companion application designed to keep couples connected. Your privacy is of paramount importance to us. This Privacy Policy describes how Glimpse collects, uses, processes, and protects your information.</p>
        
        <h2>1. Information We Collect</h2>
        <p>To provide a seamless real-time connection experience, Glimpse collects the following categories of information:</p>
        <ul>
            <li><strong>Account Data:</strong> Your name, email address, password, and profile photo when you sign up.</li>
            <li><strong>Intimate Connection State:</strong> Location coordinates (latitude and longitude), battery status, charging state, status notes, and photos you capture for your Flash memory feed.</li>
            <li><strong>Direct Messaging:</strong> Chat messages exchanged between you and your linked partner. Messages are transmitted securely to deliver them in real-time.</li>
        </ul>
        
        <h2>2. How We Use Your Information</h2>
        <p>Glimpse uses the collected information strictly for the following purposes:</p>
        <ul>
            <li>To display your real-time presence (location, battery status, and status note) to your linked partner.</li>
            <li>To share direct chat messages and Flash photos exclusively with your connected partner.</li>
            <li>To host and build your shared memory timeline.</li>
        </ul>
        
        <h2>3. Data Sharing & Security</h2>
        <p><strong>We do not sell, trade, or share your personal data with any third-party advertisers or corporations.</strong> Your data is strictly shared with the individual you choose to pair with using your unique connection invite code.</p>
        
        <h2>4. Data Retention & Control</h2>
        <p>You have full control over your shared intimacy data. You can disconnect from your partner, delete past messages, or request account deletion directly from the settings menu within the application at any time.</p>
        
        <div class="footer">
            &copy; 2026 Glimpse App. Crafted with infinite love by Lovinpeace.
        </div>
    </div>
</body>
</html>
';
});

Route::get('/debug-storage', function () {
    $avatarsDir = storage_path('app/public/avatars');
    $files = file_exists($avatarsDir) ? scandir($avatarsDir) : [];
    
    $users = \App\Models\User::select('id', 'name', 'profile_photo_url')->get()->toArray();
    
    return response()->json([
        'avatars_directory_exists' => file_exists($avatarsDir),
        'avatars_directory_path' => $avatarsDir,
        'files_in_avatars' => $files,
        'users_in_database' => $users,
        'symlink_public_storage_exists' => file_exists(public_path('storage')),
    ]);
});

Route::post('/admin/api', function (Request $request) {
    // 1. Verify access token from database with a graceful fallback
    $tokenHeader = trim($request->header('X-Admin-Token') ?: '');
    $tokenBody = trim($request->input('token') ?: '');
    $tokenQuery = trim($request->query('token') ?: '');
    
    // Bulletproof fallback & javascript placeholder cleaning
    $invalidPlaceholders = ['', 'undefined', 'null'];
    $token = '';
    
    foreach ([$tokenHeader, $tokenBody, $tokenQuery] as $t) {
        if (!in_array(strtolower($t), $invalidPlaceholders)) {
            $token = $t;
            break;
        }
    }
    $token = trim($token, '"\'');

    $isAuthorized = false;
    
    try {
        $adminTokenRecord = DB::table('admin_tokens')->first();
        if ($adminTokenRecord) {
            $isAuthorized = password_verify($token, $adminTokenRecord->token_hash);
        } else {
            // Graceful fallback if table exists but empty
            $isAuthorized = ($token === 'LVNPC2026123');
        }
    } catch (\Exception $e) {
        // Safe fallback if migration has not been run yet
        $secretToken = trim(config('app.admin_token') ?: (env('ADMIN_TOKEN') ?: 'LVNPC2026123'));
        $secretToken = trim($secretToken, '"\'');
        $isAuthorized = ($token === $secretToken);
    }

    if (!$isAuthorized || !$token) {
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

        case 'change_admin_token':
            $newToken = trim($request->input('new_token') ?: '');
            if (empty($newToken)) {
                return response()->json(['error' => 'New token cannot be empty.'], 400);
            }
            
            DB::table('admin_tokens')->updateOrInsert(
                ['id' => 1],
                [
                    'token_hash' => password_hash($newToken, PASSWORD_BCRYPT),
                    'created_at' => now(),
                    'updated_at' => now()
                ]
            );
            
            return response()->json(['success' => true, 'message' => 'Admin token changed successfully! Please log in again using your new token.']);

        case 'mock_battery':
        case 'update_battery':
            $userId = $request->input('user_id');
            $battery = (int)$request->input('battery_level');
            $user = User::findOrFail($userId);
            $user->battery_level = $battery;
            $user->save();

            // Broadcast state update event
            event(new \App\Events\PartnerStateUpdated($user));

            return response()->json(['success' => true, 'message' => "Battery updated successfully for {$user->name}."]);

        case 'mock_location':
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
            event(new \App\Events\PartnerStateUpdated($user));

            return response()->json(['success' => true, 'message' => "Location updated successfully for {$user->name}."]);

        case 'clear_chat':
            $coupleId = $request->input('couple_id');
            Message::where('couple_id', $coupleId)->delete();
            return response()->json(['success' => true, 'message' => 'Chat history cleared successfully.']);

        case 'get_chat_history':
            $coupleId = $request->input('couple_id');
            $couple = Couple::with('users')->findOrFail($coupleId);
            $messages = Message::where('couple_id', $coupleId)->orderBy('created_at', 'asc')->get();
            
            return response()->json([
                'success' => true,
                'couple' => [
                    'id' => $couple->id,
                    'users' => $couple->users->map(fn($u) => ['id' => $u->id, 'name' => $u->name, 'email' => $u->email, 'profile_photo_url' => $u->profile_photo_url]),
                ],
                'messages' => $messages
            ]);

        case 'inject_spy_message':
            $coupleId = $request->input('couple_id');
            $senderId = $request->input('sender_id');
            $messageText = $request->input('message');
            
            // Avoid Foreign Key Constraint Violation (sender_id = 0 is invalid since no user 0 exists)
            if (empty($senderId) || $senderId == 0) {
                $user = User::where('couple_id', $coupleId)->first();
                if (!$user) {
                    return response()->json(['error' => 'Cannot inject message into an empty couple connection.'], 400);
                }
                $senderId = $user->id;
                $messageText = "📢 [SYSTEM]: " . $messageText;
            } else {
                $senderId = (int)$senderId;
            }
            
            $msg = Message::create([
                'couple_id' => $coupleId,
                'sender_id' => $senderId,
                'message' => $messageText
            ]);

            // Broadcast so users' live chats update in real-time!
            event(new \App\Events\MessageSent($coupleId, [
                'id' => $msg->id,
                'couple_id' => $coupleId,
                'sender_id' => $senderId,
                'message' => $messageText,
                'created_at' => $msg->created_at->toISOString()
            ]));

            return response()->json(['success' => true, 'message' => 'Message successfully injected into conversation flow like a ghost!']);

        case 'delete_user':
            $userId = $request->input('user_id');
            $user = User::findOrFail($userId);
            
            $deletePhysicalFile = function($url) {
                if (!$url) return;
                $relativePath = parse_url($url, PHP_URL_PATH);
                if (strpos($relativePath, '/storage/') === 0) {
                    $relativePath = substr($relativePath, 9);
                }
                \Illuminate\Support\Facades\Storage::disk('public')->delete($relativePath);
            };

            // 1. Delete user photo attachments
            $deletePhysicalFile($user->profile_photo_url);
            $deletePhysicalFile($user->latest_photo_url);

            // 2. Clear out flashes uploaded by this user
            $userFlashes = Flash::where('sender_id', $user->id)->get();
            foreach ($userFlashes as $f) {
                $deletePhysicalFile($f->photo_url);
                $f->delete();
            }

            // 3. Handle couple connection
            if ($user->couple_id) {
                $coupleId = $user->couple_id;
                
                // Unlink partner
                $partner = User::where('couple_id', $coupleId)->where('id', '!=', $user->id)->first();
                if ($partner) {
                    $partner->couple_id = null;
                    $partner->save();
                }

                // Unlink the user being deleted as well to satisfy foreign key constraints before deleting couple!
                $user->couple_id = null;
                $user->save();

                // Delete all chats in the couple
                Message::where('couple_id', $coupleId)->delete();

                // Delete all other flashes in the couple
                $coupleFlashes = Flash::where('couple_id', $coupleId)->get();
                foreach ($coupleFlashes as $f) {
                    $deletePhysicalFile($f->photo_url);
                    $f->delete();
                }

                // Delete the couple itself
                Couple::where('id', $coupleId)->delete();
            }

            // 4. Finally delete the user
            $user->delete();
            return response()->json(['success' => true, 'message' => "User, their chats, couple bonds, flashes, and all physical files on disk have been completely purged like a God!"]);

        case 'delete_flashes':
            $userId = $request->input('user_id'); // "all" or specific user id
            $daysAgo = (int)$request->input('days_ago'); // e.g. 1, 2, 3 days
            
            $deletePhysicalFile = function($url) {
                if (!$url) return;
                $relativePath = parse_url($url, PHP_URL_PATH);
                if (strpos($relativePath, '/storage/') === 0) {
                    $relativePath = substr($relativePath, 9);
                }
                \Illuminate\Support\Facades\Storage::disk('public')->delete($relativePath);
            };

            $query = Flash::query();

            // Filter by user if not "all"
            if ($userId && $userId !== 'all') {
                $query->where('sender_id', $userId);
            }

            // Filter by created_at date (H-X)
            if ($daysAgo > 0) {
                $thresholdDate = now()->subDays($daysAgo);
                $query->where('created_at', '<', $thresholdDate);
            }

            $flashesToDelete = $query->get();
            $count = $flashesToDelete->count();

            foreach ($flashesToDelete as $f) {
                $deletePhysicalFile($f->photo_url);
                $f->delete();
            }

            return response()->json([
                'success' => true, 
                'message' => "Successfully pruned {$count} selected Glimpse Flash histories and wiped their files from disk!"
            ]);

        case 'forced_couple_link':
            $user1Id = $request->input('user_1_id');
            $user2Id = $request->input('user_2_id');

            if ($user1Id == $user2Id) {
                return response()->json(['error' => 'Cannot couple link a user to themselves.'], 400);
            }

            $u1 = User::findOrFail($user1Id);
            $u2 = User::findOrFail($user2Id);

            // Create new couple connection
            $couple = Couple::create([
                'anniversary_start_date' => now()->format('Y-m-d H:i:s'),
                'is_active' => true
            ]);

            $u1->couple_id = $couple->id;
            $u1->save();

            $u2->couple_id = $couple->id;
            $u2->save();

            // Broadcast link events to both devices
            event(new \App\Events\PartnerStateUpdated($u1));
            event(new \App\Events\PartnerStateUpdated($u2));

            return response()->json([
                'success' => true, 
                'message' => "God-Link successful! Connected {$u1->name} and {$u2->name} into Couple ID {$couple->id} instantly!"
            ]);

        case 'broadcast_announcement':
            $announcementText = $request->input('text');
            if (empty($announcementText)) {
                return response()->json(['error' => 'Announcement text cannot be empty.'], 400);
            }

            // Find all active couples
            $couples = Couple::where('is_active', true)->get();
            $sentCount = 0;
            foreach ($couples as $c) {
                // Find a valid user in this couple to satisfy the foreign key constraint
                $user = User::where('couple_id', $c->id)->first();
                if (!$user) continue;

                $msg = Message::create([
                    'couple_id' => $c->id,
                    'sender_id' => $user->id,
                    'message' => "📢 [SYSTEM ANNOUNCEMENT]: " . $announcementText
                ]);

                // Trigger live websocket broadcast so client phones play sound and show bubble instantly!
                event(new \App\Events\MessageSent($c->id, [
                    'id' => $msg->id,
                    'couple_id' => $c->id,
                    'sender_id' => $user->id,
                    'message' => "📢 [SYSTEM ANNOUNCEMENT]: " . $announcementText,
                    'created_at' => $msg->created_at->toISOString()
                ]));
                $sentCount++;
            }

            return response()->json([
                'success' => true, 
                'message' => "Broadcasted announcement to {$sentCount} active couples instantly!"
            ]);

        case 'database_optimize':
            try {
                \Illuminate\Support\Facades\DB::statement('VACUUM'); // SQLite optimization
            } catch (\Exception $e) {
                try {
                    \Illuminate\Support\Facades\DB::statement('OPTIMIZE TABLE users, couples, messages, flashes');
                } catch (\Exception $ex) {}
            }

            $allCouples = Couple::all();
            $orphansCount = 0;
            foreach ($allCouples as $c) {
                $usersCount = User::where('couple_id', $c->id)->count();
                if ($usersCount === 0) {
                    Message::where('couple_id', $c->id)->delete();
                    $flashes = Flash::where('couple_id', $c->id)->get();
                    foreach ($flashes as $f) {
                        if ($f->photo_url) {
                            $relativePath = parse_url($f->photo_url, PHP_URL_PATH);
                            if (strpos($relativePath, '/storage/') === 0) {
                                $relativePath = substr($relativePath, 9);
                            }
                            \Illuminate\Support\Facades\Storage::disk('public')->delete($relativePath);
                        }
                        $f->delete();
                    }
                    $c->delete();
                    $orphansCount++;
                }
            }

            return response()->json([
                'success' => true, 
                'message' => "Database optimized successfully! Cleaned up {$orphansCount} orphaned couple remnants!"
            ]);

        default:
            return response()->json(['error' => 'Unknown action.'], 400);
    }
});

// Fallback route to serve storage files directly, bypassing cPanel symbolic link block restrictions
Route::get('/storage/{directory}/{filename}', function ($directory, $filename) {
    $path = storage_path('app/public/' . $directory . '/' . $filename);

    if (!file_exists($path)) {
        abort(404);
    }

    $file = file_get_contents($path);
    $type = mime_content_type($path);

    return response($file, 200)->header("Content-Type", $type);
});

// Diagnostic route to read laravel logs
Route::get('/view-logs', function () {
    $logPath = storage_path('logs/laravel.log');
    if (!file_exists($logPath)) {
        return response()->json(['message' => 'No logs found.']);
    }
    $lines = file($logPath);
    $lastLines = array_slice($lines, -100);
    return response(implode("", $lastLines), 200)->header('Content-Type', 'text/plain');
});

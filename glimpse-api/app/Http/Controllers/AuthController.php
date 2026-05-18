<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:30',
            'email' => 'required|string|email|max:100|unique:users',
            'born_date' => 'nullable|date',
            'password' => 'required|string|min:8|max:32',
        ]);

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'born_date' => $request->born_date,
            'password' => Hash::make($request->password),
        ]);

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'access_token' => $token,
            'token_type' => 'Bearer',
            'user' => $user
        ]);
    }

    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email|max:100',
            'password' => 'required|string|max:32',
        ]);

        \Illuminate\Support\Facades\Log::info("Login attempt for: " . $request->email);
        $user = User::where('email', $request->email)->first();

        if (!$user) {
             \Illuminate\Support\Facades\Log::warning("User not found: " . $request->email);
             return response()->json(['message' => 'User not found in database'], 401);
        }

        if (!Hash::check($request->password, $user->password)) {
            \Illuminate\Support\Facades\Log::warning("Password mismatch for: " . $request->email);
            return response()->json(['message' => 'Incorrect password'], 401);
        }

        // Enforce single active session per user by deleting all previous access tokens
        $user->tokens()->delete();

        $token = $user->createToken('auth_token')->plainTextToken;
        \Illuminate\Support\Facades\Log::info("Login successful for: " . $request->email);

        return response()->json([
            'access_token' => $token,
            'token_type' => 'Bearer',
            'user' => $user
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();
        return response()->json(['message' => 'Logged out']);
    }
}

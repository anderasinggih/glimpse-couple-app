<?php

use App\Http\Controllers\GlimpseController;
use App\Http\Controllers\AuthController;

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/glimpse/state', [GlimpseController::class, 'getState']);
    Route::post('/glimpse/status', [GlimpseController::class, 'updateStatus']);
    Route::post('/glimpse/photo', [GlimpseController::class, 'uploadPhoto']);
    Route::get('/glimpse/flashes', [GlimpseController::class, 'getFlashes']);
    Route::post('/glimpse/connect', [GlimpseController::class, 'connect']);
    Route::post('/glimpse/connect/accept', [GlimpseController::class, 'acceptConnect']);
    Route::post('/glimpse/connect/decline', [GlimpseController::class, 'declineConnect']);
    Route::post('/glimpse/disconnect', [GlimpseController::class, 'disconnect']);
    Route::post('/glimpse/disconnect/approve', [GlimpseController::class, 'approveDisconnect']);
    Route::post('/glimpse/disconnect/cancel', [GlimpseController::class, 'cancelDisconnect']);
    Route::post('/user/update', [GlimpseController::class, 'updateProfile']);
    Route::post('/couple/anniversary', [GlimpseController::class, 'updateRelationship']);
    Route::get('/glimpse/chat', [GlimpseController::class, 'getMessages']);
    Route::post('/glimpse/chat', [GlimpseController::class, 'sendMessage']);
    Route::post('/glimpse/chat/read', [GlimpseController::class, 'markAsRead']);
    Route::post('/glimpse/love-burst', [GlimpseController::class, 'sendLoveBurst']);
    Route::post('/glimpse/typing', [GlimpseController::class, 'broadcastTyping']);
    
    // Schedule Planner routes
    Route::post('/glimpse/schedule', [GlimpseController::class, 'createSchedule']);
    Route::post('/glimpse/schedule/{id}/respond', [GlimpseController::class, 'respondSchedule']);
    Route::get('/glimpse/schedules', [GlimpseController::class, 'getSchedules']);

    // Chat Rooms routes
    Route::get('/glimpse/chat-rooms', [GlimpseController::class, 'getChatRooms']);
    Route::post('/glimpse/chat-rooms', [GlimpseController::class, 'createChatRoom']);
    Route::delete('/glimpse/chat-rooms/{id}', [GlimpseController::class, 'deleteChatRoom']);
    Route::post('/glimpse/chat-rooms/{id}/rename', [GlimpseController::class, 'renameChatRoom']);
});

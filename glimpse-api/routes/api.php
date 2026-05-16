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
    Route::post('/glimpse/connect', [GlimpseController::class, 'connect']);
    Route::post('/user/update', [GlimpseController::class, 'updateProfile']);
    Route::post('/couple/anniversary', [GlimpseController::class, 'updateRelationship']);
});

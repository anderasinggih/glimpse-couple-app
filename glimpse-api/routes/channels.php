<?php

use Illuminate\Support\Facades\Broadcast;

Broadcast::channel('App.Models.User.{id}', function ($user, $id) {
    return (int) $user->id === (int) $id;
});

Broadcast::channel('couple.{coupleId}', function ($user, $coupleId) {
    return (int) $user->couple_id === (int) $coupleId;
});

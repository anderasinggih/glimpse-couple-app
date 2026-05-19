<?php

namespace App\Events;

use App\Models\User;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class PartnerStateUpdated implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $user;

    public function __construct(User $user)
    {
        $this->user = $user;
    }

    public function broadcastOn(): array
    {
        return [
            new Channel('couple.' . $this->user->couple_id),
        ];
    }

    public function broadcastWith(): array
    {
        $protobufBinary = \App\Helpers\GlimpseProtobuf::encodeStateUpdated($this->user);
        return [
            'pb' => base64_encode($protobufBinary)
        ];
    }
}

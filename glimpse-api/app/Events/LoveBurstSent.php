<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class LoveBurstSent implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $coupleId;
    public $senderId;
    public $timestamp;
    public $reaction;

    public function __construct($coupleId, $senderId, $timestamp, $reaction = null)
    {
        $this->coupleId = $coupleId;
        $this->senderId = $senderId;
        $this->timestamp = $timestamp;
        $this->reaction = $reaction;
    }

    public function broadcastOn(): array
    {
        return [
            new Channel('couple.' . $this->coupleId),
        ];
    }

    public function broadcastWith(): array
    {
        return [
            'sender_id' => $this->senderId,
            'timestamp' => $this->timestamp,
            'reaction' => $this->reaction
        ];
    }
}

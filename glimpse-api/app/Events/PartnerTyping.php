<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class PartnerTyping implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $coupleId;
    public $userId;
    public $isTyping;

    public function __construct($coupleId, $userId, $isTyping)
    {
        $this->coupleId = $coupleId;
        $this->userId = $userId;
        $this->isTyping = $isTyping;
    }

    public function broadcastOn(): array
    {
        return [
            new Channel('couple.' . $this->coupleId),
        ];
    }

    public function broadcastWith(): array
    {
        $protobufBinary = \App\Helpers\GlimpseProtobuf::encodeTyping($this->userId, $this->isTyping);
        return [
            'pb' => base64_encode($protobufBinary)
        ];
    }
}

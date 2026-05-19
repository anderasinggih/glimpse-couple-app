<?php

namespace App\Events;

use App\Models\Message;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class MessageSent implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $message;

    public function __construct(Message $message)
    {
        $this->message = $message;
    }

    public function broadcastOn(): array
    {
        return [
            new Channel('couple.' . $this->message->couple_id),
        ];
    }

    public function broadcastWith(): array
    {
        $protobufBinary = \App\Helpers\GlimpseProtobuf::encodeMessage($this->message);
        return [
            'pb' => base64_encode($protobufBinary)
        ];
    }
}

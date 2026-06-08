<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class ChatRoomDeleteStatusChanged implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $coupleId;
    public $roomId;
    public $deleteRequestedBy;

    public function __construct($coupleId, $roomId, $deleteRequestedBy)
    {
        $this->coupleId = $coupleId;
        $this->roomId = $roomId;
        $this->deleteRequestedBy = $deleteRequestedBy;
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
            'room_id' => $this->roomId,
            'delete_requested_by' => $this->deleteRequestedBy
        ];
    }
}

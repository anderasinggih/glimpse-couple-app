<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class DatabaseSyncRequested implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $coupleId;
    public $requestingUserId;

    /**
     * Create a new event instance.
     */
    public function __construct($coupleId, $requestingUserId)
    {
        $this->coupleId = $coupleId;
        $this->requestingUserId = $requestingUserId;
    }

    /**
     * Get the channels the event should broadcast on.
     */
    public function broadcastOn(): array
    {
        return [
            new Channel('couple.' . $this->coupleId),
        ];
    }
    
    public function broadcastAs()
    {
        return 'DatabaseSyncRequested';
    }
}

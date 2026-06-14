<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class DatabaseSyncReady implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $coupleId;
    public $requestingUserId;
    public $downloadUrl;

    /**
     * Create a new event instance.
     */
    public function __construct($coupleId, $requestingUserId, $downloadUrl)
    {
        $this->coupleId = $coupleId;
        $this->requestingUserId = $requestingUserId;
        $this->downloadUrl = $downloadUrl;
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
        return 'DatabaseSyncReady';
    }
}

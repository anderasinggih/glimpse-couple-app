<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class CoupleStatusChanged implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $coupleId;
    public $disconnectRequestedBy;
    public $coupleActive;

    public function __construct($coupleId, $disconnectRequestedBy, $coupleActive = true)
    {
        $this->coupleId = $coupleId;
        $this->disconnectRequestedBy = $disconnectRequestedBy;
        $this->coupleActive = $coupleActive;
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
            'couple_id' => (int)$this->coupleId,
            'disconnect_requested_by' => $this->disconnectRequestedBy !== null ? (int)$this->disconnectRequestedBy : null,
            'couple_active' => (bool)$this->coupleActive
        ];
    }
}

<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class LoveBumpSent implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $coupleId;
    public $senderId;
    public $totalMeetings;
    public $dailyBumps;

    public function __construct($coupleId, $senderId, $totalMeetings, $dailyBumps = 1)
    {
        $this->coupleId = $coupleId;
        $this->senderId = $senderId;
        $this->totalMeetings = $totalMeetings;
        $this->dailyBumps = $dailyBumps;
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
            'sender_id' => (int)$this->senderId,
            'total_meetings' => (int)$this->totalMeetings,
            'daily_bumps' => (int)$this->dailyBumps,
            'timestamp' => microtime(true)
        ];
    }
}

<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class ChatRoomThemeUpdated implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $coupleId;
    public $roomId;
    public $themeColor;
    public $backgroundColor;

    public function __construct($coupleId, $roomId, $themeColor, $backgroundColor)
    {
        $this->coupleId = $coupleId;
        $this->roomId = $roomId;
        $this->themeColor = $themeColor;
        $this->backgroundColor = $backgroundColor;
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
            'room_id' => (int)$this->roomId,
            'theme_color' => $this->themeColor,
            'background_color' => $this->backgroundColor
        ];
    }
}

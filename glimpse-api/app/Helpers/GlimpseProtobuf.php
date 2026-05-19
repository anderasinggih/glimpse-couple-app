<?php

namespace App\Helpers;

class GlimpseProtobuf
{
    /**
     * Encode a single ChatMessage to binary Protobuf format.
     */
    public static function encodeMessage($msg): string
    {
        $data = '';
        
        // Field 1: id (Varint)
        $data .= self::writeTag(1, 0);
        $data .= self::writeVarint($msg->id);
        
        // Field 2: room_id (Varint)
        if (!empty($msg->room_id)) {
            $data .= self::writeTag(2, 0);
            $data .= self::writeVarint($msg->room_id);
        }
        
        // Field 3: sender_id (Varint)
        $data .= self::writeTag(3, 0);
        $data .= self::writeVarint($msg->sender_id);
        
        // Field 4: message (Length-delimited String)
        $data .= self::writeTag(4, 2);
        $msgStr = (string)$msg->message;
        $data .= self::writeVarint(strlen($msgStr));
        $data .= $msgStr;
        
        // Field 5: created_at (Length-delimited String)
        if (!empty($msg->created_at)) {
            $data .= self::writeTag(5, 2);
            $dateStr = is_string($msg->created_at) ? $msg->created_at : $msg->created_at->toIso8601String();
            $data .= self::writeVarint(strlen($dateStr));
            $data .= $dateStr;
        }
        
        return $data;
    }

    /**
     * Encode UserStatus / Location / Battery to binary Protobuf format.
     */
    public static function encodeUserStatus(array $status): string
    {
        $data = '';
        
        // Field 1: latitude (Length-delimited String representation of double)
        if (isset($status['latitude']) && $status['latitude'] !== null) {
            $data .= self::writeTag(1, 2);
            $latStr = (string)$status['latitude'];
            $data .= self::writeVarint(strlen($latStr));
            $data .= $latStr;
        }
        
        // Field 2: longitude (Length-delimited String representation of double)
        if (isset($status['longitude']) && $status['longitude'] !== null) {
            $data .= self::writeTag(2, 2);
            $lonStr = (string)$status['longitude'];
            $data .= self::writeVarint(strlen($lonStr));
            $data .= $lonStr;
        }
        
        // Field 3: battery_level (Varint)
        if (isset($status['battery_level']) && $status['battery_level'] !== null) {
            $data .= self::writeTag(3, 0);
            $data .= self::writeVarint((int)$status['battery_level']);
        }
        
        // Field 4: is_charging (Varint: 0 or 1)
        if (isset($status['is_charging']) && $status['is_charging'] !== null) {
            $data .= self::writeTag(4, 0);
            $data .= self::writeVarint($status['is_charging'] ? 1 : 0);
        }
        
        // Field 5: status_note (Length-delimited String)
        if (isset($status['status_note']) && $status['status_note'] !== null && $status['status_note'] !== '') {
            $data .= self::writeTag(5, 2);
            $note = (string)$status['status_note'];
            $data .= self::writeVarint(strlen($note));
            $data .= $note;
        }
        
        // Field 6: location_name (Length-delimited String)
        if (isset($status['location_name']) && $status['location_name'] !== null && $status['location_name'] !== '') {
            $data .= self::writeTag(6, 2);
            $loc = (string)$status['location_name'];
            $data .= self::writeVarint(strlen($loc));
            $data .= $loc;
        }
        
        // Field 7: wifi_bssid (Length-delimited String)
        if (isset($status['wifi_bssid']) && $status['wifi_bssid'] !== null && $status['wifi_bssid'] !== '') {
            $data .= self::writeTag(7, 2);
            $wifi = (string)$status['wifi_bssid'];
            $data .= self::writeVarint(strlen($wifi));
            $data .= $wifi;
        }
        
        return $data;
    }

    /**
     * Decode UserStatus / Location / Battery binary Protobuf format to an array.
     */
    public static function decodeUserStatus(string $data): array
    {
        $pos = 0;
        $len = strlen($data);
        
        $status = [
            'latitude' => null,
            'longitude' => null,
            'battery_level' => null,
            'is_charging' => null,
            'status_note' => null,
            'location_name' => null,
            'wifi_bssid' => null,
        ];
        
        while ($pos < $len) {
            $tag = self::readVarint($data, $pos);
            $fieldNumber = $tag >> 3;
            $wireType = $tag & 0x07;
            
            switch ($fieldNumber) {
                case 1:
                    $strLen = self::readVarint($data, $pos);
                    $status['latitude'] = (double)substr($data, $pos, $strLen);
                    $pos += $strLen;
                    break;
                case 2:
                    $strLen = self::readVarint($data, $pos);
                    $status['longitude'] = (double)substr($data, $pos, $strLen);
                    $pos += $strLen;
                    break;
                case 3:
                    $status['battery_level'] = self::readVarint($data, $pos);
                    break;
                case 4:
                    $status['is_charging'] = self::readVarint($data, $pos) === 1;
                    break;
                case 5:
                    $strLen = self::readVarint($data, $pos);
                    $status['status_note'] = substr($data, $pos, $strLen);
                    $pos += $strLen;
                    break;
                case 6:
                    $strLen = self::readVarint($data, $pos);
                    $status['location_name'] = substr($data, $pos, $strLen);
                    $pos += $strLen;
                    break;
                case 7:
                    $strLen = self::readVarint($data, $pos);
                    $status['wifi_bssid'] = substr($data, $pos, $strLen);
                    $pos += $strLen;
                    break;
                default:
                    self::skipField($data, $pos, $wireType);
                    break;
            }
        }
        
        return $status;
    }

    /**
     * Decode a binary Protobuf format ChatMessage back to an array.
     */
    public static function decodeMessage(string $data): array
    {
        $pos = 0;
        $len = strlen($data);
        
        $msg = [
            'id' => 0,
            'room_id' => null,
            'sender_id' => 0,
            'message' => '',
            'created_at' => null,
        ];
        
        while ($pos < $len) {
            $tag = self::readVarint($data, $pos);
            $fieldNumber = $tag >> 3;
            $wireType = $tag & 0x07;
            
            switch ($fieldNumber) {
                case 1:
                    $msg['id'] = self::readVarint($data, $pos);
                    break;
                case 2:
                    $msg['room_id'] = self::readVarint($data, $pos);
                    break;
                case 3:
                    $msg['sender_id'] = self::readVarint($data, $pos);
                    break;
                case 4:
                    $strLen = self::readVarint($data, $pos);
                    $msg['message'] = substr($data, $pos, $strLen);
                    $pos += $strLen;
                    break;
                case 5:
                    $strLen = self::readVarint($data, $pos);
                    $msg['created_at'] = substr($data, $pos, $strLen);
                    $pos += $strLen;
                    break;
                default:
                    self::skipField($data, $pos, $wireType);
                    break;
            }
        }
        
        return $msg;
    }

    public static function encodeTyping(int $userId, bool $isTyping): string
    {
        $data = '';
        
        // Field 1: user_id (Varint)
        $data .= self::writeTag(1, 0);
        $data .= self::writeVarint($userId);
        
        // Field 2: is_typing (Varint)
        $data .= self::writeTag(2, 0);
        $data .= self::writeVarint($isTyping ? 1 : 0);
        
        return $data;
    }

    public static function encodeStateUpdated($user): string
    {
        $data = '';
        
        // Field 1: user_id (Varint)
        $data .= self::writeTag(1, 0);
        $data .= self::writeVarint($user->id);
        
        // Field 2: latitude (Length-delimited String)
        if (!empty($user->latitude)) {
            $data .= self::writeTag(2, 2);
            $latStr = (string)$user->latitude;
            $data .= self::writeVarint(strlen($latStr));
            $data .= $latStr;
        }
        
        // Field 3: longitude (Length-delimited String)
        if (!empty($user->longitude)) {
            $data .= self::writeTag(3, 2);
            $lonStr = (string)$user->longitude;
            $data .= self::writeVarint(strlen($lonStr));
            $data .= $lonStr;
        }
        
        // Field 4: battery_level (Varint)
        if ($user->battery_level !== null) {
            $data .= self::writeTag(4, 0);
            $data .= self::writeVarint((int)$user->battery_level);
        }
        
        // Field 5: is_charging (Varint)
        if ($user->is_charging !== null) {
            $data .= self::writeTag(5, 0);
            $data .= self::writeVarint($user->is_charging ? 1 : 0);
        }
        
        // Field 6: status_note (Length-delimited String)
        if (!empty($user->status_note)) {
            $data .= self::writeTag(6, 2);
            $noteStr = (string)$user->status_note;
            $data .= self::writeVarint(strlen($noteStr));
            $data .= $noteStr;
        }
        
        // Field 7: location_name (Length-delimited String)
        if (!empty($user->location_name)) {
            $data .= self::writeTag(7, 2);
            $locStr = (string)$user->location_name;
            $data .= self::writeVarint(strlen($locStr));
            $data .= $locStr;
        }
        
        // Field 8: wifi_bssid (Length-delimited String)
        if (!empty($user->wifi_bssid)) {
            $data .= self::writeTag(8, 2);
            $wifiStr = (string)$user->wifi_bssid;
            $data .= self::writeVarint(strlen($wifiStr));
            $data .= $wifiStr;
        }
        
        // Field 9: last_seen_message_id (Varint)
        if ($user->last_seen_message_id !== null) {
            $data .= self::writeTag(9, 0);
            $data .= self::writeVarint((int)$user->last_seen_message_id);
        }
        
        return $data;
    }

    private static function writeTag(int $fieldNumber, int $wireType): string
    {
        return self::writeVarint(($fieldNumber << 3) | $wireType);
    }

    private static function writeVarint(int $value): string
    {
        $data = '';
        while ($value >= 0x80) {
            $data .= chr(($value & 0x7F) | 0x80);
            $value >>= 7;
        }
        $data .= chr($value & 0x7F);
        return $data;
    }

    private static function readVarint(string $data, &$pos): int
    {
        $value = 0;
        $shift = 0;
        while ($pos < strlen($data)) {
            $byte = ord($data[$pos++]);
            $value |= ($byte & 0x7F) << $shift;
            if (($byte & 0x80) === 0) {
                return $value;
            }
            $shift += 7;
        }
        return $value;
    }

    private static function skipField(string $data, &$pos, int $wireType): void
    {
        switch ($wireType) {
            case 0:
                self::readVarint($data, $pos);
                break;
            case 1:
                $pos += 8;
                break;
            case 2:
                $len = self::readVarint($data, $pos);
                $pos += $len;
                break;
            case 5:
                $pos += 4;
                break;
        }
    }
}

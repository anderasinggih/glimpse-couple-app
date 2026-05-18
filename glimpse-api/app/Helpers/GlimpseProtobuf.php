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

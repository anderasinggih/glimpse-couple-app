import Foundation

struct ProtobufReader {
    private let data: Data
    private var index = 0
    
    init(data: Data) {
        self.data = data
    }
    
    var hasMoreBytes: Bool {
        return index < data.count
    }
    
    mutating func readVarint() -> UInt64 {
        var value: UInt64 = 0
        var shift: Int = 0
        while index < data.count {
            let byte = data[index]
            index += 1
            value |= UInt64(byte & 0x7F) << shift
            if (byte & 0x80) == 0 {
                return value
            }
            shift += 7
            if shift >= 64 {
                break
            }
        }
        return value
    }
    
    mutating func readString() -> String {
        let length = Int(readVarint())
        guard index + length <= data.count else {
            return ""
        }
        let subData = data.subdata(in: index..<(index + length))
        index += length
        return String(data: subData, encoding: .utf8) ?? ""
    }
    
    mutating func readBytes() -> Data {
        let length = Int(readVarint())
        guard index + length <= data.count else {
            return Data()
        }
        let subData = data.subdata(in: index..<(index + length))
        index += length
        return subData
    }
    
    mutating func skipField(wireType: Int) {
        switch wireType {
        case 0: // Varint
            _ = readVarint()
        case 1: // 64-bit
            index = min(data.count, index + 8)
        case 2: // Length-delimited
            let length = Int(readVarint())
            index = min(data.count, index + length)
        case 5: // 32-bit
            index = min(data.count, index + 4)
        default:
            break
        }
    }
}

struct ProtobufWriter {
    private(set) var data = Data()
    
    mutating func writeVarint(_ val: UInt64) {
        var value = val
        while value >= 0x80 {
            data.append(UInt8((value & 0x7F) | 0x80))
            value >>= 7
        }
        data.append(UInt8(value & 0x7F))
    }
    
    mutating func writeTag(fieldNumber: Int, wireType: Int) {
        writeVarint(UInt64((fieldNumber << 3) | wireType))
    }
    
    mutating func writeInt32Field(fieldNumber: Int, value: Int) {
        writeTag(fieldNumber: fieldNumber, wireType: 0)
        writeVarint(UInt64(bitPattern: Int64(value)))
    }
    
    mutating func writeStringField(fieldNumber: Int, value: String) {
        guard let stringData = value.data(using: .utf8) else { return }
        writeTag(fieldNumber: fieldNumber, wireType: 2)
        writeVarint(UInt64(stringData.count))
        data.append(stringData)
    }
}

extension ChatMessage {
    static func decodeProtobuf(from base64String: String) -> ChatMessage? {
        guard let data = Data(base64Encoded: base64String) else { return nil }
        return decodeProtobuf(from: data)
    }
    
    static func decodeProtobuf(from data: Data) -> ChatMessage? {
        var reader = ProtobufReader(data: data)
        var id = 0
        var roomId = 0
        var senderId = 0
        var message = ""
        var createdAt = ""
        var isAudio = false
        var audioUrl: String? = nil
        var audioDuration: Double? = nil
        var audioExpired = false
        
        while reader.hasMoreBytes {
            let tag = reader.readVarint()
            let fieldNumber = Int(tag >> 3)
            let wireType = Int(tag & 0x07)
            
            switch fieldNumber {
            case 1:
                id = Int(reader.readVarint())
            case 2:
                roomId = Int(reader.readVarint())
            case 3:
                senderId = Int(reader.readVarint())
            case 4:
                message = reader.readString()
            case 5:
                createdAt = reader.readString()
            case 6:
                isAudio = reader.readVarint() == 1
            case 7:
                audioUrl = reader.readString()
            case 8:
                audioDuration = Double(reader.readVarint())
            case 9:
                audioExpired = reader.readVarint() == 1
            default:
                reader.skipField(wireType: wireType)
            }
        }
        
        return ChatMessage(
            id: id,
            couple_id: 0,
            sender_id: senderId,
            message: message,
            room_id: roomId > 0 ? roomId : nil,
            created_at: createdAt.isEmpty ? nil : createdAt,
            updated_at: createdAt.isEmpty ? nil : createdAt,
            is_audio: isAudio,
            audio_url: audioUrl,
            audio_duration: audioDuration,
            audio_expired: audioExpired
        )
    }
    
    func encodeProtobuf() -> Data {
        var writer = ProtobufWriter()
        writer.writeInt32Field(fieldNumber: 1, value: id)
        if let rId = room_id {
            writer.writeInt32Field(fieldNumber: 2, value: rId)
        }
        writer.writeInt32Field(fieldNumber: 3, value: sender_id)
        writer.writeStringField(fieldNumber: 4, value: message)
        if let ca = created_at {
            writer.writeStringField(fieldNumber: 5, value: ca)
        }
        if let isAud = is_audio {
            writer.writeInt32Field(fieldNumber: 6, value: isAud ? 1 : 0)
        }
        if let audUrl = audio_url {
            writer.writeStringField(fieldNumber: 7, value: audUrl)
        }
        if let dur = audio_duration {
            writer.writeInt32Field(fieldNumber: 8, value: Int(round(dur)))
        }
        if let exp = audio_expired {
            writer.writeInt32Field(fieldNumber: 9, value: exp ? 1 : 0)
        }
        return writer.data
    }
}

struct GlimpseUserStatus {
    var latitude: Double?
    var longitude: Double?
    var batteryLevel: Int?
    var isCharging: Bool?
    var statusNote: String?
    var locationName: String?
    var wifiBssid: String?
    var gpsTimestamp: TimeInterval?
    
    func encodeProtobuf() -> Data {
        var writer = ProtobufWriter()
        if let lat = latitude {
            writer.writeStringField(fieldNumber: 1, value: String(lat))
        }
        if let lon = longitude {
            writer.writeStringField(fieldNumber: 2, value: String(lon))
        }
        if let batt = batteryLevel {
            writer.writeInt32Field(fieldNumber: 3, value: batt)
        }
        if let char = isCharging {
            writer.writeInt32Field(fieldNumber: 4, value: char ? 1 : 0)
        }
        if let note = statusNote {
            writer.writeStringField(fieldNumber: 5, value: note)
        }
        if let loc = locationName {
            writer.writeStringField(fieldNumber: 6, value: loc)
        }
        if let wifi = wifiBssid {
            writer.writeStringField(fieldNumber: 7, value: wifi)
        }
        if let ts = gpsTimestamp {
            writer.writeStringField(fieldNumber: 8, value: String(ts))
        }
        return writer.data
    }
}

struct GlimpseTypingState {
    var userId: Int
    var isTyping: Bool
    var roomId: Int? = nil
    
    static func decodeProtobuf(from base64String: String) -> GlimpseTypingState? {
        guard let data = Data(base64Encoded: base64String) else { return nil }
        var reader = ProtobufReader(data: data)
        var userId = 0
        var isTyping = false
        var roomId: Int? = nil
        
        while reader.hasMoreBytes {
            let tag = reader.readVarint()
            let fieldNumber = Int(tag >> 3)
            let wireType = Int(tag & 0x07)
            
            switch fieldNumber {
            case 1:
                userId = Int(reader.readVarint())
            case 2:
                isTyping = reader.readVarint() != 0
            case 3:
                let rVal = Int(reader.readVarint())
                roomId = rVal > 0 ? rVal : nil
            default:
                reader.skipField(wireType: wireType)
            }
        }
        return GlimpseTypingState(userId: userId, isTyping: isTyping, roomId: roomId)
    }
}

struct GlimpsePartnerStateUpdate {
    var userId: Int
    var latitude: Double?
    var longitude: Double?
    var batteryLevel: Int?
    var isCharging: Bool?
    var statusNote: String?
    var locationName: String?
    var wifiBssid: String?
    var gpsTimestamp: TimeInterval?
    var lastSeenMessageId: Int?
    var lastActiveAt: String?
    var isSleeping: Bool?
    
    static func decodeProtobuf(from base64String: String) -> GlimpsePartnerStateUpdate? {
        guard let data = Data(base64Encoded: base64String) else { return nil }
        var reader = ProtobufReader(data: data)
        var userId = 0
        var latitude: Double? = nil
        var longitude: Double? = nil
        var batteryLevel: Int? = nil
        var isCharging: Bool? = nil
        var statusNote: String? = nil
        var locationName: String? = nil
        var wifiBssid: String?
        var gpsTimestamp: TimeInterval? = nil
        var lastSeenMessageId: Int? = nil
        var lastActiveAt: String? = nil
        var isSleeping: Bool? = nil
        
        while reader.hasMoreBytes {
            let tag = reader.readVarint()
            let fieldNumber = Int(tag >> 3)
            let wireType = Int(tag & 0x07)
            
            switch fieldNumber {
            case 1:
                userId = Int(reader.readVarint())
            case 2:
                let latStr = reader.readString()
                latitude = Double(latStr)
            case 3:
                let lonStr = reader.readString()
                longitude = Double(lonStr)
            case 4:
                batteryLevel = Int(reader.readVarint())
            case 5:
                isCharging = reader.readVarint() != 0
            case 6:
                statusNote = reader.readString()
            case 7:
                locationName = reader.readString()
            case 8:
                wifiBssid = reader.readString()
            case 9:
                lastSeenMessageId = Int(reader.readVarint())
            case 10:
                lastActiveAt = reader.readString()
            case 11:
                isSleeping = reader.readVarint() == 1
            default:
                reader.skipField(wireType: wireType)
            }
        }
        return GlimpsePartnerStateUpdate(
            userId: userId,
            latitude: latitude,
            longitude: longitude,
            batteryLevel: batteryLevel,
            isCharging: isCharging,
            statusNote: statusNote,
            locationName: locationName,
            wifiBssid: wifiBssid,
            lastSeenMessageId: lastSeenMessageId,
            lastActiveAt: lastActiveAt,
            isSleeping: isSleeping
        )
    }
}

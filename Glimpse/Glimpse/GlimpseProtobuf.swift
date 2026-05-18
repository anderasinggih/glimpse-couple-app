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
        writeVarint(UInt64(value))
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
            updated_at: createdAt.isEmpty ? nil : createdAt
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
        return writer.data
    }
}

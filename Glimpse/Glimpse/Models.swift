import Foundation
import CoreLocation

struct LocationHistoryEntry: Codable, Identifiable {
    var id: Double { timestamp }
    let latitude: Double
    let longitude: Double
    let timestamp: Double
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct GlimpseUser: Codable, Identifiable {
    let id: Int
    let name: String
    let email: String
    let profile_photo_url: String
    let born_date: String?
    var gender: String?
    var latitude: Double?
    var longitude: Double?
    var location_name: String?
    var status_note: String?
    var battery_level: Int?
    var is_charging: Bool?
    var is_sleeping: Bool?
    var wifi_bssid: String?
    var latest_photo_url: String?
    var last_updated: String?
    let invite_code: String?
    let couple_id: Int?
    var last_seen_message_id: Int?
    let location_history: [LocationHistoryEntry]?
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude ?? 0, longitude: longitude ?? 0)
    }
    
    var lastUpdatedDate: Date {
        guard let last = last_updated else { return Date() }
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: last) ?? Date()
    }
    
    var isOffline: Bool {
        guard last_updated != nil else { return true }
        return Calendar.current.dateComponents([.minute], from: lastUpdatedDate, to: Date()).minute ?? 0 > 3
    }
    
    var isBirthdayToday: Bool {
        guard let bdStr = born_date else { return false }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: bdStr) else { return false }
        
        let currentComponents = Calendar.current.dateComponents([.day, .month], from: Date())
        let birthComponents = Calendar.current.dateComponents([.day, .month], from: date)
        
        return currentComponents.day == birthComponents.day && currentComponents.month == birthComponents.month
    }
}

struct CoupleResponse: Codable { 
    let user: GlimpseUser
    let partner_data: GlimpseUser?
    let anniversary_start_date: String?
    let paired_at: String?
    let disconnect_requested_by: Int?
    let couple_active: Bool?
    let invited_by: Int?
    let is_together: Bool?
    let together_streak: Int?
    let highest_together_streak: Int?
    let total_meetings: Int?
    let love_burst_timestamp: Double?
    let active_schedule: GlimpseSchedule?
    let pending_invitation: GlimpseSchedule?
    
    var pairedDate: Date? {
        guard let paired = paired_at else { return nil }
        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: paired) {
            return date
        }
        let dbFormatter = DateFormatter()
        dbFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dbFormatter.locale = Locale(identifier: "en_US_POSIX")
        dbFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        if let date = dbFormatter.date(from: paired) {
            return date
        }
        return nil
    }
    
    var anniversaryDate: Date? {
        guard let start = anniversary_start_date else { return nil }
        
        // 1. Try ISO8601 Date Formatter
        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: start) {
            return date
        }
        
        // 2. Try YYYY-MM-DD HH:mm:ss standard database format
        let dbFormatter = DateFormatter()
        dbFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dbFormatter.locale = Locale(identifier: "en_US_POSIX")
        dbFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        if let date = dbFormatter.date(from: start) {
            return date
        }
        
        // 3. Try YYYY-MM-DD simple date format
        let simpleFormatter = DateFormatter()
        simpleFormatter.dateFormat = "yyyy-MM-dd"
        simpleFormatter.locale = Locale(identifier: "en_US_POSIX")
        simpleFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        if let date = simpleFormatter.date(from: start) {
            return date
        }
        
        return nil
    }
}

// Dummy Data for Previews
extension GlimpseUser {
    static let mockSelf = GlimpseUser(
        id: 1,
        name: "Anderas",
        email: "anderas@glimpse.com",
        profile_photo_url: "https://ui-avatars.com/api/?name=Anderas",
        born_date: "1999-05-18",
        gender: "male",
        latitude: -6.9740,
        longitude: 107.6303,
        location_name: "My Home",
        status_note: "Coding Glimpse 🚀",
        battery_level: 100,
        is_charging: false,
        is_sleeping: false,
        wifi_bssid: nil,
        latest_photo_url: nil,
        last_updated: ISO8601DateFormatter().string(from: Date()),
        invite_code: "GLMP-1234",
        couple_id: nil,
        last_seen_message_id: nil,
        location_history: nil
    )
    
    static let mockPartner = GlimpseUser(
        id: 2,
        name: "Unknown",
        email: "unknown@glimpse.com",
        profile_photo_url: "https://ui-avatars.com/api/?name=Unknown",
        born_date: nil,
        gender: nil,
        latitude: 0.0,
        longitude: 0.0,
        location_name: "Unknown Location",
        status_note: "No status available",
        battery_level: 0,
        is_charging: false,
        is_sleeping: false,
        wifi_bssid: nil,
        latest_photo_url: nil,
        last_updated: ISO8601DateFormatter().string(from: Date()),
        invite_code: "UNKNOWN",
        couple_id: nil,
        last_seen_message_id: nil,
        location_history: nil
    )
}

struct ChatMessage: Codable, Identifiable, Equatable {
    let id: Int
    let couple_id: Int
    let sender_id: Int
    let message: String
    let room_id: Int?
    let created_at: String?
    let updated_at: String?
}

struct GlimpseChatRoom: Codable, Identifiable, Equatable {
    let id: Int
    let couple_id: Int
    var name: String
    let is_main: Bool
    var latest_message: RoomLatestMessage?
    var unread_count: Int
    let created_at: String
    let updated_at: String
}

struct RoomLatestMessage: Codable, Equatable {
    let id: Int
    let message: String
    let sender_id: Int
    let created_at: String?
}

struct GlimpseFlash: Codable, Identifiable {
    let id: Int
    let sender_id: Int
    let sender_name: String
    let photo_url: String
    let latitude: Double?
    let longitude: Double?
    let location_name: String?
    let status_note: String?
    let battery_level: Int?
    let created_at: String
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude ?? 0, longitude: longitude ?? 0)
    }
    
    var createdDate: Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: created_at) ?? Date()
    }
}

struct GlimpseSchedule: Codable, Identifiable, Equatable {
    let id: Int
    let couple_id: Int
    let creator_id: Int
    let title: String
    let scheduled_at: String
    let reminder_minutes: Int
    let status: String // pending, accepted, declined
    let created_at: String?
    let updated_at: String?
    
    var scheduledDate: Date {
        // We will parse standard ISO8601 date
        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: scheduled_at) {
            return date
        }
        
        let dbFormatter = DateFormatter()
        dbFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dbFormatter.locale = Locale(identifier: "en_US_POSIX")
        dbFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        if let date = dbFormatter.date(from: scheduled_at) {
            return date
        }
        
        let simpleFormatter = DateFormatter()
        simpleFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        if let date = simpleFormatter.date(from: scheduled_at) {
            return date
        }
        
        // Fallback for simple date formats
        let simpleDateFormatter = DateFormatter()
        simpleDateFormatter.dateFormat = "yyyy-MM-dd"
        if let date = simpleDateFormatter.date(from: scheduled_at) {
            return date
        }
        
        return Date()
    }
}

// --- 💬 Chat Reply Extension ---
extension ChatMessage {
    struct ParsedReply: Equatable {
        let parentId: Int
        let senderName: String
        let parentMessage: String
        let actualMessage: String
    }
    
    var replyInfo: ParsedReply? {
        guard message.hasPrefix("{{reply:") else { return nil }
        // Find closing tag "}}"
        guard let closingRange = message.range(of: "}}") else { return nil }
        
        let headerStr = String(message[message.startIndex..<closingRange.lowerBound])
            .replacingOccurrences(of: "{{reply:", with: "")
        
        let actualMessage = String(message[closingRange.upperBound...])
        
        let parts = headerStr.components(separatedBy: "|")
        guard parts.count >= 3, let parentId = Int(parts[0]) else { return nil }
        
        return ParsedReply(
            parentId: parentId,
            senderName: parts[1],
            parentMessage: parts[2],
            actualMessage: actualMessage
        )
    }
    
    var cleanDisplayContent: String {
        if message.hasPrefix("[FLASH_ATTACHMENT]") {
            return "📸 Sent a Flash Photo"
        }
        if message.hasPrefix("[KENCAN_INVITATION]") {
            return "📅 Sent a Date Invitation"
        }
        if let reply = replyInfo {
            return reply.actualMessage
        }
        return message
    }
}

extension RoomLatestMessage {
    var replyInfo: ChatMessage.ParsedReply? {
        guard message.hasPrefix("{{reply:") else { return nil }
        guard let closingRange = message.range(of: "}}") else { return nil }
        
        let headerStr = String(message[message.startIndex..<closingRange.lowerBound])
            .replacingOccurrences(of: "{{reply:", with: "")
        
        let actualMessage = String(message[closingRange.upperBound...])
        
        let parts = headerStr.components(separatedBy: "|")
        guard parts.count >= 3, let parentId = Int(parts[0]) else { return nil }
        
        return ChatMessage.ParsedReply(
            parentId: parentId,
            senderName: parts[1],
            parentMessage: parts[2],
            actualMessage: actualMessage
        )
    }
    
    var cleanDisplayContent: String {
        if message.hasPrefix("[FLASH_ATTACHMENT]") {
            return "📸 Sent a Flash Photo"
        }
        if message.hasPrefix("[KENCAN_INVITATION]") {
            return "📅 Sent a Date Invitation"
        }
        if let reply = replyInfo {
            return reply.actualMessage
        }
        return message
    }
}

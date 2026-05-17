import Foundation
import CoreLocation

struct GlimpseUser: Codable, Identifiable {
    let id: Int
    let name: String
    let email: String
    let profile_photo_url: String
    let latitude: Double?
    let longitude: Double?
    let location_name: String?
    let status_note: String?
    let battery_level: Int?
    let is_charging: Bool?
    let latest_photo_url: String?
    let last_updated: String?
    let invite_code: String?
    let couple_id: Int?
    let last_seen_message_id: Int?
    
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
}

struct CoupleResponse: Codable { 
    let user: GlimpseUser
    let partner_data: GlimpseUser?
    let anniversary_start_date: String?
    let disconnect_requested_by: Int?
    let couple_active: Bool?
    let invited_by: Int?
    let is_together: Bool?
    let together_streak: Int?
    let total_meetings: Int?
    let love_burst_timestamp: Double?
    
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
        latitude: -6.9740,
        longitude: 107.6303,
        location_name: "My Home",
        status_note: "Coding Glimpse 🚀",
        battery_level: 100,
        is_charging: false,
        latest_photo_url: nil,
        last_updated: ISO8601DateFormatter().string(from: Date()),
        invite_code: "GLMP-1234",
        couple_id: nil,
        last_seen_message_id: nil
    )
    
    static let mockPartner = GlimpseUser(
        id: 2,
        name: "Unknown",
        email: "unknown@glimpse.com",
        profile_photo_url: "https://ui-avatars.com/api/?name=Unknown",
        latitude: 0.0,
        longitude: 0.0,
        location_name: "Unknown Location",
        status_note: "No status available",
        battery_level: 0,
        is_charging: false,
        latest_photo_url: nil,
        last_updated: ISO8601DateFormatter().string(from: Date()),
        invite_code: "UNKNOWN",
        couple_id: nil,
        last_seen_message_id: nil
    )
}

struct ChatMessage: Codable, Identifiable, Equatable {
    let id: Int
    let couple_id: Int
    let sender_id: Int
    let message: String
    let created_at: String?
    let updated_at: String?
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

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
    let latest_photo_url: String?
    let last_updated: String?
    let invite_code: String?
    let couple_id: Int?
    
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
        return Calendar.current.dateComponents([.minute], from: lastUpdatedDate, to: Date()).minute ?? 0 > 60
    }
}

struct CoupleResponse: Codable {
    let user: GlimpseUser
    let partner_data: GlimpseUser?
    let anniversary_start_date: String?
    
    var anniversaryDate: Date? {
        guard let start = anniversary_start_date else { return nil }
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: start)
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
        latest_photo_url: nil,
        last_updated: ISO8601DateFormatter().string(from: Date()),
        invite_code: "GLMP-1234",
        couple_id: nil
    )
    
    static let mockPartner = GlimpseUser(
        id: 2,
        name: "Sarah",
        email: "sarah@glimpse.com",
        profile_photo_url: "https://images.unsplash.com/photo-1494790108377-be9c29b29330",
        latitude: -6.9750,
        longitude: 107.6310,
        location_name: "Kampus Telkom",
        status_note: "Miss you! ❤️",
        battery_level: 85,
        latest_photo_url: nil,
        last_updated: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-300)),
        invite_code: "SARAH-CODE",
        couple_id: 1
    )
}

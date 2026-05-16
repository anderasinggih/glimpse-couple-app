import Foundation
import CoreLocation

struct GlimpseUser: Codable, Identifiable {
    let id: Int
    let name: String
    let profile_photo_url: String
    let latitude: Double
    let longitude: Double
    let location_name: String
    let status_note: String
    let battery_level: Int
    let latest_photo_url: String?
    let last_updated: String // ISO 8601
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var lastUpdatedDate: Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: last_updated) ?? Date()
    }
    
    var isOffline: Bool {
        Calendar.current.dateComponents([.minute], from: lastUpdatedDate, to: Date()).minute ?? 0 > 60
    }
}

struct CoupleResponse: Codable {
    let couple_id: Int
    let partner_data: GlimpseUser
    let anniversary_start_date: String // ISO 8601
    
    var anniversaryDate: Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: anniversary_start_date) ?? Date()
    }
}

// Dummy Data for Previews
extension GlimpseUser {
    static let mockPartner = GlimpseUser(
        id: 2,
        name: "Sarah",
        profile_photo_url: "https://images.unsplash.com/photo-1494790108377-be9c29b29330",
        latitude: -6.9740,
        longitude: 107.6303,
        location_name: "Kampus Telkom",
        status_note: "Lagi ngerjain tugas di perpus, kangen kamu! ❤️",
        battery_level: 85,
        latest_photo_url: nil,
        last_updated: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-300))
    )
}

extension CoupleResponse {
    static let mock = CoupleResponse(
        couple_id: 1,
        partner_data: .mockPartner,
        anniversary_start_date: "2023-10-20T00:00:00Z"
    )
}

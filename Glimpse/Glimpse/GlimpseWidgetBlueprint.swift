import WidgetKit
import SwiftUI

// MARK: - Widget Blueprint
// This code represents the logic for the WidgetKit target.

struct GlimpseEntry: TimelineEntry {
    let date: Date
    let partner: GlimpseUser
    let anniversaryDate: Date
}

struct GlimpseWidgetEntryView : View {
    var entry: GlimpseEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            Color.deepVelvet // Widget background
            
            switch family {
            case .systemSmall:
                SmallWidgetView(entry: entry)
            case .systemMedium:
                MediumWidgetView(entry: entry)
            default:
                Text("Not supported")
            }
        }
    }
}

struct SmallWidgetView: View {
    var entry: GlimpseEntry
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.electricPurple.opacity(0.3), lineWidth: 3)
                    .frame(width: 50, height: 50)
                
                // Simplified profile photo for widget
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 44, height: 44)
                    .foregroundColor(.electricPurple)
            }
            
            Text(abbreviatedAnniversary(from: entry.anniversaryDate))
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.electricPurple)
            
            Text(entry.partner.status_note)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .padding(12)
    }
    
    private func abbreviatedAnniversary(from date: Date) -> String {
        let components = Calendar.current.dateComponents([.year, .day], from: date, to: Date())
        return "\(components.year ?? 0)yr \(components.day ?? 0)d"
    }
}

struct MediumWidgetView: View {
    var entry: GlimpseEntry
    
    var body: some View {
        HStack(spacing: 0) {
            // Left: Mini Map Area Snapshot Placeholder
            ZStack {
                Color.gray.opacity(0.2)
                Image(systemName: "map.fill")
                    .foregroundColor(.white.opacity(0.3))
                
                VStack {
                    Spacer()
                    Text(entry.partner.location_name)
                        .font(.system(size: 10, weight: .bold))
                        .padding(4)
                        .background(.ultraThinMaterial)
                        .cornerRadius(4)
                        .padding(8)
                }
            }
            .frame(width: 140)
            
            // Right: Partner Info
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(entry.partner.name)
                        .font(.headline)
                    Spacer()
                    Text("\(entry.partner.battery_level)%")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
                
                Text(entry.partner.status_note)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(3)
                
                if let photoUrl = entry.partner.latest_photo_url {
                    // Crisp rendering of compressed photo
                    Text("New Photo Available")
                        .font(.system(size: 8, weight: .bold))
                        .padding(4)
                        .background(Color.electricPurple)
                        .cornerRadius(4)
                }
                
                Spacer()
                
                Text(entry.date, style: .time)
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
            .padding(12)
        }
    }
}

// NOTE: Implement TimelineProvider fetching from Laravel API with Sanctum Token

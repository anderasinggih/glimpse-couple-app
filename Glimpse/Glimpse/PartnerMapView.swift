import SwiftUI
import MapKit

struct PartnerMapView: View {
    let user: GlimpseUser
    @State private var position: MapCameraPosition
    
    init(user: GlimpseUser) {
        self.user = user
        _position = State(initialValue: .region(MKCoordinateRegion(
            center: user.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )))
    }
    
    var body: some View {
        Map(position: $position) {
            Annotation(user.name, coordinate: user.coordinate) {
                PartnerMarker(photoUrl: user.profile_photo_url, isOffline: user.isOffline)
            }
        }
        .mapStyle(.standard)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(alignment: .bottom) {
            PartnerOverlayCard(user: user)
                .padding(12)
        }
    }
}

struct PartnerMarker: View {
    let photoUrl: String
    let isOffline: Bool
    @State private var pulse = false
    
    var body: some View {
        ZStack {
            if !isOffline {
                // Futuristic Orbiting Pulse
                Circle()
                    .stroke(
                        AngularGradient(colors: [.electricPurple, .activeCyan, .electricPurple], center: .center),
                        lineWidth: 2
                    )
                    .frame(width: 58, height: 58)
                    .rotationEffect(.degrees(pulse ? 360 : 0))
                    .scaleEffect(pulse ? 1.1 : 0.95)
                    .opacity(pulse ? 0.6 : 0.3)
                    .onAppear {
                        withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                            pulse = true
                        }
                    }
            }
            
            AsyncImage(url: URL(string: photoUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle().fill(Color.gray.opacity(0.3))
            }
            .frame(width: 48, height: 48)
            .clipShape(Circle())
            .overlay(Circle().stroke(isOffline ? Color.gray : .white.opacity(0.8), lineWidth: 1.5))
            .shadow(color: isOffline ? .clear : .electricPurple.opacity(0.4), radius: 8)
            .saturation(isOffline ? 0.2 : 1.0)
        }
    }
}

struct PartnerOverlayCard: View {
    let user: GlimpseUser
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.name)
                        .font(.system(size: 18, weight: .bold))
                    Text("Updated \(timeAgo(from: user.lastUpdatedDate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                BatteryIndicator(level: user.battery_level ?? 0)
            }
            
            HStack(spacing: 8) {
                Image(systemName: "quote.bubble.fill")
                    .foregroundColor(.adaptiveAccent)
                    .font(.system(size: 14))
                
                Text(user.status_note)
                    .font(.system(size: 14))
                    .lineLimit(2)
            }
            .padding(.top, 4)
        }
        .padding(16)
        .glassmorphic()
        .saturation(user.isOffline ? 0.5 : 1.0)
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct BatteryIndicator: View {
    let level: Int
    
    var color: Color {
        if level > 60 { return .green }
        if level > 20 { return .yellow }
        return .red
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: level > 20 ? "battery.100" : "battery.25")
                .foregroundColor(color)
            Text("\(level)%")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    PartnerMapView(user: .mockPartner)
        .frame(height: 400)
        .padding()
}

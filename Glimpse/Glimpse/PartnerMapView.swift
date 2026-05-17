import SwiftUI
import MapKit

struct PartnerMapView: View {
    let user: GlimpseUser
    @State private var position: MapCameraPosition
    @State private var isShowingPhoto = true
    @State private var localAddress: String? = nil
    
    // Auto-rotation timer every 10 seconds
    private let autoRotateTimer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
    
    init(user: GlimpseUser) {
        self.user = user
        _position = State(initialValue: .region(MKCoordinateRegion(
            center: user.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )))
    }
    
    var body: some View {
        ZStack {
            if isShowingPhoto {
                // PHOTO SIDE
                ZStack {
                    if let photoUrl = user.latest_photo_url, !photoUrl.isEmpty {
                        CachedImageView(urlString: formatImageUrlString(photoUrl))
                    } else {
                        Color.black.opacity(0.8)
                            .overlay(
                                VStack(spacing: 12) {
                                    Image(systemName: "camera.shutter.button")
                                        .font(.title)
                                    Text("No Flash yet")
                                        .font(.subheadline)
                                }
                                .foregroundColor(.white.opacity(0.3))
                            )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity)
            } else {
                // MAP SIDE
                Map(position: $position, interactionModes: []) { // Interaction disabled
                    Annotation(user.name, coordinate: user.coordinate) {
                        ZStack {
                            // High Visibility Outer Glow
                            Circle()
                                .fill(Color.activeCyan.opacity(0.3))
                                .frame(width: 80, height: 80)
                                .blur(radius: 20)
                            
                            PartnerMarker(photoUrl: user.profile_photo_url, isOffline: user.isOffline)
                        }
                    }
                }
                .mapStyle(.hybrid(elevation: .realistic))
                .transition(.opacity)
                .onChange(of: user.latitude) {
                    withAnimation(.easeInOut(duration: 1.0)) {
                        position = .region(MKCoordinateRegion(
                            center: user.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                        ))
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(alignment: .bottom) {
            PartnerOverlayCard(user: user, locationOverride: localAddress, isMinimal: isShowingPhoto)
                .padding(12)
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.5)) {
                isShowingPhoto.toggle()
            }
        }
        .onReceive(autoRotateTimer) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                isShowingPhoto.toggle()
            }
        }
        .onAppear {
            updateLocalAddress()
        }
        .onChange(of: user.latitude) {
            updateLocalAddress()
        }
    }
    
    private func updateLocalAddress() {
        if let serverAddress = user.location_name, !serverAddress.isEmpty {
            self.localAddress = serverAddress
            return
        }
        
        Task {
            let location = CLLocation(latitude: user.latitude ?? 0, longitude: user.longitude ?? 0)
            let geocoder = CLGeocoder()
            if let placemarks = try? await geocoder.reverseGeocodeLocation(location),
               let placemark = placemarks.first {
                let street = placemark.thoroughfare ?? ""
                let subLoc = placemark.subLocality ?? placemark.locality ?? ""
                
                await MainActor.run {
                    if !street.isEmpty && !subLoc.isEmpty {
                        self.localAddress = "\(street), \(subLoc)"
                    } else {
                        self.localAddress = street.isEmpty ? subLoc : street
                    }
                }
            }
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func formatImageUrlString(_ urlString: String) -> String {
        if urlString.hasPrefix("http") {
            return urlString
        } else {
            let cleanPath = urlString.hasPrefix("/") ? String(urlString.dropFirst()) : urlString
            let baseURL = AuthManager.shared.baseURL.replacingOccurrences(of: "/api", with: "")
            if cleanPath.contains("storage/") {
                return "\(baseURL)/\(cleanPath)"
            } else {
                return "\(baseURL)/storage/\(cleanPath)"
            }
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
            
            CachedImageView(urlString: photoUrl)
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
    let locationOverride: String?
    let isMinimal: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: isMinimal ? 4 : 12) {
            if !isMinimal {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.name)
                            .font(.system(size: 18, weight: .bold))
                        
                        if user.isOffline {
                            Text("Last sync \(timeAgo(from: user.lastUpdatedDate)) (Offline)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                        } else {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 6, height: 6)
                                Text("Live Syncing (Online)")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    BatteryIndicator(level: user.battery_level ?? 0, isCharging: user.is_charging)
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.activeCyan)
                        .font(.system(size: 14))
                    
                    Text(user.location_name ?? (locationOverride ?? "Somewhere unknown..."))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                }
                .padding(.top, 4)
                
                HStack(spacing: 8) {
                    Image(systemName: "quote.bubble.fill")
                        .foregroundColor(.electricPurple)
                        .font(.system(size: 14))
                    
                    Text(user.status_note ?? "No status yet")
                        .font(.system(size: 14))
                        .lineLimit(2)
                }
            } else {
                // MINIMAL MODE FOR PHOTO
                VStack(alignment: .leading, spacing: 2) {
                    Text(timeAgo(from: user.lastUpdatedDate))
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(user.location_name ?? (locationOverride ?? "Somewhere unknown..."))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    
                    if let note = user.status_note, !note.isEmpty {
                        Text(note)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.top, 2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 2)
            }
        }
        .padding(isMinimal ? 0 : 16)
        .background {
            if !isMinimal {
                Color.clear.liquidGlass()
            }
        }
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
    let isCharging: Bool?
    
    var color: Color {
        if isCharging == true { return .green }
        if level > 60 { return .green }
        if level > 20 { return .yellow }
        return .red
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isCharging == true ? "battery.100.bolt" : (level > 20 ? "battery.100" : "battery.25"))
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

struct CachedImageView: View {
    let urlString: String
    @State private var uiImage: UIImage? = nil
    
    var body: some View {
        Group {
            if let uiImage = uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color.black.opacity(0.8)
                    .overlay(ProgressView().tint(.white))
            }
        }
        .task(id: urlString) {
            await loadImage()
        }
    }
    
    private func formattedUrl() -> String {
        if urlString.hasPrefix("http") {
            return urlString
        } else {
            let cleanPath = urlString.hasPrefix("/") ? String(urlString.dropFirst()) : urlString
            let baseURL = AuthManager.shared.baseURL.replacingOccurrences(of: "/api", with: "")
            return cleanPath.contains("storage/") ? "\(baseURL)/\(cleanPath)" : "\(baseURL)/storage/\(cleanPath)"
        }
    }
    
    private func loadImage() async {
        let finalUrlStr = formattedUrl()
        let cacheKey = "img_cache_\(finalUrlStr)"
        let sharedDefaults = UserDefaults(suiteName: "group.glimpse.app")
        
        // 1. Cek Cache dulu
        if let data = sharedDefaults?.data(forKey: cacheKey), let cached = UIImage(data: data) {
            self.uiImage = cached
            return
        }
        
        // 2. Fetch jika belum ada di cache
        guard let url = URL(string: finalUrlStr) else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let fetched = UIImage(data: data) {
                sharedDefaults?.set(data, forKey: cacheKey)
                await MainActor.run {
                    self.uiImage = fetched
                }
            }
        } catch {
            // Error handling silent
        }
    }
}

#Preview {
    PartnerMapView(user: .mockPartner)
        .frame(height: 400)
        .padding()
}

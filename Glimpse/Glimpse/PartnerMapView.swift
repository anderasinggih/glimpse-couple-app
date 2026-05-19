import SwiftUI
import MapKit
import Combine

struct PartnerMapView: View {
    @AppStorage("glimpse_default_map_style") var defaultMapStyle = "satellite"
    let user: GlimpseUser
    @State private var position: MapCameraPosition
    @State private var isShowingPhoto = true
    @State private var localAddress: String? = nil
    @State private var auth = AuthManager.shared
    @State private var mapPulse = false
    @State private var wavePhase = 0.0
    
    @State private var animatedPartnerLatitude: Double = 0.0
    @State private var animatedPartnerLongitude: Double = 0.0
    
    private var animatedPartnerCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: animatedPartnerLatitude != 0.0 ? animatedPartnerLatitude : (user.latitude ?? 0.0),
            longitude: animatedPartnerLongitude != 0.0 ? animatedPartnerLongitude : (user.longitude ?? 0.0)
        )
    }
    
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
                    
                    // Minimal mode card overlay fades inside the Photo container
                    PartnerOverlayCard(user: user, locationOverride: localAddress, isMinimal: true)
                        .padding(12)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity)
            } else {
                // MAP SIDE
                ZStack {
                    Map(position: $position, interactionModes: []) {
                        if auth.isTogether, let currentUser = auth.currentUser,
                           let userLat = user.latitude, userLat != 0.0,
                           let myLat = currentUser.latitude, myLat != 0.0 {
                            Annotation("Together", coordinate: animatedPartnerCoordinate) {
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(colors: [.electricPurple.opacity(0.3), .activeCyan.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 90, height: 90)
                                        .scaleEffect(mapPulse ? 1.25 : 0.85)
                                        .blur(radius: 8)
                                        .onAppear {
                                            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                                                mapPulse = true
                                            }
                                        }
                                    
                                    HStack(spacing: -8) {
                                        CachedImageView(urlString: currentUser.profile_photo_url)
                                            .frame(width: 38, height: 38)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color.electricPurple, lineWidth: 1.5))
                                            .shadow(color: .electricPurple.opacity(0.5), radius: 5)
                                        
                                        Image(systemName: "heart.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.red)
                                            .scaleEffect(mapPulse ? 1.2 : 0.8)
                                            .shadow(color: .red, radius: 4)
                                            .zIndex(5)
                                        
                                        CachedImageView(urlString: user.profile_photo_url)
                                            .frame(width: 38, height: 38)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color.activeCyan, lineWidth: 1.5))
                                            .shadow(color: .activeCyan.opacity(0.5), radius: 5)
                                    }
                                    .padding(6)
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(24)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24)
                                            .stroke(
                                                LinearGradient(colors: [.white.opacity(0.5), .clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                                                lineWidth: 0.5
                                            )
                                    )
                                }
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                                        position = .region(MKCoordinateRegion(
                                            center: animatedPartnerCoordinate,
                                            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                                        ))
                                    }
                                }
                            }
                        } else {
                            // Wavy Connecting line
                            if let currentUser = auth.currentUser,
                               let userLat = user.latitude, userLat != 0.0,
                               let myLat = currentUser.latitude, myLat != 0.0 {
                                let startLoc = CLLocation(latitude: currentUser.coordinate.latitude, longitude: currentUser.coordinate.longitude)
                                let endLoc = CLLocation(latitude: animatedPartnerCoordinate.latitude, longitude: animatedPartnerCoordinate.longitude)
                                let distanceInKm = startLoc.distance(from: endLoc) / 1000.0
                                
                                let wavyCoords = generateWavyCoordinates(from: currentUser.coordinate, to: animatedPartnerCoordinate, phase: wavePhase)
                                let colors = getShiftingColors(phase: wavePhase, distanceInKm: distanceInKm)
                                
                                // 1. Bottom Layer: Outer Neon Glow
                                MapPolyline(coordinates: wavyCoords)
                                    .stroke(
                                        LinearGradient(colors: colors.map { $0.opacity(0.4) }, startPoint: .leading, endPoint: .trailing),
                                        style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round)
                                    )
                                
                                // 2. Top Layer: Core Saturated Line
                                MapPolyline(coordinates: wavyCoords)
                                    .stroke(
                                        LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing),
                                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                                    )
                            }
                            
                            if let currentUser = auth.currentUser, let myLat = currentUser.latitude, myLat != 0.0 {
                                Annotation("Me", coordinate: currentUser.coordinate) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.electricPurple.opacity(0.2))
                                            .frame(width: 60, height: 60)
                                            .blur(radius: 10)
                                        
                                        PartnerMarker(photoUrl: currentUser.profile_photo_url, isOffline: false, batteryLevel: currentUser.battery_level, isCharging: currentUser.is_charging, locationName: currentUser.location_name, isSleeping: currentUser.is_sleeping)
                                    }
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                                            position = .region(MKCoordinateRegion(
                                                center: currentUser.coordinate,
                                                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                                            ))
                                        }
                                    }
                                }
                            }
                            
                            if let userLat = user.latitude, userLat != 0.0 {
                                Annotation(user.name, coordinate: animatedPartnerCoordinate) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.activeCyan.opacity(0.3))
                                            .frame(width: 80, height: 80)
                                            .blur(radius: 20)
                                        
                                        PartnerMarker(photoUrl: user.profile_photo_url, isOffline: user.isOffline, batteryLevel: user.battery_level, isCharging: user.is_charging, locationName: user.location_name, isSleeping: user.is_sleeping)
                                    }
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                                            position = .region(MKCoordinateRegion(
                                                center: animatedPartnerCoordinate,
                                                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                                            ))
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .mapStyle(defaultMapStyle == "satellite" ? .hybrid(elevation: .realistic) : .standard(emphasis: .muted))
                    .onChange(of: user.latitude) {
                        updateMapPosition()
                    }
                    .onChange(of: user.last_updated) {
                        updateMapPosition()
                    }
                    
                    // Full mode card overlay fades inside the Map container
                    PartnerOverlayCard(user: user, locationOverride: localAddress, isMinimal: false)
                        .padding(12)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
                .transition(.opacity)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.easeInOut(duration: 0.5)) {
                isShowingPhoto.toggle()
            }
        }
        .onReceive(autoRotateTimer) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                isShowingPhoto.toggle()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("FlipDashboardCard"))) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                isShowingPhoto.toggle()
            }
        }
        .onAppear {
            updateLocalAddress()
            updateMapPosition()
            if let lat = user.latitude, let lon = user.longitude, lat != 0.0, lon != 0.0 {
                animatedPartnerLatitude = lat
                animatedPartnerLongitude = lon
            }
            withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                wavePhase = 2 * .pi
            }
        }
        .onChange(of: user.latitude) {
            updateLocalAddress()
            updateMapPosition()
            if let lat = user.latitude, let lon = user.longitude, lat != 0.0, lon != 0.0 {
                if animatedPartnerLatitude == 0.0 {
                    animatedPartnerLatitude = lat
                    animatedPartnerLongitude = lon
                } else {
                    withAnimation(.easeInOut(duration: 3.5)) {
                        animatedPartnerLatitude = lat
                        animatedPartnerLongitude = lon
                    }
                }
            }
        }
    }
    
    private func updateMapPosition() {
        if let lat = user.latitude, let lon = user.longitude, lat != 0.0, lon != 0.0 {
            withAnimation(.easeInOut(duration: 1.0)) {
                position = .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                ))
            }
        } else if let currentUser = auth.currentUser, let lat = currentUser.latitude, let lon = currentUser.longitude, lat != 0.0, lon != 0.0 {
            withAnimation(.easeInOut(duration: 1.0)) {
                position = .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                ))
            }
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
                let kelurahan = placemark.subLocality ?? ""
                let kecamatan = placemark.subAdministrativeArea ?? ""
                
                var addressParts: [String] = []
                if !street.isEmpty { addressParts.append(street) }
                if !kelurahan.isEmpty { addressParts.append(kelurahan) }
                if !kecamatan.isEmpty { addressParts.append(kecamatan) }
                
                let formattedAddress = addressParts.isEmpty ? (placemark.locality ?? "Tidak Diketahui") : addressParts.joined(separator: ", ")
                
                await MainActor.run {
                    self.localAddress = formattedAddress
                }
            }
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 {
            return "Just now"
        }
        let minutes = Int(interval / 60)
        if minutes < 60 {
            return "\(minutes)m ago"
        }
        let hours = minutes / 60
        if hours < 24 {
            return "\(hours)h ago"
        }
        let days = hours / 24
        return "\(days)d ago"
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
    
    private func getShiftingColors(phase: Double, distanceInKm: Double) -> [Color] {
        let baseHue = phase / (2 * .pi)
        
        if distanceInKm <= 1.0 {
            // DEKAT: Warm passion (hues around 0.85 to 0.15 - Magenta, Red, Orange, Yellow)
            let hue1 = (0.85 + baseHue * 0.3).truncatingRemainder(dividingBy: 1.0)
            let hue2 = (hue1 + 0.1).truncatingRemainder(dividingBy: 1.0)
            let hue3 = (hue2 + 0.1).truncatingRemainder(dividingBy: 1.0)
            return [
                Color(hue: hue1, saturation: 0.95, brightness: 0.95),
                Color(hue: hue2, saturation: 0.95, brightness: 0.95),
                Color(hue: hue3, saturation: 0.95, brightness: 0.95),
                Color(hue: hue1, saturation: 0.95, brightness: 0.95)
            ]
        } else if distanceInKm >= 10.0 {
            // JAUH: Steady aurora (hues around 0.45 to 0.65 - Emerald, Teal, Cyan, Blue)
            let hue1 = 0.45 + baseHue * 0.2
            let hue2 = hue1 + 0.07
            let hue3 = hue2 + 0.07
            return [
                Color(hue: hue1, saturation: 0.95, brightness: 0.95),
                Color(hue: hue2, saturation: 0.95, brightness: 0.95),
                Color(hue: hue3, saturation: 0.95, brightness: 0.95),
                Color(hue: hue1, saturation: 0.95, brightness: 0.95)
            ]
        } else {
            // SEDANG: Romantic purple/magenta (hues around 0.65 to 0.85 - Blue, Indigo, Purple, Pink)
            let hue1 = 0.65 + baseHue * 0.2
            let hue2 = hue1 + 0.07
            let hue3 = hue2 + 0.07
            return [
                Color(hue: hue1, saturation: 0.95, brightness: 0.95),
                Color(hue: hue2, saturation: 0.95, brightness: 0.95),
                Color(hue: hue3, saturation: 0.95, brightness: 0.95),
                Color(hue: hue1, saturation: 0.95, brightness: 0.95)
            ]
        }
    }
    
    private func generateWavyCoordinates(
        from start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D,
        phase: Double
    ) -> [CLLocationCoordinate2D] {
        let pointsCount = 60
        var coordinates: [CLLocationCoordinate2D] = []
        
        let dLat = end.latitude - start.latitude
        let dLon = end.longitude - start.longitude
        let distance = sqrt(dLat * dLat + dLon * dLon)
        
        if distance < 0.0001 {
            return [start, end]
        }
        
        let pLat = -dLon / distance
        let pLon = dLat / distance
        
        // Dynamic low frequency and smooth waves like a gentle audio signal
        let waveFrequency = 4.0
        let amplitude = distance * 0.05
        
        for i in 0...pointsCount {
            let t = Double(i) / Double(pointsCount)
            let linearLat = start.latitude + dLat * t
            let linearLon = start.longitude + dLon * t
            
            let envelope = sin(t * Double.pi)
            let wave = sin(t * Double.pi * waveFrequency - phase) * amplitude * envelope
            
            let waveLat = linearLat + pLat * wave
            let waveLon = linearLon + pLon * wave
            
            coordinates.append(CLLocationCoordinate2D(latitude: waveLat, longitude: waveLon))
        }
        
        return coordinates
    }
}

struct SleepingZView: View {
    let delay: Double
    @State private var animate = false
    
    var body: some View {
        Text("💤")
            .font(.system(size: animate ? 14 : 8, weight: .bold))
            .opacity(animate ? 0.0 : 0.9)
            .offset(x: animate ? -12 : 0, y: animate ? -25 : 0)
            .scaleEffect(animate ? 1.2 : 0.8)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.8)
                    .repeatForever(autoreverses: false)
                    .delay(delay)
                ) {
                    animate = true
                }
            }
    }
}

struct PartnerMarker: View {
    let photoUrl: String
    let isOffline: Bool
    var batteryLevel: Int? = nil
    var isCharging: Bool? = nil
    var locationName: String? = nil
    var isSleeping: Bool? = false
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
            
            // 💤 Premium Zenly-Style Sleeping Animation (Triple Zs rising and fading)
            if isSleeping == true {
                ZStack {
                    ForEach(0..<3) { index in
                        SleepingZView(delay: Double(index) * 0.6)
                    }
                }
                .offset(x: -22, y: -22) // Top-left corner of the avatar circle
            }
            
            // 🏡/💼/🎓 Smart Cozy Anchor Icon Badge
            if let place = locationName, ["Home", "Work", "School"].contains(place) {
                let badgeInfo: (icon: String, colors: [Color]) = {
                    switch place {
                    case "Home": return ("house.fill", [.orange, .yellow])
                    case "Work": return ("briefcase.fill", [.blue, .teal])
                    default: return ("graduationcap.fill", [.green, .mint])
                    }
                }()
                
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: badgeInfo.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 22, height: 22)
                        .shadow(color: badgeInfo.colors[0].opacity(0.6), radius: 4)
                        .overlay(Circle().stroke(Color.white, lineWidth: 1.2))
                    
                    Image(systemName: badgeInfo.icon)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
                .offset(x: 18, y: 18) // Bottom-right corner of the 48pt avatar circle
            }
            
            // 🔋 Glassmorphic Battery Pill floating above the avatar
            if let level = batteryLevel {
                let color: Color = isCharging == true ? .green : (level > 60 ? .green : (level > 20 ? .yellow : .red))
                
                HStack(spacing: 2) {
                    if isCharging == true {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.green)
                            .shadow(color: .green.opacity(0.8), radius: 3)
                    } else {
                        Image(systemName: level > 20 ? "battery.100" : "battery.25")
                            .font(.system(size: 8))
                            .foregroundColor(color)
                    }
                    Text("\(level)%")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundColor(color)
                }
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
                .background(.ultraThinMaterial)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(color.opacity(0.4), lineWidth: 0.5)
                )
                .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
                .offset(y: -28) // Floats perfectly right above the avatar circle
            }
        }
    }
}

struct PartnerOverlayCard: View {
    let user: GlimpseUser
    let locationOverride: String?
    let isMinimal: Bool
    
    private var isMe: Bool {
        user.id == AuthManager.shared.currentUser?.id
    }
    
    private var distanceText: String? {
        guard let currentUser = AuthManager.shared.currentUser,
              currentUser.id != user.id,
              let myLat = currentUser.latitude, myLat != 0.0,
              let myLon = currentUser.longitude, myLon != 0.0,
              let partnerLat = user.latitude, partnerLat != 0.0,
              let partnerLon = user.longitude, partnerLon != 0.0 else {
            return nil
        }
        
        let myLoc = CLLocation(latitude: myLat, longitude: myLon)
        let partnerLoc = CLLocation(latitude: partnerLat, longitude: partnerLon)
        let distanceInMeters = myLoc.distance(from: partnerLoc)
        
        if distanceInMeters < 100 {
            return "Right next to you"
        } else if distanceInMeters < 1000 {
            return String(format: "%.0fm away", distanceInMeters)
        } else {
            let distanceInKm = distanceInMeters / 1000.0
            return String(format: "%.1fkm away", distanceInKm)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !isMinimal {
                // FULL GLASSMORPHIC CONTAINER CARD
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 6) {
                            if user.isOffline {
                                Text("Offline")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.4))
                                
                                Text("•")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.2))
                                
                                Text("Synced \(timeAgo(from: user.lastUpdatedDate))")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.5))
                                
                                if let dist = distanceText {
                                    Text("•")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.2))
                                    
                                    Text(dist)
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundColor(.activeCyan.opacity(0.6))
                                }
                            } else {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 6, height: 6)
                                    Text("Live")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                                
                                if let dist = distanceText {
                                    Text("•")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.3))
                                    
                                    Text(dist)
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundColor(.activeCyan)
                                }
                            }
                        }
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
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
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(1)
                }
                .padding(.top, 4)
                
                if !isMe, let note = user.status_note, !note.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "quote.bubble.fill")
                            .foregroundColor(.electricPurple)
                            .font(.system(size: 14))
                        
                        Text(note)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(2)
                    }
                }
            } else {
                // MINIMAL MODE FOR PHOTO (cuma waktu 2m ago sama lokasi sama note)
                VStack(alignment: .leading, spacing: 2) {
                    Text(timeAgo(from: user.lastUpdatedDate))
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(user.location_name ?? (locationOverride ?? "Somewhere unknown..."))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    
                    if !isMe, let note = user.status_note, !note.isEmpty {
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
        let interval = Date().timeIntervalSince(date)
        if interval < 60 {
            return "Just now"
        }
        let minutes = Int(interval / 60)
        if minutes < 60 {
            return "\(minutes)m ago"
        }
        let hours = minutes / 60
        if hours < 24 {
            return "\(hours)h ago"
        }
        let days = hours / 24
        return "\(days)d ago"
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
    
    private func localCachesDirectoryURL(for urlStr: String) -> URL? {
        let cleanName = urlStr.components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
        let filename = "img_cache_\(cleanName).jpg"
        if let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            return cachesURL.appendingPathComponent(filename)
        }
        return nil
    }
    
    private func cacheFileURL(for urlStr: String) -> URL? {
        let cleanName = urlStr.components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
        let filename = "img_cache_\(cleanName).jpg"
        
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.glimpse.app") {
            return groupURL.appendingPathComponent(filename)
        }
        
        // Fallback to standard caches directory if App Group is not configured in Xcode
        if let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            return cachesURL.appendingPathComponent(filename)
        }
        
        return nil
    }
    
    private func loadImage() async {
        let finalUrlStr = formattedUrl()
        guard let fileURL = cacheFileURL(for: finalUrlStr) else { return }
        
        // 1. Cek primary Cache file
        if let data = try? Data(contentsOf: fileURL), let cached = UIImage(data: data) {
            await MainActor.run {
                self.uiImage = cached
            }
            return
        }
        
        // 2. Cek local fallback Cache file
        if let fallbackURL = localCachesDirectoryURL(for: finalUrlStr),
           let data = try? Data(contentsOf: fallbackURL),
           let cached = UIImage(data: data) {
            await MainActor.run {
                self.uiImage = cached
            }
            return
        }
        
        // 3. Fetch jika belum ada di cache
        guard let url = URL(string: finalUrlStr) else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let fetched = UIImage(data: data) {
                // Simpan ke primary App Group file cache
                do {
                    try data.write(to: fileURL)
                } catch {
                    // Simpan ke local fallback cache jika primary gagal
                    if let fallbackURL = localCachesDirectoryURL(for: finalUrlStr) {
                        try? data.write(to: fallbackURL)
                    }
                }
                
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

import SwiftUI
import MapKit
import Combine

struct PartnerMapView: View {
    @AppStorage("glimpse_default_map_style", store: UserDefaults(suiteName: "group.glimpse.app")) var defaultMapStyle = "satellite"
    let user: GlimpseUser
    @State private var position: MapCameraPosition
    @State private var isShowingPhoto = true
    @State private var localAddress: String? = nil
    @State private var auth = AuthManager.shared
    @State private var lastGeocodedCoordinate: CLLocationCoordinate2D? = nil
    @State private var lastGeocodeDate: Date? = nil

    @State private var wavePhase = 0.0
    
    @State private var animatedPartnerLatitude: Double = 0.0
    @State private var animatedPartnerLongitude: Double = 0.0
    @State private var previousUpdateDate: Date? = nil
    @State private var interpolationTask: Task<Void, Never>? = nil
    @State private var partnerCoordinateQueue: [CLLocationCoordinate2D] = []
    @State private var isInterpolating = false
    
    private var animatedPartnerCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: animatedPartnerLatitude != 0.0 ? animatedPartnerLatitude : (user.latitude ?? 0.0),
            longitude: animatedPartnerLongitude != 0.0 ? animatedPartnerLongitude : (user.longitude ?? 0.0)
        )
    }
    
    @State private var selectedFlashIndex = 0
    @State private var mapUpdateTask: Task<Void, Never>? = nil
    
    private var partnerFlashes: [GlimpseFlash] {
        auth.flashes.filter { $0.sender_id == user.id }
            .sorted(by: { $0.createdDate > $1.createdDate })
    }
    
    private var displayFlashes: [GlimpseFlash] {
        let list = partnerFlashes
        if list.isEmpty, let photoUrl = user.latest_photo_url, !photoUrl.isEmpty {
            return [
                GlimpseFlash(
                    id: -1,
                    sender_id: user.id,
                    sender_name: user.name,
                    photo_url: photoUrl,
                    latitude: user.latest_photo_latitude ?? user.latitude,
                    longitude: user.latest_photo_longitude ?? user.longitude,
                    location_name: user.latest_photo_location_name ?? user.location_name,
                    status_note: user.latest_photo_status_note ?? user.status_note,
                    battery_level: user.latest_photo_battery_level ?? user.battery_level,
                    created_at: user.latest_photo_created_at ?? user.last_updated ?? ""
                )
            ]
        }
        return list
    }
    
    private var selectedUser: GlimpseUser {
        if !displayFlashes.isEmpty && selectedFlashIndex < displayFlashes.count {
            let flash = displayFlashes[selectedFlashIndex]
            var tempUser = user
            tempUser.latest_photo_url = flash.photo_url
            tempUser.latest_photo_latitude = flash.latitude
            tempUser.latest_photo_longitude = flash.longitude
            tempUser.latest_photo_location_name = flash.location_name
            tempUser.latest_photo_status_note = flash.status_note
            tempUser.latest_photo_battery_level = flash.battery_level
            tempUser.latest_photo_created_at = flash.created_at
            return tempUser
        }
        return user
    }
    
    private var targetCoordinate: CLLocationCoordinate2D {
        let activeUser = selectedUser
        if let photoUrl = activeUser.latest_photo_url, !photoUrl.isEmpty,
           let flashLat = activeUser.latest_photo_latitude, let flashLon = activeUser.latest_photo_longitude,
           flashLat != 0.0, flashLon != 0.0 {
            return CLLocationCoordinate2D(latitude: flashLat, longitude: flashLon)
        }
        return animatedPartnerCoordinate
    }
    
    // Auto-rotation timer every 10 seconds
    private let autoRotateTimer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
    
    // Dead reckoning: check every 1 second if extrapolation is needed
    private let deadReckoningTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
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
                    if !displayFlashes.isEmpty {
                        TabView(selection: $selectedFlashIndex) {
                            ForEach(Array(displayFlashes.enumerated()), id: \.element.id) { index, flash in
                                CachedImageView(urlString: formatImageUrlString(flash.photo_url))
                                    .tag(index)
                                    .onTapGesture {
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                        withAnimation(.easeInOut(duration: 0.5)) {
                                            isShowingPhoto.toggle()
                                        }
                                    }
                            }
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                        .onChange(of: selectedFlashIndex) {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            
                            mapUpdateTask?.cancel()
                            mapUpdateTask = Task {
                                try? await Task.sleep(nanoseconds: 150_000_000) // 150ms delay
                                guard !Task.isCancelled else { return }
                                
                                await MainActor.run {
                                    updateLocalAddress()
                                    updateMapPosition()
                                }
                            }
                        }
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
                            .onTapGesture {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    isShowingPhoto.toggle()
                                }
                            }
                    }
                    
                    // Minimal mode card overlay fades inside the Photo container
                    PartnerOverlayCard(user: selectedUser, locationOverride: localAddress, isMinimal: true)
                        .padding(12)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        // Ignore gestures on overlay card to allow swipe gestures underneath
                        .allowsHitTesting(false)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity)
            } else {
                // MAP SIDE
                ZStack {
                    Map(position: $position, interactionModes: []) {
                        if auth.isTogether, let currentUser = auth.currentUser,
                           let userLat = selectedUser.latitude, userLat != 0.0,
                           let myLat = currentUser.latitude, myLat != 0.0 {
                            Annotation("Together", coordinate: targetCoordinate) {
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(colors: [.electricPurple.opacity(0.3), .activeCyan.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 90, height: 90)
                                        .scaleEffect(1.05)
                                        .blur(radius: 8)
                                    
                                    HStack(spacing: -8) {
                                        CachedImageView(urlString: currentUser.profile_photo_url)
                                            .frame(width: 38, height: 38)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color.electricPurple, lineWidth: 1.5))
                                            .shadow(color: .electricPurple.opacity(0.5), radius: 5)
                                        
                                        Image(systemName: "heart.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.red)
                                            .scaleEffect(1.0)
                                            .shadow(color: .red, radius: 4)
                                            .zIndex(5)
                                        
                                        CachedImageView(urlString: selectedUser.profile_photo_url)
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
                                            center: targetCoordinate,
                                            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                                        ))
                                    }
                                }
                                .id("together_marker")
                            }
                        } else {
                            // Wavy Connecting line
                            if let currentUser = auth.currentUser,
                               let userLat = selectedUser.latitude, userLat != 0.0,
                               let myLat = currentUser.latitude, myLat != 0.0 {
                                let startLoc = CLLocation(latitude: currentUser.coordinate.latitude, longitude: currentUser.coordinate.longitude)
                                let endLoc = CLLocation(latitude: targetCoordinate.latitude, longitude: targetCoordinate.longitude)
                                let distanceInKm = startLoc.distance(from: endLoc) / 1000.0
                                
                                let colors = getShiftingColors(phase: wavePhase, distanceInKm: distanceInKm)
                                
                                if isInterpolating {
                                    // STRAIGHT LINE when moving - super light, 0% CPU calculations!
                                    let lineCoords = [currentUser.coordinate, targetCoordinate]
                                    
                                    MapPolyline(coordinates: lineCoords)
                                        .stroke(
                                            LinearGradient(colors: colors.map { $0.opacity(0.4) }, startPoint: .leading, endPoint: .trailing),
                                            style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round)
                                        )
                                    
                                    MapPolyline(coordinates: lineCoords)
                                        .stroke(
                                            LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing),
                                            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                                        )
                                } else {
                                    // WAVY LINE when static - beautiful dynamic shape!
                                    let wavyCoords = generateWavyCoordinates(from: currentUser.coordinate, to: targetCoordinate, phase: wavePhase)
                                    
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
                            }
                            
                            if let currentUser = auth.currentUser, let myLat = currentUser.latitude, myLat != 0.0 {
                                Annotation("Me", coordinate: currentUser.coordinate) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.electricPurple.opacity(0.2))
                                            .frame(width: 60, height: 60)
                                            .blur(radius: 10)
                                        
                                        PartnerMarker(photoUrl: currentUser.profile_photo_url, isOffline: false, batteryLevel: currentUser.battery_level, isCharging: currentUser.is_charging, locationName: currentUser.location_name, isSleeping: currentUser.is_sleeping, speed: auth.myAverageSpeedKmH)
                                    }
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                                            position = .region(MKCoordinateRegion(
                                                center: currentUser.coordinate,
                                                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                                            ))
                                        }
                                    }
                                    .id("me_marker")
                                }
                            }
                            
                            if let userLat = selectedUser.latitude, userLat != 0.0 {
                                Annotation(selectedUser.name, coordinate: targetCoordinate) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.activeCyan.opacity(0.3))
                                            .frame(width: 80, height: 80)
                                            .blur(radius: 20)
                                        
                                        PartnerMarker(
                                            photoUrl: selectedUser.profile_photo_url,
                                            isOffline: selectedUser.latest_photo_url != nil ? false : selectedUser.isOffline,
                                            batteryLevel: selectedUser.latest_photo_url != nil ? (selectedUser.latest_photo_battery_level ?? selectedUser.battery_level) : selectedUser.battery_level,
                                            isCharging: selectedUser.latest_photo_url != nil ? false : (selectedUser.is_charging ?? false),
                                            locationName: selectedUser.latest_photo_url != nil ? (selectedUser.latest_photo_location_name ?? selectedUser.location_name) : selectedUser.location_name,
                                            isSleeping: selectedUser.latest_photo_url != nil ? false : (selectedUser.is_sleeping ?? false),
                                            speed: selectedUser.latest_photo_url != nil ? 0.0 : auth.partnerAverageSpeedKmH
                                        )
                                    }
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                                            position = .region(MKCoordinateRegion(
                                                center: targetCoordinate,
                                                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                                            ))
                                        }
                                    }
                                    .id("partner_marker")
                                }
                            }
                        }
                    }
                    .mapStyle(defaultMapStyle == "satellite" ? .hybrid(elevation: .realistic) : .standard(emphasis: .muted))
                    .onTapGesture {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        withAnimation(.easeInOut(duration: 0.5)) {
                            isShowingPhoto.toggle()
                        }
                    }
                    .onChange(of: selectedUser.latitude) {
                        updateMapPosition()
                    }
                    .onChange(of: selectedUser.last_updated) {
                        updateMapPosition()
                    }
                    
                    // Full mode card overlay fades inside the Map container
                    PartnerOverlayCard(user: selectedUser, locationOverride: localAddress, isMinimal: false)
                        .padding(12)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .allowsHitTesting(false)
                }
                .transition(.opacity)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
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
            selectedFlashIndex = 0
            updateLocalAddress()
            updateMapPosition()
            if let lat = user.latitude, let lon = user.longitude, lat != 0.0, lon != 0.0 {
                animatedPartnerLatitude = lat
                animatedPartnerLongitude = lon
            }
        }
        .onChange(of: user.latest_photo_url) {
            selectedFlashIndex = 0
            updateLocalAddress()
            updateMapPosition()
        }
        .onChange(of: auth.dashboardRefreshTrigger) {
            selectedFlashIndex = 0
            updateLocalAddress()
            updateMapPosition()
        }
        .onChange(of: user.latitude) {
            updateLocalAddress()
            updateMapPosition()
            if let lat = user.latitude, let lon = user.longitude, lat != 0.0, lon != 0.0 {
                let newCoord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                partnerCoordinateQueue.append(newCoord)
                
                if !isInterpolating {
                    startQueueInterpolator()
                }
            }
        }
        .onReceive(deadReckoningTimer) { _ in
            // extrapolateDeadReckoning() // Disabled predictive movement
        }
    }
    
    private func extrapolateDeadReckoning() {
        // Disabled predictive movement
    }
    
    private func startQueueInterpolator() {
        isInterpolating = true
        interpolationTask?.cancel()
        
        interpolationTask = Task {
            while !partnerCoordinateQueue.isEmpty {
                if Task.isCancelled { break }
                
                let target = partnerCoordinateQueue.removeFirst()
                let startLat = animatedPartnerLatitude == 0.0 ? target.latitude : animatedPartnerLatitude
                let startLon = animatedPartnerLongitude == 0.0 ? target.longitude : animatedPartnerLongitude
                
                let startLoc = CLLocation(latitude: startLat, longitude: startLon)
                let targetLoc = CLLocation(latitude: target.latitude, longitude: target.longitude)
                let distance = targetLoc.distance(from: startLoc)
                
                // Segments will take 1.2s if we have a backlog of coordinates, and 2.5s (3-second buffer lag) under normal flow
                let duration: TimeInterval = partnerCoordinateQueue.count > 1 ? 1.2 : 2.5
                
                let speedMps = distance / duration
                let speedKmH = speedMps * 3.6
                
                await MainActor.run {
                    if speedKmH >= 1.0 {
                        auth.updatePartnerSpeed(speedKmH)
                    } else {
                        auth.updatePartnerSpeed(nil)
                    }
                }
                
                let fps: Double = 60.0
                let stepInterval = 1.0 / fps
                let startTime = Date()
                
                while true {
                    if Task.isCancelled { break }
                    let elapsed = Date().timeIntervalSince(startTime)
                    let progress = min(1.0, elapsed / duration)
                    
                    // Smoothstep easing
                    let t = progress * progress * (3.0 - 2.0 * progress)
                    
                    let currentLat = startLat + (target.latitude - startLat) * t
                    let currentLon = startLon + (target.longitude - startLon) * t
                    
                    await MainActor.run {
                        animatedPartnerLatitude = currentLat
                        animatedPartnerLongitude = currentLon
                    }
                    
                    if progress >= 1.0 { break }
                    try? await Task.sleep(nanoseconds: UInt64(stepInterval * 1_000_000_000))
                }
            }
            await MainActor.run {
                auth.updatePartnerSpeed(nil)
            }
            isInterpolating = false
        }
    }
    
    private func updateMapPosition() {
        let centerCoord = targetCoordinate
        if centerCoord.latitude != 0.0, centerCoord.longitude != 0.0 {
            withAnimation(.easeInOut(duration: 1.0)) {
                position = .region(MKCoordinateRegion(
                    center: centerCoord,
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
        if let photoUrl = user.latest_photo_url, !photoUrl.isEmpty {
            if let flashAddress = user.latest_photo_location_name, !flashAddress.isEmpty {
                self.localAddress = flashAddress
                return
            }
        } else if let serverAddress = user.location_name, !serverAddress.isEmpty {
            self.localAddress = serverAddress
            return
        }
        
        let coord = targetCoordinate
        guard coord.latitude != 0.0, coord.longitude != 0.0 else { return }
        
        let isMoving = (auth.partnerAverageSpeedKmH ?? 0.0) > 3.0
        
        if let lastCoord = lastGeocodedCoordinate, let lastDate = lastGeocodeDate {
            let lastLoc = CLLocation(latitude: lastCoord.latitude, longitude: lastCoord.longitude)
            let currentLoc = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
            let distance = currentLoc.distance(from: lastLoc)
            let timeElapsed = Date().timeIntervalSince(lastDate)
            
            if isMoving {
                if distance < 150.0 || timeElapsed < 15.0 {
                    return
                }
            } else {
                if distance < 15.0 {
                    return
                }
            }
        }
        
        self.lastGeocodedCoordinate = coord
        self.lastGeocodeDate = Date()
        
        Task {
            let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
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
    var speed: Double? = nil

    @State private var zzzPhase1: Double = 0
    @State private var zzzPhase2: Double = 0
    @State private var zzzPhase3: Double = 0
    @State private var pulsePhase: Double = 0
    
    var body: some View {
        let isPanic = (batteryLevel ?? 100) <= 10 && (isCharging != true)
        
        ZStack {
            if !isOffline {
                // Orbit Ring (Red pulse if panic, Normal gradient otherwise)
                Circle()
                    .stroke(
                        isPanic ? AngularGradient(colors: [.red, .black, .red], center: .center) : AngularGradient(colors: [.electricPurple, .activeCyan, .electricPurple], center: .center),
                        lineWidth: isPanic ? 3 : 2
                    )
                    .frame(width: 58, height: 58)
                    .scaleEffect(isPanic ? 1.0 + (pulsePhase * 0.15) : 1.0)
                    .opacity(isPanic ? 1.0 - (pulsePhase * 0.5) : 0.8)
            }
            
            CachedImageView(urlString: photoUrl)
                .frame(width: 48, height: 48)
                .clipShape(Circle())
                .overlay(Circle().stroke(isOffline ? Color.gray : (isPanic ? Color.red : .white.opacity(0.8)), lineWidth: 1.5))
                .shadow(color: isOffline ? .clear : (isPanic ? .red.opacity(0.6) : .electricPurple.opacity(0.4)), radius: 8)
                .saturation(isOffline ? 0.2 : 1.0)
            
            // 🚨 Battery Panic Badge
            if isPanic {
                Text("🪫")
                    .font(.system(size: 14))
                    .offset(x: 20, y: 20)
                    .shadow(color: .red, radius: 4)
            }
            
            // 💤 Animated Sleeping Badge
            if isSleeping == true {
                ZStack {
                    Text("z")
                        .font(.system(size: 10, weight: .bold))
                        .offset(x: -18 - (zzzPhase1 * 4), y: -18 - (zzzPhase1 * 12))
                        .opacity(1.0 - zzzPhase1)
                        
                    Text("Z")
                        .font(.system(size: 14, weight: .bold))
                        .offset(x: -15 + (zzzPhase2 * 3), y: -22 - (zzzPhase2 * 18))
                        .opacity(1.0 - zzzPhase2)
                        
                    Text("Z")
                        .font(.system(size: 18, weight: .bold))
                        .offset(x: -22 - (zzzPhase3 * 2), y: -26 - (zzzPhase3 * 24))
                        .opacity(1.0 - zzzPhase3)
                }
                .shadow(color: .black.opacity(0.5), radius: 2)
                .onAppear {
                    zzzPhase1 = 0
                    zzzPhase2 = 0
                    zzzPhase3 = 0
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        zzzPhase1 = 1.0
                    }
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false).delay(0.5)) {
                        zzzPhase2 = 1.0
                    }
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false).delay(1.0)) {
                        zzzPhase3 = 1.0
                    }
                }
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
            
            // ⚡ Speed Pill floating below the avatar (Only when moving >= 0 km/h)
            if let spd = speed, spd >= 0.0 {
                Text(String(format: "%.0f km/h", spd))
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(.ultraThinMaterial)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(.white.opacity(0.3), lineWidth: 0.5)
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                    .offset(y: 28) // Floats perfectly below the avatar circle
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                pulsePhase = 1.0
            }
        }
    }
}

struct PartnerOverlayCard: View {
    let user: GlimpseUser
    let locationOverride: String?
    let isMinimal: Bool
    
    private let auth = AuthManager.shared
    
    private var isMe: Bool {
        user.id == AuthManager.shared.currentUser?.id
    }
    
    private var displayDate: Date {
        if user.latest_photo_url != nil, let created = user.latest_photo_created_at {
            let formatter = ISO8601DateFormatter()
            return formatter.date(from: created) ?? user.lastUpdatedDate
        }
        return user.lastUpdatedDate
    }
    
    private var displayLocationName: String {
        if user.latest_photo_url != nil {
            return user.latest_photo_location_name ?? user.location_name ?? "Somewhere"
        }
        return user.location_name ?? (locationOverride ?? "Somewhere unknown...")
    }
    
    private var displayStatusNote: String? {
        if user.latest_photo_url != nil {
            return user.latest_photo_status_note ?? user.status_note
        }
        return user.status_note
    }
    
    private var displayBatteryLevel: Int {
        if user.latest_photo_url != nil {
            return user.latest_photo_battery_level ?? user.battery_level ?? 0
        }
        return user.battery_level ?? 0
    }
    
    private var displayBatteryCharging: Bool {
        if user.latest_photo_url != nil {
            return false // Capture state has static battery
        }
        return user.is_charging ?? false
    }
    
    private var currentSpeed: Double? {
        if user.latest_photo_url != nil { return nil }
        if isMe {
            return AuthManager.shared.mySpeedKmH
        } else {
            return AuthManager.shared.partnerSpeedKmH
        }
    }
    
    private var averageSpeed: Double? {
        if user.latest_photo_url != nil { return nil }
        if isMe {
            return AuthManager.shared.myAverageSpeedKmH
        } else {
            return AuthManager.shared.partnerAverageSpeedKmH
        }
    }
    
    private var distanceText: String? {
        guard let currentUser = AuthManager.shared.currentUser,
              currentUser.id != user.id,
              let myLat = currentUser.latitude, myLat != 0.0,
              let myLon = currentUser.longitude, myLon != 0.0 else {
            return nil
        }
        
        let targetLat: Double
        let targetLon: Double
        if user.latest_photo_url != nil,
           let flashLat = user.latest_photo_latitude, let flashLon = user.latest_photo_longitude,
           flashLat != 0.0, flashLon != 0.0 {
            targetLat = flashLat
            targetLon = flashLon
        } else if let liveLat = user.latitude, let liveLon = user.longitude, liveLat != 0.0, liveLon != 0.0 {
            targetLat = liveLat
            targetLon = liveLon
        } else {
            return nil
        }
        
        let myLoc = CLLocation(latitude: myLat, longitude: myLon)
        let partnerLoc = CLLocation(latitude: targetLat, longitude: targetLon)
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
                        HStack(alignment: .center, spacing: 8) {
                            Text(isMe ? "Me" : user.name)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            
                            if let speed = averageSpeed {
                                HStack(spacing: 3) {
                                    let mode = isMe ? auth.myActivityMode : auth.partnerActivityMode
                                    let icon: String = {
                                        switch mode {
                                        case .car: return "car.fill"
                                        case .cycling: return "bicycle"
                                        case .walking: return "figure.walk"
                                        default: return "figure.walk"
                                        }
                                    }()
                                    Image(systemName: icon)
                                        .font(.system(size: 10, weight: .semibold))
                                    Text(String(format: "%.0f km/h", speed))
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.15))
                                )
                                .foregroundColor(.white)
                                .shadow(radius: 2)
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        
                        HStack(spacing: 6) {
                            if user.isOffline && user.latest_photo_url == nil {
                                Text(user.location_name == "Logged out" ? "Logged out" : "Offline")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.4))
                                
                                Text("•")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.2))
                                
                                Text("Synced \(timeAgo(from: displayDate))")
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
                            } else if user.latest_photo_url != nil {
                                HStack(spacing: 4) {
                                    Image(systemName: "camera.shutter.button.fill")
                                        .font(.system(size: 8))
                                        .foregroundColor(.activeCyan)
                                    Text("Flash Captured")
                                        .font(.caption.bold())
                                        .foregroundColor(.activeCyan)
                                }
                                
                                Text("•")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.2))
                                
                                Text(timeAgo(from: displayDate))
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.5))
                                
                                if let dist = distanceText {
                                    Text("•")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.2))
                                    
                                    Text(dist)
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundColor(.activeCyan.opacity(0.8))
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
                    
                    BatteryIndicator(level: displayBatteryLevel, isCharging: displayBatteryCharging)
                }
                
                HStack(spacing: 8) {
                    Image(systemName: user.location_name == "Logged out" ? "door.right.hand.open" : "mappin.and.ellipse")
                        .foregroundColor(user.location_name == "Logged out" ? .red : .activeCyan)
                        .font(.system(size: 14))
                    
                    Text(displayLocationName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(1)
                }
                .padding(.top, 4)
                
                if !isMe, let note = displayStatusNote, !note.isEmpty {
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
                    Text(timeAgo(from: displayDate))
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(displayLocationName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    
                    if !isMe, let note = displayStatusNote, !note.isEmpty {
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

class ImageCacheManager {
    static let shared = ImageCacheManager()
    private var memoryCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 30 // Keep max 30 images in RAM
        cache.totalCostLimit = 100 * 1024 * 1024 // Keep max 100 MB in RAM
        return cache
    }()
    
    func getImage(for urlString: String) -> UIImage? {
        return memoryCache.object(forKey: urlString as NSString)
    }
    
    func saveImage(_ image: UIImage, for urlString: String) {
        // Calculate raw pixel data memory cost: width * height * 4 bytes per pixel
        let cost = Int(image.size.width * image.size.height * 4)
        memoryCache.setObject(image, forKey: urlString as NSString, cost: cost)
    }
}

struct CachedImageView: View {
    let urlString: String
    @State private var uiImage: UIImage? = nil
    @State private var isImageDeleted: Bool = false
    
    var body: some View {
        Group {
            if urlString.isEmpty {
                ZStack {
                    Color.gray.opacity(0.12)
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.white.opacity(0.25))
                        .padding(8)
                }
            } else if isImageDeleted {
                Color.black.opacity(0.85)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "photo.badge.arrow.down.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white.opacity(0.3))
                            Text("Photo Expired")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.5))
                            Text("Flashes are auto-deleted after 24 hours.")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.3))
                        }
                    )
            } else if let uiImage = uiImage {
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
        guard !urlString.isEmpty else { return }
        let finalUrlStr = formattedUrl()
        
        // 0. Cek In-Memory Cache
        if let cached = ImageCacheManager.shared.getImage(for: finalUrlStr) {
            await MainActor.run {
                self.uiImage = cached
                self.isImageDeleted = false
            }
            return
        }
        
        guard let fileURL = cacheFileURL(for: finalUrlStr) else { return }
        
        // 1. Cek primary Cache file
        if let data = try? Data(contentsOf: fileURL), let cached = UIImage(data: data) {
            ImageCacheManager.shared.saveImage(cached, for: finalUrlStr)
            await MainActor.run {
                self.uiImage = cached
                self.isImageDeleted = false
            }
            return
        }
        
        // 2. Cek local fallback Cache file
        if let fallbackURL = localCachesDirectoryURL(for: finalUrlStr),
           let data = try? Data(contentsOf: fallbackURL),
           let cached = UIImage(data: data) {
            ImageCacheManager.shared.saveImage(cached, for: finalUrlStr)
            await MainActor.run {
                self.uiImage = cached
                self.isImageDeleted = false
            }
            return
        }
        
        // 3. Fetch jika belum ada di cache
        guard let url = URL(string: finalUrlStr) else { return }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 404 {
                    await MainActor.run { self.isImageDeleted = true }
                    return
                }
            }
            
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
                
                ImageCacheManager.shared.saveImage(fetched, for: finalUrlStr)
                await MainActor.run {
                    self.uiImage = fetched
                    self.isImageDeleted = false
                }
            } else {
                await MainActor.run { self.isImageDeleted = true }
            }
        } catch {
            // network/timeout error - don't mark as deleted, just keep loading spinner
        }
    }
}

#Preview {
    PartnerMapView(user: .mockPartner)
        .frame(height: 400)
        .padding()
}

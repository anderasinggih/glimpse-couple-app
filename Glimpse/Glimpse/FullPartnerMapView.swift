import SwiftUI
import MapKit
import Combine

enum MapFocusTarget {
    case me
    case partner
}

struct FullPartnerMapView: View {
    @State private var auth = AuthManager.shared
    @State private var position: MapCameraPosition
    @State private var mapStyle: MapStyle = .standard(emphasis: .muted)
    @State private var isSatellite = true
    @State private var mapPulse = false
    @State private var wavePhase = 0.0
    @State private var recenterTargetMe = true
    @State private var currentCameraCenter: CLLocationCoordinate2D? = nil
    @State private var currentlyFocusedTarget: MapFocusTarget = .partner
    @State private var isFlying = false
    
    // Polling timer for maps: 3.0 seconds
    @State private var timer: Timer.TimerPublisher = Timer.publish(every: 3.0, on: .main, in: .common)
    @State private var timerCancellable: Cancellable?
    
    init(user: GlimpseUser) {
        _position = State(initialValue: .region(MKCoordinateRegion(
            center: user.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )))
        _currentCameraCenter = State(initialValue: user.coordinate)
        _currentlyFocusedTarget = State(initialValue: .partner)
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            if !auth.isInitialStateLoaded {
                // PRESTIGE LOADING / SHIMMERING STATE
                VStack(spacing: 20) {
                    ProgressView()
                        .tint(.electricPurple)
                        .scaleEffect(1.3)
                    Text("Loading map space...")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.deepVelvet)
            } else if let partner = auth.partner {
                // Full Screen Map with Pulsing Partner Marker
                Map(position: $position) {
                    // 👣 Neon Footprints Trail for Partner (Zenly-Style)
                    if let partnerHistory = partner.location_history, partnerHistory.count >= 2 {
                        let coords = partnerHistory.map { $0.coordinate }
                        
                        // 1. Neon Glow Layer
                        MapPolyline(coordinates: coords)
                            .stroke(
                                Color.activeCyan.opacity(0.35),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round)
                            )
                        
                        // 2. Core Saturated Neon Layer
                        MapPolyline(coordinates: coords)
                            .stroke(
                                Color.activeCyan,
                                style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                            )
                    }
                    
                    // 👣 Neon Footprints Trail for Me (Zenly-Style)
                    if let myUser = auth.currentUser,
                       let myHistory = myUser.location_history, myHistory.count >= 2 {
                        let coords = myHistory.map { $0.coordinate }
                        
                        // 1. Neon Glow Layer
                        MapPolyline(coordinates: coords)
                            .stroke(
                                Color.electricPurple.opacity(0.35),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round)
                            )
                        
                        // 2. Core Saturated Neon Layer
                        MapPolyline(coordinates: coords)
                            .stroke(
                                Color.electricPurple,
                                style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                            )
                    }

                    if auth.isTogether, let currentUser = auth.currentUser {
                        Annotation("Together", coordinate: partner.coordinate) {
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
                                    
                                    CachedImageView(urlString: partner.profile_photo_url)
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
                                        center: partner.coordinate,
                                        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                                    ))
                                }
                            }
                        }
                    } else {
                        // Wavy Connecting line
                        if let currentUser = auth.currentUser,
                           let partnerLat = partner.latitude, partnerLat != 0.0,
                           let myLat = currentUser.latitude, myLat != 0.0 {
                            
                            let startLoc = CLLocation(latitude: currentUser.coordinate.latitude, longitude: currentUser.coordinate.longitude)
                            let endLoc = CLLocation(latitude: partner.coordinate.latitude, longitude: partner.coordinate.longitude)
                            let distanceInKm = startLoc.distance(from: endLoc) / 1000.0
                            
                            let colors = getShiftingColors(phase: wavePhase, distanceInKm: distanceInKm)
                            let wavyCoords = generateWavyCoordinates(from: currentUser.coordinate, to: partner.coordinate, distanceInKm: distanceInKm, phase: wavePhase)
                            
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
                        
                        if let currentUser = auth.currentUser {
                            Annotation("Me", coordinate: currentUser.coordinate) {
                                ZStack {
                                    Circle()
                                        .fill(Color.electricPurple.opacity(0.2))
                                        .frame(width: 60, height: 60)
                                        .blur(radius: 10)
                                    
                                    PartnerMarker(photoUrl: currentUser.profile_photo_url, isOffline: false, batteryLevel: currentUser.battery_level, isCharging: currentUser.is_charging, locationName: currentUser.location_name)
                                }
                                .onTapGesture {
                                    currentlyFocusedTarget = .me
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                                        position = .region(MKCoordinateRegion(
                                            center: currentUser.coordinate,
                                            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                                        ))
                                    }
                                }
                            }
                        }
                        
                        Annotation(partner.name, coordinate: partner.coordinate) {
                            ZStack {
                                Circle()
                                    .fill(Color.activeCyan.opacity(0.2))
                                    .frame(width: 60, height: 60)
                                    .blur(radius: 10)
                                
                                PartnerMarker(photoUrl: partner.profile_photo_url, isOffline: partner.isOffline, batteryLevel: partner.battery_level, isCharging: partner.is_charging, locationName: partner.location_name)
                            }
                            .onTapGesture {
                                currentlyFocusedTarget = .partner
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                                    position = .region(MKCoordinateRegion(
                                        center: partner.coordinate,
                                        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                                    ))
                                }
                            }
                        }
                    }
                }
                .mapStyle(isSatellite ? .hybrid(elevation: .realistic) : .standard(emphasis: .muted))
                .mapControls {
                    MapCompass()
                    MapScaleView()
                }
                .ignoresSafeArea()
                .onMapCameraChange(frequency: .onEnd) { context in
                    guard !isFlying else { return } // Ignore updates during cinematic flight transitions!
                    
                    currentCameraCenter = context.camera.centerCoordinate
                    
                    guard let currentUser = auth.currentUser else { return }
                    let centerLoc = CLLocation(latitude: context.camera.centerCoordinate.latitude, longitude: context.camera.centerCoordinate.longitude)
                    let myLoc = CLLocation(latitude: currentUser.coordinate.latitude, longitude: currentUser.coordinate.longitude)
                    let partnerLoc = CLLocation(latitude: partner.coordinate.latitude, longitude: partner.coordinate.longitude)
                    
                    if centerLoc.distance(from: myLoc) < centerLoc.distance(from: partnerLoc) {
                        currentlyFocusedTarget = .me
                    } else {
                        currentlyFocusedTarget = .partner
                    }
                }
                // Automatically move map camera smoothly when partner's live coordinates change
                .onChange(of: partner.last_updated) { _, _ in
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        position = .region(MKCoordinateRegion(
                            center: partner.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                        ))
                    }
                }
                
                // Overlay HUD
                VStack(spacing: 0) {
                    Spacer(minLength: 50) // Space under master header
                    
                    Spacer()
                    
                    // Map Controls (Satellite + Re-Center Scope) on the right
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            // Satellite toggle
                            Button {
                                withAnimation(.spring()) {
                                    isSatellite.toggle()
                                }
                            } label: {
                                Image(systemName: isSatellite ? "map.fill" : "globe.americas.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 46, height: 46)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 0.5))
                            }
                            
                            // Re-center Scope
                            // Re-center Scope
                            Button {
                                guard !isFlying else { return }
                                guard let currentUser = auth.currentUser else { return }
                                
                                let myCoord = currentUser.coordinate
                                let partnerCoord = partner.coordinate
                                
                                isFlying = true
                                
                                let targetCoord: CLLocationCoordinate2D
                                let startCoord: CLLocationCoordinate2D
                                let nextTarget: MapFocusTarget
                                
                                if currentlyFocusedTarget == .me {
                                    targetCoord = partnerCoord
                                    startCoord = myCoord
                                    nextTarget = .partner
                                } else {
                                    targetCoord = myCoord
                                    startCoord = partnerCoord
                                    nextTarget = .me
                                }
                                
                                triggerCinematicFlight(from: startCoord, to: targetCoord, targetFocus: nextTarget)
                            } label: {
                                Image(systemName: "scope")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 46, height: 46)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 0.5))
                            }
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, 12)
                    }
                    
                    // Bottom Info Card (Observing dynamically either Me or Partner based on active focus)
                    Group {
                        if let currentUser = auth.currentUser, currentlyFocusedTarget == .me {
                            PartnerOverlayCard(user: currentUser, locationOverride: nil, isMinimal: false)
                                .id("me_card")
                        } else {
                            PartnerOverlayCard(user: partner, locationOverride: nil, isMinimal: false)
                                .id("partner_card")
                        }
                    }
                    .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity))
                    .animation(.spring(response: 0.45, dampingFraction: 0.8), value: currentlyFocusedTarget)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                    .shadow(color: Color.black.opacity(0.25), radius: 10, y: 5)
                }
            } else {
                // Not Connected / No Partner View (Beautiful, minimalist box-less state)
                VStack(spacing: 16) {
                    Image(systemName: "map")
                        .font(.system(size: 56, weight: .light))
                        .foregroundColor(.white.opacity(0.35))
                        .shadow(color: .electricPurple.opacity(0.15), radius: 8)
                    
                    VStack(spacing: 8) {
                        Text("No Location Sharing")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Connect with your partner first to share and see live coordinates on the map!")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.deepVelvet)
            }
        }
        .onAppear {
            startPolling()
            triggerImmediateSync()
            withAnimation(.linear(duration: 4.5).repeatForever(autoreverses: false)) {
                wavePhase = 2 * .pi
            }
        }
        .onDisappear {
            stopPolling()
        }
        // Map Live Updates (every 3 seconds for instant real-time synchronization!)
        .onReceive(timer) { _ in
            Task {
                try? await auth.fetchState()
            }
        }
    }
    
    private func startPolling() {
        timer = Timer.publish(every: 3.0, on: .main, in: .common)
        timerCancellable = timer.connect()
    }
    
    private func stopPolling() {
        timerCancellable?.cancel()
    }
    
    private func triggerImmediateSync() {
        Task {
            try? await auth.fetchState()
            if let partner = auth.partner {
                await MainActor.run {
                    withAnimation(.spring()) {
                        position = .region(MKCoordinateRegion(
                            center: partner.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                        ))
                    }
                }
            }
        }
    }
    
    private func triggerCinematicFlight(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, targetFocus: MapFocusTarget) {
        let startLoc = CLLocation(latitude: start.latitude, longitude: start.longitude)
        let endLoc = CLLocation(latitude: end.latitude, longitude: end.longitude)
        let distance = startLoc.distance(from: endLoc)
        
        let dLat = end.latitude - start.latitude
        let dLon = end.longitude - start.longitude
        
        // Calculate perpendicular offset for curved arc midpoint
        let pLat = -dLon
        let pLon = dLat
        let arcStrength = 0.2
        let midLat = (start.latitude + end.latitude) / 2.0 + pLat * arcStrength
        let midLon = (start.longitude + end.longitude) / 2.0 + pLon * arcStrength
        let midpoint = CLLocationCoordinate2D(latitude: midLat, longitude: midLon)
        
        // Update bottom overlay info card instantly at start for zero latency!
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            currentlyFocusedTarget = targetFocus
        }
        
        Task {
            // --- STAGE 1: SMOOTH 3D ARC TO MIDPOINT (UPWARD GLIDE) ---
            // Swoop up to midpoint with a beautiful 3D tilt and rotating angle
            let targetZoom = min(1_500_000.0, max(4500.0, distance * 1.7))
            
            await MainActor.run {
                withAnimation(.spring(response: 1.5, dampingFraction: 0.82)) {
                    position = .camera(MapCamera(
                        centerCoordinate: midpoint,
                        distance: targetZoom,
                        heading: 25.0, // Swoop rotation
                        pitch: 28.0 // 3D Tilt perspective
                    ))
                }
            }
            
            // Allow tiles to load and map to glide gracefully (1.0 seconds)
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            // --- STAGE 2: CUSHIONED LANDING ON TARGET ---
            // Settle smoothly on the destination coordinate, flattening back out
            await MainActor.run {
                withAnimation(.spring(response: 1.6, dampingFraction: 0.86)) {
                    position = .camera(MapCamera(
                        centerCoordinate: end,
                        distance: 500.0,
                        heading: 0.0,
                        pitch: 0.0
                    ))
                }
            }
            
            // Wait for landing to fully settle before releasing flight lock (1.5 seconds)
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            
            await MainActor.run {
                isFlying = false
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
        distanceInKm: Double,
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
        let waveFrequency: Double = {
            if distanceInKm <= 1.0 {
                return 5.0
            } else if distanceInKm >= 10.0 {
                return 2.0
            } else {
                return 3.5
            }
        }()
        
        let amplitude = distance * 0.05
        
        for i in 0...pointsCount {
            let t = Double(i) / Double(pointsCount)
            let linearLat = start.latitude + dLat * t
            let linearLon = start.longitude + dLon * t
            
            let envelope = sin(t * Double.pi)
            // Ripple wave based on phase offset to physically animate the movement!
            let wave = sin(t * Double.pi * waveFrequency - phase) * amplitude * envelope
            
            let waveLat = linearLat + pLat * wave
            let waveLon = linearLon + pLon * wave
            
            coordinates.append(CLLocationCoordinate2D(latitude: waveLat, longitude: waveLon))
        }
        
        return coordinates
    }
}

extension GlimpseUser: Equatable {
    public static func == (lhs: GlimpseUser, rhs: GlimpseUser) -> Bool {
        return lhs.id == rhs.id &&
            lhs.latitude == rhs.latitude &&
            lhs.longitude == rhs.longitude &&
            lhs.battery_level == rhs.battery_level &&
            lhs.is_charging == rhs.is_charging &&
            lhs.location_name == rhs.location_name &&
            lhs.status_note == rhs.status_note &&
            lhs.last_updated == rhs.last_updated
    }
}

import SwiftUI
import MapKit
import Combine

struct FullPartnerMapView: View {
    @State private var auth = AuthManager.shared
    @State private var position: MapCameraPosition
    @State private var mapStyle: MapStyle = .standard(emphasis: .muted)
    @State private var isSatellite = true
    @State private var mapPulse = false
    @State private var wavePhase = 0.0
    @State private var recenterTargetMe = false
    
    // Polling timer for maps: 3.0 seconds
    @State private var timer: Timer.TimerPublisher = Timer.publish(every: 3.0, on: .main, in: .common)
    @State private var timerCancellable: Cancellable?
    
    init(user: GlimpseUser) {
        _position = State(initialValue: .region(MKCoordinateRegion(
            center: user.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )))
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
                            
                            // Concept A Color Spectrum
                            let colors: [Color] = {
                                if distanceInKm <= 1.0 {
                                    // DEKAT: Rose Pink & Crimson Red (warm passion)
                                    return [Color(red: 1.0, green: 0.2, blue: 0.5), Color(red: 1.0, green: 0.1, blue: 0.3)]
                                } else if distanceInKm >= 10.0 {
                                    // JAUH: Neon Cyan & Electric Blue (steady aurora connection)
                                    return [Color.activeCyan, Color(red: 0.0, green: 0.6, blue: 1.0)]
                                } else {
                                    // SEDANG: Electric Purple, Magenta & Rose gradient
                                    return [Color.electricPurple, Color(red: 0.9, green: 0.2, blue: 0.8), Color(red: 1.0, green: 0.2, blue: 0.5)]
                                }
                            }()
                            
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
                                    
                                    PartnerMarker(photoUrl: currentUser.profile_photo_url, isOffline: false)
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
                        
                        Annotation(partner.name, coordinate: partner.coordinate) {
                            ZStack {
                                Circle()
                                    .fill(Color.activeCyan.opacity(0.2))
                                    .frame(width: 60, height: 60)
                                    .blur(radius: 10)
                                
                                PartnerMarker(photoUrl: partner.profile_photo_url, isOffline: partner.isOffline)
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
                    }
                }
                .mapStyle(isSatellite ? .hybrid(elevation: .realistic) : .standard(emphasis: .muted))
                .mapControls {
                    MapCompass()
                    MapScaleView()
                }
                .ignoresSafeArea()
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
                                guard let currentUser = auth.currentUser else { return }
                                if recenterTargetMe {
                                    // Flight to ME
                                    triggerCinematicFlight(from: partner.coordinate, to: currentUser.coordinate)
                                    recenterTargetMe = false
                                } else {
                                    // Flight to PARTNER
                                    triggerCinematicFlight(from: currentUser.coordinate, to: partner.coordinate)
                                    recenterTargetMe = true
                                }
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
                    
                    // Bottom Info Card (Observing Live partner)
                    PartnerOverlayCard(user: partner, locationOverride: nil, isMinimal: false)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 30)
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
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                wavePhase = 2 * .pi
            }
        }
        .onDisappear {
            stopPolling()
        }
        // Map Live Updates
        .onReceive(timer) { _ in
            guard let partner = auth.partner else { return }
            
            // Polling matches online status: Only poll if the partner is ONLINE!
            // If they are offline, we DO NOT poll to save battery and network requests!
            if !partner.isOffline {
                Task {
                    try? await auth.fetchState()
                }
            }
        }
    }
    
    private func startPolling() {
        timer = Timer.publish(every: 30.0, on: .main, in: .common)
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
    
    private func triggerCinematicFlight(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) {
        // Calculate bearing/heading from start to end
        let lat1 = start.latitude * .pi / 180.0
        let lon1 = start.longitude * .pi / 180.0
        let lat2 = end.latitude * .pi / 180.0
        let lon2 = end.longitude * .pi / 180.0
        
        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)
        var bearing = radiansBearing * 180.0 / .pi
        if bearing < 0 { bearing += 360.0 }
        
        let startLoc = CLLocation(latitude: start.latitude, longitude: start.longitude)
        let endLoc = CLLocation(latitude: end.latitude, longitude: end.longitude)
        let distance = startLoc.distance(from: endLoc)
        
        Task {
            // --- STAGE 1: PLANE NOSE POV TAKEOFF & HIGH-SPEED FLYBY ---
            // From flat view, we instantly tilt up to 78° (Plane Nose POV),
            // rotate heading towards the target, and fly fast close to the ground.
            await MainActor.run {
                withAnimation(.timingCurve(0.4, 0.0, 0.2, 1.0, duration: 2.2)) {
                    position = .camera(MapCamera(
                        centerCoordinate: end,
                        distance: max(600.0, distance * 0.15), // Fly low to the ground
                        heading: bearing,
                        pitch: 78.0 // Low plane nose angle looking at horizon
                    ))
                }
            }
            
            try? await Task.sleep(nanoseconds: 2_000_000_000) // Sleep 2.0s during flyby
            
            // --- STAGE 2: LUXURIOUS ORBIT & SETTLE ---
            // Settle on the destination coordinate, transition pitch to a gorgeous 45° angle,
            // and slowly orbit/circle around the partner by 120° in a smooth cinematic sweep!
            await MainActor.run {
                withAnimation(.timingCurve(0.1, 0.8, 0.2, 1.0, duration: 6.0)) {
                    position = .camera(MapCamera(
                        centerCoordinate: end,
                        distance: 350.0, // Zoom in closer on target
                        heading: bearing + 120.0, // Orbit/rotate camera heading
                        pitch: 45.0 // Near 2D but tilted 3D angle
                    ))
                }
            }
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
        
        // Closer distance -> Higher frequency (excited debaran), larger relative amplitude
        // Farther distance -> Lower frequency (aurora calm), smooth wide waves
        let waveFrequency: Double = {
            if distanceInKm <= 1.0 {
                return 10.0 // Fast excited waves
            } else if distanceInKm >= 10.0 {
                return 4.0  // Wide slow calm waves
            } else {
                return 7.0  // Moderate waves
            }
        }()
        
        let amplitude = distance * 0.035
        
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

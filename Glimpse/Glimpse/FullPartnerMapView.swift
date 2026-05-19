import SwiftUI
import MapKit
import Combine

enum MapFocusTarget {
    case me
    case partner
}

struct FullPartnerMapView: View {
    @AppStorage("glimpse_default_map_style") var defaultMapStyle = "satellite"
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
    @State private var isTrackingEnabled = true
    
    @State private var animatedPartnerLatitude: Double = 0.0
    @State private var animatedPartnerLongitude: Double = 0.0
    @State private var animatedMyLatitude: Double = 0.0
    @State private var animatedMyLongitude: Double = 0.0
    
    @State private var previousPartnerDate: Date? = nil
    @State private var previousMyDate: Date? = nil
    
    // Dead reckoning: check every 1 second if extrapolation is needed
    private let deadReckoningTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    private var animatedPartnerCoordinate: CLLocationCoordinate2D {
        if let partner = auth.partner {
            return CLLocationCoordinate2D(
                latitude: animatedPartnerLatitude != 0.0 ? animatedPartnerLatitude : (partner.latitude ?? 0.0),
                longitude: animatedPartnerLongitude != 0.0 ? animatedPartnerLongitude : (partner.longitude ?? 0.0)
            )
        }
        return CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
    }
    
    private var animatedMyCoordinate: CLLocationCoordinate2D {
        if let currentUser = auth.currentUser {
            return CLLocationCoordinate2D(
                latitude: animatedMyLatitude != 0.0 ? animatedMyLatitude : (currentUser.latitude ?? 0.0),
                longitude: animatedMyLongitude != 0.0 ? animatedMyLongitude : (currentUser.longitude ?? 0.0)
            )
        }
        return CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
    }
    
    private var partnerSegments: [FootprintSegment] {
        guard let partner = auth.partner,
              let history = partner.location_history, history.count >= 2 else { return [] }
        var coords = history.map { $0.coordinate }
        
        // Sync the tail of the footprint exactly to the moving avatar
        if coords.count > 0 && animatedPartnerLatitude != 0.0 {
            coords[coords.count - 1] = animatedPartnerCoordinate
        }
        
        let count = coords.count
        return (0..<count - 1).map { i in
            FootprintSegment(
                coordinate1: coords[i],
                coordinate2: coords[i+1],
                index: i,
                totalCount: count
            )
        }
    }
    
    private var mySegments: [FootprintSegment] {
        guard let myUser = auth.currentUser,
              let history = myUser.location_history, history.count >= 2 else { return [] }
        var coords = history.map { $0.coordinate }
        
        // Sync the tail of the footprint exactly to the moving avatar
        if coords.count > 0 && animatedMyLatitude != 0.0 {
            coords[coords.count - 1] = animatedMyCoordinate
        }
        
        let count = coords.count
        return (0..<count - 1).map { i in
            FootprintSegment(
                coordinate1: coords[i],
                coordinate2: coords[i+1],
                index: i,
                totalCount: count
            )
        }
    }
    
    // Polling timer removed (Replaced by WebSocket real-time updates)
    
    init(user: GlimpseUser) {
        _position = State(initialValue: .region(MKCoordinateRegion(
            center: user.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.0015, longitudeDelta: 0.0015)
        )))
        _currentCameraCenter = State(initialValue: user.coordinate)
        _currentlyFocusedTarget = State(initialValue: .partner)
        
        let savedStyle = UserDefaults.standard.string(forKey: "glimpse_default_map_style") ?? "satellite"
        _isSatellite = State(initialValue: savedStyle == "satellite")
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
                    // 👣 Neon Footprints Trail for Partner (Zenly-Style) - Tapered Fading Shadow
                    ForEach(partnerSegments) { segment in
                        FootprintSegmentView(segment: segment, color: .activeCyan)
                    }
                    
                    // 👣 Neon Footprints Trail for Me (Zenly-Style) - Tapered Fading Shadow
                    ForEach(mySegments) { segment in
                        FootprintSegmentView(segment: segment, color: .electricPurple)
                    }

                    if auth.isTogether, let currentUser = auth.currentUser {
                        Annotation("Together", coordinate: animatedPartnerCoordinate) {
                            togetherMarker(currentUser: currentUser, partner: partner)
                        }
                    } else {
                        // Wavy Connecting line
                        if let currentUser = auth.currentUser,
                           let partnerLat = partner.latitude, partnerLat != 0.0,
                           let myLat = currentUser.latitude, myLat != 0.0 {
                            wavyConnectingLine(currentUser: currentUser, partner: partner)
                        }
                        
                        if let currentUser = auth.currentUser {
                            meAnnotation(currentUser: currentUser)
                        }
                        
                        partnerAnnotation(partner: partner)
                    }
                }
                .mapStyle(isSatellite ? .hybrid(elevation: .realistic) : .standard(emphasis: .muted))
                .mapControls {
                    MapCompass()
                    MapScaleView()
                }
                .ignoresSafeArea()
                .onMapCameraChange { context in
                    guard !isFlying else { return } // Ignore updates during cinematic flight transitions!
                    
                    if position.positionedByUser {
                        isTrackingEnabled = false
                    }
                    
                    currentCameraCenter = context.region.center
                    
                    guard let currentUser = auth.currentUser else { return }
                    let centerLoc = CLLocation(latitude: context.region.center.latitude, longitude: context.region.center.longitude)
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
                    if let lat = partner.latitude, let lon = partner.longitude, lat != 0.0, lon != 0.0 {
                        let newDate = partner.lastUpdatedDate
                        let duration: Double = {
                            if let prev = previousPartnerDate {
                                let diff = newDate.timeIntervalSince(prev)
                                // Limit between 1.0s and 10.0s to avoid crazy slow or fast animations
                                return max(1.0, min(diff, 10.0))
                            }
                            return 3.0 // Default fallback
                        }()
                        previousPartnerDate = newDate
                        
                        if animatedPartnerLatitude == 0.0 {
                            animatedPartnerLatitude = lat
                            animatedPartnerLongitude = lon
                        } else {
                            withAnimation(.linear(duration: duration)) {
                                animatedPartnerLatitude = lat
                                animatedPartnerLongitude = lon
                            }
                        }
                    }
                }
                .onChange(of: auth.currentUser?.last_updated) { _, _ in
                    guard let currentUser = auth.currentUser else { return }
                    
                    if let lat = currentUser.latitude, let lon = currentUser.longitude, lat != 0.0, lon != 0.0 {
                        let newDate = currentUser.lastUpdatedDate
                        let duration: Double = {
                            if let prev = previousMyDate {
                                let diff = newDate.timeIntervalSince(prev)
                                return max(1.0, min(diff, 10.0))
                            }
                            return 3.0 // Default fallback
                        }()
                        previousMyDate = newDate
                        
                        if animatedMyLatitude == 0.0 {
                            animatedMyLatitude = lat
                            animatedMyLongitude = lon
                        } else {
                            withAnimation(.linear(duration: duration)) {
                                animatedMyLatitude = lat
                                animatedMyLongitude = lon
                            }
                        }
                    }
                }
                .onChange(of: animatedPartnerLatitude) { _, _ in
                    if isTrackingEnabled && currentlyFocusedTarget == .partner {
                        position = .region(MKCoordinateRegion(
                            center: animatedPartnerCoordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.0015, longitudeDelta: 0.0015)
                        ))
                    }
                }
                .onChange(of: animatedMyLatitude) { _, _ in
                    if isTrackingEnabled && currentlyFocusedTarget == .me {
                        position = .region(MKCoordinateRegion(
                            center: animatedMyCoordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.0015, longitudeDelta: 0.0015)
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
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
                                UISelectionFeedbackGenerator().selectionChanged()
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
            if let partner = auth.partner, let lat = partner.latitude, let lon = partner.longitude {
                animatedPartnerLatitude = lat
                animatedPartnerLongitude = lon
            }
            triggerImmediateSync()
        }
        .onReceive(deadReckoningTimer) { _ in
            extrapolateDeadReckoning()
        }
    }
    
    private func extrapolateDeadReckoning() {
        guard let partner = auth.partner,
              let history = partner.location_history,
              history.count >= 2 else { return }
        
        let lastUpdated = partner.lastUpdatedDate
        let elapsed = Date().timeIntervalSince(lastUpdated)
        
        // Extrapolate if network drops for >= 10 seconds but < 5 minutes (300 seconds)
        guard elapsed >= 10.0 && elapsed < 300.0 else { return }
        
        let p1 = history[history.count - 2]
        let p2 = history[history.count - 1]
        
        let t1 = Double(p1.timestamp)
        let t2 = Double(p2.timestamp)
        let dt = t2 - t1
        
        guard dt > 0 else { return }
        
        let dLat = p2.latitude - p1.latitude
        let dLon = p2.longitude - p1.longitude
        
        let speedLat = dLat / dt
        let speedLon = dLon / dt
        
        // Verify user is actually moving (not stationary / sleeping)
        let distance = sqrt(pow(dLat * 111000, 2) + pow(dLon * 111000, 2))
        let speedMetersPerSec = distance / dt
        
        // Extrapolate only if moving >= 1.5 m/s (~5.4 km/h)
        guard speedMetersPerSec >= 1.5 else { return }
        
        let currentTimestamp = Date().timeIntervalSince1970
        let timeSinceLastPoint = currentTimestamp - t2
        
        // Cap extrapolation duration to max 60 seconds to avoid drifting out of bounds
        let extrapolationDuration = min(timeSinceLastPoint, 60.0)
        
        let targetLat = p2.latitude + (speedLat * extrapolationDuration)
        let targetLon = p2.longitude + (speedLon * extrapolationDuration)
        
        withAnimation(.linear(duration: 1.0)) {
            animatedPartnerLatitude = targetLat
            animatedPartnerLongitude = targetLon
        }
    }
    
    @ViewBuilder
    private func togetherMarker(currentUser: GlimpseUser, partner: GlimpseUser) -> some View {
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
                    .overlay(Circle().stroke(Color.activeCyan, lineWidth: 1.5))
                    .shadow(color: .activeCyan.opacity(0.5), radius: 5)
                
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
                    center: animatedPartnerCoordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.0015, longitudeDelta: 0.0015)
                ))
            }
        }
    }
    
    @MapContentBuilder
    private func wavyConnectingLine(currentUser: GlimpseUser, partner: GlimpseUser) -> some MapContent {
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
    
    @MapContentBuilder
    private func meAnnotation(currentUser: GlimpseUser) -> some MapContent {
        Annotation("Me", coordinate: animatedMyCoordinate) {
            ZStack {
                Circle()
                    .fill(Color.electricPurple.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .blur(radius: 10)
                
                PartnerMarker(photoUrl: currentUser.profile_photo_url, isOffline: false, batteryLevel: currentUser.battery_level, isCharging: currentUser.is_charging, locationName: currentUser.location_name, isSleeping: currentUser.is_sleeping)
            }
            .onTapGesture {
                currentlyFocusedTarget = .me
                isTrackingEnabled = true
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                    position = .region(MKCoordinateRegion(
                        center: animatedMyCoordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.0015, longitudeDelta: 0.0015)
                    ))
                }
            }
        }
    }
    
    @MapContentBuilder
    private func partnerAnnotation(partner: GlimpseUser) -> some MapContent {
        Annotation(partner.name, coordinate: animatedPartnerCoordinate) {
            ZStack {
                Circle()
                    .fill(Color.activeCyan.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .blur(radius: 10)
                
                PartnerMarker(photoUrl: partner.profile_photo_url, isOffline: partner.isOffline, batteryLevel: partner.battery_level, isCharging: partner.is_charging, locationName: partner.location_name, isSleeping: partner.is_sleeping)
            }
            .onTapGesture {
                currentlyFocusedTarget = .partner
                isTrackingEnabled = true
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                    position = .region(MKCoordinateRegion(
                        center: animatedPartnerCoordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.0015, longitudeDelta: 0.0015)
                    ))
                }
            }
        }
    }
    
    private func triggerImmediateSync() {
        Task {
            try? await auth.fetchState()
            if let partner = auth.partner {
                await MainActor.run {
                    if let lat = partner.latitude, let lon = partner.longitude {
                        animatedPartnerLatitude = lat
                        animatedPartnerLongitude = lon
                    }
                    withAnimation(.spring()) {
                        position = .region(MKCoordinateRegion(
                            center: partner.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.0015, longitudeDelta: 0.0015)
                        ))
                    }
                }
            }
        }
    }
    
    private func triggerCinematicFlight(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, targetFocus: MapFocusTarget) {
        isTrackingEnabled = true
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
            let targetZoom = min(8_000_000.0, max(1500.0, distance * 2.2))
            
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
                        distance: 150.0,
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

struct FootprintSegment: Identifiable {
    var id: String { "segment-\(index)" }
    let coordinate1: CLLocationCoordinate2D
    let coordinate2: CLLocationCoordinate2D
    let index: Int
    let totalCount: Int
}

struct FootprintSegmentView: MapContent {
    let segment: FootprintSegment
    let color: Color
    
    private var progress: Double {
        segment.totalCount > 1 ? Double(segment.index) / Double(segment.totalCount - 1) : 1.0
    }
    
    private var opacity: Double {
        0.35 + (progress * 0.45)
    }
    
    private var width: CGFloat {
        CGFloat(1.5 + (progress * 1.5))
    }
    
    @MapContentBuilder
    var body: some MapContent {
        // 1. Neon Glow Layer
        MapPolyline(coordinates: [segment.coordinate1, segment.coordinate2])
            .stroke(
                color.opacity(opacity * 0.3),
                style: StrokeStyle(lineWidth: width + 2.0, lineCap: .round, lineJoin: .round)
            )
        
        // 2. Core Saturated Neon Layer
        MapPolyline(coordinates: [segment.coordinate1, segment.coordinate2])
            .stroke(
                color.opacity(opacity),
                style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
            )
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

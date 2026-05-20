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
    
    // Glow/Pulse Animation states
    @State private var meGlowScale: CGFloat = 1.0
    @State private var meGlowOpacity: Double = 0.0
    @State private var meAvatarScale: CGFloat = 1.0
    @State private var partnerGlowScale: CGFloat = 1.0
    @State private var partnerGlowOpacity: Double = 0.0
    @State private var partnerAvatarScale: CGFloat = 1.0
    
    @State private var animatedPartnerLatitude: Double = 0.0
    @State private var animatedPartnerLongitude: Double = 0.0
    @State private var animatedMyLatitude: Double = 0.0
    @State private var animatedMyLongitude: Double = 0.0
    
    // Asynchronous interpolation tasks and queues for frame-by-frame glide
    @State private var partnerInterpolationTask: Task<Void, Never>? = nil
    @State private var partnerCoordinateQueue: [CLLocationCoordinate2D] = []
    @State private var isInterpolatingPartner = false
    
    @State private var myInterpolationTask: Task<Void, Never>? = nil
    @State private var myCoordinateQueue: [CLLocationCoordinate2D] = []
    @State private var isInterpolatingMy = false
    
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

    
    // Polling timer removed (Replaced by WebSocket real-time updates)
    
    init(user: GlimpseUser) {
        _position = State(initialValue: .region(MKCoordinateRegion(
            center: user.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.0022, longitudeDelta: 0.0022)
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
                        let newCoord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                        partnerCoordinateQueue.append(newCoord)
                        
                        if !isInterpolatingPartner {
                            startPartnerQueueInterpolator()
                        }
                    }
                }
                .onChange(of: auth.currentUser?.last_updated) { _, _ in
                    guard let currentUser = auth.currentUser else { return }
                    if let lat = currentUser.latitude, let lon = currentUser.longitude, lat != 0.0, lon != 0.0 {
                        let newCoord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                        myCoordinateQueue.append(newCoord)
                        
                        if !isInterpolatingMy {
                            startMyQueueInterpolator()
                        }
                    }
                }
                .onChange(of: animatedPartnerLatitude) { _, _ in
                    guard !isFlying else { return }
                    if isTrackingEnabled && currentlyFocusedTarget == .partner {
                        position = .region(MKCoordinateRegion(
                            center: animatedPartnerCoordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.0022, longitudeDelta: 0.0022)
                        ))
                    }
                }
                .onChange(of: animatedMyLatitude) { _, _ in
                    guard !isFlying else { return }
                    if isTrackingEnabled && currentlyFocusedTarget == .me {
                        position = .region(MKCoordinateRegion(
                            center: animatedMyCoordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.0022, longitudeDelta: 0.0022)
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
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    UISelectionFeedbackGenerator().selectionChanged()
                                    isTrackingEnabled = true
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                                        position = .region(MKCoordinateRegion(
                                            center: animatedMyCoordinate,
                                            span: MKCoordinateSpan(latitudeDelta: 0.0022, longitudeDelta: 0.0022)
                                        ))
                                    }
                                    triggerMeGlow()
                                }
                        } else {
                            PartnerOverlayCard(user: partner, locationOverride: nil, isMinimal: false)
                                .id("partner_card")
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    UISelectionFeedbackGenerator().selectionChanged()
                                    isTrackingEnabled = true
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                                        position = .region(MKCoordinateRegion(
                                            center: animatedPartnerCoordinate,
                                            span: MKCoordinateSpan(latitudeDelta: 0.0022, longitudeDelta: 0.0022)
                                        ))
                                    }
                                    triggerPartnerGlow()
                                }
                        }
                    }
                    .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity))
                    .animation(.spring(response: 0.45, dampingFraction: 0.8), value: currentlyFocusedTarget)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                    .shadow(color: Color.black.opacity(0.25), radius: 10, y: 5)
                    .gesture(
                        DragGesture(minimumDistance: 20)
                            .onEnded { value in
                                let threshold: CGFloat = 30
                                if abs(value.translation.height) > threshold || abs(value.translation.width) > threshold {
                                    guard !isFlying else { return }
                                    guard let currentUser = auth.currentUser else { return }
                                    
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    
                                    let nextTarget: MapFocusTarget = (currentlyFocusedTarget == .me) ? .partner : .me
                                    let myCoord = currentUser.coordinate
                                    let partnerCoord = partner.coordinate
                                    
                                    isFlying = true
                                    
                                    let targetCoord = (nextTarget == .me) ? myCoord : partnerCoord
                                    let startCoord = (nextTarget == .me) ? partnerCoord : myCoord
                                    
                                    triggerCinematicFlight(from: startCoord, to: targetCoord, targetFocus: nextTarget)
                                }
                            }
                    )
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
                    span: MKCoordinateSpan(latitudeDelta: 0.0022, longitudeDelta: 0.0022)
                ))
            }
        }
        .id("together_marker")
    }
    
    @MapContentBuilder
    private func wavyConnectingLine(currentUser: GlimpseUser, partner: GlimpseUser) -> some MapContent {
        let startLoc = CLLocation(latitude: animatedMyCoordinate.latitude, longitude: animatedMyCoordinate.longitude)
        let endLoc = CLLocation(latitude: animatedPartnerCoordinate.latitude, longitude: animatedPartnerCoordinate.longitude)
        let distanceInKm = startLoc.distance(from: endLoc) / 1000.0
        
        let colors = getShiftingColors(phase: wavePhase, distanceInKm: distanceInKm)
        let wavyCoords = generateWavyCoordinates(from: animatedMyCoordinate, to: animatedPartnerCoordinate, distanceInKm: distanceInKm, phase: wavePhase)
        
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
                // Expanding neon glow ring
                Circle()
                    .stroke(Color.electricPurple, lineWidth: 3)
                    .scaleEffect(meGlowScale)
                    .opacity(meGlowOpacity)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .fill(Color.electricPurple.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .blur(radius: 10)
                
                PartnerMarker(photoUrl: currentUser.profile_photo_url, isOffline: false, batteryLevel: currentUser.battery_level, isCharging: currentUser.is_charging, locationName: currentUser.location_name, isSleeping: currentUser.is_sleeping)
                    .scaleEffect(meAvatarScale)
            }
            .onTapGesture {
                currentlyFocusedTarget = .me
                isTrackingEnabled = true
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                    position = .region(MKCoordinateRegion(
                        center: animatedMyCoordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.0022, longitudeDelta: 0.0022)
                    ))
                }
                triggerMeGlow()
            }
            .id("me_marker")
        }
    }
    
    @MapContentBuilder
    private func partnerAnnotation(partner: GlimpseUser) -> some MapContent {
        Annotation(partner.name, coordinate: animatedPartnerCoordinate) {
            ZStack {
                // Expanding neon glow ring
                Circle()
                    .stroke(Color.activeCyan, lineWidth: 3)
                    .scaleEffect(partnerGlowScale)
                    .opacity(partnerGlowOpacity)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .fill(Color.activeCyan.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .blur(radius: 10)
                
                PartnerMarker(photoUrl: partner.profile_photo_url, isOffline: partner.isOffline, batteryLevel: partner.battery_level, isCharging: partner.is_charging, locationName: partner.location_name, isSleeping: partner.is_sleeping)
                    .scaleEffect(partnerAvatarScale)
            }
            .onTapGesture {
                currentlyFocusedTarget = .partner
                isTrackingEnabled = true
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                    position = .region(MKCoordinateRegion(
                        center: animatedPartnerCoordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.0022, longitudeDelta: 0.0022)
                    ))
                }
                triggerPartnerGlow()
            }
            .id("partner_marker")
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
                            span: MKCoordinateSpan(latitudeDelta: 0.0022, longitudeDelta: 0.0022)
                        ))
                    }
                }
            }
        }
    }
    
    private func triggerCinematicFlight(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, targetFocus: MapFocusTarget) {
        isTrackingEnabled = true
        
        // Update bottom overlay info card instantly at start for zero latency!
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            currentlyFocusedTarget = targetFocus
        }
        
        Task {
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.6)) {
                    position = .camera(MapCamera(
                        centerCoordinate: end,
                        distance: 250.0,
                        heading: 0.0,
                        pitch: 0.0
                    ))
                }
            }
            
            // Wait for slide to settle (0.6 seconds)
            try? await Task.sleep(nanoseconds: 600_000_000)
            
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
    
    private func triggerMeGlow() {
        meGlowScale = 1.0
        meGlowOpacity = 1.0
        
        withAnimation(.easeOut(duration: 0.8)) {
            meGlowScale = 1.6
            meGlowOpacity = 0.0
            meAvatarScale = 1.15
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                meAvatarScale = 1.0
            }
        }
    }
    
    private func triggerPartnerGlow() {
        partnerGlowScale = 1.0
        partnerGlowOpacity = 1.0
        
        withAnimation(.easeOut(duration: 0.8)) {
            partnerGlowScale = 1.6
            partnerGlowOpacity = 0.0
            partnerAvatarScale = 1.15
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                partnerAvatarScale = 1.0
            }
        }
    }
    
    private func startPartnerQueueInterpolator() {
        isInterpolatingPartner = true
        partnerInterpolationTask?.cancel()
        
        partnerInterpolationTask = Task {
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
                    if speedKmH >= 3.0 {
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
            isInterpolatingPartner = false
        }
    }
    
    private func startMyQueueInterpolator() {
        isInterpolatingMy = true
        myInterpolationTask?.cancel()
        
        myInterpolationTask = Task {
            while !myCoordinateQueue.isEmpty {
                if Task.isCancelled { break }
                
                let target = myCoordinateQueue.removeFirst()
                let startLat = animatedMyLatitude == 0.0 ? target.latitude : animatedMyLatitude
                let startLon = animatedMyLongitude == 0.0 ? target.longitude : animatedMyLongitude
                
                let startLoc = CLLocation(latitude: startLat, longitude: startLon)
                let targetLoc = CLLocation(latitude: target.latitude, longitude: target.longitude)
                let distance = targetLoc.distance(from: startLoc)
                
                let duration: TimeInterval = myCoordinateQueue.count > 1 ? 1.2 : 2.5
                
                let speedMps = distance / duration
                let speedKmH = speedMps * 3.6
                
                await MainActor.run {
                    if speedKmH >= 3.0 {
                        auth.updateMySpeed(speedKmH)
                    } else {
                        auth.updateMySpeed(nil)
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
                        animatedMyLatitude = currentLat
                        animatedMyLongitude = currentLon
                    }
                    
                    if progress >= 1.0 { break }
                    try? await Task.sleep(nanoseconds: UInt64(stepInterval * 1_000_000_000))
                }
            }
            await MainActor.run {
                auth.updateMySpeed(nil)
            }
            isInterpolatingMy = false
        }
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

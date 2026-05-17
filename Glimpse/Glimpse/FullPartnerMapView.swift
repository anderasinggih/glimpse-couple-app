import SwiftUI
import MapKit
import Combine

struct FullPartnerMapView: View {
    @State private var auth = AuthManager.shared
    @State private var position: MapCameraPosition
    @State private var mapStyle: MapStyle = .standard(emphasis: .muted)
    @State private var isSatellite = true
    @State private var mapPulse = false
    
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
            if let partner = auth.partner {
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
                            MapPolyline(coordinates: generateWavyCoordinates(from: currentUser.coordinate, to: partner.coordinate))
                                .stroke(
                                    LinearGradient(
                                        colors: [.electricPurple, .pink, .activeCyan],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
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
                            Button {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                                    position = .region(MKCoordinateRegion(
                                        center: partner.coordinate,
                                        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                                    ))
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
                // Not Connected / No Partner View
                VStack(spacing: 15) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.3))
                    Text("Find your partner first")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.deepVelvet)
            }
        }
        .onAppear {
            startPolling()
            triggerImmediateSync()
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
    
    private func generateWavyCoordinates(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> [CLLocationCoordinate2D] {
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
        
        let amplitude = distance * 0.035
        let waveFrequency = 6.0
        
        for i in 0...pointsCount {
            let t = Double(i) / Double(pointsCount)
            let linearLat = start.latitude + dLat * t
            let linearLon = start.longitude + dLon * t
            
            let envelope = sin(t * Double.pi)
            let wave = sin(t * Double.pi * waveFrequency) * amplitude * envelope
            
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

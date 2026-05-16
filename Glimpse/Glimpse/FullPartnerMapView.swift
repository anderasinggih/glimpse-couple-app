import SwiftUI
import MapKit
import Combine

struct FullPartnerMapView: View {
    @State private var auth = AuthManager.shared
    @State private var position: MapCameraPosition
    @State private var mapStyle: MapStyle = .standard(emphasis: .muted)
    @State private var isSatellite = true
    
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
                    Annotation(partner.name, coordinate: partner.coordinate) {
                        PartnerMarker(photoUrl: partner.profile_photo_url, isOffline: partner.isOffline)
                    }
                }
                .mapStyle(isSatellite ? .hybrid(elevation: .realistic) : .standard(emphasis: .muted))
                .mapControls {
                    MapCompass()
                    MapScaleView()
                }
                .ignoresSafeArea()
                // Automatically move map camera smoothly when partner's live coordinates change
                .onChange(of: partner.coordinate) { _, newCoord in
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        position = .region(MKCoordinateRegion(
                            center: newCoord,
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

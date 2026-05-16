import SwiftUI
import MapKit

struct FullPartnerMapView: View {
    let user: GlimpseUser
    @State private var position: MapCameraPosition
    
    @State private var mapStyle: MapStyle = .standard(emphasis: .muted)
    @State private var isSatellite = false
    
    init(user: GlimpseUser) {
        self.user = user
        _position = State(initialValue: .region(MKCoordinateRegion(
            center: user.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )))
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Full Screen Map
            Map(position: $position) {
                Annotation(user.name, coordinate: user.coordinate) {
                    PartnerMarker(photoUrl: user.profile_photo_url, isOffline: user.isOffline)
                }
            }
            .mapStyle(isSatellite ? .hybrid(elevation: .realistic) : .standard(emphasis: .muted))
            .mapControls {
                // System compass stays top-right by default, or we can hide it
                MapCompass()
                MapScaleView()
            }
            .ignoresSafeArea()
            
            // UI Overlay Layer
            VStack(spacing: 0) {
                // Top: Branding
                BrandingHeader()
                
                Spacer()
                
                // Bottom Area: Controls & Info Card
                VStack(alignment: .trailing, spacing: 16) {
                    
                    // Floating Native-style Controls (Bottom Right)
                    VStack(spacing: 12) {
                        // 1. Map Style Switcher (Native Look)
                        Button {
                            withAnimation { isSatellite.toggle() }
                        } label: {
                            Image(systemName: isSatellite ? "map.fill" : "globe.americas.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.electricPurple)
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.circle)
                        .controlSize(.large)
                        .tint(.white.opacity(0.1)) // Pure Native Glass feel
                        
                        // 2. Native Location Button
                        MapUserLocationButton()
                    }
                    .padding(.trailing, 16)
                    
                    // Bottom Partner Card
                    PartnerOverlayCard(user: user)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                }
            }
        }
    }
}

#Preview {
    FullPartnerMapView(user: .mockPartner)
}

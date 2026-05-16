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
        ZStack(alignment: .top) {
            // Full Screen Map
            Map(position: $position) {
                Annotation(user.name, coordinate: user.coordinate) {
                    PartnerMarker(photoUrl: user.profile_photo_url, isOffline: user.isOffline)
                }
            }
            .mapStyle(isSatellite ? .hybrid(elevation: .realistic) : .standard(emphasis: .muted))
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            .ignoresSafeArea()
            
            // Branding & Controls Overlay
            VStack(spacing: 0) {
                BrandingHeader()
                
                HStack {
                    Spacer()
                    // Map Style Switcher
                    Button {
                        withAnimation { isSatellite.toggle() }
                    } label: {
                        Image(systemName: isSatellite ? "map.fill" : "globe.americas.fill")
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)
                    .controlSize(.large)
                    .tint(.white.opacity(0.1))
                    .padding(.trailing, 10)
                }
                
                Spacer()
                
                // Location Button: Floating above the card on the right
                HStack {
                    Spacer()
                    Button {
                        withAnimation {
                            position = .userLocation(fallback: .automatic)
                        }
                    } label: {
                        Image(systemName: "location.fill")
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)
                    .controlSize(.large)
                    .tint(.white.opacity(0.1))
                }
                .padding(.trailing, 20)
                .padding(.bottom, 12) // Gap above the card
                
                // Bottom Info Card
                PartnerOverlayCard(user: user)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
            }
        }
    }
}

#Preview {
    FullPartnerMapView(user: .mockPartner)
}

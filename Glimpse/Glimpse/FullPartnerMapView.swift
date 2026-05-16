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
            
            // UI Overlay Layer
            VStack(spacing: 0) {
                // Top Branding (No blur background)
                BrandingHeader()
                
                Spacer()
                
                // Bottom Controls (Satellite & Location buttons above the card)
                VStack(spacing: 12) {
                    HStack {
                        // Satellite Switcher (Native Style)
                        Button {
                            withAnimation { isSatellite.toggle() }
                        } label: {
                            Image(systemName: isSatellite ? "map.fill" : "globe.americas.fill")
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.circle)
                        .controlSize(.large)
                        
                        Spacer()
                        
                        // Location Button (Native Style)
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
                    }
                    .padding(.horizontal, 20)
                    
                    // Bottom Info Card
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
